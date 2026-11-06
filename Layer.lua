-- Experimental layer indicator for WoW Forever.
-- Reads zone instance IDs from visible creature GUIDs. These are NOT official
-- realm-wide layer numbers; modern client GUID obfuscation may prevent detection.
local addonName = ...
local frame = CreateFrame("Frame")
local textLabel, overlay
local current, candidate, observedAt
local seconds = 0
local TTL = 120
local diagnostics = { calls = 0, readable = 0, secret = 0, malformed = 0, creatures = 0, last = nil }
local function isSecret(v)
    if type(issecretvalue) == "function" then
        local ok, result = pcall(issecretvalue, v)
        return not ok or result
    end
    return false
end
local function Parse(guid)
    if isSecret(guid) then diagnostics.secret = diagnostics.secret + 1; return end
    if type(guid) ~= "string" then return end
    diagnostics.readable = diagnostics.readable + 1
    local kind, zero, server, map, zone, npc, spawn = strsplit("-", guid)
    if kind ~= "Creature" and kind ~= "Vehicle" then return end
    if not (tonumber(server) and tonumber(map) and tonumber(zone) and tonumber(npc) and spawn and spawn ~= "") then
        diagnostics.malformed = diagnostics.malformed + 1
        return
    end
    diagnostics.creatures = diagnostics.creatures + 1
    diagnostics.last = server .. "-" .. map .. "-" .. zone
    local key = diagnostics.last
    return key, zone, spawn
end
local function UpdateLabel()
    if not textLabel then return end
    local db = VoidMarkMiniMapDB
    local show = type(db) == "table" and db.layer ~= false
    textLabel:SetShown(show)
    if not show then return end
    textLabel:SetText(current and ("[Layer " .. current.zone .. "]") or "[Layer ?]")
    if current then textLabel:SetTextColor(0.72, 0.96, 0.72)
    else textLabel:SetTextColor(0.85, 0.78, 0.95) end
end
local function Observe(unit, now)
    local ok, guid = pcall(UnitGUID, unit)
    if not ok then diagnostics.secret = diagnostics.secret + 1; return end
    diagnostics.calls = diagnostics.calls + 1
    local key, zone, spawn = Parse(guid)
    if not key then return end
    if current and current.key == key then observedAt = now; candidate = nil; return end
    if not candidate or candidate.key ~= key or now - candidate.first > 60 then
        candidate = { key = key, zone = zone, first = now, spawns = {}, count = 0 }
    end
    if not candidate.spawns[spawn] then
        candidate.spawns[spawn] = true
        candidate.count = candidate.count + 1
    end
    if candidate.count >= 2 then
        current = { key = key, zone = zone }
        candidate = nil
        observedAt = now
        UpdateLabel()
    end
end
_G.VoidMarkMiniMapLayerRefresh = UpdateLabel
local function Attach()
    if textLabel then return end
    local parent = _G.VoidMarkMiniMapFrame
    if not parent then return end
    -- The minimap renders above holder-owned FontStrings. Use an independent
    -- high-strata, mouse-transparent frame so the label stays visible.
    overlay = CreateFrame("Frame", nil, parent)
    overlay:SetFrameStrata("HIGH")
    overlay:SetFrameLevel(parent:GetFrameLevel() + 20)
    overlay:SetSize(125, 20)
    -- Bottom left of the terrain, above the 32px footer and away from the corner border.
    overlay:SetPoint("BOTTOMLEFT", parent, "BOTTOMLEFT", 11, 43)
    overlay:EnableMouse(false)
    textLabel = overlay:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    textLabel:SetPoint("LEFT", overlay, "LEFT", 0, 0)
    local font = textLabel:GetFont()
    if font then textLabel:SetFont(font, 11, "OUTLINE") end
    textLabel:SetShadowColor(0, 0, 0, 1)
    textLabel:SetShadowOffset(1, -1)
    UpdateLabel()
end
local function Reset()
    current, candidate, observedAt = nil, nil, nil
    UpdateLabel()
end
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("PLAYER_LOGIN")
frame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_ENTERING_WORLD" then Reset() end
    Attach()
end)
frame:SetScript("OnUpdate", function(_, dt)
    seconds = seconds + dt
    if seconds < 3 then return end
    seconds = 0
    Attach()
    if not textLabel then return end
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" or db.layer == false then UpdateLabel(); return end
    local now = GetTime()
    if observedAt and now - observedAt > TTL then Reset() end
    Observe("target", now)
    Observe("mouseover", now)
    Observe("focus", now)
    -- Nameplate tokens only; no world-object or combat-log scans.
    for i = 1, 40 do Observe("nameplate" .. i, now) end
    UpdateLabel()
end)
SLASH_VOIDMARKLAYER1 = "/vmlayer"
SlashCmdList.VOIDMARKLAYER = function(msg)
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" then print("VoidMark Mini Map is not initialized."); return end
    local cmd = (msg or ""):match("^%s*(%S*)")
    cmd = cmd and cmd:lower() or ""
    if cmd == "on" then db.layer = true
    elseif cmd == "off" then db.layer = false
    elseif cmd == "reset" then Reset()
    elseif cmd == "debug" then
        print("VoidMark layer:", current and current.key or "unknown",
            "candidate:", candidate and (candidate.key .. " (" .. candidate.count .. "/2)") or "none")
        print("VoidMark GUID checks:", diagnostics.calls,
            "readable:", diagnostics.readable, "creatures:", diagnostics.creatures,
            "secret/errors:", diagnostics.secret, "malformed:", diagnostics.malformed)
        print("VoidMark last creature instance:", diagnostics.last or "none",
            "(not an official layer number)")
        return
    else
        print("VoidMark layer: /vmlayer on | off | reset | debug")
        return
    end
    UpdateLabel()
end
