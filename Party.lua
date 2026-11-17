-- Party markers: a big class-colored dot with the first letter of each party
-- member's name, drawn above quest icons. Anyone off the map (same zone or a
-- zone next to you) gets the dot pinned to the map edge with an arrow pointing
-- at them and the distance in yards.
local P = {}
_G.VoidMarkMiniMapParty = P

local SIZES = { small = 10, medium = 13, large = 17 }
local NEXT_SIZE = { small = "medium", medium = "large", large = "small" }
-- Yards shown across the full minimap width per zoom level (same as HereBeDragons).
local OUTDOOR = { [0] = 466 + 2 / 3, 400, 333 + 1 / 3, 266 + 2 / 3, 200, 133 + 1 / 3 }
local INDOOR = { [0] = 300, 240, 180, 120, 80, 50 }
local CIRCLE = "Interface\\CHARACTERFRAME\\TempPortraitAlphaMask"
local WHITE = "Interface\\Buttons\\WHITE8X8"

local layer, pins = nil, {}
local mapSizeCache = {}

local function Readable(v)
    if type(issecretvalue) == "function" then
        local ok, secret = pcall(issecretvalue, v)
        if not ok or secret then return nil end
    end
    return v
end
local function Call(fn, ...)
    if type(fn) ~= "function" then return nil end
    local r = { pcall(fn, ...) }
    if not r[1] then return nil end
    for i = 2, #r do r[i] = Readable(r[i]) end
    return unpack(r, 2, table.maxn(r))
end
local function Settings()
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" then return nil end
    if type(db.party) ~= "boolean" then db.party = true end
    if not SIZES[db.partySize] then db.partySize = "medium" end
    if type(db.selfArrow) ~= "boolean" then db.selfArrow = true end
    return db
end

-- Yards across the map width at the current zoom.
function P.Span(zoom, indoors)
    local t = indoors and INDOOR or OUTDOOR
    zoom = math.max(0, math.min(5, math.floor(tonumber(zoom) or 0)))
    return t[zoom]
end

-- Where a marker goes. dx/dy in yards (east/north of you), half = half the map
-- width in pixels, inset = keep this far from the edge.
-- Returns x, y (pixels from center), onMap, angle (radians, 0 = east).
function P.Place(dx, dy, yardsPerPixel, half, inset)
    local px, py = dx / yardsPerPixel, dy / yardsPerPixel
    local limit = math.max(1, half - inset)
    local far = math.max(math.abs(px), math.abs(py))
    local angle = math.atan2(py, px)
    if far <= limit then return px, py, true, angle end
    local t = limit / far
    return px * t, py * t, false, angle
end

---------------------------------------------------------------------------
-- Positions
---------------------------------------------------------------------------
local function XY(pos)
    if type(pos) ~= "table" then return nil end
    local x, y
    if pos.GetXY then x, y = Call(pos.GetXY, pos) else x, y = Readable(pos.x), Readable(pos.y) end
    x, y = tonumber(x), tonumber(y)
    if x and y and x == x and y == y then return x, y end
end

-- Width and height of a zone map in yards (zone maps are 3:2, wider than tall).
local function MapYards(map)
    if mapSizeCache[map] then return mapSizeCache[map][1], mapSizeCache[map][2] end
    if not (C_Map and C_Map.GetWorldPosFromMapPos and CreateVector2D) then return nil end
    local _, a = Call(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(0, 0))
    local _, b = Call(C_Map.GetWorldPosFromMapPos, map, CreateVector2D(1, 1))
    local ax, ay = XY(a); local bx, by = XY(b)
    if not ax or not bx then return nil end
    local s1, s2 = math.abs(ax - bx), math.abs(ay - by)
    local w, h = math.max(s1, s2), math.min(s1, s2)
    if w <= 0 or h <= 0 then return nil end
    mapSizeCache[map] = { w, h }
    return w, h
end

-- A unit's position on the player's zone map (may be outside 0-1 when they are
-- in the next zone over).
local function OnMap(map, unit)
    local x, y = XY(Call(C_Map.GetPlayerMapPosition, map, unit))
    if x then return x, y end
    -- Not on this map: find them on their own map and project into ours.
    local theirs = Call(C_Map.GetBestMapForUnit, unit)
    if not theirs or not C_Map.GetWorldPosFromMapPos or not C_Map.GetMapPosFromWorldPos then return nil end
    local pos = Call(C_Map.GetPlayerMapPosition, theirs, unit)
    if not XY(pos) then return nil end
    local continent, world = Call(C_Map.GetWorldPosFromMapPos, theirs, pos)
    if not continent or not world then return nil end
    local _, mine = Call(C_Map.GetMapPosFromWorldPos, continent, world, map)
    return XY(mine)
end

-- Yards east (dx) and north (dy) of the player, or nil if unknown.
function P.Offset(unit)
    if C_Map and C_Map.GetBestMapForUnit and C_Map.GetPlayerMapPosition then
        local map = Call(C_Map.GetBestMapForUnit, "player")
        local w, h
        if map then w, h = MapYards(map) end
        if w then
            local mx, my = OnMap(map, "player")
            local ux, uy = OnMap(map, unit)
            if mx and ux then return (ux - mx) * w, -(uy - my) * h end
        end
    end
    -- Fallback: world coordinates (first value grows west, second grows north).
    local pw, pn, _, pi = Call(UnitPosition, "player")
    local uw, un, _, ui = Call(UnitPosition, unit)
    if pw and pn and uw and un and pi == ui then return -(uw - pw), un - pn end
end

---------------------------------------------------------------------------
-- Drawing
---------------------------------------------------------------------------
local function Round(parent, layerName, sub)
    local t = parent:CreateTexture(nil, layerName, nil, sub)
    t:SetTexture(WHITE)
    if parent.CreateMaskTexture then
        local mask = parent:CreateMaskTexture()
        mask:SetTexture(CIRCLE, "CLAMPTOBLACKADDITIVE", "CLAMPTOBLACKADDITIVE")
        mask:SetAllPoints(t)
        t:AddMaskTexture(mask)
    end
    return t
end

local function NewPin()
    local pin = CreateFrame("Frame", nil, layer)
    pin:EnableMouse(false)
    pin.Ring = Round(pin, "ARTWORK", 1); pin.Ring:SetPoint("CENTER")
    pin.Ring:SetVertexColor(0, 0, 0, 1)
    pin.Dot = Round(pin, "ARTWORK", 2); pin.Dot:SetPoint("CENTER")
    pin.Letter = pin:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    pin.Letter:SetPoint("CENTER", 0, 0)
    pin.Letter:SetTextColor(0.05, 0.05, 0.05)
    pin.Arrow = pin:CreateTexture(nil, "OVERLAY")
    pin.Arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    pin.Distance = pin:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    if pin.Distance.SetShadowOffset then pin.Distance:SetShadowOffset(1, -1) end
    return pin
end

local function ClassColor(unit)
    local _, class = Call(UnitClass, unit)
    local c = class and ((C_ClassColor and C_ClassColor.GetClassColor and Call(C_ClassColor.GetClassColor, class))
        or (RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]))
    if type(c) == "table" and c.r then return c.r, c.g, c.b end
    return 0.4, 0.75, 1
end

local function FirstLetter(unit)
    local name = Call(UnitName, unit)
    if type(name) ~= "string" or name == "" then return "?" end
    return (name:match("^[%z\1-\127\194-\244][\128-\191]*") or "?"):upper()
end

local function Units()
    local list = {}
    local raid = Call(IsInRaid)
    local count = tonumber(Call(GetNumGroupMembers)) or 0
    if raid then
        for i = 1, math.min(40, count) do
            local u = "raid" .. i
            if not Call(UnitIsUnit, u, "player") then list[#list + 1] = u end
        end
    else
        for i = 1, 4 do list[#list + 1] = "party" .. i end
    end
    return list
end

local function Draw(pin, unit, size, half, ypp)
    if not Call(UnitExists, unit) or Call(UnitIsConnected, unit) == false then return false end
    local dx, dy = P.Offset(unit)
    if not dx then return false end
    local x, y, onMap, angle = P.Place(dx, dy, ypp, half, size / 2 + 3)
    local r, g, b = ClassColor(unit)
    pin:SetSize(size + 4, size + 4)
    pin.Ring:SetSize(size + 4, size + 4)
    pin.Dot:SetSize(size, size); pin.Dot:SetVertexColor(r, g, b, 1)
    local path, _, flags = pin.Letter:GetFont()
    if path then pin.Letter:SetFont(path, math.max(8, math.floor(size * 0.65)), flags) end
    pin.Letter:SetText(FirstLetter(unit))
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", layer, "CENTER", x, y)
    if onMap then
        pin.Arrow:Hide(); pin.Distance:Hide()
    else
        -- Arrow sits just past the dot, pointing at them.
        local a = size * 0.9
        pin.Arrow:SetSize(size * 1.1, size * 1.1)
        pin.Arrow:ClearAllPoints()
        pin.Arrow:SetPoint("CENTER", pin, "CENTER", math.cos(angle) * a, math.sin(angle) * a)
        if pin.Arrow.SetRotation then pin.Arrow:SetRotation(angle - math.pi / 2) end
        pin.Arrow:SetVertexColor(r, g, b, 1)
        pin.Arrow:Show()
        local yards = math.floor(math.sqrt(dx * dx + dy * dy) + 0.5)
        pin.Distance:SetText(yards .. " yd")
        pin.Distance:ClearAllPoints()
        -- Distance goes on the map side of the dot.
        local back = size * 0.5 + 16
        pin.Distance:SetPoint("CENTER", pin, "CENTER", -math.cos(angle) * back, -math.sin(angle) * back)
        pin.Distance:Show()
    end
    pin:Show()
    return true
end

---------------------------------------------------------------------------
-- Your own arrow, drawn on top of quest icons (the native one sits under them)
---------------------------------------------------------------------------
local me
local function BuildMe()
    me = CreateFrame("Frame", nil, layer)
    me:SetSize(26, 26)
    me:SetPoint("CENTER", layer, "CENTER", 0, 0)
    me:SetFrameLevel((layer.GetFrameLevel and layer:GetFrameLevel() or 0) + 20)
    me:EnableMouse(false)
    -- Black copy slightly larger behind = outline.
    me.Outline = me:CreateTexture(nil, "ARTWORK", nil, 1)
    me.Outline:SetTexture("Interface\\Minimap\\MinimapArrow")
    me.Outline:SetSize(30, 30); me.Outline:SetPoint("CENTER")
    me.Outline:SetVertexColor(0, 0, 0, 1)
    me.Arrow = me:CreateTexture(nil, "ARTWORK", nil, 2)
    me.Arrow:SetTexture("Interface\\Minimap\\MinimapArrow")
    me.Arrow:SetSize(26, 26); me.Arrow:SetPoint("CENTER")
    -- If Forever hides your facing, a ring marks where you are instead.
    me.Ring = Round(me, "ARTWORK", 0)
    me.Ring:SetSize(14, 14); me.Ring:SetPoint("CENTER")
    me.Ring:SetVertexColor(1, 1, 1, 1)
    me.Ring:Hide()
end

function P.UpdateMe()
    local db = Settings()
    if not layer then return end
    if not (db and db.selfArrow) then if me then me:Hide() end; return end
    if not me then BuildMe() end
    local facing = tonumber((Call(GetPlayerFacing)))
    if facing and facing == facing then
        if me.Arrow.SetRotation then me.Arrow:SetRotation(facing); me.Outline:SetRotation(facing) end
        me.Arrow:Show(); me.Outline:Show(); me.Ring:Hide()
    else
        me.Arrow:Hide(); me.Outline:Hide(); me.Ring:Show()
    end
    me:Show()
    P.facing = facing
end

function P.Update()
    local db = Settings()
    local viewport = _G.VoidMarkMiniMapMapViewport
    if not viewport then return end
    if not layer then
        layer = CreateFrame("Frame", "VoidMarkMiniMapPartyLayer", viewport)
        layer:SetAllPoints(viewport)
        layer:SetFrameStrata("LOW")   -- above the map and quest objective icons
        layer:EnableMouse(false)
    end
    local used = 0
    if db and db.party and Call(IsInGroup) and Minimap then
        local width = viewport:GetWidth()
        local span = P.Span(Call(Minimap.GetZoom, Minimap), Call(IsIndoors))
        if width and width > 0 and span then
            local size = SIZES[db.partySize]
            for _, unit in ipairs(Units()) do
                used = used + 1
                pins[used] = pins[used] or NewPin()
                if not Draw(pins[used], unit, size, width / 2, span / width) then
                    pins[used]:Hide(); used = used - 1
                end
            end
        end
    end
    for i = used + 1, #pins do pins[i]:Hide() end
    P.shown = used
    P.UpdateMe()
end

function P.CycleSize()
    local db = Settings()
    if not db then return end
    db.partySize = NEXT_SIZE[db.partySize] or "medium"
    P.Update()
    return db.partySize
end

local driver = CreateFrame("Frame")
for _, ev in ipairs({ "PLAYER_LOGIN", "GROUP_ROSTER_UPDATE", "PLAYER_ENTERING_WORLD", "ZONE_CHANGED_NEW_AREA" }) do
    pcall(driver.RegisterEvent, driver, ev)
end
local elapsed = 0
driver:SetScript("OnEvent", function(_, event)
    if event == "ZONE_CHANGED_NEW_AREA" then mapSizeCache = {} end
    P.Update()
end)
-- 10 updates a second while grouped; nothing at all when solo.
driver:SetScript("OnUpdate", function(_, delta)
    -- Your arrow turns every frame so it never lags behind the camera.
    if me and me:IsShown() then P.UpdateMe() end
    elapsed = elapsed + delta
    if elapsed < 0.1 then return end
    elapsed = 0
    if (P.shown or 0) > 0 or Call(IsInGroup) then P.Update() end
end)
