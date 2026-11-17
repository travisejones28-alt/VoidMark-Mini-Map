-- Party marker regressions: placement math, edge arrows, next-zone projection, secrets, settings.
local M = {}
local function obj() return setmetatable({shown=true},{__index=M}) end
for _,k in ipairs({"SetSize","EnableMouse","SetFrameStrata","SetAllPoints","SetVertexColor","SetShadowOffset","SetTextColor","AddMaskTexture","RegisterEvent"}) do M[k]=function() end end
function M:SetTexture(v) self.texture=v end
function M:SetPoint(...) self.point={...} end
function M:ClearAllPoints() self.point=nil end
function M:SetText(v) self.text=v end
function M:SetRotation(v) self.rotation=v end
function M:Show() self.shown=true end
function M:Hide() self.shown=false end
function M:SetScript(k,f) self.scripts=self.scripts or {}; self.scripts[k]=f end
function M:GetFont() return "Fonts/FRIZQT__.TTF",12,"" end
function M:SetFont(p,s) self.fontSize=s end
function M:GetWidth() return 300 end
function M:CreateTexture() local t=obj(); FRAMES[#FRAMES+1]=t; return t end
function M:CreateFontString() return obj() end
function M:CreateMaskTexture() return obj() end
FRAMES={}
function CreateFrame() local f=obj(); FRAMES[#FRAMES+1]=f; return f end
unpack=unpack or table.unpack
SECRET={}
function issecretvalue(v) return v==SECRET end
VoidMarkMiniMapDB={}
VoidMarkMiniMapMapViewport=CreateFrame()
local zoom=0
Minimap={GetZoom=function() return zoom end}
function IsIndoors() return false end
function IsInGroup() return true end
function IsInRaid() return false end
function GetNumGroupMembers() return 3 end
function UnitIsUnit() return false end
function UnitIsConnected() return true end
local members={party1={name='Kaelith',class='MAGE'},party2={name='Thrumm',class='WARRIOR'}}
function UnitExists(u) return members[u]~=nil end
function UnitName(u) return members[u].name end
function UnitClass(u) return 'x',members[u].class end
RAID_CLASS_COLORS={MAGE={r=0.25,g=0.78,b=0.92},WARRIOR={r=0.78,g=0.61,b=0.43}}
-- Map 1 = your zone (3000 x 2000 yd). Map 2 = the next zone east.
function CreateVector2D(x,y) return {x=x,y=y} end
local pos={player={1,0.5,0.5},party1={1,0.52,0.5},party2={2,0.1,0.5}}
C_Map={
 GetBestMapForUnit=function(u) return pos[u] and pos[u][1] end,
 GetPlayerMapPosition=function(map,u) local p=pos[u]; if p and p[1]==map then return CreateVector2D(p[2],p[3]) end end,
 GetWorldPosFromMapPos=function(map,v)
  if map==1 then return 0,{x=(1-v.y)*2000,y=(1-v.x)*3000} end  -- x north, y west
  return 0,{x=(1-v.y)*2000,y=-(v.x)*3000} end,                  -- map 2 starts at map 1's east edge
 GetMapPosFromWorldPos=function(c,w,map) return 0,CreateVector2D(1-w.y/3000,1-w.x/2000) end,
}
assert(loadfile('Party.lua'))()
local P=VoidMarkMiniMapParty
local function near(a,b,m) assert(math.abs(a-b)<0.01,(m or '')..' expected '..b..' got '..a) end

-- Math: on-map stays put; off-map is clamped to the square edge, angle kept.
local x,y,on=P.Place(30,40,1,150,12); assert(on); near(x,30); near(y,40)
x,y,on,a=P.Place(1000,0,1,150,12); assert(not on); near(x,138); near(y,0); near(a,0)
x,y,on,a=P.Place(-500,500,1,150,12); assert(not on); near(x,-138); near(y,138); near(a,3*math.pi/4)
near(P.Span(0,false),466.667); near(P.Span(5,true),50); near(P.Span(99,false),133.333)

-- Defaults saved; two pins drawn (party3/4 absent).
P.Update()
eq=function(a,b,m) assert(a==b,(m or '')..': expected '..tostring(b)..', got '..tostring(a)) end
eq(VoidMarkMiniMapDB.party,true,'party default on'); eq(VoidMarkMiniMapDB.partySize,'medium')
eq(P.shown,2,'two party members')
local layer=VoidMarkMiniMapPartyLayer or nil
-- Find pins: frames with Letter.
local pins={}
for _,f in ipairs(FRAMES) do if f.Letter then pins[#pins+1]=f end end
eq(#pins>=2,true); eq(pins[3] and pins[3].shown or false,false,"unused pin hidden")
-- party1: 0.02 * 3000 = 60 yd east -> on map (466 yd span over 300 px => 1.556 yd/px => 38.6 px).
eq(pins[1].Letter.text,'K'); assert(pins[1].point[4]>38 and pins[1].point[4]<39,'K x '..pins[1].point[4]); near(pins[1].point[5],0)
eq(pins[1].Arrow.shown,false,'no arrow on map')
-- party2: next zone east, 0.6*3000=1800 yd away -> edge, arrow pointing east, distance shown.
eq(pins[2].Letter.text,'T'); eq(pins[2].Arrow.shown,true,'edge arrow'); near(pins[2].point[4],150-(18/2+3))
near(pins[2].Arrow.rotation,-math.pi/2,'arrow points east'); eq(pins[2].Distance.text,'1800 yd')
-- North-west of you (same zone): arrow points up-left, marker on top-left edge.
pos.party2={1,0.2,0.1}; P.Update()
assert(pins[2].point[4]<0 and pins[2].point[5]>0,'NW marker'); assert(pins[2].Arrow.rotation>0,'arrow turns left')
-- Zooming in moves the on-map marker outward.
zoom=5; P.Update(); assert(pins[1].point[4]>130,'zoom scale'); zoom=0
-- Secret positions: hidden, no error.
local real=C_Map.GetPlayerMapPosition
C_Map.GetPlayerMapPosition=function() return SECRET end
function UnitPosition() return SECRET end
P.Update(); eq(P.shown,0,'secret positions hide markers'); eq(pins[1].shown,false)
C_Map.GetPlayerMapPosition=real; UnitPosition=nil
-- Fallback to world coordinates when map APIs are missing.
local cm=C_Map; C_Map=nil
local world={player={0,0,0,1},party1={-100,0,0,1},party2={0,50,0,2}} -- party1 100 yd east; party2 other instance
function UnitPosition(u) return unpack(world[u]) end
P.Update(); eq(P.shown,1,'other instance hidden'); assert(pins[1].point[4]>0,'east via world coords')
C_Map=cm; UnitPosition=nil
-- Settings: size cycles, turning off hides everything.
eq(P.CycleSize(),'large'); P.Update(); eq(pins[1].Dot and true,true)
eq(P.CycleSize(),'small'); eq(P.CycleSize(),'medium')
VoidMarkMiniMapDB.party=false; P.Update(); eq(P.shown,0); eq(pins[1].shown,false)
-- Solo: nothing drawn.
VoidMarkMiniMapDB.party=true; IsInGroup=function() return false end; P.Update(); eq(P.shown,0)
print('PASS: party markers - placement, edge arrows, next-zone projection, zoom, secrets, world fallback, settings')
