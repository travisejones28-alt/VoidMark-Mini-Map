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

-- Returns { red = {names...}, ... } with the most relevant herbs first:
-- red lists the next herbs to unlock; other bands list the highest herb first.
local function Groups(skill)
    local groups = {}
    for _, band in ipairs(BANDS) do groups[band] = {} end
    for i = 1, #HERBS do
        local herb = HERBS[i]
        local list = groups[Band(skill, herb[2])]
        list[#list + 1] = herb[1]
    end
    for _, band in ipairs(BANDS) do
        if band ~= "red" then
            local list, reversed = groups[band], {}
            for i = #list, 1, -1 do reversed[#reversed + 1] = list[i] end
            groups[band] = reversed
        end
    end
    return groups
end

local function ReadSkill()
    if type(GetNumSkillLines) ~= "function" or type(GetSkillLineInfo) ~= "function" then return end
    local ok, count = pcall(GetNumSkillLines)
    if not ok or type(count) ~= "number" then return end
    for i = 1, count do
        local okLine, name, isHeader, _, rank, _, _, maxRank = pcall(GetSkillLineInfo, i)
        if okLine and not isHeader and SKILL_NAMES[name] and type(rank) == "number" then
            return rank, maxRank
        end
    end
end

local box, title, rows
local skill, maxSkill
local function Hex(c) return string.format("ff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255) end

local function Summary(list)
    if #list == 0 then return "-" end
    local text = list[1]
    if #list > 1 then text = text .. " +" .. (#list - 1) end
    return text
end

local function Refresh()
    if not box then return end
    local db = VoidMarkMiniMapDB
    skill, maxSkill = ReadSkill()
    local show = type(db) == "table" and db.herb ~= false and skill ~= nil
    box:SetShown(show)
    if not show then return end
    local accent = ACCENTS[db.accent] or ACCENTS.purple
    if db.purple == false then accent = { 0.35, 0.35, 0.35 } end
    box:SetBackdropBorderColor(accent[1], accent[2], accent[3], 1)
    title:SetText("Herb " .. skill .. (maxSkill and maxSkill > 0 and ("/" .. maxSkill) or ""))
    local groups = Groups(skill)
    for i, band in ipairs(BANDS) do
        local c = COLORS[band]
        rows[i].text:SetText(Summary(groups[band]))
        rows[i].text:SetTextColor(c[1], c[2], c[3])
    end
end
_G.VoidMarkMiniMapHerbRefresh = Refresh

local function ShowTooltip(self)
    if not skill or not GameTooltip then return end
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("Herbalism " .. skill)
    local groups = Groups(skill)
    for _, band in ipairs(BANDS) do
        local list = groups[band]
        if #list > 0 then
            GameTooltip:AddLine("|c" .. Hex(COLORS[band]) .. table.concat(list, ", ") .. "|r", 1, 1, 1, true)
        end
    end
    GameTooltip:Show()
end

local WIDTH, ROW = 128, 13
local function Attach()
    if box then return true end
    local parent = _G.VoidMarkMiniMapFrame
    if not parent then return false end
    box = CreateFrame("Frame", "VoidMarkMiniMapHerbBox", parent, "BackdropTemplate")
    box:SetSize(WIDTH, 22 + #BANDS * ROW)
    box:SetPoint("TOPRIGHT", parent, "TOPLEFT", -4, 0)
    if box.SetBackdrop then
        box:SetBackdrop({ bgFile = "Interface\\Buttons\\WHITE8X8", edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
        box:SetBackdropColor(0.04, 0.03, 0.07, 0.85)
    end
    box:EnableMouse(true)
    box:SetScript("OnEnter", ShowTooltip)
    box:SetScript("OnLeave", function() if GameTooltip then GameTooltip:Hide() end end)
    title = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    title:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -5)
    rows = {}
    for i, band in ipairs(BANDS) do
        local swatch = box:CreateTexture(nil, "ARTWORK")
        swatch:SetSize(8, 8)
        swatch:SetPoint("TOPLEFT", box, "TOPLEFT", 6, -(19 + (i - 1) * ROW))
        swatch:SetColorTexture(COLORS[band][1], COLORS[band][2], COLORS[band][3], 1)
        local text = box:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
        text:SetPoint("LEFT", swatch, "RIGHT", 4, 0)
        text:SetWidth(WIDTH - 24)
        text:SetJustifyH("LEFT")
        if text.SetWordWrap then text:SetWordWrap(false) end
        rows[i] = { swatch = swatch, text = text }
    end
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
local HERB_REQ = {}
for i = 1, #HERBS do HERB_REQ[HERBS[i][1]] = HERBS[i][2] end
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
local function DecorateTooltip(tooltip)
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" or db.herbTip == false then return end
    if not tooltip.GetOwner or tooltip:GetOwner() ~= Minimap then lastTip = nil; return end
    tipsSeen = tipsSeen + 1
    local rank = skill or ReadSkill()
    if not rank then return end
    local changed = false
    local lines = tooltip.NumLines and tooltip:NumLines() or 1
    for i = 1, lines do
        local line = _G["GameTooltipTextLeft" .. i]
        local text = line and line:GetText()
        if text and text ~= lastTip then
            local decorated = Decorate(text, rank)
            if decorated ~= text then line:SetText(decorated); changed = true end
            if i == 1 then lastTip = decorated end
        end
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
        GameTooltip:HookScript("OnHide", function() lastTip = nil end)
    end)
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
    else
        local rank, maxRank = ReadSkill()
        local skillApi = type(GetNumSkillLines) == "function" and type(GetSkillLineInfo) == "function"
        print("|cffb366ffVoidMark herbs:|r /vmherb on|off (side box), /vmherb tip on|off (map label squares)")
        print("  Herbalism: " .. (rank and (rank .. "/" .. (maxRank or "?")) or (skillApi and "not found in skill list" or "skill API missing")))
        print("  Side box: " .. (box and (box:IsShown() and "shown" or "hidden") or "not attached") ..
            " | setting " .. tostring(db.herb ~= false))
        print("  Map label hook: " .. tostring(tipHooked) .. " | minimap labels seen: " .. tipsSeen ..
            " | setting " .. tostring(db.herbTip ~= false))
        return
    end
    Attach()
    Refresh()
end

-- Exposed for tests.
_G.VoidMarkMiniMapHerb = { Band = Band, Groups = Groups, ReadSkill = ReadSkill, Attach = Attach, Refresh = Refresh,
    Box = function() return box end, Decorate = Decorate, DecorateTooltip = DecorateTooltip }
