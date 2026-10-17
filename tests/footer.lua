local F=assert(VoidMarkMiniMapFooter)
local count=0
local function test(name,fn) fn();count=count+1;print('PASS footer: '..name) end
local function near(a,b) assert(math.abs(a-b)<.00001,tostring(a)..' ~= '..tostring(b)) end
test('equipped durability is weighted by actual maximums',function()
 near(F.Durability(function(slot) if slot==1 then return 50,100 elseif slot==5 then return 10,20 end end),50)
 near(F.Durability(function(slot) if slot==16 then return 92,100 end end),92)
end)
test('broken, repaired and over-reported equipment',function()
 near(F.Durability(function()return 0,100 end),0)
 near(F.Durability(function()return 100,100 end),100)
 near(F.Durability(function()return 120,100 end),100)
end)
test('empty equipment, missing API and invalid values stay unknown',function()
 for _,api in ipairs({function()end,function()return 1,0 end,function()return -1,10 end,
  function()return 0/0,100 end,function()return 10,math.huge end,function()return 1e308,1e308 end,function()return '10',100 end,
  function()error('Unavailable item data')end}) do assert(F.Durability(api)==nil) end
 assert(F.Durability(nil)==nil)
end)
test('readable equipment survives unrelated missing slots',function()
 near(F.Durability(function(slot)if slot==1 then return 30,100 elseif slot==2 then error('missing')end end),30)
end)
test('restricted durability values are not used',function()
 local old=issecretvalue;local secret={}
 issecretvalue=function(v)return v==secret end
 assert(F.Durability(function()return secret,100 end)==nil)
 issecretvalue=old
end)
test('color boundaries are green above 70, yellow 30 through 70, red below 30',function()
 local r,g=F.Color(70.01);assert(g>r)
 r,g=F.Color(70);assert(r==1 and g==.82)
 r,g=F.Color(30);assert(r==1 and g==.82)
 r,g=F.Color(29.99);assert(r==1 and g==.28)
 local r,g,b=F.Color(nil);assert(r==g and b>r)
end)
test('clock formatting preserves 12/24, midnight, noon and padding',function()
 assert(F.Clock(15,11,false)=='3:11 PM');assert(F.Clock(15,11,true)=='15:11')
 assert(F.Clock(0,5,false)=='12:05 AM');assert(F.Clock(12,0,false)=='12:00 PM')
 assert(F.Clock(0,5,true)=='00:05')
end)
test('unavailable and invalid clocks',function()
 for _,hour in ipairs({-1,24,math.huge,0/0,'3'}) do assert(F.Clock(hour,0,false)=='--:--') end
 assert(F.Clock(nil,nil,true)=='--:--');assert(F.Clock(1,60,true)=='--:--')
end)
test('all footer combinations fit every supported map size',function()
 for mask=0,15 do for width=180,600,10 do for _,dual in ipairs({false,true}) do
  local entries={
   {key='time',width=dual and 290 or 82,compactWidth=dual and 122 or 82,icon=true},
   {key='coordinates',width=80,compactWidth=80,icon=true},
   {key='durability',width=132,compactWidth=32,icon=true},
   {key='fps',width=65,compactWidth=65},
  }
  for i,e in ipairs(entries) do e.enabled=math.floor(mask/2^(i-1))%2==1 end
  local p=F.Plan(width,entries);local last=0
  for i,e in ipairs(entries) do local item=p.items[i]
   if item then assert(e.enabled and item.x>=last and item.x+item.width<=width);last=item.x+item.width end
  end
  if entries[1].enabled then assert(p.items[1],'Time must remain visible') end
 end end end
end)
test('information priority and wide layout restoration',function()
 local entries={{key='time',enabled=true,width=80,compactWidth=80,icon=true},
 {key='coordinates',enabled=true,width=80,compactWidth=80,icon=true},
 {key='durability',enabled=true,width=130,compactWidth=35,icon=true},
 {key='fps',enabled=true,width=60,compactWidth=60}}
 local small=F.Plan(180,entries)
 assert(small.items[1] and small.items[3] and not small.items[2] and not small.items[4])
 local wide=F.Plan(600,entries)
 assert(not wide.compact and wide.icons)
 for i=1,4 do assert(wide.items[i]) end
end)
print('PASS: '..count..' footer calculation/layout regression groups')
