local frames, combat, messages = {}, false, {}
local cursorX = 900
local Methods = {}
local function noop() end
for _, key in ipairs({"SetFrameStrata", "SetMovable", "SetClampedToScreen", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "SetScale", "RegisterForDrag", "SetWordWrap",
    "SetValueStep", "SetObeyStepOnDrag", "SetMinMaxValues", "EnableMouseWheel", "RegisterEvent"}) do
    Methods[key] = noop
end
function Methods:SetSize(w,h) self.width,self.height=w,h end
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
assert(Minimap.width==300 and Minimap.height==300)
assert(GetMinimapShape()=="SQUARE")
assert(VoidMarkMiniMapDB.point=="TOPRIGHT" and VoidMarkMiniMapDB.x==-35)
assert(VoidMarkMiniMapDB.locked==true)
assert(MinimapCluster.Tracking.parent.parent==VoidMarkMiniMapFrame)
assert(MinimapCluster.MailFrame.parent.parent==VoidMarkMiniMapFrame)
assert(GameTimeFrame.parent.parent==VoidMarkMiniMapFrame)
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
assert(Minimap.width<=300,"Size must fit screen")
assert(VoidMarkMiniMapFrame.height<=400,"Dock must fit screen too")
event("ZONE_CHANGED")
event("PLAYER_ENTERING_WORLD")
controller.scripts.OnUpdate(controller,11)
realPrint("PASS: startup, corrupt settings, sparse/late controls, combat deferral, commands, drag, resize/UI scale, options, zoom, reset, screen cap")
