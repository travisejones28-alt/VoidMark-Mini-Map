-- Herb difficulty box regressions (run after stubs below; Herb.lua loaded here).
local M = {}
function M:SetSize(w,h) self.w,self.h=w,h end
function M:SetPoint(...) self.point={...} end
function M:SetShown(v) self.shown=not not v end
function M:SetText(v) self.text=v end
function M:SetTextColor(r,g,b) self.color={r,g,b} end
function M:SetScript(k,f) self.scripts=self.scripts or {}; self.scripts[k]=f end
function M:RegisterEvent(e) if e=='LEARNED_SPELL_IN_TAB' then error('Attempt to register unknown event') end end
function M:IsShown() return self.shown end
function M:Hide() self.shown=false end
function M:CreateFontString() return setmetatable({},{__index=M}) end
function M:CreateTexture() return setmetatable({},{__index=M}) end
function M:SetBackdropBorderColor(...) self.border={...} end
for _,k in ipairs({"SetBackdrop","SetBackdropColor","EnableMouse","SetWidth","SetJustifyH","SetWordWrap","SetColorTexture"}) do M[k]=function() end end
function CreateFrame() return setmetatable({},{__index=M}) end
SlashCmdList = {}
local lines = { {"Professions",true}, {"Kräuterkunde",false,nil,120,nil,nil,150,182} }
C_SkillInfo={GetNumSkillLines=function() return #lines end,
 GetSkillLineInfo=function(i) local l=lines[i]; return {name=l[1],isHeader=l[2],rank=l[4],maxRank=l[7],skillLineID=l[8]} end}
local clock=100
function GetTime() return clock end
VoidMarkMiniMapDB = { herb = true, accent = "purple", purple = true }
Minimap = CreateFrame()
local hooks = {}
GameTooltip = CreateFrame()
function GameTooltip:HookScript(k,f) hooks[k]=f end
function GameTooltip:GetOwner() return self.owner end
function GameTooltip:NumLines() return 1 end
function GameTooltip:Show() self.showCount=(self.showCount or 0)+1 end
GameTooltipTextLeft1 = CreateFrame()
function GameTooltipTextLeft1:GetText() return self.text end
dofile('Herb.lua')
assert(SlashCmdList.VOIDMARKHERB, 'unknown event must not stop the file loading')
local H = VoidMarkMiniMapHerb
assert(H.Band(120,121)=="red" and H.Band(120,120)=="orange" and H.Band(144,120)=="orange")
assert(H.Band(145,120)=="yellow" and H.Band(170,120)=="green" and H.Band(220,120)=="grey")
local rank,maxRank = H.ReadSkill(); assert(rank==120 and maxRank==150)
function GetProfessions() return 3, nil, nil, 7 end
function GetProfessionInfo(i) if i==3 then return "Herbalism","icon",205,225,0,0,182 end return "Fishing","icon",1,75,0,0,356 end
assert(H.ReadSkill()==205, "GetProfessions path"); GetProfessions=nil; GetProfessionInfo=nil
-- No minimap frame yet: attach waits.
assert(H.Attach()==false)
VoidMarkMiniMapFrame = CreateFrame()
assert(H.Attach()==true)
local box = H.Box(); assert(box.shown==false and box.point[2]==VoidMarkMiniMapFrame and box.point[3]=="TOPLEFT", "hidden until a herb is hovered")
-- Find box through refresh side effects: re-run with skill removed hides it.
SlashCmdList.VOIDMARKHERB("off"); assert(VoidMarkMiniMapDB.herb==false)
SlashCmdList.VOIDMARKHERB("on"); assert(VoidMarkMiniMapDB.herb==true)
lines = { {"Professions",true}, {"Mining",false,nil,50,nil,nil,75,186} }
H.Refresh()
assert(H.ReadSkill()==nil and box.shown==false, "no herbalism -> hidden")
-- Map hover label squares (skill 120).
local D = H.Decorate
local m = D("Mageroyal", 120)
assert(m:find("WHITE8X8",1,true) and m:find(":63:191:63|t Mageroyal",1,true), "Mageroyal is green at 120: "..m)
assert(D(m,120)==m, "decorating twice must not add a second square")
local multi = D("|TInterface\\Minimap\\Tracking:0|t Earthroot\nKingsblood", 120)
assert(multi:find(":0:0|t Kingsblood",1,true) == nil and multi:find(":255:33:33|t Kingsblood",1,true), "Kingsblood red")
assert(multi:find(":140:140:140|t Earthroot",1,true), "Earthroot grey at 120")
assert(D("Copper Vein",120)=="Copper Vein")
lines = { {"Professions",true}, {"Kräuterkunde",false,nil,120,nil,nil,150,182} }
H.Refresh()
GameTooltip.owner = {}; GameTooltipTextLeft1.text = "Mageroyal"
hooks.OnShow(GameTooltip); assert(GameTooltipTextLeft1.text=="Mageroyal", "only minimap tooltips are touched")
function Minimap:IsMouseOver() return true end
hooks.OnShow(GameTooltip); assert(GameTooltipTextLeft1.text:find("|t Mageroyal",1,true), "tooltip over the map counts even with another owner")
Minimap.IsMouseOver=nil; GameTooltipTextLeft1.text="Mageroyal"
GameTooltip.owner = Minimap
hooks.OnShow(GameTooltip); assert(GameTooltipTextLeft1.text:find("|t Mageroyal",1,true))
local shows = GameTooltip.showCount
hooks.OnUpdate(GameTooltip); assert(GameTooltip.showCount==shows, "no re-show when unchanged")
VoidMarkMiniMapDB.herbTip = false; GameTooltipTextLeft1.text = "Bruiseweed"
hooks.OnShow(GameTooltip); assert(GameTooltipTextLeft1.text=="Bruiseweed", "tip off")
-- Hover mode: hidden until a herb label shows over the map, hides after it ends.
VoidMarkMiniMapDB.herbTip = true
GameTooltip.owner = {}; GameTooltipTextLeft1.text = "Silverleaf"
clock = clock + 5; H.Refresh(); assert(box.shown==false, "hover mode starts hidden")
hooks.OnShow(GameTooltip); assert(box.shown==false, "non-map tooltip does not open the box")
GameTooltip.owner = Minimap; hooks.OnUpdate(GameTooltip)
assert(box.shown==true and box.scripts.OnUpdate, "hovering a herb shows the box")
local lbl = H.Label(); assert(lbl.text=="Silverleaf  no skill-up" and lbl.color[1]<0.6, lbl.text)
clock = clock + 1; GameTooltipTextLeft1.text = "Kingsblood"; hooks.OnUpdate(GameTooltip)
assert(lbl.text=="Kingsblood  needs 125" and lbl.color[1]==1 and lbl.color[2]<0.2, lbl.text)
clock = clock + 1; box.scripts.OnUpdate(box); assert(box.shown==false, "box hides when hover ends")
GameTooltip.owner = Minimap; GameTooltipTextLeft1.text = "Copper Vein"; hooks.OnUpdate(GameTooltip)
assert(box.shown==false, "non-herb label keeps box hidden")
local printed={}; local realPrint=print; print=function(...) printed[#printed+1]=table.concat({...}," ") end
SlashCmdList.VOIDMARKHERB(""); print=realPrint
assert(#printed>=4 and printed[2]:find("120/150",1,true), "status shows skill")
-- In-game color learning (Forever): world tooltip line 2 shows the real difficulty color.
local C = H.ColorBand
assert(C(1,1,0)=="yellow" and C(1,0.82,0)=="yellow" and C(1,0.5,0.25)=="orange")
assert(C(0.25,0.75,0.25)=="green" and C(0.5,0.5,0.5)=="grey" and C(1,0.1,0.1)=="red" and C(1,1,1)==nil)
assert(H.BandOf(169,"Wild Steelbloom")=="green", "Classic default before learning")
GameTooltipTextLeft2 = CreateFrame()
function GameTooltipTextLeft2:GetText() return self.text end
function GameTooltipTextLeft2:GetTextColor() return unpack(self.rgb) end
lines = { {"Professions",true}, {"Herbalism",false,nil,169,nil,nil,225,182} }
H.Refresh()
Minimap.IsMouseOver=nil; GameTooltip.owner = {}
GameTooltipTextLeft1.text = "Wild Steelbloom"; GameTooltipTextLeft2.text = "Herbalism"; GameTooltipTextLeft2.rgb = {1,1,0}
hooks.OnShow(GameTooltip)
assert(H.BandOf(169,"Wild Steelbloom")=="yellow", "game said yellow at 169 -> learned")
assert(H.BandOf(152,"Bruiseweed")=="yellow", "other herbs use learned global steps (+52 is yellow now)")
assert(VoidMarkMiniMapDB.herbLearn["*"].green==55, "green now starts at +55")
GameTooltipTextLeft2.rgb = {0.25,0.75,0.25}; lines[2][4]=180; H.Refresh(); hooks.OnUpdate(GameTooltip)
assert(H.BandOf(180,"Wild Steelbloom")=="green" and VoidMarkMiniMapDB.herbLearn["Wild Steelbloom"].green<=65)
-- Red with enough classic skill means Forever raised the requirement.
GameTooltipTextLeft1.text = "Liferoot"; GameTooltipTextLeft2.text = "Requires Herbalism"; GameTooltipTextLeft2.rgb = {1,0.1,0.1}
hooks.OnShow(GameTooltip)
assert(H.BandOf(180,"Liferoot")=="red" and VoidMarkMiniMapDB.herbLearn["Liferoot"].req==181)
-- Non-skill second line is ignored.
GameTooltipTextLeft1.text = "Fadeleaf"; GameTooltipTextLeft2.text = "Level 30"; GameTooltipTextLeft2.rgb = {1,1,0}
hooks.OnShow(GameTooltip); assert(VoidMarkMiniMapDB.herbLearn["Fadeleaf"]==nil)
-- Secret tooltip text (Forever unit/combat tooltips) is skipped, never indexed.
issecretvalue=function(v) return v=="SECRET" end
GameTooltipTextLeft1.text = "SECRET"; hooks.OnUpdate(GameTooltip)
GameTooltipTextLeft1.text = "Wild Steelbloom"; GameTooltipTextLeft2.text = "SECRET"; hooks.OnUpdate(GameTooltip)
GameTooltip.owner = Minimap; GameTooltipTextLeft1.text = "SECRET"; hooks.OnUpdate(GameTooltip)
assert(GameTooltipTextLeft1.text=="SECRET", "secret map text untouched"); GameTooltip.owner = {}
issecretvalue=nil
SlashCmdList.VOIDMARKHERB("reset"); assert(VoidMarkMiniMapDB.herbLearn==nil and H.BandOf(169,"Wild Steelbloom")=="green")
print("PASS: herb box")
