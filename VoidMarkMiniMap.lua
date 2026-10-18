local addonName = ...
local Footer = VoidMarkMiniMapFooter
local LayoutFooter, UpdateDurability
local footerIcons, footerSeparators = {}, {}
local durabilityText, durabilityPercent, clockFull, clockCompact
local embeddedFPS, footerLayoutKey
local repair, repairHover, repairPending, merchantOpen
local ShowDurabilityTooltip, HideDurabilityTooltip
local VM = CreateFrame("Frame")
local db, holder, header, zone, clock, options, sizeSlider, lockButton, grip, dock, mapViewport
local ready, pending, applying = false, false, false
local controls, seenControls = {}, {}
local mailButton
local layoutDirty, rimDirty, rimApplying = false, true, false
local watched = {}
local drawer, drawerToggle, coordinates, footer, fpsText, latencyText
local topHeight, bottomHeight = 24, 32
local drawerEntries, drawerSeen = {}, {}
local nativeHidden = {}
local function InEditMode()
    return EditModeManagerFrame and EditModeManagerFrame.IsShown and EditModeManagerFrame:IsShown()
end
local accents = { purple={0.55,0.25,0.85}, cyan={0.1,0.75,0.85}, amber={0.9,0.6,0.15} }
local defaults = { size = 300, locked = true, clock = true, localClock = false, clock24 = true, durability = true, fps = true, latency = true, purple = true,
    coordinates = false, drawer = true, accent = "purple",
    iconScale = 1, rotate = false, headerBelow = false,
    point = "TOPRIGHT", x = -35, y = -45 }
local points = { TOPLEFT=true, TOP=true, TOPRIGHT=true, LEFT=true, CENTER=true,
    RIGHT=true, BOTTOMLEFT=true, BOTTOM=true, BOTTOMRIGHT=true }

local function Say(message)
    print("|cffb366ffVoidMark Mini Map:|r " .. message)
end

local function Number(value, fallback)
    local n = tonumber(value)
    if not n or n ~= n or n == math.huge or n == -math.huge then return fallback end
    return n
end

local function Size(value)
    local reservedHeight = topHeight + bottomHeight + 16
    -- Forever can render large map surfaces; screen bounds set the real maximum.
    local maximum = math.max(180, math.min(600, UIParent:GetWidth()-80, UIParent:GetHeight()-reservedHeight))
    return math.floor(math.max(180, math.min(maximum, Number(value, 300))) + 0.5)
end

local function LoadSettings()
    if type(VoidMarkMiniMapDB) ~= "table" then VoidMarkMiniMapDB = {} end
    db = VoidMarkMiniMapDB
    -- Preserve the previous combined toggle on first upgrade only.
    if type(db.latency)~="boolean" then
        if type(db.fps)=="boolean" then db.latency=db.fps else db.latency=defaults.latency end
    end
    for key, value in pairs(defaults) do
        if type(db[key]) ~= type(value) then db[key] = value end
    end
    if type(db.rimPositions)~="table" then db.rimPositions={} end
    db.iconScale = math.max(.5, math.min(2, Number(db.iconScale, 1)))
    db.size = Size(db.size)
    db.point = points[db.point] and db.point or defaults.point
    db.x = math.max(-UIParent:GetWidth(), math.min(UIParent:GetWidth(), Number(db.x, -35)))
    db.y = math.max(-UIParent:GetHeight(), math.min(UIParent:GetHeight(), Number(db.y, -45)))
end

local function Backdrop(frame)
    frame:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8", edgeFile="Interface\\Buttons\\WHITE8X8", edgeSize=2})
    frame:SetBackdropColor(0.035, 0.025, 0.055, 0.96)
    frame:SetBackdropBorderColor(0.55, 0.25, 0.85, 1)
end

local function Button(parent, text, width, onClick)
    local button = CreateFrame("Button", nil, parent, "UIPanelButtonTemplate")
    button:SetSize(width, 22)
    button:SetText(text)
    button:SetScript("OnClick", onClick)
    return button
end

local function Tooltip(frame, title, detail)
    frame:HookScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(title)
        GameTooltip:AddLine(detail, 1, 1, 1, true)
        GameTooltip:Show()
    end)
    frame:HookScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
end

-- Native and addon minimap buttons are distributed along the outside edge.
-- Keep their original OnClick scripts; only reposition non-protected frames.
local function RimPoint(index)
    local step = 29
    local perSide = math.max(1, math.floor((db.size - 40) / step))
    local side = math.floor(index / perSide) % 4
    local offset = 24 + (index % perSide) * step
    if side == 0 then return "TOPRIGHT", holder, "TOPRIGHT", 16, -(topHeight+2)-offset end
    if side == 1 then return "BOTTOMRIGHT", holder, "BOTTOMRIGHT", -offset, -14 end
    if side == 2 then return "BOTTOMLEFT", holder, "BOTTOMLEFT", -14, 25+offset end
    return "TOPLEFT", holder, "TOPLEFT", offset, 14
end

-- Nexus keeps its own circular positioning when addon collection is disabled.
-- Project only that button's CENTER anchors onto the square, preserving its
-- mouse/click handlers and saved angle. Hooks remain inert during combat/Edit Mode.
local nexusHooks = {}
local function AdaptNexusShape()
    local button = _G.VoidMarkNexusMinimap or (_G.VoidMarkNexus and _G.VoidMarkNexus.minimap)
    if not button or not hooksecurefunc or (button.IsProtected and button:IsProtected()) then return end
    if not nexusHooks[button] then
        local adjusting = false
        local function Project(self, point, relative, relativePoint, x, y)
            if adjusting or not ready or db.drawer then return end
            if InCombatLockdown() or InEditMode() then pending=true; return end
            if point~="CENTER" or relative~=Minimap or relativePoint~="CENTER"
                or type(x)~="number" or type(y)~="number" or (x==0 and y==0) then return end
            local halfWidth, halfHeight = Minimap:GetWidth()/2+8, Minimap:GetHeight()/2+8
            local factor = math.min(x~=0 and halfWidth/math.abs(x) or math.huge,
                y~=0 and halfHeight/math.abs(y) or math.huge)
            if math.abs(factor-1)<0.0001 then return end
            adjusting=true
            self:ClearAllPoints()
            self:SetPoint("CENTER",Minimap,"CENTER",x*factor,y*factor)
            adjusting=false
        end
        hooksecurefunc(button,"SetPoint",Project)
        nexusHooks[button]=Project
    end
    if button.GetNumPoints and button:GetNumPoints()==1 then
        nexusHooks[button](button,button:GetPoint(1))
    end
end

local function CollectControls()
    local function Add(control)
        if not control or seenControls[control] or (control.IsProtected and control:IsProtected()) then return end
        seenControls[control] = true
        controls[#controls+1] = control
        control:SetParent(holder)
        control:SetFrameStrata(holder:GetFrameStrata())
        control:SetFrameLevel(holder:GetFrameLevel()+8)
    end
    Add(MiniMapTracking)
    if not MiniMapTracking then Add(MiniMapTrackingButton) end
    Add(MiniMapWorldMapButton)
    -- Calendar and Forever DielFrame day/night chrome are suppressed separately.
    Add(QueueStatusMinimapButton)
    Add(QueueStatusButton)
    Add(MiniMapBattlefieldFrame)
    if MinimapCluster then
        Add(MinimapCluster.Tracking)
        if not MinimapCluster.Tracking then Add(MinimapCluster.TrackingButton) end
        Add(MinimapCluster.InstanceDifficulty)
    end
end

local function LayoutControls()
    CollectControls()
    db.size = Size(db.size)
    holder:SetSize(db.size+8, db.size+topHeight+bottomHeight+4)
    mapViewport:SetSize(db.size, db.size)
    local count = 0
    for _, control in ipairs(controls) do
        if control:IsShown() then
            control:SetParent(holder)
            local dimension = math.max(control:GetWidth(),control:GetHeight(),1)
            local scale = math.min(1,24/dimension)
            control:SetScale(scale)
            control:ClearAllPoints()
            local point, relative, relativePoint, x, y = RimPoint(count)
            control:SetPoint("CENTER",relative,relativePoint,x/scale,y/scale)
            count = count + 1
        end
    end
    return count
end

local function LayoutDrawer()
    if not drawer then return end
    if InCombatLockdown() or InEditMode() then pending = true; return end
    AdaptNexusShape()
    local function Add(button, key)
        if not button or drawerSeen[button] or (button.IsProtected and button:IsProtected()) then return end
        if not button.GetParent or not button.GetNumPoints then return end
        local entry = {button=button, parent=button:GetParent(), scale=button:GetScale(),
            strata=button:GetFrameStrata(),level=button:GetFrameLevel(),points={}}
        for i=1,button:GetNumPoints() do entry.points[i]={button:GetPoint(i)} end
        -- Preserve native click/drag/hover scripts. Reproject native drag anchors
        -- rather than disabling library-specific dragging implementations.
        entry.key=key or (button.GetName and button:GetName())
        if hooksecurefunc and not button.VoidMarkRimHook then
            button.VoidMarkRimHook=true
            hooksecurefunc(button,"SetPoint",function(self,point,relative,relativePoint,x,y)
                if not ready or not db.drawer or applying or rimApplying then return end
                if point~="CENTER" or relative~=Minimap or relativePoint~="CENTER" then return end
                if type(x)~="number" or type(y)~="number" then return end
                local extent=math.max(math.abs(x),math.abs(y))
                if extent==0 or extent==math.huge or extent~=extent then return end
                for _,owned in ipairs(drawerEntries) do
                    if owned.button==self then
                        owned.position={x/extent,y/extent}
                        if owned.key then db.rimPositions[owned.key]=owned.position end
                        rimDirty=true
                        break
                    end
                end
            end)
        end
        drawerSeen[button]=true
        drawerEntries[#drawerEntries+1]=entry
        button:SetParent(holder)
        button:SetFrameStrata(holder:GetFrameStrata())
        button:SetFrameLevel(holder:GetFrameLevel()+8)
    end
    if not db.drawer then
        for _,entry in ipairs(drawerEntries) do
            local button=entry.button
            button:SetParent(entry.parent)
            button:SetFrameStrata(entry.strata)
            button:SetFrameLevel(entry.level)
            button:SetScale(entry.scale)
            button:ClearAllPoints()
            for _,point in ipairs(entry.points) do button:SetPoint(unpack(point)) end
        end
        drawerEntries,drawerSeen={},{}
        drawer:Hide(); drawerToggle:Hide()
        return
    end
    local lib=LibStub and LibStub("LibDBIcon-1.0",true)
    if lib and lib.GetButtonList and lib.GetMinimapButton then
        local names=lib:GetButtonList()
        table.sort(names)
        for _,name in ipairs(names) do
            local button=lib:GetMinimapButton(name)
            Add(button,"LibDBIcon:"..name)
        end
    end
    Add(_G.VoidMarkNexusMinimap,"VoidMarkNexus")
    Add(_G.VoidMarkMinimapButton,"VoidMark")
    Add(_G.VoidMarkMarketMinimapButton,"VoidMarkMarket")
    local count=0
    for _,control in ipairs(controls) do if control:IsShown() then count=count+1 end end
    for _,entry in ipairs(drawerEntries) do
        local button=entry.button
        if button:IsShown() then
            button:SetParent(holder)
            button:SetFrameStrata(holder:GetFrameStrata())
            local scale=math.min(1,24/math.max(button:GetWidth(),button:GetHeight(),1))
            button:SetScale(scale)
            button:ClearAllPoints()
            local point,relative,relativePoint,x,y=RimPoint(count)
            local pos=entry.position or (entry.key and db.rimPositions[entry.key])
            if type(pos)=="table" then
                local px,py=Number(pos[1],0),Number(pos[2],0)
                local extent=math.max(math.abs(px),math.abs(py))
                if extent>0 then
                    relative,relativePoint=mapViewport,"CENTER"
                    x,y=px/extent*(db.size/2+16),py/extent*(db.size/2+16)
                end
            end
            button:SetPoint("CENTER",relative,relativePoint,x/scale,y/scale)
            count=count+1
        end
    end
    drawer:Hide()
    drawerToggle:Hide()
end

-- Coalesce button-library anchor writes and visibility changes into one layout.
-- Hooks never reposition synchronously and are inert while our own layout runs.
local function WatchRim(button)
    if not button or watched[button] or not hooksecurefunc then return end
    watched[button]=true
    local function Dirty()
        if ready and not rimApplying and not applying then rimDirty=true end
    end
    for _,method in ipairs({"SetPoint","SetScale","SetParent"}) do
        if type(button[method])=="function" then hooksecurefunc(button,method,Dirty) end
    end
    if button.HookScript then
        button:HookScript("OnShow",Dirty)
        button:HookScript("OnHide",Dirty)
    end
end

local function RefreshRim()
    if not ready or InCombatLockdown() or InEditMode() then pending=true; return end
    rimApplying=true
    LayoutControls()
    LayoutDrawer()
    for _,button in ipairs(controls) do WatchRim(button) end
    for _,entry in ipairs(drawerEntries) do WatchRim(entry.button) end
    rimApplying=false
    rimDirty=false
end

local function RecoverPosition()
    -- Convert the saved anchor into a clamped top-left position, preserving visible placement.
    local width,height=UIParent:GetWidth(),UIParent:GetHeight()
    local w,h=holder:GetWidth(),holder:GetHeight()
    local point=db.point
    local x=point:find("LEFT") and db.x or (point:find("RIGHT") and width-w+db.x or (width-w)/2+db.x)
    local top=point:find("TOP") and height+db.y or (point:find("BOTTOM") and h+db.y or (height+h)/2+db.y)
    x=math.max(0,math.min(math.max(0,width-w),x))
    top=math.max(math.min(h,height),math.min(height,top))
    db.point,db.x,db.y="TOPLEFT",x,top-height
end

-- Scan only minimap-owned trees, never UIParent or arbitrary addon windows.
local function WalkMinimap(visit)
    local seen = {}
    local function Walk(frame, depth)
        if not frame or seen[frame] or depth > 8 then return end
        seen[frame] = true
        visit(frame)
        if frame.GetChildren then
            for _, child in ipairs({frame:GetChildren()}) do Walk(child, depth+1) end
        end
    end
    Walk(Minimap, 0)
    Walk(MinimapCluster, 0)
    Walk(MinimapBackdrop, 0)
end

local function SuppressNativeCoordinates()
    WalkMinimap(function(frame)
        if not frame.GetRegions then return end
        for _, region in ipairs({frame:GetRegions()}) do
            if region ~= coordinates and region.IsObjectType and region:IsObjectType("FontString")
                and region.GetText then
                local value = region:GetText()
                if not (issecretvalue and issecretvalue(value)) and type(value) == "string" then
                    -- Color codes, integer coordinates and optional parentheses occur in addons.
                    value = value:gsub("|c%x%x%x%x%x%x%x%x", ""):gsub("|r", "")
                    if value:match("^%s*%(?%s*%d+%.?%d*%s*,%s*%d+%.?%d*%s*%)?%s*$") then
                        region:SetAlpha(0)
                    end
                end
            end
        end
    end)
end

-- Keep confirmed native chrome under a hidden parent. OnShow alone cannot stop
-- another layout from restoring alpha/anchors or creating controls after login.
local function SuppressNativeChrome()
    if InCombatLockdown() or InEditMode() then pending = true; return end
    local function Hide(frame)
        if not frame or frame == Minimap or frame == MinimapCluster then return end
        if not nativeHidden[frame] then
            nativeHidden[frame] = true
            if frame.HookScript then
                frame:HookScript("OnShow", function(self)
                    if not InCombatLockdown() and not InEditMode() then self:Hide() end
                end)
            end
        end
        frame:Hide()
        -- Do not hide containers: they can own addon buttons or native overlays.
        if frame.SetParent then frame:SetParent(VM.hiddenChrome) end
    end
    for _, name in ipairs({"MinimapZoomIn", "MinimapZoomOut", "MiniMapZoomIn", "MiniMapZoomOut",
        "GameTimeFrame", "GameTimeTexture", "TimeManagerClockButton", "MiniMapCalendarButton",
        "GameTimeCalendarInvitesTexture", "GameTimeCalendarInvitesGlow", "GameTimeCalendarEventAlarmTexture",
        "AddonCompartmentFrame", "MiniMapMailFrame",
        "MinimapBorder", "MinimapBorderTop", "MinimapCompassTexture", "MinimapCompassTextureUnderlay", "MinimapZoneTextButton", "MinimapZoneText",
        "MinimapClusterBorderTop"}) do Hide(_G[name]) end
    WalkMinimap(function(frame)
        for _, key in ipairs({"MailFrame", "ZoomHitArea", "ZoomIn", "ZoomOut", "ZoomInButton", "ZoomOutButton",
            "Calendar", "CalendarButton", "GameTimeFrame", "GameTimeTexture", "DielFrame",
            "AddonCompartmentFrame", "AddonCompartment", "ZoneTextButton", "BorderTop"}) do
            Hide(frame[key])
        end
        -- Some client versions have anonymous zoom buttons; match their normal
        -- texture only. Addon icons commonly share the zoom HIGHLIGHT texture.
        if frame.GetNormalTexture then
            local texture = frame:GetNormalTexture()
            local path = texture and texture.GetTexture and texture:GetTexture()
            if type(path) == "string" then
                path = path:lower():gsub("/", "\\")
                if (path:match("ui%-minimap%-zoomin$") or path:match("ui%-minimap%-zoomout$")) then Hide(frame) end
            end
        end
    end)
end

-- Independent mail notification: use Blizzard mail APIs without its minimap frame.
local function UpdateMail()
    if not mailButton then return end
    local query = HasNewMail or (C_Mail and C_Mail.HasNewMail)
    local ok, waiting = false, nil
    if type(query)=="function" then ok,waiting=pcall(query) end
    if ok and not (issecretvalue and issecretvalue(waiting)) then
        mailButton:SetShown(waiting==true or waiting==1)
    end
end

local function CreateMailButton()
    mailButton = CreateFrame("Button", "VoidMarkMiniMapMailButton", holder)
    mailButton:SetSize(24, 24)
    mailButton:SetFrameStrata(holder:GetFrameStrata())
    mailButton:SetFrameLevel(holder:GetFrameLevel()+10)
    -- A small inset keeps the envelope inside the terrain's top-left corner.
    -- Anchor to the viewport, not the movable header or Blizzard's HUD shell.
    mailButton:SetPoint("TOPLEFT", mapViewport, "TOPLEFT", 6, -6)
    local icon = mailButton:CreateTexture(nil, "ARTWORK")
    icon:SetPoint("CENTER")
    -- The former Minimap-Mail path is not the native mail asset. Prefer the
    -- client atlas only when it exists, retaining its original aspect ratio.
    local atlas="ui-hud-minimap-mail-up"
    local info=C_Texture and C_Texture.GetAtlasInfo and C_Texture.GetAtlasInfo(atlas)
    if info and icon.SetAtlas then
        icon:SetAtlas(atlas)
        local w,h=info.width or 20,info.height or 15
        local scale=24/math.max(w,h,1)
        icon:SetSize(w*scale,h*scale)
    else
        icon:SetTexture("Interface\\Icons\\INV_Letter_15")
        icon:SetSize(24,24)
    end
    mailButton:Hide()
    mailButton:SetScript("OnEnter", function(self)
        if not GameTooltip then return end
        GameTooltip:SetOwner(self, "ANCHOR_LEFT")
        GameTooltip:SetText(HAVE_MAIL or "You have unread mail", 1, 0.82, 0)
        local senders=GetLatestThreeSenders or (C_Mail and C_Mail.GetLatestThreeSenders)
        if senders then
            local ok,sender1,sender2,sender3 = pcall(senders)
            local values=ok and {sender1,sender2,sender3} or {}
            for i=1,3 do
                local sender=values[i]
                if type(sender) == "string" and sender ~= "" then
                    GameTooltip:AddLine(sender, 1, 1, 1)
                end
            end
        end
        GameTooltip:Show()
    end)
    local function HideMailTooltip(self)
        if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(self) then GameTooltip:Hide() end
    end
    mailButton:SetScript("OnLeave",HideMailTooltip)
    mailButton:SetScript("OnHide",HideMailTooltip)
    UpdateMail()
end

local function UpdateCoordinates()
    if not coordinates then return end
    if not db.coordinates then return end
    local text="--, --"
    -- Instances and restricted map data must not cause errors or disturb the world map.
    local ok,result=pcall(function()
        if not C_Map or not C_Map.GetBestMapForUnit or not C_Map.GetPlayerMapPosition then return end
        local map=C_Map.GetBestMapForUnit("player")
        local position=map and C_Map.GetPlayerMapPosition(map,"player")
        if not position then return end
        local x,y=position:GetXY()
        if issecretvalue and (issecretvalue(x) or issecretvalue(y)) then return end
        if type(x)=="number" and type(y)=="number" and x>=0 and x<=1 and y>=0 and y<=1 then
            return string.format("%.1f, %.1f",x*100,y*100)
        end
    end)
    if ok and result then text=result end
    coordinates:SetText(text)
    if LayoutFooter then LayoutFooter() end
end

local function StyleFooterText(text)
    text:SetFontObject("GameFontHighlight")
    local font = text:GetFont()
    if font then text:SetFont(font,14,"OUTLINE") end
    text:SetTextColor(1,1,1)
    text:SetShadowColor(0,0,0,1)
    text:SetShadowOffset(1,-1)
end

-- Embed TaliaaFPS's live frame, retaining its own update interval/rounding.
-- Do not write its saved position or scale; standalone settings remain intact.
local function LayoutFPS()
    if not footer then return end
    footerLayoutKey=nil
    if InCombatLockdown() or InEditMode() then pending=true; return end
    local frame = _G.TaliaaFPSFrame
    embeddedFPS = nil
    if frame and not (frame.IsProtected and frame:IsProtected()) then
        frame:SetParent(footer)
        frame:ClearAllPoints()
        frame:SetPoint("RIGHT",footer,"RIGHT",-8,0)
        frame:SetSize(90,bottomHeight-2)
        frame:SetScale(1)
        frame:SetBackdrop(nil)
        frame:EnableMouse(false)
        frame:SetFrameStrata(holder:GetFrameStrata())
        frame:SetFrameLevel(footer:GetFrameLevel()+1)
        if frame.GetRegions then
            for _,region in ipairs({frame:GetRegions()}) do
                if region.IsObjectType and region:IsObjectType("FontString") then
                    StyleFooterText(region)
                end
            end
        end
        embeddedFPS = frame
        frame:SetShown(db.fps)
        fpsText:Hide()
    else fpsText:SetShown(db.fps) end
    if LayoutFooter then LayoutFooter() end
end

local function UpdateLatency()
    if not latencyText then return end
    local ok,ms=pcall(function()
        if type(GetNetStats)~="function" then return end
        local _,_,_,world=GetNetStats()
        if issecretvalue and issecretvalue(world) then return end
        local value=Number(world,nil)
        return value and value>=0 and value or nil
    end)
    ms=ok and ms or nil
    latencyText:SetText(ms and string.format("MS: %d",math.floor(ms+.5)) or "MS: --")
    if not ms then latencyText:SetTextColor(.65,.65,.72)
    elseif ms<100 then latencyText:SetTextColor(.3,.95,.45)
    elseif ms<=200 then latencyText:SetTextColor(1,.82,.2)
    else latencyText:SetTextColor(1,.28,.28) end
    if LayoutFooter then LayoutFooter() end
end

local function UpdateFPS()
    if not fpsText then return end
    if latencyText and not latencyText:GetText() then UpdateLatency() end
    local ok,fps=pcall(function() return GetFramerate and GetFramerate() end)
    local readable,value=pcall(function()
        if not ok or (issecretvalue and issecretvalue(fps)) then return end
        return Number(fps,nil)
    end)
    fps=readable and value or nil
    fpsText:SetText(fps and fps>=0 and string.format("FPS: %d",math.floor(fps+0.5)) or "FPS: --")
    if LayoutFooter then LayoutFooter() end
end

local function FormatClock(hour,minute)
    return Footer.Clock(hour,minute,db.clock24)
end

UpdateDurability = function()
    if not durabilityText then return end
    durabilityPercent=Footer.Durability(GetInventoryItemDurability)
    durabilityText:SetTextColor(Footer.Color(durabilityPercent))
    if LayoutFooter then LayoutFooter() end
end

LayoutFooter = function()
    if not footer or not durabilityText then return end
    local size=math.max(12,math.min(14,db.size/35))
    local entries={
        {key="time",text=clock,enabled=db.clock or db.localClock,full=clockFull or "",compact=clockCompact or "",icon=true},
        {key="coordinates",text=coordinates,enabled=db.coordinates,icon=true},
        {key="durability",text=durabilityText,enabled=db.durability,full="Durability: "..(durabilityPercent and string.format("%d%%",math.floor(durabilityPercent+.5)) or "--"),icon=true},
        {key="fps",text=fpsText,enabled=db.fps or db.latency},
    }
    local fpsRegions={}
    if embeddedFPS and embeddedFPS.GetRegions then
        for _,region in ipairs({embeddedFPS:GetRegions()}) do
            if region.IsObjectType and region:IsObjectType("FontString") then
                fpsRegions[#fpsRegions+1]=region
            end
        end
    end
    local signature={tostring(db.size),tostring(embeddedFPS),latencyText:GetText() or "",tostring(db.fps),tostring(db.latency)}
    for _,e in ipairs(entries) do
        e.full=e.full or e.text:GetText() or ""
        signature[#signature+1]=tostring(e.enabled)..":"..e.full
    end
    for _,region in ipairs(fpsRegions) do signature[#signature+1]=region:GetText() or "" end
    local key=table.concat(signature,"|")
    if key==footerLayoutKey then return end
    footerLayoutKey=key
    local function measure(region,text)
        region:SetText(text);region:SetWidth(0)
        return region:GetStringWidth()
    end
    for _,e in ipairs(entries) do
        local font=e.text:GetFont()
        if font then e.text:SetFont(font,size,"OUTLINE") end
        e.text:SetWordWrap(false)
        e.full=e.full or e.text:GetText() or ""
        e.compact=e.compact or (e.key=="durability" and (e.full:gsub("Durability: ",""))) or e.full
        e.width=measure(e.text,e.full);e.compactWidth=measure(e.text,e.compact)
        if e.key=="fps" and #fpsRegions>0 then
            local widest=0
            for _,region in ipairs(fpsRegions) do
                local font=region:GetFont();if font then region:SetFont(font,size,"OUTLINE") end
                region:SetWidth(0)
                widest=math.max(widest,region:GetStringWidth())
            end
            e.width=math.max(e.width,widest);e.compactWidth=e.width
        end
    end
    local font=latencyText:GetFont()
    if font then latencyText:SetFont(font,size,"OUTLINE") end
    latencyText:SetWidth(0);latencyText:SetWordWrap(false)
    local latencyWidth=db.latency and latencyText:GetStringWidth() or 0
    local fpsWidth=db.fps and entries[4].width or 0
    local performanceGap=db.fps and db.latency and 6 or 0
    entries[4].width=fpsWidth+performanceGap+latencyWidth
    entries[4].compactWidth=entries[4].width
    local plan=Footer.Plan(db.size,entries)
    latencyText:SetShown(db.latency and not not plan.items[4])
    local previous
    for i,e in ipairs(entries) do
        local item=plan.items[i]
        local shown=not not item
        if e.key=="durability" and repairHover then
            repairHover:SetShown(shown)
            if item then
                repairHover:ClearAllPoints()
                repairHover:SetPoint("LEFT",footer,"LEFT",item.x,0)
                repairHover:SetSize(item.width,bottomHeight-2)
            elseif HideDurabilityTooltip then HideDurabilityTooltip() end
        end
        e.text:SetShown(shown and (e.key~="fps" or (db.fps and not embeddedFPS)))
        if footerIcons[i] then footerIcons[i]:SetShown(shown and not not item.icon) end
        if footerSeparators[i] then footerSeparators[i]:Hide() end
        if item then
            local inset=item.icon and 17 or 0
            e.text:SetText(plan.compact and e.compact or e.full)
            e.text:ClearAllPoints();e.text:SetPoint("LEFT",footer,"LEFT",item.x+inset,0)
            e.text:SetWidth(math.max(0,item.width-inset))
            e.text:SetJustifyH("LEFT")
            if footerIcons[i] then
                footerIcons[i]:ClearAllPoints();footerIcons[i]:SetPoint("LEFT",footer,"LEFT",item.x,0)
            end
            if previous and footerSeparators[i] then
                footerSeparators[i]:SetPoint("CENTER",footer,"LEFT",item.x-8,0);footerSeparators[i]:Show()
            end
            previous=i
            if e.key=="fps" then
                e.text:SetWidth(fpsWidth)
                latencyText:ClearAllPoints()
                latencyText:SetPoint("LEFT",footer,"LEFT",item.x+fpsWidth+performanceGap,0)
                latencyText:SetWidth(latencyWidth)
            end
            if e.key=="fps" and embeddedFPS then
                embeddedFPS:ClearAllPoints();embeddedFPS:SetPoint("LEFT",footer,"LEFT",item.x,0)
                embeddedFPS:SetSize(fpsWidth,bottomHeight-2)
                for _,region in ipairs(fpsRegions) do
                    region:ClearAllPoints();region:SetPoint("CENTER",embeddedFPS,"CENTER",0,0)
                    region:SetWidth(fpsWidth);region:SetWordWrap(false)
                end
            end
        end
    end
    if embeddedFPS then embeddedFPS:SetShown(db.fps and not not plan.items[4]) end
end

HideDurabilityTooltip = function()
    if not repairHover or not repairHover.hovered then return end
    repairHover.hovered=false
    if GameTooltip and GameTooltip.IsOwned and GameTooltip:IsOwned(repairHover) then GameTooltip:Hide() end
end
ShowDurabilityTooltip = function()
    if not GameTooltip or not repairHover or not GameTooltip.SetOwner or not GameTooltip.SetText
        or not GameTooltip.AddLine or not GameTooltip.Show then return end
    if GameTooltip.IsOwned and not GameTooltip:IsOwned(repairHover) and not repairHover.entering then return end
    GameTooltip:SetOwner(repairHover,"ANCHOR_TOP")
    GameTooltip:SetText("Durability: "..(durabilityPercent and string.format("%d%%",math.floor(durabilityPercent+.5)) or "--"))
    GameTooltip:AddLine(VoidMarkMiniMapRepair.Line(repair and repair.result),1,1,1)
    GameTooltip:Show()
end

local function UpdateLabels()
    if not ready then return end
    zone:SetText(GetMinimapZoneText() or "")
    local server,localTime
    if db.clock then
        local ok,hour,minute=pcall(function() if GetGameTime then return GetGameTime() end end)
        if not ok then hour,minute=nil,nil end
        server=FormatClock(hour,minute)
    end
    if db.localClock then
        local ok,value=pcall(function() if date then return date("%H:%M") end end)
        local hour,minute
        if ok and type(value)=="string" then hour,minute=value:match("^(%d+):(%d+)$") end
        localTime=FormatClock(tonumber(hour),tonumber(minute))
    end
    if server and localTime then
        clockFull="Server "..server.." / Local "..localTime
        clockCompact="Server "..server.."\nLocal "..localTime
    else clockFull=localTime or server or "";clockCompact=clockFull end
    LayoutFooter()
end

local function UpdateOptions()
    if not options then return end
    options.refreshing = true
    sizeSlider:SetValue(db.size)
    options.sizeText:SetText("Map size: " .. db.size)
    lockButton:SetText(db.locked and "Unlock position" or "Lock position")
    options.clock:SetChecked(db.clock)
    options.localClock:SetChecked(db.localClock)
    options.clock24:SetChecked(db.clock24)
    options.fps:SetChecked(db.fps)
    options.latency:SetChecked(db.latency)
    options.durability:SetChecked(db.durability)
    options.purple:SetChecked(db.purple)
    options.coordinates:SetChecked(db.coordinates)
    options.drawer:SetChecked(db.drawer)
    options.rotate:SetChecked(db.rotate)
    options.headerBelow:SetChecked(db.headerBelow)
    options.iconScale:SetValue(db.iconScale)
    options.iconText:SetText(Minimap.SetIconScale and ("Native icon scale: "..math.floor(db.iconScale*100+.5).."%") or "Native icon scale: unavailable on this client")
    options.accent:SetText("Border: "..db.accent)
    options.status:SetText(pending and "Changes queued until combat ends." or
        (db.locked and "Position and resize handle locked." or "Drag the zone bar or bottom-right resize handle."))
    options.refreshing = false
end

-- Keep native renderer/children alive. The former LOW-strata, mouse-enabled
-- cluster could intercept the BACKGROUND map even after it was reparented.
local function ReleaseNativeHitRegions()
    local function Release(frame)
        if not frame or frame==Minimap or not frame.EnableMouse then return end
        frame:EnableMouse(false)
        if frame.EnableMouseMotion then frame:EnableMouseMotion(false) end
        if frame.EnableMouseWheel then frame:EnableMouseWheel(false) end
    end
    Release(MinimapCluster)
    if MinimapCluster then
        Release(MinimapCluster.MinimapContainer)
        Release(MinimapCluster.Selection)
        Release(MinimapCluster.Highlight)
    end
    Release(MinimapBackdrop)
end

local function InstallOwnershipHooks()
    if not hooksecurefunc then return end
    local function Dirty()
        if ready and not applying then layoutDirty=true end
    end
    local function Watch(frame,methods)
        if not frame then return end
        for _,method in ipairs(methods) do
            if type(frame[method])=="function" then hooksecurefunc(frame,method,Dirty) end
        end
    end
    Watch(Minimap,{"SetParent","SetPoint","SetSize","SetScale","SetIconScale","SetMaskTexture"})
    -- Forever (Camelot) updates the mask and compass underlay in a CVar callback
    -- after the rotation setting changes, independently of HUD layout methods.
    Watch(MinimapCluster,{"EnableMouse","Layout","SetIconScale","SetRotateMinimap","SetHeaderUnderneath","UpdateMinimapConfig"})
    if MinimapCluster then
        Watch(MinimapCluster.Selection,{"EnableMouse","Show"})
        Watch(MinimapCluster.MinimapContainer,{"EnableMouse"})
    end
end

local function Apply()
    if not ready then return end
    if InCombatLockdown() or InEditMode() then pending = true; UpdateOptions(); return end
    if applying then return end
    applying = true
    db.size = Size(db.size)
    SuppressNativeChrome()
    SuppressNativeCoordinates()
    LayoutControls()
    mapViewport:ClearAllPoints()
    mapViewport:SetPoint("TOPLEFT",holder,"TOPLEFT",4,db.headerBelow and -2 or -(topHeight+2))
    header:ClearAllPoints()
    header:SetPoint("TOPLEFT",mapViewport,db.headerBelow and "BOTTOMLEFT" or "TOPLEFT",0,db.headerBelow and 0 or topHeight)
    header:SetPoint("TOPRIGHT",mapViewport,db.headerBelow and "BOTTOMRIGHT" or "TOPRIGHT",0,db.headerBelow and 0 or topHeight)
    RecoverPosition()
    holder:ClearAllPoints()
    holder:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    -- Match map geometry to the viewport, without scaling the player arrow.
    -- Render rotating terrain behind a square clipping viewport. The diagonal
    -- of the viewport must fit inside the rendered map at every heading.
    Minimap:SetParent(mapViewport)
    ReleaseNativeHitRegions()
    Minimap:ClearAllPoints()
    -- Use native unit scaling: applying a 2x scale also makes the player arrow 2x.
    -- Allow the map texture and its internal icons to keep their normal sizes.
    Minimap:SetFrameStrata("BACKGROUND")
    Minimap:SetScale(1)
    -- Native Forever rotation also rotates the mask; prevent terrain escaping.
    Minimap:SetSize(db.size,db.size)
    if Minimap.SetIconScale then Minimap:SetIconScale(db.iconScale) end
    local getCVar=(C_CVar and C_CVar.GetCVar) or GetCVar
    local setCVar=(C_CVar and C_CVar.SetCVar) or SetCVar
    if getCVar and setCVar then
        local wanted=db.rotate and "1" or "0"
        if getCVar("rotateMinimap")~=wanted then setCVar("rotateMinimap",wanted) end
    end
    -- The native minimap renderer ignores ScrollFrame child clipping on Forever.
    Minimap:SetPoint("CENTER",mapViewport,"CENTER",0,0)
    -- Native square mask: do not overscan or rotate a secondary mask.
    Minimap:SetMaskTexture("Interface\\ChatFrame\\ChatFrameBackground")
    if not accents[db.accent] then db.accent="purple" end
    if db.purple then
        local color=accents[db.accent]
        holder:SetBackdropBorderColor(color[1],color[2],color[3],1)
    else holder:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) end
    header:EnableMouse(not db.locked)
    grip:SetShown(not db.locked)
    LayoutDrawer()
    zone:SetWidth(math.max(60,db.size-64))
    LayoutFPS()
    UpdateFPS()
    pending, applying, layoutDirty = false, false, false
    rimDirty=true
    UpdateLabels()
    UpdateCoordinates()
    UpdateDurability()
    UpdateOptions()
end

local function Reset()
    for key, value in pairs(defaults) do db[key] = value end
    db.rimPositions={}
    for _,entry in ipairs(drawerEntries) do entry.position=nil end
    Apply()
end

local function ToggleOptions()
    if not ready then Say("Minimap is unavailable or another minimap replacement is active."); return end
    if not options then
        options = CreateFrame("Frame", "VoidMarkMiniMapOptions", UIParent, "BackdropTemplate")
        options:SetSize(390, 690)
        options:SetPoint("CENTER")
        options:SetFrameStrata("DIALOG")
        options:EnableMouse(true)
        Backdrop(options)
        local title = options:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
        title:SetPoint("TOPLEFT", 18, -18)
        title:SetText("VoidMark Mini Map")
        local close = CreateFrame("Button", nil, options, "UIPanelCloseButton")
        close:SetPoint("TOPRIGHT", -3, -3)
        close:SetScript("OnClick", function() options:Hide() end)
        options.sizeText = options:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
        options.sizeText:SetPoint("TOPLEFT", 22, -58)
        sizeSlider = CreateFrame("Slider", nil, options, "OptionsSliderTemplate")
        sizeSlider:SetPoint("TOPLEFT", 24, -84)
        sizeSlider:SetSize(340, 18)
        sizeSlider:SetMinMaxValues(180, 600)
        sizeSlider:SetValueStep(10)
        if sizeSlider.SetObeyStepOnDrag then sizeSlider:SetObeyStepOnDrag(true) end
        sizeSlider:SetScript("OnValueChanged", function(_, value)
            if options.refreshing then return end
            db.size = Size(value)
            options.sizeText:SetText("Map size: " .. db.size)
            Apply()
        end)
        lockButton = Button(options, "", 150, function() db.locked = not db.locked; Apply() end)
        lockButton:SetPoint("TOPLEFT", 20, -120)
        local reset = Button(options, "Reset", 150, Reset)
        reset:SetPoint("LEFT", lockButton, "RIGHT", 10, 0)
        local function Check(text, y, key)
            local check = CreateFrame("CheckButton", nil, options, "UICheckButtonTemplate")
            check:SetPoint("TOPLEFT", 18, y)
            local label = check:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
            label:SetPoint("LEFT", check, "RIGHT", 2, 0)
            label:SetText(text)
            check:SetScript("OnClick", function(self) db[key] = not not self:GetChecked(); Apply() end)
            return check
        end
        options.clock = Check("Show server clock", -153, "clock")
        options.purple = Check("Colored border", -185, "purple")
        options.coordinates = Check("Show player coordinates", -217, "coordinates")
        options.drawer = Check("Place addon buttons around map", -249, "drawer")
        options.fps = Check("Show FPS", -281, "fps")
        options.localClock = Check("Show local clock", -313, "localClock")
        options.clock24 = Check("Use 24-hour time (off: 12-hour AM/PM)", -345, "clock24")
        options.durability = Check("Show equipment durability", -377, "durability")
        options.latency = Check("Show server latency (MS)", -409, "latency")
        options.accent = Button(options,"",180,function()
            local nextColor={purple="cyan",cyan="amber",amber="purple"}
            db.accent=nextColor[db.accent] or "purple"; db.purple=true; Apply()
        end)
        options.accent:SetPoint("TOPLEFT",22,-450)
        local compatibility=options:CreateFontString(nil,"OVERLAY","GameFontDisableSmall")
        compatibility:SetPoint("TOPLEFT",22,-620)
        compatibility:SetPoint("TOPRIGHT",-22,-620)
        compatibility:SetText("Disable minimap movement/styling in Leatrix Plus or MoveAny if enabled.")
        options.rotate=Check("Rotate minimap (native square)",-484,"rotate")
        options.headerBelow=Check("Zone header below map",-516,"headerBelow")
        options.iconText=options:CreateFontString(nil,"OVERLAY","GameFontHighlight")
        options.iconText:SetPoint("TOPLEFT",22,-558)
        options.iconScale=CreateFrame("Slider",nil,options,"OptionsSliderTemplate")
        options.iconScale:SetPoint("TOPLEFT",24,-587)
        options.iconScale:SetSize(340,18)
        options.iconScale:SetMinMaxValues(.5,2)
        options.iconScale:SetValueStep(.05)
        if options.iconScale.SetObeyStepOnDrag then options.iconScale:SetObeyStepOnDrag(true) end
        options.iconScale:SetScript("OnValueChanged",function(_,value)
            if options.refreshing then return end
            db.iconScale=math.max(.5,math.min(2,Number(value,1))); Apply()
        end)
        Tooltip(options.iconScale,"Native map icons","Scales supported quest/POI indicators, not terrain or addon buttons. Requires the client SetIconScale API.")
        Tooltip(sizeSlider,"Visible map size","Changes terrain width and height in UI units without scaling buttons or the player arrow.")
        Tooltip(options.rotate,"Rotation","Uses native map rotation with the standard square mask.")
        options.status = options:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        options.status:SetPoint("BOTTOMLEFT", 14, 14)
        options.status:SetPoint("BOTTOMRIGHT", -14, 14)
        UISpecialFrames[#UISpecialFrames+1] = "VoidMarkMiniMapOptions"
        options:Hide()
    end
    UpdateOptions()
    options:SetShown(not options:IsShown())
end

local function Initialize()
    if ready then Apply(); return end
    if InCombatLockdown() then pending = true; return end
    if not Minimap then return end
    -- Do not fight another addon for ownership of the same frame.
    if SexyMap or (ElvUI and ElvUI[1] and ElvUI[1].private and ElvUI[1].private.general
        and ElvUI[1].private.general.minimap) then
        Say("Disable the other minimap replacement and /reload to use this addon.")
        return
    end
    LoadSettings()
    if LeaPlusLC and LeaPlusLC.MinimapModder == "On" then
        Say("Turn off Leatrix Plus 'Enhance minimap', then /reload. Minimap styling paused to avoid a conflict.")
        return
    end
    if MoveAny and type(MoveAny.IsEnabled)=="function" then
        local ok,enabled=pcall(MoveAny.IsEnabled,MoveAny,"MINIMAP",false)
        if ok and enabled then
            Say("Turn off MoveAny minimap movement, then /reload. Minimap styling paused to avoid a conflict.")
            return
        end
    end
    repair=VoidMarkMiniMapRepair.New(db)
    repairPending=true
    holder = CreateFrame("Frame", "VoidMarkMiniMapFrame", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("BACKGROUND")
    holder:SetMovable(true)
    -- The holder is decorative: it must not consume hover events from map pins.
    holder:EnableMouse(false)
    holder:SetClampedToScreen(true)
    Backdrop(holder)
    Minimap:SetParent(holder)
    Minimap:SetFrameStrata("BACKGROUND")
    Minimap:SetScale(1)
    Minimap:EnableMouse(true)
    Minimap:SetFrameLevel(holder:GetFrameLevel()+2)
    mapViewport = CreateFrame("Frame",nil,holder)
    mapViewport:SetPoint("TOPLEFT",holder,"TOPLEFT",4,-(topHeight+2))
    mapViewport:SetSize(db.size,db.size)
    mapViewport:EnableMouse(false)
    -- ScrollFrame clips its scroll child independently of frame texture masking.
    _G.GetMinimapShape = function() return "SQUARE" end
    VM.hiddenChrome = CreateFrame("Frame", nil, UIParent)
    VM.hiddenChrome:Hide()
    SuppressNativeChrome()
    CreateMailButton()
    header = CreateFrame("Frame", nil, holder)
    header:SetPoint("TOPLEFT",mapViewport,"TOPLEFT",0,0)
    header:SetPoint("TOPRIGHT",mapViewport,"TOPRIGHT",0,0)
    header:SetFrameLevel(holder:GetFrameLevel()+5)
    header:SetHeight(22)
    header:RegisterForDrag("LeftButton")
    header:SetScript("OnDragStart", function()
        if not db.locked and not holder.resizing and not InCombatLockdown() then
            holder:StartMoving(); holder.dragging = true
        end
    end)
    local function StopMoving()
        if not holder.dragging then return end
        holder:StopMovingOrSizing()
        holder.dragging = false
        local x, y = holder:GetCenter()
        if x and y then
            db.point = "CENTER"
            db.x, db.y = x-UIParent:GetWidth()/2, y-UIParent:GetHeight()/2
        end
    end
    header:SetScript("OnDragStop", StopMoving)
    holder.stopMoving = StopMoving
    Tooltip(header, "VoidMark Mini Map", "Drag this bar to move the map. /vmini opens settings.")
    zone = header:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    zone:SetPoint("CENTER", header, "CENTER", 0, 0)
    StyleFooterText(zone)
    zone:SetTextColor(0.88,0.81,0.98)
    zone:SetWidth(130)
    zone:SetWordWrap(false)
    local gear = CreateFrame("Button",nil,holder)
    gear:SetSize(22,22)
    gear:SetFrameLevel(holder:GetFrameLevel()+7)
    local gearLabel=gear:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    gearLabel:SetPoint("CENTER",0,2)
    gearLabel:SetText("...")
    gearLabel:SetTextColor(0.7,0.6,0.85)
    gear:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square")
    gear:SetScript("OnClick",ToggleOptions)
    gear:SetPoint("RIGHT",header,"RIGHT",-2,0)
    Tooltip(gear, "VoidMark Mini Map", "Click to adjust map size, lock position, or reset.")
    footer=CreateFrame("Frame",nil,holder,"BackdropTemplate")
    footer:SetPoint("BOTTOMLEFT",holder,"BOTTOMLEFT",4,2)
    footer:SetPoint("BOTTOMRIGHT",holder,"BOTTOMRIGHT",-4,2)
    footer:SetHeight(bottomHeight)
    footer:SetBackdrop({bgFile="Interface\\Buttons\\WHITE8X8",edgeFile="Interface\\Buttons\\WHITE8X8",edgeSize=1})
    footer:SetBackdropBorderColor(.48,.20,.72,.8)
    footer:SetBackdropColor(0.015,0.012,0.025,.92)
    local divider=footer:CreateTexture(nil,"ARTWORK")
    divider:SetHeight(1)
    divider:SetPoint("TOPLEFT")
    divider:SetPoint("TOPRIGHT")
    divider:SetColorTexture(0.38,0.22,0.52,0.8)
    clock = footer:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clock:SetPoint("LEFT", footer, "LEFT", 9, 0)
    StyleFooterText(clock)
    coordinates=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    coordinates:SetPoint("CENTER", footer, "CENTER", 0, 0)
    StyleFooterText(coordinates)
    fpsText=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    fpsText:SetPoint("RIGHT",footer,"RIGHT",-9,0)
    StyleFooterText(fpsText)
    latencyText=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    StyleFooterText(latencyText)
    durabilityText=footer:CreateFontString(nil,"OVERLAY","GameFontHighlightSmall")
    StyleFooterText(durabilityText)
    repairHover=CreateFrame("Frame",nil,footer)
    repairHover:SetFrameLevel(footer:GetFrameLevel()+2)
    repairHover:EnableMouse(true)
    repairHover:SetScript("OnEnter",function(self)
        self.hovered=true;self.entering=true
        UpdateDurability()
        repair:Refresh(merchantOpen);repairPending=false
        ShowDurabilityTooltip();self.entering=false
    end)
    repairHover:SetScript("OnLeave",HideDurabilityTooltip)
    repairHover:SetScript("OnHide",HideDurabilityTooltip)
    local iconPaths={"Interface\\Icons\\INV_Misc_PocketWatch_01","Interface\\Icons\\INV_Misc_Map_01","Interface\\Icons\\INV_Shield_06"}
    for i=1,4 do
        if iconPaths[i] then
            local icon=footer:CreateTexture(nil,"ARTWORK")
            icon:SetSize(13,13);icon:SetTexture(iconPaths[i]);icon:SetTexCoord(.08,.92,.08,.92)
            footerIcons[i]=icon
        end
        local diamond=footer:CreateTexture(nil,"ARTWORK")
        diamond:SetSize(4,4);diamond:SetColorTexture(.65,.32,.92,.85)
        diamond:SetRotation(math.pi/4);diamond:Hide();footerSeparators[i]=diamond
    end
    -- A quiet inner highlight keeps the one-pixel border from looking flat.
    local glow=footer:CreateTexture(nil,"BACKGROUND")
    glow:SetPoint("TOPLEFT",1,-1);glow:SetPoint("TOPRIGHT",-1,-1);glow:SetHeight(3)
    glow:SetColorTexture(.40,.13,.65,.10)
    drawer=CreateFrame("Frame","VoidMarkMiniMapDrawer",UIParent,"BackdropTemplate")
    drawer:SetFrameStrata("DIALOG")
    drawer:SetClampedToScreen(true)
    drawer:SetPoint("TOPRIGHT",holder,"TOPRIGHT",0,-26)
    Backdrop(drawer)
    drawer:EnableMouse(true)
    drawer:Hide()
    UISpecialFrames[#UISpecialFrames+1]="VoidMarkMiniMapDrawer"
    drawerToggle=Button(holder,"Addons",68,function()
        if InCombatLockdown() then Say("Open the addon drawer after combat."); return end
        LayoutDrawer(); drawer:SetShown(not drawer:IsShown())
    end)
    drawerToggle:SetPoint("TOPRIGHT",-28,-3)
    drawerToggle:Hide()
    Tooltip(drawerToggle,"Addon buttons","Click to open or close. Escape closes the drawer. Hidden addon icons stay hidden.")
    grip = CreateFrame("Button", "VoidMarkMiniMapResize", holder)
    grip:SetSize(18, 18)
    grip:SetPoint("BOTTOMRIGHT", -3, 3)
    local gripText = grip:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    gripText:SetPoint("CENTER")
    gripText:SetText("//")
    Tooltip(grip, "Resize map", "Drag left or right to resize the square map.")
    grip:RegisterForDrag("LeftButton")
    grip:SetScript("OnDragStart", function()
        if db.locked or holder.dragging or InCombatLockdown() then return end
        local left, top = holder:GetLeft(), holder:GetTop()
        if not left or not top then return end
        db.point, db.x, db.y = "TOPLEFT", left, top-UIParent:GetHeight()
        Apply()
        holder.resizing = true
        holder.resizeCursor = GetCursorPosition()
        holder.resizeSize = db.size
    end)
    local function StopResizing()
        if not holder.resizing then return end
        holder.resizing = false
        Apply()
    end
    grip:SetScript("OnDragStop", StopResizing)
    grip:SetScript("OnHide", StopResizing)
    holder.stopResizing = StopResizing
    grip:SetScript("OnUpdate", function()
        if not holder.resizing then return end
        if InCombatLockdown() then StopResizing(); return end
        local x = GetCursorPosition()
        local value = Size(holder.resizeSize+(x-holder.resizeCursor)/holder:GetEffectiveScale())
        if value ~= db.size then db.size = value; Apply() end
    end)
    Minimap:EnableMouseWheel(true)
    Minimap:SetScript("OnMouseWheel", function(self, delta)
        local zoom = self:GetZoom() + (delta > 0 and 1 or -1)
        self:SetZoom(math.max(0, math.min(self:GetZoomLevels()-1, zoom)))
    end)
    if EditModeManagerFrame and EditModeManagerFrame.HookScript then
        EditModeManagerFrame:HookScript("OnHide",function()
            if ready and not InCombatLockdown() then Apply() end
        end)
    end
    InstallOwnershipHooks()
    ready = true
    Apply()
    Say("Loaded. /vmini opens settings.")
end

SLASH_VOIDMARKMINIMAP1 = "/vmini"
SLASH_VOIDMARKMINIMAP2 = "/voidmarkminimap"
-- Market owns /vmm when both addons load; OptionalDeps establishes that order.
if not _G.VoidMarkMarket then SLASH_VOIDMARKMINIMAP3 = "/vmm" end
SlashCmdList.VOIDMARKMINIMAP = function(message)
    if not ready then ToggleOptions(); return end
    local command, value = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "lock" or command == "unlock" then
        db.locked = command == "lock"; Apply()
        Say(db.locked and "Position locked." or "Drag the zone bar to move the map.")
    elseif command == "size" then
        if not tonumber(value) then Say("Usage: /vmini size 300 (180-600)"); return end
        db.size = Size(value); Apply()
    elseif command == "reset" then Reset()
    elseif command == "" then ToggleOptions()
    else Say("/vmini | /vmini unlock | /vmini lock | /vmini size 350 | /vmini reset") end
    if pending then Say("Layout will update after combat.") end
end

for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
    "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "ADDON_LOADED",
    "UPDATE_PENDING_MAIL", "MAIL_INBOX_UPDATE", "MAIL_SHOW", "MAIL_CLOSED", "CVAR_UPDATE",
    "PLAYER_EQUIPMENT_CHANGED", "UPDATE_INVENTORY_DURABILITY", "MERCHANT_CLOSED", "MERCHANT_SHOW", "MERCHANT_UPDATE", "PLAYER_DEAD", "PLAYER_UNGHOST"}) do VM:RegisterEvent(event) end
VM:SetScript("OnEvent", function(_, event, name)
    if event=="CVAR_UPDATE" then
        if name=="rotateMinimap" then layoutDirty=true end
    elseif event == "UPDATE_PENDING_MAIL" or event == "MAIL_INBOX_UPDATE" or event=="MAIL_SHOW" or event=="MAIL_CLOSED" then
        UpdateMail()
    elseif event == "MERCHANT_SHOW" then
        merchantOpen=true;repairPending=true
        -- Capture the opening quote promptly, without intercepting auto-repair addons.
        if ready and repair then
            repair:Refresh(true);repairPending=false
            if repairHover and repairHover.hovered then ShowDurabilityTooltip() end
        end
    elseif event == "MERCHANT_UPDATE" then if merchantOpen then repairPending=true end
    elseif event == "PLAYER_EQUIPMENT_CHANGED" or event == "UPDATE_INVENTORY_DURABILITY"
        or event == "PLAYER_DEAD" or event == "PLAYER_UNGHOST" or event == "MERCHANT_CLOSED" then
        if event=="MERCHANT_CLOSED" then merchantOpen=false end
        repairPending=true
        if ready then UpdateDurability() end
    elseif event == "PLAYER_LOGIN" then Initialize(); UpdateMail()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if holder then holder.stopMoving(); holder.stopResizing() end
    elseif event == "PLAYER_REGEN_ENABLED" and pending then Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED"
        or event == "ADDON_LOADED" then
        if ready then Apply(); UpdateMail(); repairPending=true end
    else UpdateLabels() end
end)
local discoverySignature
local elapsed, coordinateElapsed, drawerElapsed, fpsElapsed, durabilityElapsed, latencyElapsed = 0,0,0,0,0,0
VM:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 1 then elapsed = 0; UpdateLabels() end
    if not ready then return end
    if not InCombatLockdown() and not InEditMode() then
        if layoutDirty then Apply() end
        if rimDirty then RefreshRim() end
    elseif layoutDirty or rimDirty then pending=true end
    if repairPending and repair then
        repairPending=false
        repair:Refresh(merchantOpen)
        if repairHover and repairHover.hovered then ShowDurabilityTooltip() end
    end
    durabilityElapsed=durabilityElapsed+delta
    if durabilityElapsed>=5 then durabilityElapsed=0; if db.durability then UpdateDurability() end end
    latencyElapsed=latencyElapsed+delta
    if latencyElapsed>=5 then latencyElapsed=0; if db.latency then UpdateLatency() end end
    fpsElapsed=fpsElapsed+delta
    if fpsElapsed>=0.25 then fpsElapsed=0; UpdateFPS() end
    coordinateElapsed=coordinateElapsed+delta
    drawerElapsed=drawerElapsed+delta
    if coordinateElapsed>=0.5 then coordinateElapsed=0; UpdateCoordinates() end
    if drawerElapsed>=2 then
        drawerElapsed=0
        if InCombatLockdown() or InEditMode() then pending=true
        else
            SuppressNativeChrome()
            CollectControls()
            local signature={tostring(db.drawer),tostring(#controls),tostring(_G.VoidMarkNexusMinimap),
                tostring(_G.VoidMarkMinimapButton),tostring(_G.VoidMarkMarketMinimapButton)}
            local lib=LibStub and LibStub("LibDBIcon-1.0",true)
            if lib and lib.GetButtonList and lib.GetMinimapButton then
                local names=lib:GetButtonList();table.sort(names)
                for _,name in ipairs(names) do signature[#signature+1]=name..tostring(lib:GetMinimapButton(name)) end
            end
            local key=table.concat(signature,"|")
            if key~=discoverySignature then discoverySignature=key;RefreshRim() end
            if _G.TaliaaFPSFrame~=embeddedFPS then LayoutFPS() end
        end
    end
    if coordinateElapsed==0 then SuppressNativeCoordinates() end
end)
