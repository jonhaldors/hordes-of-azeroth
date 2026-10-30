local L = VanillaBonkL
VanillaBonkSpellTip = {}
local Tip = VanillaBonkSpellTip
local UI = VanillaBonkUI

local WIDTH = 290
local PAD = 12
local INNER = WIDTH - PAD * 2
local TEXT_SIZE = 12
local SMALL_SIZE = 11
local TITLE_SIZE = 15
local LINE_SPACING = 2
local ROW_GAP = 3
local SPACER = 7
local RULE_GAP = 7

local SCHOOL_COLORS = {
    Holy = { 1, 0.9, 0.5 },
    Fire = { 1, 0.5, 0.25 },
    Nature = { 0.38, 1, 0.38 },
    Frost = { 0.5, 0.88, 1 },
    Shadow = { 0.69, 0.5, 1 },
    Arcane = { 1, 0.5, 1 },
}
local LEGENDARY_BORDER = { 1, 0.5, 0 }

Tip.GOLD = { 1, 0.82, 0 }
Tip.GREY = { 0.62, 0.62, 0.62 }
Tip.GREEN = { 0.13, 1, 0.13 }
Tip.WHITE = { 1, 1, 1 }
Tip.ORANGE = { 1, 0.5, 0 }
Tip.SPEC = { 0.44, 0.84, 1 }

local frame = CreateFrame("Frame", nil, UIParent)
frame:SetFrameStrata("TOOLTIP")
frame:SetWidth(WIDTH)
frame:SetHeight(40)
frame:SetClampedToScreen(true)
frame:SetBackdrop({ bgFile = UI.FLAT, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16,
    insets = { left = 5, right = 5, top = 5, bottom = 5 } })
frame:Hide()

local rows, texts, rules, chips = {}, {}, {}, {}
local owner, legendary

local function Pooled(pool, index, make)
    if not pool[index] then
        pool[index] = make()
    end
    return pool[index]
end

local function MakeText()
    local text = UI.Text(frame, TEXT_SIZE)
    text:SetJustifyH("LEFT")
    text:SetJustifyV("TOP")
    text:SetSpacing(LINE_SPACING)
    return text
end

local function MakeRule()
    local rule = frame:CreateTexture(nil, "ARTWORK")
    rule:SetTexture(UI.FLAT)
    rule:SetVertexColor(1, 1, 1, 0.1)
    rule:SetHeight(1)
    return rule
end

local function MakeChip()
    local chip = CreateFrame("Frame", nil, frame)
    chip:SetHeight(15)
    chip:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    chip:SetBackdropColor(0, 0, 0, 0.45)
    chip.text = UI.Text(chip, 10)
    chip.text:SetPoint("CENTER", chip, "CENTER", 0, 0)
    return chip
end

local function Clear()
    rows = {}
    for _, text in ipairs(texts) do
        text:Hide()
    end
    for _, rule in ipairs(rules) do
        rule:Hide()
    end
    for _, chip in ipairs(chips) do
        chip:Hide()
    end
    legendary = nil
end

local function Color(color, r, g, b)
    if r then
        return { r, g, b }
    end
    return color or Tip.WHITE
end

function Tip.SchoolColor(school)
    return SCHOOL_COLORS[school or ""]
end

function Tip:SetOwner(newOwner, anchor)
    GameTooltip:Hide()
    Clear()
    owner = newOwner
    frame:ClearAllPoints()
    if anchor == "ANCHOR_TOP" then
        frame:SetPoint("BOTTOM", newOwner, "TOP", 0, 6)
    else
        frame:SetPoint("BOTTOMLEFT", newOwner, "TOPRIGHT", 0, 0)
    end
end

function Tip:IsOwned(candidate)
    return frame:IsShown() and owner == candidate
end

function Tip:IsShown()
    return frame:IsShown()
end

function Tip:Title(text, color, tags)
    tinsert(rows, { kind = "title", text = text, color = color or Tip.WHITE, tags = tags or {} })
end

function Tip:SetLegendary(on)
    legendary = on
end

function Tip:AddLine(text, r, g, b)
    if not text or text == " " or text == "" then
        tinsert(rows, { kind = "gap" })
        return
    end
    local color = Color(nil, r, g, b)
    local start = 1
    while true do
        local breakAt = strfind(text, "\n\n", start, true)
        tinsert(rows, { kind = "text", text = strsub(text, start, breakAt and breakAt - 1), color = color })
        if not breakAt then
            return
        end
        tinsert(rows, { kind = "gap" })
        start = breakAt + 2
    end
end

function Tip:AddSmallLine(text, color)
    tinsert(rows, { kind = "text", text = text, color = color or Tip.GREY, size = SMALL_SIZE })
end

function Tip.Yards(value)
    local tenths = floor(value * 10 + 0.5)
    if mod(tenths, 10) == 0 then
        return format("%d", tenths / 10) .. L[" yd"]
    end
    return format("%.1f", tenths / 10) .. L[" yd"]
end

local function Grown(base, current, word)
    current = tonumber(current) or 0
    if current > 0 and abs(current - base) >= 0.05 then
        return (current > base and "|cff21ff21" or "|cffff2020") .. Tip.Yards(current) .. " " .. word .. "|r"
    end
    return Tip.Yards(base) .. " " .. word
end

function Tip.ReachText(radius, range, current, currentRange)
    radius = tonumber(radius) or 0
    range = tonumber(range) or 0
    if radius > 0 then
        return Grown(radius, current, "radius")
    elseif range > 0 then
        return Grown(range, currentRange, "range")
    end
    return ""
end

function Tip:AddReach(radius, range)
    local text = Tip.ReachText(radius, range)
    if text ~= "" then
        self:AddLine(text, 1, 1, 1)
    end
end

function Tip:AddFooter(spec, school, aoe)
    local text = (spec and spec ~= "") and spec or (school or "")
    if aoe then
        text = text ~= "" and (text .. L["  ·  AoE"]) or "AoE"
    end
    if text ~= "" then
        self:AddSmallLine(text, Tip.GREY)
    end
end

function Tip:AddDoubleLine(left, right, lr, lg, lb, rr, rg, rb, size)
    tinsert(rows, { kind = "double", left = left or "", right = right or "", leftColor = Color(nil, lr, lg, lb), rightColor = Color(nil, rr, rg, rb), size = size })
end

function Tip:AddRule()
    tinsert(rows, { kind = "rule" })
end

function Tip:NumLines()
    return getn(rows)
end

function Tip:LineText(index)
    local row = rows[index]
    return row and (row.text or row.left)
end

local function PlaceText(index, value, color, size, x, y, width)
    local text = Pooled(texts, index, MakeText)
    text:SetFont(UI.FONT, size or TEXT_SIZE, "")
    text:SetWidth(width or INNER)
    text:SetText(value)
    text:SetTextColor(color[1], color[2], color[3])
    text:ClearAllPoints()
    text:SetPoint("TOPLEFT", frame, "TOPLEFT", x, y)
    text:Show()
    return text
end

local function PlaceChips(tags, y)
    local right = -PAD
    local used = 0
    for index = getn(tags), 1, -1 do
        local tag = tags[index]
        local chip = Pooled(chips, index, MakeChip)
        chip.text:SetText(tag.text)
        chip.text:SetFont(UI.FONT, tag.plain and TEXT_SIZE or 10, "")
        chip.text:SetTextColor(tag.color[1], tag.color[2], tag.color[3])
        if tag.plain then
            chip:SetBackdropColor(0, 0, 0, 0)
            chip:SetBackdropBorderColor(0, 0, 0, 0)
        else
            chip:SetBackdropColor(tag.color[1], tag.color[2], tag.color[3], 0.12)
            chip:SetBackdropBorderColor(tag.color[1], tag.color[2], tag.color[3], 0.9)
        end
        local width = chip.text:GetStringWidth() + (tag.plain and 2 or 12)
        chip:SetWidth(width)
        chip:ClearAllPoints()
        chip:SetPoint("TOPRIGHT", frame, "TOPRIGHT", right, y - 2)
        chip:Show()
        right = right - width - 4
        used = used + width + 4
    end
    return used
end

local function Layout()
    local y = -PAD + 1
    local textIndex, ruleIndex = 0, 0
    local previous
    for _, row in ipairs(rows) do
        if row.kind == "gap" then
            y = y - SPACER
        elseif row.kind == "rule" then
            ruleIndex = ruleIndex + 1
            local rule = Pooled(rules, ruleIndex, MakeRule)
            y = y - RULE_GAP + ROW_GAP
            rule:ClearAllPoints()
            rule:SetPoint("TOPLEFT", frame, "TOPLEFT", PAD, y)
            rule:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -PAD, y)
            rule:Show()
            y = y - RULE_GAP
        else
            if previous and previous ~= "rule" and previous ~= "gap" then
                y = y - ROW_GAP
            end
            if row.kind == "title" then
                local chipWidth = PlaceChips(row.tags, y)
                textIndex = textIndex + 1
                local text = PlaceText(textIndex, row.text, row.color, TITLE_SIZE, PAD, y, INNER - chipWidth - 4)
                y = y - max(18, text:GetHeight())
            elseif row.kind == "double" then
                textIndex = textIndex + 1
                local right = PlaceText(textIndex, row.right, row.rightColor, row.size, PAD, y, INNER)
                right:SetJustifyH("RIGHT")
                local rightWidth = row.right ~= "" and right:GetStringWidth() or 0
                textIndex = textIndex + 1
                local left = PlaceText(textIndex, row.left, row.leftColor, row.size, PAD, y, INNER - rightWidth - 10)
                y = y - max(left:GetHeight(), right:GetHeight())
            else
                textIndex = textIndex + 1
                local text = PlaceText(textIndex, row.text, row.color, row.size, PAD, y, INNER)
                y = y - text:GetHeight()
            end
        end
        previous = row.kind
    end
    for index = textIndex + 1, getn(texts) do
        texts[index]:Hide()
    end
    for index = ruleIndex + 1, getn(rules) do
        rules[index]:Hide()
    end
    frame:SetHeight(-y + PAD)
end

function Tip:Show()
    for _, text in ipairs(texts) do
        text:SetJustifyH("LEFT")
    end
    local background = TOOLTIP_DEFAULT_BACKGROUND_COLOR or { r = 0.09, g = 0.09, b = 0.19 }
    local border = TOOLTIP_DEFAULT_COLOR or { r = 1, g = 1, b = 1 }
    frame:SetBackdropColor(background.r, background.g, background.b)
    if legendary then
        frame:SetBackdropBorderColor(LEGENDARY_BORDER[1], LEGENDARY_BORDER[2], LEGENDARY_BORDER[3])
    else
        frame:SetBackdropBorderColor(border.r, border.g, border.b)
    end
    Layout()
    frame.relayout = true
    frame:Show()
end

function Tip:Hide()
    frame:Hide()
    owner = nil
end

frame:SetScript("OnUpdate", function()
    if owner and not owner:IsVisible() then
        Tip:Hide()
        return
    end
    if frame.relayout then
        frame.relayout = nil
        Layout()
    end
end)

local gameTooltipHide = GameTooltip.Hide
GameTooltip.Hide = function(self)
    Tip:Hide()
    return gameTooltipHide(self)
end

local gameTooltipSetOwner = GameTooltip.SetOwner
GameTooltip.SetOwner = function(self, newOwner, anchor, x, y)
    Tip:Hide()
    return gameTooltipSetOwner(self, newOwner, anchor, x, y)
end
