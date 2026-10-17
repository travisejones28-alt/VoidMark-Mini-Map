-- Pure Lua 5.1 footer calculations, shared by the live UI and regression tests.
VoidMarkMiniMapFooter = {}
local F = VoidMarkMiniMapFooter
local function finite(n)
    if issecretvalue and issecretvalue(n) then return false end
    return type(n)=="number" and n==n and n~=math.huge and n~=-math.huge
end
function F.Clock(hour, minute, clock24)
    if not finite(hour) or not finite(minute) or hour<0 or hour>=24 or minute<0 or minute>=60 then return "--:--" end
    hour,minute=math.floor(hour),math.floor(minute)
    if clock24 then return string.format("%02d:%02d",hour,minute) end
    local display=hour%12; if display==0 then display=12 end
    return string.format("%d:%02d %s",display,minute,hour<12 and "AM" or "PM")
end
function F.Durability(api)
    if type(api)~="function" then return nil end
    local current,maximum=0,0
    for slot=1,19 do
        local ok,c,m=pcall(function()
            local c,m=api(slot)
            if issecretvalue and (issecretvalue(c) or issecretvalue(m)) then return end
            if finite(c) and finite(m) and m>0 and c>=0 then return math.min(c,m),m end
        end)
        if ok and c and m then current=current+c;maximum=maximum+m end
    end
    if maximum==0 or not finite(maximum) or not finite(current) then return nil end
    return current/maximum*100
end
function F.Color(percent)
    if not finite(percent) then return .65,.65,.72 end
    if percent>70 then return .30,.95,.45 end
    if percent>=30 then return 1,.82,.20 end
    return 1,.28,.28
end
-- Entries contain natural full/compact text widths. All offsets remain inside width.
-- Priority: time, durability, coordinates, FPS. Presentation order stays unchanged.
function F.Plan(width,entries)
    width=math.max(0,width or 0)
    local compact,icons=false,true
    local shown={};for i,e in ipairs(entries) do shown[i]=e.enabled end
    local function total()
        local n,sum=0,0
        for i,e in ipairs(entries) do if shown[i] then
            n=n+1;sum=sum+(compact and e.compactWidth or e.width)+(icons and e.icon and 17 or 0)
        end end
        return sum+math.max(0,n-1)*16+16,n
    end
    if total()>width then compact=true end
    if total()>width then icons=false end
    for _,key in ipairs({"fps","coordinates","durability"}) do
        if total()>width then for i,e in ipairs(entries) do if e.key==key then shown[i]=false end end end
    end
    local used,count=total()
    local spare=math.max(0,width-used)
    local x=8
    local result={compact=compact,icons=icons,items={},width=width}
    for i,e in ipairs(entries) do if shown[i] then
        local w=(compact and e.compactWidth or e.width)+(icons and e.icon and 17 or 0)
        w=math.min(w,math.max(0,width-x-8))
        result.items[i]={x=x,width=w,icon=icons and e.icon or false}
        x=x+w+(count>0 and spare/count or 0)+16
    end end
    return result
end
