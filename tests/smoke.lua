local frames, combat, messages = {}, false, {}
local cursorX = 900
unpack=unpack or table.unpack
local Methods = {}
local function noop() end
for _, key in ipairs({"SetFrameStrata", "SetMovable", "SetClampedToScreen", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "SetScale", "RegisterForDrag", "SetWordWrap",
    "SetValueStep", "SetObeyStepOnDrag", "SetMinMaxValues", "EnableMouseWheel", "RegisterEvent"}) do
    Methods[key] = noop
end
function Methods:SetSize(w,h) self.width,self.height=w,h end
function Methods:SetWidth(w) self.width=w end
function Methods:SetHeight(h) self.height=h end
function Methods:GetWidth() return self.width or 100 end
function Methods:GetHeight() return self.height or 100 end
function Methods:GetScale() return self.scale or 1 end
function Methods:SetScale(v) self.scale=v end
function Methods:GetEffectiveScale() return 0.8 end
function Methods:GetLeft() return 400 end
function Methods:GetTop() return 900 end
function Methods:SetPoint(...) self.point={...} end
function Methods:ClearAllPoints() self.point=nil end
function Methods:SetParent(p) self.parent=p end
function Methods:GetParent() return self.parent end
function Methods:GetFrameStrata() return self.strata or "MEDIUM" end
function Methods:SetFrameStrata(s) self.strata=s end
function Methods:GetNumPoints() return self.point and 1 or 0 end
function Methods:GetPoint() return unpack(self.point) end
function Methods:GetScript(e) return self.scripts[e] end
function Methods:SetNormalTexture(v) self.normalTexture=v end
function Methods:SetHighlightTexture(v) self.highlightTexture=v end
function Methods:SetFrameLevel(v) self.level=v end
function Methods:GetFrameLevel() return self.level or 1 end
function Methods:SetMaskTexture(t) self.mask=t end
function Methods:EnableMouse(v) self.mouse=v end
function Methods:SetText(v) self.text=v end
function Methods:SetShown(v) self.visible=v end
function Methods:Show() self.visible=true end
function Methods:Hide() self.visible=false end
function Methods:IsShown() return self.visible end
function Methods:SetScript(e,f) self.scripts[e]=f end
function Methods:HookScript(e,f) self.hooks[e]=f end
function Methods:SetValue(v)
    self.value=v
    if self.scripts.OnValueChanged then self.scripts.OnValueChanged(self,v) end
end
function Methods:SetChecked(v) self.checked=v end
function Methods:GetChecked() return self.checked end
function Methods:StartMoving() self.moving=true end
function Methods:StopMovingOrSizing() self.moving=false end
function Methods:GetCenter() return 700,500 end
function Methods:GetZoom() return self.zoom or 0 end
function Methods:GetZoomLevels() return 6 end
function Methods:SetZoom(v) assert(v>=0 and v<=5); self.zoom=v end
function CreateFrame(kind,name,parent,template)
    local frame=setmetatable({scripts={},hooks={},visible=true,parent=parent,kind=kind,template=template}, {__index=Methods})
    frames[#frames+1]=frame
    if name then _G[name]=frame end
    return frame
end
function Methods:CreateFontString() return CreateFrame("FontString") end
function Methods:IsObjectType(kind) return self.kind==kind end
function Methods:GetText() return self.text end
function Methods:SetAlpha(v) self.alpha=v end
function Methods:GetRegions()
    local regions={}
    for _, f in ipairs(frames) do
        if f.parent==self and f.kind=="FontString" then regions[#regions+1]=f end
    end
    return unpack(regions)
end
function Methods:GetChildren()
    local children={}
    for _, f in ipairs(frames) do
        if f.parent==self and f.kind~="FontString" then children[#children+1]=f end
    end
    return unpack(children)
end
function Methods:GetNormalTexture() return self.normal end
UIParent=CreateFrame("Frame")
UIParent:SetSize(1920,1080)
Minimap=CreateFrame("Minimap")
Minimap:SetSize(140,140)
-- Missing legacy controls must not discard modern controls or error on nil holes.
MinimapCluster={Tracking=CreateFrame("Button"), MailFrame=CreateFrame("Button")}
GameTimeFrame=CreateFrame("Button")
UISpecialFrames={}
SlashCmdList={}
function GetMinimapZoneText() return "Orgrimmar" end
function GetGameTime() return 22,45 end
function InCombatLockdown() return combat end
function GetCursorPosition() return cursorX,500 end
local realPrint=print
function print(text) messages[#messages+1]=text end
VoidMarkMiniMapDB={size=0/0,point="garbage",x=math.huge,locked="bad",clock=true}
assert(loadfile("VoidMarkMiniMap.lua"))("VoidMarkMiniMap")
local controller=frames[5] -- find by PLAYER_LOGIN handler, not frame index
for _,frame in ipairs(frames) do if frame.scripts.OnEvent then controller=frame end end
local function event(name) controller.scripts.OnEvent(controller,name) end
local function command(s) SlashCmdList.VOIDMARKMINIMAP(s) end
combat=true
event("PLAYER_LOGIN")
assert(not VoidMarkMiniMapFrame,"Startup must defer in combat")
combat=false
event("PLAYER_REGEN_ENABLED")
if VMM_TEST_CONFLICT then
    assert(not VoidMarkMiniMapFrame,"Conflicting minimap owner must leave native minimap untouched")
    assert(Minimap.width==140)
    realPrint("PASS: active minimap conflict pauses styling")
    return
end
assert(Minimap.width==300 and Minimap.height==300)
assert(GetMinimapShape()=="SQUARE")
assert(VoidMarkMiniMapDB.point=="TOPLEFT" and VoidMarkMiniMapDB.x>=0)
assert(VoidMarkMiniMapDB.locked==true)
assert(MinimapCluster.Tracking.parent==VoidMarkMiniMapFrame)
assert(MinimapCluster.MailFrame.parent==VoidMarkMiniMapFrame)
assert(GameTimeFrame.parent~=VoidMarkMiniMapFrame and not GameTimeFrame:IsShown())
command("size 420")
assert(Minimap.width==420)
command("size 99999")
assert(Minimap.width==600)
command("size nonsense")
assert(Minimap.width==600)
combat=true
command("size 240")
assert(Minimap.width==600,"Must not resize during combat")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(Minimap.width==240)
command("unlock")
assert(VoidMarkMiniMapDB.locked==false)
local drag
for _,frame in ipairs(frames) do if frame.scripts.OnDragStart and frame~=VoidMarkMiniMapResize then drag=frame end end
drag.scripts.OnDragStart()
assert(VoidMarkMiniMapFrame.moving)
drag.scripts.OnDragStop()
assert(VoidMarkMiniMapDB.point=="CENTER" and VoidMarkMiniMapDB.x==-260)
command("lock")
drag.scripts.OnDragStart()
assert(not VoidMarkMiniMapFrame.moving)
command("")
assert(VoidMarkMiniMapOptions:IsShown())
command("")
assert(not VoidMarkMiniMapOptions:IsShown())
combat=true
command("size 320")
assert(VoidMarkMiniMapOptions.status.text=="Changes queued until combat ends.")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(Minimap.width==320)
command("unlock")
local grip=VoidMarkMiniMapResize
grip.scripts.OnDragStart()
assert(VoidMarkMiniMapFrame.resizing)
assert(VoidMarkMiniMapDB.point=="TOPLEFT")
cursorX=980
grip.scripts.OnUpdate()
assert(Minimap.width==420,"Resize must account for effective UI scale")
combat=true
event("PLAYER_REGEN_DISABLED")
assert(not VoidMarkMiniMapFrame.resizing)
combat=false
event("PLAYER_REGEN_ENABLED")
command("lock")
assert(not grip:IsShown())
grip.scripts.OnDragStart()
assert(not VoidMarkMiniMapFrame.resizing)
QueueStatusButton=CreateFrame("Button")
QueueStatusButton:SetSize(64,64)
combat=true
event("ADDON_LOADED")
assert(not QueueStatusButton.parent,"Late controls must defer in combat")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(QueueStatusButton.parent==MinimapCluster.Tracking.parent)
assert(QueueStatusButton:GetScale()==24/64)
event("ADDON_LOADED")
for i=1,10 do Minimap.scripts.OnMouseWheel(Minimap,1) end
assert(Minimap:GetZoom()==5)
for i=1,10 do Minimap.scripts.OnMouseWheel(Minimap,-1) end
assert(Minimap:GetZoom()==0)
command("reset")
assert(Minimap.width==300 and VoidMarkMiniMapDB.locked)
UIParent:SetSize(400,400)
command("size 600")
assert(Minimap.width<=320,"Size must fit screen")
assert(VoidMarkMiniMapFrame.height<=400,"Dock must fit screen too")
event("ZONE_CHANGED")
event("PLAYER_ENTERING_WORLD")
controller.scripts.OnUpdate(controller,11)
-- Drawer captures supported buttons, keeps hidden buttons hidden, skips protected ones,
-- and restores all saved points/scripts when disabled.
local icon=CreateFrame("Button",nil,Minimap)
icon:SetSize(32,32)
icon:SetPoint("CENTER",Minimap,"CENTER",10,20)
local dragStart=function() end
icon:SetScript("OnDragStart",dragStart)
local hidden=CreateFrame("Button",nil,Minimap)
hidden:Hide()
local protected=CreateFrame("Button",nil,Minimap)
protected.IsProtected=function() return true end
local lib={GetButtonList=function() return {"Test","Hidden","Protected"} end,
    GetMinimapButton=function(_,name) return ({Test=icon,Hidden=hidden,Protected=protected})[name] end}
LibStub=function() return lib end
controller.scripts.OnUpdate(controller,2)
assert(icon.parent==VoidMarkMiniMapFrame)
assert(icon:GetScript("OnDragStart")==nil,"Managed icons should not be dragged onto map")
assert(not hidden:IsShown())
assert(protected.parent==Minimap)
assert(not VoidMarkMiniMapDrawer:IsShown(),"Addon icons now stay on perimeter")
local capturedScale=icon:GetScale()
combat=true
VoidMarkMiniMapDB.drawer=false
controller.scripts.OnUpdate(controller,2)
assert(icon.parent==VoidMarkMiniMapFrame,"Restoration must wait until combat ends")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(icon.parent==Minimap and icon:GetScale()==1)
assert(icon:GetScript("OnDragStart")==dragStart)
assert(icon.point[4]==10 and icon.point[5]==20)
assert(not hidden:IsShown())
VoidMarkMiniMapDB.coordinates=true
local coord
controller.scripts.OnUpdate(controller,0.5)
for _,frame in ipairs(frames) do if frame.text=="--, --" then coord=frame end end
assert(coord,"Missing coordinate API must show a placeholder")
C_Map={GetBestMapForUnit=function() return 1 end,
    GetPlayerMapPosition=function() return {GetXY=function() return .25,.75 end} end}
controller.scripts.OnUpdate(controller,0.5)
assert(coord.text=="25.0, 75.0")
C_Map.GetPlayerMapPosition=function() error("Restricted map") end
controller.scripts.OnUpdate(controller,0.5)
assert(coord.text=="--, --")
VoidMarkMiniMapDB.point="BOTTOMRIGHT"
VoidMarkMiniMapDB.x=99999;VoidMarkMiniMapDB.y=-99999
event("DISPLAY_SIZE_CHANGED")
assert(VoidMarkMiniMapDB.x>=0 and VoidMarkMiniMapDB.x<=UIParent:GetWidth()-VoidMarkMiniMapFrame:GetWidth())
assert(VoidMarkMiniMapDB.y<=0 and VoidMarkMiniMapDB.y>=-UIParent:GetHeight()+VoidMarkMiniMapFrame:GetHeight())
-- Screenshot regressions: nested/colorized coordinates and late native chrome.
local wrapper=CreateFrame("Frame",nil,Minimap)
local nested=CreateFrame("Frame",nil,wrapper)
local duplicate=CreateFrame("FontString",nil,nested)
duplicate:SetText("|cffffffff55.4, 39.0|r")
local unrelated=CreateFrame("FontString",nil,nested)
unrelated:SetText("Level 60")
local outside=CreateFrame("FontString",nil,UIParent)
outside:SetText("55.4, 39.0")
Minimap.ZoomIn=CreateFrame("Button",nil,nested)
local anonymous=CreateFrame("Button",nil,nested)
anonymous.normal={GetTexture=function() return "Interface\\Minimap\\UI-Minimap-ZoomOut" end}
local addonIcon=CreateFrame("Button",nil,nested)
addonIcon.normal={GetTexture=function() return "Interface\\Icons\\Trade_Engineering" end}
MiniMapCalendarButton=CreateFrame("Button",nil,UIParent)
GameTimeFrame=CreateFrame("Button",nil,UIParent)
combat=true
controller.scripts.OnUpdate(controller,2)
assert(MiniMapCalendarButton:IsShown(),"Do not mutate native chrome during combat")
combat=false
event("PLAYER_REGEN_ENABLED")
controller.scripts.OnUpdate(controller,2)
assert(duplicate.alpha==0,"Nested colorized duplicate coordinates must be suppressed")
assert(unrelated.alpha==nil and outside.alpha==nil,"Do not hide unrelated labels")
assert(not Minimap.ZoomIn:IsShown() and not anonymous:IsShown())
assert(not MiniMapCalendarButton:IsShown() and not GameTimeFrame:IsShown())
assert(addonIcon:IsShown(),"Do not mistake addon icons for zoom controls")
assert(MiniMapCalendarButton.parent==GameTimeFrame.parent)
assert(not GameTimeFrame.parent:IsShown(),"Park chrome under a hidden parent")
GameTimeFrame:Show()
GameTimeFrame.hooks.OnShow(GameTimeFrame)
assert(not GameTimeFrame:IsShown(),"Native OnShow must not restore the sun")
Minimap.ZoomOut=CreateFrame("Button",nil,Minimap)
controller.scripts.OnUpdate(controller,2)
assert(not Minimap.ZoomOut:IsShown(),"Discover controls created after login")
duplicate:SetAlpha(1)
duplicate:SetText("(55, 39)")
controller.scripts.OnUpdate(controller,0.5)
assert(duplicate.alpha==0)
realPrint("PASS: nested duplicate coordinates, late/nested/anonymous zoom, sun/calendar, unrelated icons, combat safety")
realPrint("PASS: startup, corrupt settings, sparse/late controls, combat deferral, commands, drag, resize/UI scale, options, zoom, reset, screen cap")
realPrint("PASS: drawer capture/restore, protected and hidden icons, coordinates/failure fallback, saved position recovery")
