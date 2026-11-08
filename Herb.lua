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
for _, event in ipairs({ "PLAYER_LOGIN", "PLAYER_ENTERING_WORLD", "SKILL_LINES_CHANGED", "CHAT_MSG_SKILL", "LEARNED_SPELL_IN_TAB" }) do
    frame:RegisterEvent(event)
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

SLASH_VOIDMARKHERB1 = "/vmherb"
SlashCmdList.VOIDMARKHERB = function(msg)
    local db = VoidMarkMiniMapDB
    if type(db) ~= "table" then print("VoidMark Mini Map is not initialized."); return end
    local cmd = ((msg or ""):match("^%s*(%S*)") or ""):lower()
    if cmd == "on" then db.herb = true
    elseif cmd == "off" then db.herb = false
    else
        local rank = ReadSkill()
        print("VoidMark herb box: /vmherb on | off  (skill: " .. (rank or "Herbalism not found") .. ")")
        return
    end
    Attach()
    Refresh()
end

-- Exposed for tests.
_G.VoidMarkMiniMapHerb = { Band = Band, Groups = Groups, ReadSkill = ReadSkill, Attach = Attach, Refresh = Refresh,
    Box = function() return box end }
