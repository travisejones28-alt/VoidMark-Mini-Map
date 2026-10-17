local addonName = ...
local VM = CreateFrame("Frame")
local db, holder, header, zone, clock, options, sizeSlider, lockButton, grip, dock
local ready, pending, applying = false, false, false
local controls, seenControls = {}, {}
local defaults = { size = 300, locked = true, clock = true, purple = true,
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
    local reservedHeight = 72 + math.ceil(#controls/6)*30
    local maximum = math.max(180, math.min(600, UIParent:GetWidth()-80, UIParent:GetHeight()-reservedHeight))
    return math.floor(math.max(180, math.min(maximum, Number(value, 300))) + 0.5)
end

local function LoadSettings()
    if type(VoidMarkMiniMapDB) ~= "table" then VoidMarkMiniMapDB = {} end
    db = VoidMarkMiniMapDB
    for key, value in pairs(defaults) do
        if type(db[key]) ~= type(value) then db[key] = value end
    end
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

local function CollectControls()
    local function Add(control)
        if not control or seenControls[control] then return end
        seenControls[control] = true
        controls[#controls+1] = control
        control:SetParent(dock)
        -- Keep native scripts and show/hide rules; fit each control to one dock slot.
        local dimension = math.max(control:GetWidth(), control:GetHeight(), 1)
        control:SetScale(math.min(1, 24 / dimension))
        control:SetFrameLevel(Minimap:GetFrameLevel()+5)
    end
    Add(MiniMapTracking)
    Add(MiniMapMailFrame)
    Add(GameTimeFrame)
    Add(QueueStatusMinimapButton)
    Add(QueueStatusButton)
    Add(MiniMapBattlefieldFrame)
    if MinimapCluster then
        Add(MinimapCluster.Tracking)
        Add(MinimapCluster.MailFrame)
        Add(MinimapCluster.InstanceDifficulty)
    end
end

local function LayoutControls()
    CollectControls()
    db.size = Size(db.size)
    local columns = math.max(1, math.floor(db.size / 30))
    local rows = math.ceil(#controls / columns)
    local dockHeight = rows * 30
    dock:SetHeight(math.max(1, dockHeight))
    for index, control in ipairs(controls) do
        local slot = index-1
        local scale = control:GetScale()
        control:ClearAllPoints()
        control:SetPoint("CENTER", dock, "TOPLEFT", (15+(slot%columns)*30)/scale,
            (-15-math.floor(slot/columns)*30)/scale)
    end
    holder:SetSize(db.size+8, db.size+52+dockHeight)
end

local function UpdateLabels()
    if not ready then return end
    zone:SetText(GetMinimapZoneText() or "")
    if db.clock then
        local hour, minute = GetGameTime()
        clock:SetText(string.format("%02d:%02d", hour, minute))
        clock:Show()
    else clock:Hide() end
end

local function UpdateOptions()
    if not options then return end
    options.refreshing = true
    sizeSlider:SetValue(db.size)
    options.sizeText:SetText("Map size: " .. db.size)
    lockButton:SetText(db.locked and "Unlock position" or "Lock position")
    options.clock:SetChecked(db.clock)
    options.purple:SetChecked(db.purple)
    options.status:SetText(pending and "Changes queued until combat ends." or
        (db.locked and "Position and resize handle locked." or "Drag the zone bar or bottom-right resize handle."))
    options.refreshing = false
end

local function Apply()
    if not ready then return end
    if InCombatLockdown() then pending = true; UpdateOptions(); return end
    if applying then return end
    applying = true
    db.size = Size(db.size)
    LayoutControls()
    holder:ClearAllPoints()
    holder:SetPoint(db.point, UIParent, db.point, db.x, db.y)
    Minimap:ClearAllPoints()
    Minimap:SetPoint("TOPLEFT", holder, "TOPLEFT", 4, -26)
    Minimap:SetSize(db.size, db.size)
    Minimap:SetMaskTexture("Interface\\Buttons\\WHITE8X8")
    if db.purple then holder:SetBackdropBorderColor(0.55, 0.25, 0.85, 1)
    else holder:SetBackdropBorderColor(0.2, 0.2, 0.2, 1) end
    header:EnableMouse(not db.locked)
    grip:SetShown(not db.locked)
    local lib = LibStub and LibStub("LibDBIcon-1.0", true)
    if lib and lib.GetButtonList and lib.Refresh then
        for _, name in ipairs(lib:GetButtonList()) do lib:Refresh(name) end
    end
    pending, applying = false, false
    UpdateLabels()
    UpdateOptions()
end

local function Reset()
    for key, value in pairs(defaults) do db[key] = value end
    Apply()
end

local function ToggleOptions()
    if not ready then Say("Minimap is unavailable or another minimap replacement is active."); return end
    if not options then
        options = CreateFrame("Frame", "VoidMarkMiniMapOptions", UIParent, "BackdropTemplate")
        options:SetSize(390, 280)
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
        options.purple = Check("Purple border", -185, "purple")
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
    holder = CreateFrame("Frame", "VoidMarkMiniMapFrame", UIParent, "BackdropTemplate")
    holder:SetFrameStrata("LOW")
    holder:SetMovable(true)
    holder:SetClampedToScreen(true)
    Backdrop(holder)
    Minimap:SetParent(holder)
    Minimap:SetScale(1)
    Minimap:SetFrameLevel(holder:GetFrameLevel()+2)
    dock = CreateFrame("Frame", nil, holder)
    dock:SetPoint("TOPLEFT", Minimap, "BOTTOMLEFT", 0, -2)
    dock:SetPoint("TOPRIGHT", Minimap, "BOTTOMRIGHT", 0, -2)
    _G.GetMinimapShape = function() return "SQUARE" end
    for _, name in ipairs({"MinimapBorder", "MinimapBorderTop", "MinimapBackdrop",
        "MinimapZoneTextButton", "MinimapZoomIn", "MinimapZoomOut"}) do
        local object = _G[name]
        if object then
            object:Hide()
            if object.HookScript then object:HookScript("OnShow", function(self) self:Hide() end) end
        end
    end
    header = CreateFrame("Frame", nil, holder)
    header:SetPoint("TOPLEFT", 4, -3)
    header:SetPoint("TOPRIGHT", -30, -3)
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
    Tooltip(header, "VoidMark Mini Map", "Drag this bar to move the map. /vmm opens settings.")
    zone = header:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    zone:SetPoint("LEFT", 5, 0)
    zone:SetPoint("RIGHT", -5, 0)
    zone:SetWordWrap(false)
    local gear = Button(holder, "*", 24, ToggleOptions)
    gear:SetPoint("TOPRIGHT", -3, -3)
    Tooltip(gear, "VoidMark Mini Map", "Click to adjust map size, lock position, or reset.")
    clock = holder:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    clock:SetPoint("BOTTOMLEFT", 8, 8)
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
    ready = true
    Apply()
    Say("Loaded. /vmm opens settings.")
end

SLASH_VOIDMARKMINIMAP1 = "/vmm"
SLASH_VOIDMARKMINIMAP2 = "/voidmarkminimap"
SlashCmdList.VOIDMARKMINIMAP = function(message)
    if not ready then ToggleOptions(); return end
    local command, value = (message or ""):match("^%s*(%S*)%s*(.-)%s*$")
    command = command:lower()
    if command == "lock" or command == "unlock" then
        db.locked = command == "lock"; Apply()
        Say(db.locked and "Position locked." or "Drag the zone bar to move the map.")
    elseif command == "size" then
        if not tonumber(value) then Say("Usage: /vmm size 300 (180-600)"); return end
        db.size = Size(value); Apply()
    elseif command == "reset" then Reset()
    elseif command == "" then ToggleOptions()
    else Say("/vmm | /vmm unlock | /vmm lock | /vmm size 350 | /vmm reset") end
    if pending then Say("Layout will update after combat.") end
end

for _, event in ipairs({"PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "PLAYER_REGEN_ENABLED",
    "PLAYER_REGEN_DISABLED", "ZONE_CHANGED", "ZONE_CHANGED_INDOORS", "ZONE_CHANGED_NEW_AREA",
    "DISPLAY_SIZE_CHANGED", "UI_SCALE_CHANGED", "ADDON_LOADED"}) do VM:RegisterEvent(event) end
VM:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_LOGIN" then Initialize()
    elseif event == "PLAYER_REGEN_DISABLED" then
        if holder then holder.stopMoving(); holder.stopResizing() end
    elseif event == "PLAYER_REGEN_ENABLED" and pending then Initialize()
    elseif event == "PLAYER_ENTERING_WORLD" or event == "DISPLAY_SIZE_CHANGED" or event == "UI_SCALE_CHANGED"
        or event == "ADDON_LOADED" then
        if ready then Apply() end
    else UpdateLabels() end
end)
local elapsed = 0
VM:SetScript("OnUpdate", function(_, delta)
    elapsed = elapsed + delta
    if elapsed >= 10 then elapsed = 0; UpdateLabels() end
end)
