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
function M:CreateFontString() return setmetatable({},{__index=M}) end
function M:CreateTexture() return setmetatable({},{__index=M}) end
function M:SetBackdropBorderColor(...) self.border={...} end
for _,k in ipairs({"SetBackdrop","SetBackdropColor","EnableMouse","SetWidth","SetJustifyH","SetWordWrap","SetColorTexture"}) do M[k]=function() end end
function CreateFrame() return setmetatable({},{__index=M}) end
SlashCmdList = {}
local lines = { {"Professions",true}, {"Kräuterkunde",false,nil,120,nil,nil,150,182} }
C_SkillInfo={GetNumSkillLines=function() return #lines end,
 GetSkillLineInfo=function(i) local l=lines[i]; return {name=l[1],isHeader=l[2],rank=l[4],maxRank=l[7],skillLineID=l[8]} end}
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
local g = H.Groups(120)
assert(g.red[1]=="Kingsblood", "red should list next unlock first")
assert(g.orange[1]=="Grave Moss" and #g.orange==3, "orange: Grave Moss, Wild Steelbloom, Bruiseweed")
assert(g.yellow[1]=="Stranglekelp" and g.green[1]=="Briarthorn" and g.grey[1]=="Earthroot")
local rank,maxRank = H.ReadSkill(); assert(rank==120 and maxRank==150)
function GetProfessions() return 3, nil, nil, 7 end
function GetProfessionInfo(i) if i==3 then return "Herbalism","icon",205,225,0,0,182 end return "Fishing","icon",1,75,0,0,356 end
assert(H.ReadSkill()==205, "GetProfessions path"); GetProfessions=nil; GetProfessionInfo=nil
-- No minimap frame yet: attach waits.
assert(H.Attach()==false)
VoidMarkMiniMapFrame = CreateFrame()
assert(H.Attach()==true)
local box = H.Box(); assert(box.shown==true and box.point[2]==VoidMarkMiniMapFrame and box.point[3]=="TOPLEFT")
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
local printed={}; local realPrint=print; print=function(...) printed[#printed+1]=table.concat({...}," ") end
SlashCmdList.VOIDMARKHERB(""); print=realPrint
assert(#printed>=4 and printed[2]:find("120/150",1,true), "status shows skill")
print("PASS: herb box")
