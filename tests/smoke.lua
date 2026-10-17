local frames, combat, messages = {}, false, {}
local cursorX = 900
unpack=unpack or table.unpack
local Methods = {}
local function noop() end
for _, key in ipairs({"SetFrameStrata", "SetMovable", "SetClampedToScreen", "SetBackdrop",
    "SetBackdropColor", "SetBackdropBorderColor", "SetColorTexture", "SetFontObject", "SetTextColor", "SetScale", "RegisterForDrag", "SetWordWrap",
    "SetValueStep", "SetObeyStepOnDrag", "SetMinMaxValues", "EnableMouseWheel", "RegisterEvent"}) do
    Methods[key] = noop
end
function Methods:GetStringWidth()
    local text=self.text or ""
    local width=0
    for line in (text.."\n"):gmatch("(.-)\n") do width=math.max(width,#line*(self.fontSize or 14)*.52) end
    return width
end
function Methods:SetTexture(v) self.texture=v end
function Methods:SetTexCoord(...) self.texcoord={...} end
function Methods:SetRotation(v) self.rotation=v end
function Methods:SetJustifyH(v) self.justify=v end
function Methods:RegisterEvent(event) self.registered=self.registered or {};self.registered[event]=true end
function Methods:GetFont() return "Fonts/FRIZQT__.TTF",10,"" end
function Methods:SetFont(path,size,flags) self.fontSize,self.fontFlags=size,flags end
function Methods:SetShadowColor() end
function Methods:SetShadowOffset() end
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
function Methods:CreateTexture() return CreateFrame("Texture",nil,self) end
function Methods:CreateFontString() return CreateFrame("FontString",nil,self) end
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
function hooksecurefunc(object, method, callback)
    local original=object[method]
    object[method]=function(self,...)
        original(self,...)
        callback(self,...)
    end
end
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
if VMM_TEST_SAVED_SETTINGS then VoidMarkMiniMapDB.durability=false end
assert(loadfile("Footer.lua"))()
assert(loadfile("Repair.lua"))()
assert(loadfile("VoidMarkMiniMap.lua"))("VoidMarkMiniMap")
local controller=frames[5] -- find by PLAYER_LOGIN handler, not frame index
for _,frame in ipairs(frames) do if frame.scripts.OnEvent then controller=frame end end
assert(controller.registered.UPDATE_INVENTORY_DURABILITY and controller.registered.PLAYER_EQUIPMENT_CHANGED and controller.registered.MERCHANT_CLOSED,"Durability events missing")
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
if VMM_TEST_SAVED_SETTINGS then
 assert(VoidMarkMiniMapDB.durability==false,"Saved durability-off preference was overwritten")
 event("PLAYER_ENTERING_WORLD")
 assert(VoidMarkMiniMapDB.durability==false,"Reload/startup events lost durability preference")
 realPrint("PASS: saved durability-off preference survives initialization")
end
assert(GetMinimapShape()=="SQUARE")
assert(Minimap:GetFrameStrata()=="BACKGROUND" and VoidMarkMiniMapFrame:GetFrameStrata()=="BACKGROUND", "Quest objectives should render above map")
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
-- Nexus uses mouse scripts and an OnUpdate loop, not standard drag scripts.
VoidMarkMiniMapDB.drawer=true
local nexusDown=function(self) self:SetScript("OnUpdate",function(button)
    button:SetPoint("CENTER",Minimap,"CENTER",99,99)
end) end
local nexusUp=function(self) self:SetScript("OnUpdate",nil) end
local nexusTick=function() end
local clicks=0
VoidMarkNexusMinimap=CreateFrame("Button",nil,Minimap)
VoidMarkNexusMinimap:SetScript("OnMouseDown",nexusDown)
VoidMarkNexusMinimap:SetScript("OnMouseUp",nexusUp)
VoidMarkNexusMinimap:SetScript("OnUpdate",nexusTick)
VoidMarkNexusMinimap:SetScript("OnClick",function() clicks=clicks+1 end)
controller.scripts.OnUpdate(controller,2)
assert(VoidMarkNexusMinimap.parent==VoidMarkMiniMapFrame)
assert(VoidMarkNexusMinimap.point[2]==VoidMarkMiniMapFrame)
assert(not VoidMarkNexusMinimap:GetScript("OnMouseDown"))
assert(not VoidMarkNexusMinimap:GetScript("OnMouseUp"))
assert(not VoidMarkNexusMinimap:GetScript("OnUpdate"))
VoidMarkNexusMinimap.scripts.OnClick()
assert(clicks==1,"Keep Nexus click actions")
assert(icon:GetScript("OnMouseDown")==nil)
VoidMarkMiniMapDB.drawer=false
controller.scripts.OnUpdate(controller,2)
assert(VoidMarkNexusMinimap:GetScript("OnMouseDown")==nexusDown)
assert(VoidMarkNexusMinimap:GetScript("OnMouseUp")==nexusUp)
assert(VoidMarkNexusMinimap:GetScript("OnUpdate")==nexusTick)
assert(VoidMarkNexusMinimap.parent==Minimap)
-- Confirmed protected native chrome can be hidden outside combat, but not in it.
AddonCompartmentFrame=CreateFrame("Button",nil,UIParent)
AddonCompartmentFrame.IsProtected=function() return true end
GameTimeFrame.IsProtected=function() return true end
GameTimeFrame:Show()
GameTimeTexture=CreateFrame("Texture",nil,GameTimeFrame)
combat=true
controller.scripts.OnUpdate(controller,2)
assert(AddonCompartmentFrame:IsShown() and GameTimeFrame:IsShown())
combat=false
event("PLAYER_REGEN_ENABLED")
assert(not AddonCompartmentFrame:IsShown() and not GameTimeFrame:IsShown())
assert(not GameTimeTexture:IsShown())
assert(AddonCompartmentFrame.parent==GameTimeFrame.parent)
-- Reproduce the user's saved drawer=false setting with Nexus's real circular anchors.
VoidMarkMiniMapDB.drawer=false
controller.scripts.OnUpdate(controller,2)
local nexus=VoidMarkNexusMinimap
local radius=Minimap:GetWidth()/2+8
for _,angle in ipairs({0,30,45,90,135,180,225,270,315}) do
    local radians=math.rad(angle)
    nexus:ClearAllPoints()
    nexus:SetPoint("CENTER",Minimap,"CENTER",math.cos(radians)*radius,math.sin(radians)*radius)
    local x,y=nexus.point[4],nexus.point[5]
    assert(math.abs(math.max(math.abs(x),math.abs(y))-radius)<0.001,
        "Nexus must follow the square even with collection disabled")
end
assert(nexus:GetScript("OnMouseDown")==nexusDown,"Keep native drag with collection off")
assert(nexus:GetScript("OnMouseUp")==nexusUp)
combat=true
nexus:SetPoint("CENTER",Minimap,"CENTER",50,50)
assert(nexus.point[4]==50,"Square hook must defer during combat")
combat=false
event("PLAYER_REGEN_ENABLED")
assert(math.abs(nexus.point[4]-radius)<0.001,"Reproject after combat")
MinimapCluster.DielFrame=CreateFrame("Frame",nil,UIParent)
controller.scripts.OnUpdate(controller,2)
assert(not MinimapCluster.DielFrame:IsShown(),"Hide Forever's actual day/night frame")
assert(MinimapCluster.DielFrame.parent==GameTimeFrame.parent)
MinimapCluster.DielFrame:Show()
MinimapCluster.DielFrame.hooks.OnShow(MinimapCluster.DielFrame)
assert(not MinimapCluster.DielFrame:IsShown())
-- Footer uses the real FPS addon frame and keeps its update script/settings.
GetFramerate=function() return 86.7 end
controller.scripts.OnUpdate(controller,0.25)
local fallback
for _,f in ipairs(frames) do if f.text=="FPS: 87" then fallback=f end end
assert(fallback and fallback:IsShown(),"Fallback FPS must update without TaliaaFPS")
TaliaaFPSDB={point="TOPRIGHT",x=-20,scale=1.4}
TaliaaFPSFrame=CreateFrame("Frame",nil,UIParent)
local update=function() end
TaliaaFPSFrame:SetScript("OnUpdate",update)
TaliaaFPSFrame:CreateFontString():SetText("FPS: 87")
controller.scripts.OnUpdate(controller,2)
assert(TaliaaFPSFrame.parent==fallback.parent,"Embed native FPS frame in footer")
assert(TaliaaFPSFrame:GetScript("OnUpdate")==update)
assert(not TaliaaFPSFrame.mouse and not fallback:IsShown())
assert(TaliaaFPSDB.scale==1.4 and TaliaaFPSDB.x==-20,"Do not overwrite standalone settings")
assert(VoidMarkMiniMapFrame.height==Minimap.height+38,"Reserve footer space outside terrain")
assert(fallback.fontSize>=12 and fallback.fontSize<=14 and fallback.fontFlags=="OUTLINE","Footer must use readable outlined text")
assert(VoidMarkMiniMapOptions.fps:GetChecked(),"Show FPS defaults on")
VoidMarkMiniMapOptions.fps:SetChecked(false)
VoidMarkMiniMapOptions.fps.scripts.OnClick(VoidMarkMiniMapOptions.fps)
assert(not VoidMarkMiniMapDB.fps and not TaliaaFPSFrame:IsShown() and not fallback:IsShown())
controller.scripts.OnUpdate(controller,2)
assert(not TaliaaFPSFrame:IsShown(),"Periodic layout must respect FPS disabled")
VoidMarkMiniMapOptions.fps:SetChecked(true)
VoidMarkMiniMapOptions.fps.scripts.OnClick(VoidMarkMiniMapOptions.fps)
assert(TaliaaFPSFrame:IsShown() and not fallback:IsShown())
local embedded=TaliaaFPSFrame
TaliaaFPSFrame=nil
VoidMarkMiniMapOptions.fps:SetChecked(false)
VoidMarkMiniMapOptions.fps.scripts.OnClick(VoidMarkMiniMapOptions.fps)
assert(not fallback:IsShown(),"Toggle also hides built-in fallback")
VoidMarkMiniMapOptions.fps:SetChecked(true)
VoidMarkMiniMapOptions.fps.scripts.OnClick(VoidMarkMiniMapOptions.fps)
assert(fallback:IsShown())
TaliaaFPSFrame=embedded
controller.scripts.OnUpdate(controller,2)
date=function(format) assert(format=="%H:%M"); return "16:25" end
local function checkClock(server,localTime,expected)
    VoidMarkMiniMapOptions.clock:SetChecked(server)
    VoidMarkMiniMapOptions.clock.scripts.OnClick(VoidMarkMiniMapOptions.clock)
    VoidMarkMiniMapOptions.localClock:SetChecked(localTime)
    VoidMarkMiniMapOptions.localClock.scripts.OnClick(VoidMarkMiniMapOptions.localClock)
    local found
    for _,f in ipairs(frames) do
        if f.kind=="FontString" and f.parent==fallback.parent and (f.text or ""):gsub("\n"," / ")==expected then found=f end
    end
    assert(found,"Missing expected clock text: "..expected)
    assert(found:IsShown()==(server or localTime))
end
checkClock(true,false,"22:45")
checkClock(false,true,"16:25")
checkClock(true,true,"Server 22:45 / Local 16:25")
checkClock(false,false,"")
checkClock(true,false,"22:45")
assert(VoidMarkMiniMapOptions.clock24:GetChecked(),"Existing clocks default to 24-hour")
VoidMarkMiniMapOptions.clock24:SetChecked(false)
VoidMarkMiniMapOptions.clock24.scripts.OnClick(VoidMarkMiniMapOptions.clock24)
checkClock(true,false,"10:45 PM")
checkClock(false,true,"4:25 PM")
checkClock(true,true,"Server 10:45 PM / Local 4:25 PM")
GetGameTime=function() return 0,5 end
checkClock(true,false,"12:05 AM")
GetGameTime=function() return 12,0 end
checkClock(true,false,"12:00 PM")
VoidMarkMiniMapOptions.clock24:SetChecked(true)
VoidMarkMiniMapOptions.clock24.scripts.OnClick(VoidMarkMiniMapOptions.clock24)
checkClock(true,false,"12:00")
realPrint("PASS: saved 12/24-hour toggle, both clocks, midnight and noon")
realPrint("PASS: server/local/both/neither clock choices and compact overlay header geometry")
realPrint("PASS: FPS setting hides/restores embedded and fallback counters; larger outlined footer")
realPrint("PASS: FPS fallback, live TaliaaFPS embedding, saved settings, footer geometry")
realPrint("PASS: saved collection-off Nexus square geometry at nine angles, combat recovery, Forever DielFrame")
realPrint("PASS: Nexus mouse-loop capture/restore, click preservation, protected native daylight/addon compartment")
realPrint("PASS: nested duplicate coordinates, late/nested/anonymous zoom, sun/calendar, unrelated icons, combat safety")
realPrint("PASS: startup, corrupt settings, sparse/late controls, combat deferral, commands, drag, resize/UI scale, options, zoom, reset, screen cap")
realPrint("PASS: drawer capture/restore, protected and hidden icons, coordinates/failure fallback, saved position recovery")

-- Quest counts are not coordinate strings, and temporary zero icon scales are safe.
local questProgress=Minimap:CreateFontString();questProgress:SetText("1 / 35");questProgress:SetAlpha(1)
controller.scripts.OnUpdate(controller,.5)
assert(questProgress.alpha==1,"Quest counters must not be suppressed as coordinates")
QueueStatusButton:SetScale(0);controller.scripts.OnUpdate(controller,.25)
for _,v in ipairs(QueueStatusButton.point) do if type(v)=="number" then assert(v==v and math.abs(v)<1e8) end end
assert(SLASH_VOIDMARKMINIMAP1=="/vmini" and SLASH_VOIDMARKMINIMAP2=="/voidmarkminimap")
assert(SLASH_VOIDMARKMINIMAP3=="/vmm","Standalone legacy shortcut retained")
realPrint("PASS: quest progress preserved, zero icon scale bounded, unique minimap commands")

local gameClock,fpsAPI=GetGameTime,GetFramerate
GetGameTime=function() return nil,nil end;GetFramerate=function() return 0/0 end
controller.scripts.OnUpdate(controller,2)
checkClock(true,false,"--:--")
GetGameTime,GetFramerate=gameClock,fpsAPI
realPrint("PASS: unavailable clocks and non-finite FPS do not stop minimap updates")

-- Event-driven durability and setting behavior use the actual live footer.
GetInventoryItemDurability=function(slot) if slot==1 then return 92,100 end end
event("UPDATE_INVENTORY_DURABILITY")
local durability
for _,f in ipairs(frames) do if f.kind=="FontString" and f.parent==fallback.parent and (f.text=="Durability: 92%" or f.text=="92%") then durability=f end end
assert(durability,"Durability event did not refresh actual equipment")
assert(VoidMarkMiniMapOptions.durability:GetChecked(),"Durability defaults on")
VoidMarkMiniMapOptions.durability:SetChecked(false)
VoidMarkMiniMapOptions.durability.scripts.OnClick(VoidMarkMiniMapOptions.durability)
assert(not durability:IsShown() and not VoidMarkMiniMapDB.durability)
VoidMarkMiniMapOptions.durability:SetChecked(true)
VoidMarkMiniMapOptions.durability.scripts.OnClick(VoidMarkMiniMapOptions.durability)
GetInventoryItemDurability=function(slot) if slot==1 then return 20,100 end end
event("PLAYER_EQUIPMENT_CHANGED")
assert(durability.text=="Durability: 20%" or durability.text=="20%")
GetInventoryItemDurability=function(slot) if slot==1 then return 100,100 end end
event("MERCHANT_CLOSED")
assert(durability.text=="Durability: 100%" or durability.text=="100%")
UIParent:SetSize(1920,1080)
for _,size in ipairs({180,220,300,400,600,180,600}) do
 command("size "..size)
 controller.scripts.OnUpdate(controller,.5)
 local intervals={}
 if TaliaaFPSFrame and TaliaaFPSFrame:IsShown() then
  local left=TaliaaFPSFrame.point[4]
  assert(left>=0 and left+TaliaaFPSFrame.width<=size,"Embedded FPS escaped footer bounds")
  intervals[#intervals+1]={left,left+TaliaaFPSFrame.width}
 end
 for _,f in ipairs(frames) do
  if f.kind=="FontString" and f.parent==fallback.parent and f:IsShown() and f.point and f.point[1]=="LEFT" then
   local left=f.point[4];assert(left>=0 and left+f.width<=size,"Footer text escaped minimap width")
   intervals[#intervals+1]={left,left+f.width}
  end
 end
 table.sort(intervals,function(a,b)return a[1]<b[1] end)
 for i=2,#intervals do assert(intervals[i][1]>=intervals[i-1][2],"Footer labels overlap") end
end
assert(durability.text=="Durability: 100%","Expanding must restore the full durability label")
local localDate=date;date=function()error("Date unavailable")end
checkClock(false,true,"--:--");date=localDate
GetFramerate=function()return nil end;controller.scripts.OnUpdate(controller,.25)
assert(fallback.text=="FPS: --","Missing FPS API value did not become unknown")
GetInventoryItemDurability=nil;event("UPDATE_INVENTORY_DURABILITY")
assert(durability.text=="Durability: --","Missing durability data must remain unknown")
realPrint("PASS: footer equipment/repair events, durability toggle, responsive bounds, expansion and missing date/durability")
-- Hover on the existing durability segment; no additional visible window/button.
time=function()return 1000000 end
GetInventoryItemDurability=function(slot)if slot==1 then return 92,100 end end
GetInventoryItemLink=function(_,slot)if slot==1 then return '|Hitem:100:0|h[Helm]|h' end end
local repairReads=0
C_TooltipInfo={GetInventoryItem=function(_,slot)repairReads=repairReads+1;return {repairCost=26157}end}
GameTooltip=CreateFrame('GameTooltip',nil,UIParent)
GameTooltip.SetOwner=function(self,owner)self.owner=owner end
GameTooltip.IsOwned=function(self,owner)return self.owner==owner end
GameTooltip.SetText=function(self,text)self.text=text;self.lines={}end
GameTooltip.AddLine=function(self,text)self.lines[#self.lines+1]=text end
local hover
for _,f in ipairs(frames)do if f.parent==fallback.parent and f.scripts.OnEnter then hover=f end end
assert(hover and hover.kind=='Frame','Repair tooltip must reuse the durability footer area')
assert(controller.registered.MERCHANT_SHOW and controller.registered.MERCHANT_UPDATE)
hover.scripts.OnEnter(hover)
assert(GameTooltip.text=='Durability: 92%' and #GameTooltip.lines==1 and GameTooltip.lines[1]=='Repair cost: 2g 61s 57c')
local previousReads=repairReads
for i=1,30 do controller.scripts.OnUpdate(controller,.25) end
assert(repairReads==previousReads,'Unchanged equipment must not poll repair APIs')
CanMerchantRepair=function()return true end
GetRepairAllCost=function()return 30000,true end
event('MERCHANT_SHOW')
assert(repairReads==previousReads+1,'Opening merchant must read the quote promptly')
event('MERCHANT_UPDATE');event('MERCHANT_UPDATE')
controller.scripts.OnUpdate(controller,.01)
assert(repairReads==previousReads+2,'Merchant update bursts should coalesce to one repair scan')
assert(#GameTooltip.lines==1 and GameTooltip.lines[1]=='Repair cost: 3g 0s 0c (vendor total)')
assert(next(VoidMarkMiniMapDB.repairObservations.items),'Vendor per-item observation was not saved')
C_TooltipInfo.GetInventoryItem=function()return {}end
event('MERCHANT_CLOSED');controller.scripts.OnUpdate(controller,.01)
assert(GameTooltip.lines[1]=='Repair cost: ~2g 62s 0c','Merchant close should restore equipment-only estimate')
-- Another tooltip owner must never be overwritten or hidden by our refresh/leave.
GameTooltip.owner=UIParent;GameTooltip:SetText('Other addon tooltip')
event('PLAYER_EQUIPMENT_CHANGED');controller.scripts.OnUpdate(controller,.01)
assert(GameTooltip.text=='Other addon tooltip')
hover.scripts.OnLeave(hover);assert(GameTooltip:IsShown())
hover.scripts.OnEnter(hover);hover.scripts.OnLeave(hover)
assert(not GameTooltip:IsShown(),'Leaving durability must close its own tooltip')
VoidMarkMiniMapOptions.durability:SetChecked(false)
VoidMarkMiniMapOptions.durability.scripts.OnClick(VoidMarkMiniMapOptions.durability)
assert(not hover:IsShown(),'Disabled durability must remove hover interception')
-- Broker_DurabilityInfo also invalidates on death and resurrection explicitly.
assert(controller.registered.PLAYER_DEAD and controller.registered.PLAYER_UNGHOST,
 'Death/resurrection refresh events must be registered')
local current,quote=80,2000
GetInventoryItemDurability=function(slot)if slot==1 then return current,100 end end
C_TooltipInfo.GetInventoryItem=function()repairReads=repairReads+1;return {repairCost=quote}end
VoidMarkMiniMapOptions.durability:SetChecked(true)
VoidMarkMiniMapOptions.durability.scripts.OnClick(VoidMarkMiniMapOptions.durability)
hover.scripts.OnEnter(hover)
current=70;quote=3000
previousReads=repairReads
event('PLAYER_DEAD');event('PLAYER_DEAD')
controller.scripts.OnUpdate(controller,.01)
assert(repairReads==previousReads+1 and GameTooltip.text=='Durability: 70%'
 and GameTooltip.lines[1]=='Repair cost: 0g 30s 0c','Death must refresh current damage and repair price')
current=100;quote=0
event('PLAYER_UNGHOST');controller.scripts.OnUpdate(controller,.01)
assert(GameTooltip.text=='Durability: 100%' and GameTooltip.lines[1]=='Repair cost: 0g 0s 0c',
 'Resurrection after repairs must not keep the old cost')
hover.scripts.OnLeave(hover)
realPrint('PASS: explicit death/resurrection repair refresh and repeated-event coalescing')
realPrint('PASS: compact repair tooltip, no polling, merchant event coalescing, saved estimates and other-tooltip ownership')
