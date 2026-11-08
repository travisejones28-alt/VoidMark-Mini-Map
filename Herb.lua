-- Herbalism difficulty box: a small panel on the left of the minimap that shows
-- which herbs are red / orange / yellow / green / grey for the current skill.
-- Event driven only (skill changes, login); no polling once attached.
local HERBS = {
    { "Peacebloom", 1 }, { "Silverleaf", 1 }, { "Earthroot", 15 },
    { "Mageroyal", 50 }, { "Briarthorn", 70 }, { "Stranglekelp", 85 },
    { "Bruiseweed", 100 }, { "Wild Steelbloom", 115 }, { "Grave Moss", 120 },
    { "Kingsblood", 125 }, { "Liferoot", 150 }, { "Fadeleaf", 160 },
    { "Goldthorn", 170 }, { "Khadgar's Whisker", 185 }, { "Wintersbite", 195 },
    { "Firebloom", 205 }, { "Purple Lotus", 210 }, { "Arthas' Tears", 220 },
    { "Sungrass", 230 }, { "Blindweed", 235 }, { "Ghost Mushroom", 245 },
    { "Gromsblood", 250 }, { "Golden Sansam", 260 }, { "Dreamfoil", 270 },
    { "Mountain Silversage", 280 }, { "Plaguebloom", 285 }, { "Icecap", 290 },
    { "Black Lotus", 300 },
}
local BANDS = { "red", "orange", "yellow", "green", "grey" }
local COLORS = {
    red = { 1, 0.13, 0.13 }, orange = { 1, 0.5, 0.25 }, yellow = { 1, 1, 0 },
    green = { 0.25, 0.75, 0.25 }, grey = { 0.55, 0.55, 0.55 },
}
local ACCENTS = { purple = { 0.55, 0.25, 0.85 }, cyan = { 0.1, 0.75, 0.85 }, amber = { 0.9, 0.6, 0.15 } }
local SKILL_NAMES = { Herbalism = true, ["Kräuterkunde"] = true, ["Herboristería"] = true,
    ["Herboristerie"] = true, ["Erbalismo"] = true, ["Herborismo"] = true,
    ["Травничество"] = true, ["약초채집"] = true, ["草药学"] = true, ["草藥學"] = true }

-- Classic gathering colors: orange until req+25, yellow until +50, green until +100.
local function Band(skill, req)
    if skill < req then return "red" end
    if skill < req + 25 then return "orange" end
    if skill < req + 50 then return "yellow" end
    if skill < req + 100 then return "green" end
    return "grey"
end


local HERB_LINE = 182 -- Herbalism skill line ID
local function IsHerb(id, name) return id == HERB_LINE or SKILL_NAMES[name] end
-- Forever: GetProfessions/GetProfessionInfo and C_SkillInfo; legacy skill list last.
local function ReadSkill()
    if type(GetProfessions) == "function" and type(GetProfessionInfo) == "function" then
        local ok, a, b, c, d, e = pcall(GetProfessions)
        if ok then
            for _, index in pairs({ a, b, c, d, e }) do
                local okInfo, name, _, rank, maxRank, _, _, line = pcall(GetProfessionInfo, index)
                if okInfo and IsHerb(line, name) and type(rank) == "number" then return rank, maxRank end
            end
        end
    end
    local api = C_SkillInfo
    if type(api) == "table" and type(api.GetNumSkillLines) == "function" and type(api.GetSkillLineInfo) == "function" then
        local ok, count = pcall(api.GetNumSkillLines)
        for i = 1, (ok and type(count) == "number") and count or 0 do
            local okLine, info = pcall(api.GetSkillLineInfo, i)
            if okLine and type(info) == "table" and not info.isHeader and IsHerb(info.skillLineID, info.name)
                and type(info.rank) == "number" then
                return info.rank, info.maxRank
            end
        end
    end
    if type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function" then
        local ok, count = pcall(GetNumSkillLines)
        for i = 1, (ok and type(count) == "number") and count or 0 do
            local okLine, name, isHeader, _, rank, _, _, maxRank = pcall(GetSkillLineInfo, i)
            if okLine and not isHeader and SKILL_NAMES[name] and type(rank) == "number" then return rank, maxRank end
        end
    end
end

local box, swatch, label
local hoverHerb, hoverAt = nil, 0
local HERB_REQ = {}
for i = 1, #HERBS do HERB_REQ[HERBS[i][1]] = HERBS[i][2] end
local skill, maxSkill
local MEANING = { orange = "skill-up", yellow = "likely skill-up", green = "unlikely skill-up", grey = "no skill-up" }

-- One line, only while hovering a herb: [square] Silverleaf  no skill-up
local function Refresh()
    if not box then return end
    local db = VoidMarkMiniMapDB
    skill, maxSkill = ReadSkill()
    local hovering = hoverHerb and HERB_REQ[hoverHerb] and GetTime() - hoverAt < 0.35
    local show = type(db) == "table" and db.herb ~= false and skill ~= nil and hovering
    box:SetShown(show)
    if not show then return end
    local accent = ACCENTS[db.accent] or ACCENTS.purple
    if db.purple == false then accent = { 0.35, 0.35, 0.35 } end
    box:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
    local req = HERB_REQ[hoverHerb]
    local band = Band(skill, req)
    local c = COLORS[band]
    swatch:SetColorTexture(c[1], c[2], c[3], 1)
    label:SetText(hoverHerb .. "  " .. (band == "red" and ("needs " .. req) or MEANING[band]))
    label:SetTextColor(c[1], c[2], c[3])
    local width = label.GetStringWidth and label:GetStringWidth() or 120
    box:SetSize(math.max(60, math.floor(width + 28)), 20)
end
_G.VoidMarkMiniMapHerbRefresh = Refresh

local function Attach()
    if box then return true end
    local parent = _G.VoidMarkMiniMapFrame
    if not parent then return false end
    box = CreateFrame("Frame", "VoidMarkMiniMapHerbBox", parent, "BackdropTemplate")
    box:SetSize(140, 20)
    box:SetPoint("TOPRIGHT", parent, "TOPLEFT", -4, 0)
    if box.SetBackdrop then
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        box:SetBackdropColor(0.04, 0.03, 0.07, 0.85)
    end
    if box.EnableMouse then box:EnableMouse(false) end
    swatch = box:CreateTexture(nil, "ARTWORK")
    swatch:SetSize(9, 9)
    swatch:SetPoint("LEFT", box, "LEFT", 7, 0)
    label = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    label:SetPoint("LEFT", swatch, "RIGHT", 5, 0)
    if label.SetWordWrap then label:SetWordWrap(false) end
    box:SetScript("OnUpdate", function()
        if GetTime() - hoverAt >= 0.35 then hoverHerb = nil; box:Hide() end
    end)
    box:Hide()
    Refresh()
    return true
end

local frame = CreateFrame("Frame")
-- Some events differ between client builds; registering an unknown one throws,
-- so each is guarded and a missing event never stops this file from loading.
local registered = {}
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL",
    "LEARNED_SPELL_IN_TAB", "LEARNED_SPELL_IN_SKILL_LINE" }) do
    if pcall(frame.RegisterEvent, frame, event) then registered[#registered + 1] = event end
end
local waited = 0
frame:SetScript("OnEvent", function()
    if Attach() then Refresh() end
end)
-- Short attach retry only until the minimap frame exists, then stop.
frame:SetScript("OnUpdate", function(self, dt)
    waited = waited + dt
    if waited < 1 then return end
    waited = 0
    if Attach() then self:SetScript("OnUpdate", nil) end
end)

-- Minimap hover label: put a small colored square left of each herb name.
-- Only touches GameTooltip while the minimap owns it; re-checks when text changes.
local HERB_NAMES = {}
for name in pairs(HERB_REQ) do HERB_NAMES[#HERB_NAMES + 1] = name end
table.sort(HERB_NAMES, function(a, b) return #a > #b end)
local SQUARE_PREFIX = "|TInterface\\Buttons\\WHITE8X8:10:10:0:0:8:8:0:8:0:8:"
local function Square(band)
    local c = COLORS[band]
    return SQUARE_PREFIX .. math.floor(c[1] * 255) .. ":" .. math.floor(c[2] * 255) .. ":" .. math.floor(c[3] * 255) .. "|t "
end
local function Escape(s) return (s:gsub("[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")) end

-- Returns the text with a square before each known herb name (idempotent).
local function Decorate(text, rank)
    if type(text) ~= "string" or text == "" or not rank then return text end
    text = text:gsub("|TInterface\\Buttons\\WHITE8X8:10:10:[^|]*|t ", "")
    local taken = {}
    for _, name in ipairs(HERB_NAMES) do
        local s, e = text:find(name, 1, true)
        while s do
            local covered = false
            for _, span in ipairs(taken) do if s >= span[1] and e <= span[2] then covered = true end end
            if not covered then taken[#taken + 1] = { s, e, name } end
            s, e = text:find(name, e + 1, true)
        end
    end
    table.sort(taken, function(a, b) return a[1] > b[1] end)
    for _, span in ipairs(taken) do
        text = text:sub(1, span[1] - 1) .. Square(Band(rank, HERB_REQ[span[3]])) .. text:sub(span[1])
    end
    return text
end

local lastTip
local tipsSeen = 0
local lastOwner, lastOwnerName
local function DecorateTooltip(tooltip)
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" then return end
    local squares = db.herbTip ~= false
    local owner = tooltip.GetOwner and tooltip:GetOwner()
    local overMap = Minimap and Minimap.IsMouseOver and Minimap:IsMouseOver()
    if owner ~= Minimap and not overMap then lastTip = nil; return end
    if owner ~= lastOwner then
        lastOwner = owner
        lastOwnerName = owner and owner.GetName and owner:GetName() or (owner and "unnamed frame") or "none"
        tipsSeen = tipsSeen + 1
    end
    local rank = skill or ReadSkill()
    if not rank then return end
    local changed, found = false, nil
    local lines = tooltip.NumLines and tooltip:NumLines() or 1
    for i = 1, lines do
        local line = _G["GameTooltipTextLeft" .. i]
        local text = line and line:GetText()
        if text and not found then
            for _, name in ipairs(HERB_NAMES) do
                if text:find(name, 1, true) then found = name; break end
            end
        end
        if text and text ~= lastTip then
            local decorated = squares and Decorate(text, rank) or text
            if decorated ~= text then line:SetText(decorated); changed = true end
            if i == 1 then lastTip = decorated end
        end
    end
    if found then
        local wasShown = hoverHerb ~= nil and GetTime() - hoverAt < 0.35
        local wasHerb = hoverHerb
        hoverHerb, hoverAt = found, GetTime()
        if not wasShown or wasHerb ~= found then Refresh() end
    end
    if changed and not tooltip.vmHerbResizing then
        tooltip.vmHerbResizing = true
        tooltip:Show()
        tooltip.vmHerbResizing = nil
    end
end
local tipHooked = false
if GameTooltip and GameTooltip.HookScript then
    tipHooked = pcall(function()
        GameTooltip:HookScript("OnShow", DecorateTooltip)
        GameTooltip:HookScript("OnUpdate", DecorateTooltip)
        GameTooltip:HookScript("OnHide", function() lastTip = nil; lastOwner = nil; hoverAt = 0 end)
    end)
end
-- Newer clients route minimap hover text through TooltipDataProcessor.
local dataHooked = false
if type(TooltipDataProcessor) == "table" and type(TooltipDataProcessor.AddTooltipPostCall) == "function"
    and type(Enum) == "table" and type(Enum.TooltipDataType) == "table" and Enum.TooltipDataType.MinimapMouseover then
    dataHooked = pcall(TooltipDataProcessor.AddTooltipPostCall, Enum.TooltipDataType.MinimapMouseover,
        function(tooltip) if tooltip == GameTooltip then DecorateTooltip(tooltip) end end)
end

-- /vmherb scan: report what is under the mouse 3 seconds later (hover a herb meanwhile).
local function FrameName(f)
    if not f then return "none" end
    local ok, name = pcall(function() return f.GetName and f:GetName() end)
    return (ok and name) or tostring(f.GetObjectType and f:GetObjectType() or "frame")
end
local function Scan()
    local out = {}
    out[#out + 1] = "over map: " .. tostring(Minimap and Minimap.IsMouseOver and Minimap:IsMouseOver())
    local foci = {}
    if type(GetMouseFoci) == "function" then foci = GetMouseFoci() or {}
    elseif type(GetMouseFocus) == "function" then foci = { GetMouseFocus() } end
    local names = {}
    for i = 1, math.min(#foci, 4) do names[#names + 1] = FrameName(foci[i]) end
    out[#out + 1] = "mouse focus: " .. (#names > 0 and table.concat(names, ", ") or "none")
    local gt = GameTooltip
    local shown = gt and gt.IsShown and gt:IsShown()
    local first = _G.GameTooltipTextLeft1 and _G.GameTooltipTextLeft1:GetText()
    out[#out + 1] = "GameTooltip: " .. (shown and "shown" or "hidden") .. " | owner " ..
        FrameName(gt and gt.GetOwner and gt:GetOwner()) .. " | text " .. tostring(first and first:gsub("|", "||") or "none")
    out[#out + 1] = "data hook: " .. tostring(dataHooked) .. " | herb detected: " .. tostring(hoverHerb or "none")
    for _, line in ipairs(out) do print("  " .. line) end
end

SLASH_VOIDMARKHERB1 = "/vmherb"
SlashCmdList.VOIDMARKHERB = function(msg)
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" then print("VoidMark Mini Map is not initialized."); return end
    local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
    local arg = ((msg or ""):match("^%s*%S+%s+(%S+)") or ""):lower()
    if cmd == "on" then db.herb = true
    elseif cmd == "off" then db.herb = false
    elseif cmd == "tip" and (arg == "on" or arg == "off") then db.herbTip = arg == "on"; return
    elseif cmd == "scan" then
        print("|cffb366ffVoidMark herbs:|r hover a herb on the map now; scanning in 3 seconds...")
        if C_Timer and C_Timer.After then C_Timer.After(3, Scan) else Scan() end
        return
    else
        local rank, maxRank = ReadSkill()
        print("|cffb366ffVoidMark herbs:|r /vmherb on|off (hover box), tip on|off (label squares), scan")
        print("  Herbalism: " .. (rank and (rank .. "/" .. (maxRank or "?")) or "not found (no Herbalism on this character?)"))
        print("  Side box: " .. (box and (box:IsShown() and "shown" or "hidden") or "not attached") ..
            " | setting " .. tostring(db.herb ~= false))
        print("  Map label hook: " .. tostring(tipHooked) .. " | map tooltips seen: " .. tipsSeen .. " (last owner: " .. (lastOwnerName or "none") .. ")" ..
            " | setting " .. tostring(db.herbTip ~= false))
        return
    end
    Attach()
    Refresh()
end

-- Exposed for tests.
_G.VoidMarkMiniMapHerb = { Band = Band, ReadSkill = ReadSkill, Attach = Attach, Refresh = Refresh,
    Box = function() return box end, Label = function() return label end, Scan = Scan, Decorate = Decorate, DecorateTooltip = DecorateTooltip }
