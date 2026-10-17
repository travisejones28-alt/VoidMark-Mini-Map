local R=assert(VoidMarkMiniMapRepair)
local count=0
local function test(name,fn) fn();count=count+1;print('PASS repair: '..name) end
local function setup()
 time=function()return 1000000 end
 issecretvalue=nil
 CreateFrame=nil;UIParent={}
 GameTooltip={untouched=true}
 C_Item=nil;GetItemInfoInstant=nil
 CanMerchantRepair=function()return false end
 GetRepairAllCost=nil
 local items={ [1]={current=90,maximum=100,id=100,price=26157} }
 GetInventoryItemDurability=function(slot)local i=items[slot];if i then return i.current,i.maximum end end
 GetInventoryItemLink=function(_,slot)local i=items[slot];return i and ('|Hitem:'..i.id..':0|h[Gear]|h') end
 C_TooltipInfo={GetInventoryItem=function(_,slot)local i=items[slot];return i and {repairCost=i.price} end}
 return items
end
local function nkeys(t)local n=0;for _ in pairs(t)do n=n+1 end;return n end
test('live API price and compact gold/silver/copper format',function()
 local items=setup();local r=R.New({});local result=r:Refresh(false)
 assert(result.cost==26157 and not result.estimated)
 assert(R.Line(result)=='Repair cost: 2g 61s 57c')
 assert(R.Money(0)=='0g 0s 0c' and R.Money(101)=='0g 1s 1c')
 items[5]={current=0,maximum=20,id=200,price=100};assert(r:Refresh(false).cost==26257)
 assert(nkeys(r.cache.items)==0,'Non-vendor readings must not become vendor observations')
end)
test('fully repaired equipment is zero, missing data is unknown',function()
 local items=setup();items[1].current=100
 local r=R.New({});assert(r:Refresh(false).cost==0)
 items[1].current=90;items[1].price=nil
 assert(r:Refresh(false)==nil and R.Line(nil)=='Repair cost: Unavailable')
 GetInventoryItemDurability=nil;assert(r:Refresh(false)==nil)
end)
test('partially unavailable equipped armor cannot produce a partial total',function()
 local items=setup();items[5]={id=200,price=100,current=50,maximum=100}
 GetInventoryItemDurability=function(slot)if slot==5 then return 50,100 end end
 assert(R.New({}):Refresh(false)==nil)
 -- A known non-durable relic in the same slot is safe to omit.
 GetItemInfoInstant=function()return 100,'Armor','Relic','INVTYPE_RELIC' end
 assert(R.New({}):Refresh(false).cost==100)
end)
test('repair merchant quote wins and is labeled as including bag gear',function()
 setup();CanMerchantRepair=function()return true end
 GetRepairAllCost=function()return 50000,true end
 local r=R.New({});local result=r:Refresh(true)
 assert(result.cost==50000 and result.vendorTotal)
 assert(R.Line(result)=='Repair cost: 5g 0s 0c (vendor total)')
 assert(r:Refresh(false).cost==26157,'Closed merchant quote must not remain active')
 CanMerchantRepair=function()return false end
 assert(r:Refresh(true).cost==26157,'Non-repair vendor must not supply repair total')
end)
test('vendor observations survive reload and refine future estimates',function()
 local items=setup();CanMerchantRepair=function()return true end
 local db={size=350,clock24=false};local r=R.New(db)
 items[1].price=1000;r:Refresh(true)
 assert(db.size==350 and db.clock24==false and db.repairObservations.version==1)
 local key=next(r.cache.items);assert(r.cache.items[key].rate==100)
 items[1].price=2000;r:Refresh(true)
 assert(r.cache.items[key].rate==150 and r.cache.items[key].weight==2)
 r:Refresh(true);assert(r.cache.items[key].weight==2,'Repeated identical quote must not bias observations')
 items[1].price=nil;items[1].current=80
 local reloaded=R.New(db);local result=reloaded:Refresh(false)
 assert(result.estimated and result.cost==3000 and R.Line(result)=='Repair cost: ~0g 30s 0c')
 items[1].price=1234
 result=reloaded:Refresh(false);assert(result.cost==1234 and not result.estimated,'Live API price must beat history')
end)
test('unknown or changed equipment cannot borrow another item price',function()
 local items=setup();CanMerchantRepair=function()return true end
 local r=R.New({});r:Refresh(true)
 items[1].id=101;items[1].price=nil;assert(r:Refresh(false)==nil)
 items[1].id=100;items[1].maximum=120;assert(r:Refresh(false)==nil)
end)
test('aggregate bag-inclusive vendor quote is never used to train equipment estimates',function()
 local items=setup();items[1].price=nil
 CanMerchantRepair=function()return true end;GetRepairAllCost=function()return 999999,true end
 local r=R.New({});assert(r:Refresh(true).vendorTotal)
 assert(nkeys(r.cache.items)==0 and r:Refresh(false)==nil)
end)
test('expired, future and corrupt observations are dropped; cache is bounded',function()
 setup();local data={};for i=1,100 do data['item:'..i..'/100']={rate=100,at=1000000-i,maximum=100}end
 data.old={rate=1,at=0,maximum=100};data.future={rate=1,at=1000500,maximum=100};data.bad={rate=0/0,at=1000000,maximum=100}
 local r=R.New({repairObservations={version=1,items=data}})
 assert(nkeys(r.cache.items)==64 and not r.cache.items.old and not r.cache.items.future and not r.cache.items.bad)
 time=function()return 1000000+31*86400 end;r:Refresh(false);assert(nkeys(r.cache.items)==0)
end)
test('new vendor observations remain bounded across many different items',function()
 local items=setup();CanMerchantRepair=function()return true end;local r=R.New({})
 for i=1,100 do items[1].id=i;r:Refresh(true) end
 assert(nkeys(r.cache.items)==64)
end)
test('future cache schemas and unrelated preferences are preserved',function()
 setup();local future={version=20,items={untouched=true}};local db={repairObservations=future,fps=false}
 local r=R.New(db);r:Refresh(false)
 assert(db.repairObservations==future and db.repairObservations.items.untouched and db.fps==false)
 assert(R.New({repairObservations='broken'}).cache.version==1)
end)
test('legacy private scanner returns third value and remains hidden',function()
 setup();C_TooltipInfo=nil
 local made,cleared,hidden=0,0,false
 local scanner={SetOwner=function(_,owner,anchor)assert(owner==UIParent and anchor=='ANCHOR_NONE')end,
  ClearLines=function()cleared=cleared+1 end,SetInventoryItem=function(_,unit,slot)assert(unit=='player' and slot==1);return true,false,26157 end,
  Hide=function()hidden=true end}
 CreateFrame=function(kind,name,parent,template)made=made+1;assert(kind=='GameTooltip' and template=='GameTooltipTemplate');return scanner end
 local r=R.New({});assert(r:Refresh(false).cost==26157);assert(r:Refresh(false).cost==26157)
 assert(made==1 and cleared==2 and hidden and GameTooltip.untouched)
end)
test('modern missing price falls back to scanner data and scanner is hidden after errors',function()
 setup();local hidden=false
 local scanner={SetOwner=function()end,ClearLines=function()end,SetInventoryItem=function()return true end,
 GetTooltipData=function()return {repairCost=42}end,Hide=function()hidden=true end}
 C_TooltipInfo.GetInventoryItem=function()return {}end
 CreateFrame=function()return scanner end
 local r=R.New({});assert(r:Refresh(false).cost==42 and hidden)
 scanner.SetInventoryItem=function()error('restricted')end;hidden=false
 assert(r:Refresh(false)==nil and hidden)
end)
test('restricted, throwing, negative and nonfinite APIs fail closed',function()
 local items=setup();local secret={};issecretvalue=function(v)return v==secret end
 local r=R.New({})
 for _,v in ipairs({secret,-1,0/0,math.huge,'100'})do items[1].price=v;assert(r:Refresh(false)==nil) end
 C_TooltipInfo.GetInventoryItem=function()error('unavailable')end;assert(r:Refresh(false)==nil)
 GetInventoryItemDurability=function()return secret,100 end;assert(r:Refresh(false)==nil)
 assert(R.Money(secret)=='Unavailable' and R.Money(-1)=='Unavailable')
 CanMerchantRepair=function()return secret end;GetRepairAllCost=function()error('must not be used')end
 assert(r:Refresh(true)==nil)
end)
test('no clock means no persistent price learning, but live prices still work',function()
 setup();time=nil;CanMerchantRepair=function()return true end
 local r=R.New({});assert(r:Refresh(true).cost==26157 and nkeys(r.cache.items)==0)
end)
test('approximate totals round to silver and show the estimate marker',function()
 setup();assert(R.Line({cost=26157,estimated=true})=='Repair cost: ~2g 62s 0c')
end)
print('PASS: '..count..' repair regression groups')
