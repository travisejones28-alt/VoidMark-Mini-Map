-- Herb difficulty box regressions (run after stubs below; Herb.lua loaded here).
local M = {}
function M:SetSize(w,h) self.w,self.h=w,h end
function M:SetPoint(...) self.point={...} end
function M:SetShown(v) self.shown=not not v end
function M:SetText(v) self.text=v end
function M:SetTextColor(r,g,b) self.color={r,g,b} end
function M:SetScript(k,f) self.scripts=self.scripts or {}; self.scripts[k]=f end
function M:RegisterEvent() end
function M:CreateFontString() return setmetatable({},{__index=M}) end
function M:CreateTexture() return setmetatable({},{__index=M}) end
function M:SetBackdropBorderColor(...) self.border={...} end
for _,k in ipairs({"SetBackdrop","SetBackdropColor","EnableMouse","SetWidth","SetJustifyH","SetWordWrap","SetColorTexture"}) do M[k]=function() end end
function CreateFrame() return setmetatable({},{__index=M}) end
SlashCmdList = {}
local lines = { {"Professions",true}, {"Herbalism",false,nil,120,nil,nil,150} }
function GetNumSkillLines() return #lines end
function GetSkillLineInfo(i) local l=lines[i]; return l[1],l[2],l[3],l[4],l[5],l[6],l[7] end
VoidMarkMiniMapDB = { herb = true, accent = "purple", purple = true }
dofile('Herb.lua')
local H = VoidMarkMiniMapHerb
assert(H.Band(120,121)=="red" and H.Band(120,120)=="orange" and H.Band(144,120)=="orange")
assert(H.Band(145,120)=="yellow" and H.Band(170,120)=="green" and H.Band(220,120)=="grey")
local g = H.Groups(120)
assert(g.red[1]=="Kingsblood", "red should list next unlock first")
assert(g.orange[1]=="Grave Moss" and #g.orange==3, "orange: Grave Moss, Wild Steelbloom, Bruiseweed")
assert(g.yellow[1]=="Stranglekelp" and g.green[1]=="Briarthorn" and g.grey[1]=="Earthroot")
local rank,maxRank = H.ReadSkill(); assert(rank==120 and maxRank==150)
-- No minimap frame yet: attach waits.
assert(H.Attach()==false)
VoidMarkMiniMapFrame = CreateFrame()
assert(H.Attach()==true)
local box = H.Box(); assert(box.shown==true and box.point[2]==VoidMarkMiniMapFrame and box.point[3]=="TOPLEFT")
-- Find box through refresh side effects: re-run with skill removed hides it.
SlashCmdList.VOIDMARKHERB("off"); assert(VoidMarkMiniMapDB.herb==false)
SlashCmdList.VOIDMARKHERB("on"); assert(VoidMarkMiniMapDB.herb==true)
lines = { {"Professions",true}, {"Mining",false,nil,50} }
H.Refresh()
assert(H.ReadSkill()==nil and box.shown==false, "no herbalism -> hidden")
print("PASS: herb box")
