-- Repair prices are read only. This module never buys, repairs or changes game tooltips.
local R = {}
VoidMarkMiniMapRepair = R
local LIMIT, AGE, MAX_COST = 64, 30*24*60*60, 1000000000000
local nonDurableSlots={[2]=true,[4]=true,[11]=true,[12]=true,[13]=true,[14]=true,[15]=true,[19]=true}
local function number(v)
    if issecretvalue and issecretvalue(v) then return nil end
    if type(v)=="number" and v==v and v~=math.huge and v~=-math.huge then return v end
end
local function call(fn,...)
    if type(fn)~="function" then return nil end
    local ok,value=pcall(fn,...)
    if ok then return value end
end
local function now()
    local n=number(call(time))
    return n and n>=0 and n or nil
end
local function cost(v)
    v=number(v)
    return v and v>=0 and v<=MAX_COST and v==math.floor(v) and v or nil
end
local function valid(record,t)
    return type(record)=="table" and number(record.rate) and record.rate>0 and record.rate<=MAX_COST
        and number(record.at) and t and record.at>=0 and record.at<=t+300 and t-record.at<=AGE
        and number(record.maximum) and record.maximum>0
end
local function identity(link,maximum)
    if issecretvalue and issecretvalue(link) then return nil end
    if type(link)~="string" or #link>1024 then return nil end
    local item=link:match("(item:[%d:%-]+)")
    return item and #item<=512 and (item.."/"..tostring(maximum)) or nil
end
function R.New(db)
    local self=setmetatable({db=db},{__index=R})
    local saved=db.repairObservations
    if type(saved)=="table" and saved.version~=nil and saved.version~=1 then
        -- An unrecognized future cache must not be destroyed by an older addon.
        self.cache={version=1,items={}}
    else
        self.cache={version=1,items={}}
        if type(saved)=="table" and type(saved.items)=="table" then
            local t=now()
            for key,record in pairs(saved.items) do
                if type(key)=="string" and #key<=550 and valid(record,t) then
                    self.cache.items[key]={rate=record.rate,at=record.at,maximum=record.maximum,
                        weight=math.min(16,math.max(1,number(record.weight) or 1)),
                        lastLost=number(record.lastLost),lastCost=cost(record.lastCost)}
                end
            end
        end
        db.repairObservations=self.cache
    end
    self:Prune()
    return self
end
function R:Prune()
    local rows,t={},now()
    for key,record in pairs(self.cache.items) do
        if not valid(record,t) then self.cache.items[key]=nil
        else rows[#rows+1]={key=key,at=record.at} end
    end
    table.sort(rows,function(a,b) if a.at==b.at then return a.key<b.key end return a.at>b.at end)
    for i=LIMIT+1,#rows do self.cache.items[rows[i].key]=nil end
end
function R:Observe(key,maximum,lost,price)
    local t=now()
    if not key or not t or lost<=0 or not price or price<=0 then return end
    local old=self.cache.items[key]
    if valid(old,t) and old.lastLost==lost and old.lastCost==price then old.at=t;return end
    local rate,weight=price/lost,1
    if valid(old,t) and old.maximum==maximum then
        local w=math.min(15,old.weight or 1)
        rate=(old.rate*w+rate)/(w+1);weight=w+1
    end
    self.cache.items[key]={rate=rate,weight=weight,maximum=maximum,at=t,lastLost=lost,lastCost=price}
end
function R:ItemPrice(slot)
    local ok,price=pcall(function()
        if C_TooltipInfo and type(C_TooltipInfo.GetInventoryItem)=="function" then
            local data=C_TooltipInfo.GetInventoryItem("player",slot)
            if not (issecretvalue and issecretvalue(data)) and type(data)=="table" then return cost(data.repairCost) end
        end
    end)
    if ok and price~=nil then return price end
    -- Classic fallback: one private, hidden scanner; never borrow GameTooltip.
    if not self.scannerTried then
        self.scannerTried=true
        self.scanner=call(CreateFrame,"GameTooltip","VoidMarkMiniMapRepairScan",UIParent,"GameTooltipTemplate")
    end
    local scanner=self.scanner
    if not scanner then return nil end
    ok,price=pcall(function()
        scanner:SetOwner(UIParent,"ANCHOR_NONE")
        scanner:ClearLines()
        local _,_,quote=scanner:SetInventoryItem("player",slot)
        local value=cost(quote)
        if value~=nil then return value end
        if scanner.GetTooltipData then
            local data=scanner:GetTooltipData()
            if not (issecretvalue and issecretvalue(data)) and type(data)=="table" then return cost(data.repairCost) end
        end
    end)
    if scanner.Hide then pcall(scanner.Hide,scanner) end
    return ok and price or nil
end
function R:Refresh(merchantOpen)
    local merchant=false
    if merchantOpen then
        local ok,can=pcall(function()
            local v=CanMerchantRepair and CanMerchantRepair()
            if issecretvalue and issecretvalue(v) then return false end
            return v==true or v==1
        end)
        merchant=ok and can
    end
    local total,complete,hasDurability,estimated=0,true,false,false
    for slot=1,19 do
        local ok,current,maximum,key=pcall(function()
            if type(GetInventoryItemDurability)~="function" then error("Durability unavailable") end
            local c,m=GetInventoryItemDurability(slot)
            local link=call(GetInventoryItemLink,"player",slot)
            if c==nil and m==nil then
                if not link or nonDurableSlots[slot] then return end
                -- Frills/relics occupy weapon slots but are not repairable. A
                -- populated armor slot with unreadable durability is not free.
                local getInfo=(C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
                local equipLoc
                if getInfo then local _,_,_,location=getInfo(link);equipLoc=location end
                if equipLoc=="INVTYPE_HOLDABLE" or equipLoc=="INVTYPE_RELIC" then return end
                error("Equipped item durability is not ready")
            end
            c,m=number(c),number(m)
            if not c or not m or m<=0 or c<0 or c>m then error("Unreadable durability") end
            return c,m,identity(link,m)
        end)
        if not ok then complete=false
        elseif current and maximum then
            hasDurability=true
            local lost=maximum-current
            if lost>0 then
                local price=self:ItemPrice(slot)
                if price~=nil then
                    total=total+price
                    if merchant then self:Observe(key,maximum,lost,price) end
                else
                    local record=key and self.cache.items[key]
                    if valid(record,now()) and record.maximum==maximum then
                        total=total+record.rate*lost;estimated=true
                    else complete=false end
                end
            end
        end
    end
    self:Prune()
    local result
    if complete and hasDurability and total<=MAX_COST then result={cost=math.floor(total+.5),estimated=estimated} end
    if merchant then
        local ok,quote=pcall(function() return cost(GetRepairAllCost and GetRepairAllCost()) end)
        if ok and quote~=nil then
            -- The merchant total can include damaged bag gear: display, never train on it.
            result={cost=quote,vendorTotal=true}
        end
    end
    self.result=result
    return result
end
function R.Money(copper)
    if cost(copper)==nil then return "Unavailable" end
    return string.format("%dg %ds %dc",math.floor(copper/10000),math.floor(copper/100)%100,copper%100)
end
function R.Line(result)
    if type(result)~="table" or cost(result.cost)==nil then return "Repair cost: Unavailable" end
    local copper=result.cost
    -- Historical values are approximate, rounded to silver rather than false copper precision.
    if result.estimated then copper=math.floor((copper+50)/100)*100 end
    return "Repair cost: "..(result.estimated and "~" or "")..R.Money(copper)..(result.vendorTotal and " (vendor total)" or "")
end
