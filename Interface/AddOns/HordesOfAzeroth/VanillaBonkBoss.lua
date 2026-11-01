local L = VanillaBonkL
local UI = VanillaBonkUI

local TOP = -36
local SMOOTHING = 8
local MAX_BARS = 4
local PER_ROW = 2
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local GOLD_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border"
local STONE_BORDER = "Interface\\DialogFrame\\UI-DialogBox-Border"

local SIZES = {
    single = { width = 450, box = 34, inset = 7, edge = 20, nameHeight = 16, nameSize = 13, tagSize = 10, valueSize = 12, skull = 26, debuffGap = 6,
        debuffs = UI.DEBUFF_LOOKS.bar },
    group = { width = 300, box = 30, inset = 7, edge = 18, nameHeight = 13, nameSize = 12, tagSize = 9, valueSize = 11, skull = 24, debuffGap = 1,
        debuffs = UI.DEBUFF_LOOKS.group, gapX = 14, rowGap = 4 },
}

local LOOKS = {
    boss = { fill = { 0.78, 0.12, 0.12 }, name = { 1, 0.82, 0 }, tag = L["|cffff4b4bSTAGE BOSS|r"], kind = L["Stage boss"], border = GOLD_BORDER, edge = { 1, 1, 1 } },
    mini = { fill = { 0.9, 0.48, 0.1 }, name = { 1, 1, 1 }, tag = L["|cffffa040MINI-BOSS|r"], kind = L["Mini-boss"], border = STONE_BORDER, edge = { 0.85, 0.85, 0.85 } },
}

local function Short(value)
    if value >= 1000000000 then
        return format("%.2fb", value / 1000000000)
    elseif value >= 1000000 then
        return format("%.2fm", value / 1000000)
    elseif value >= 10000 then
        return format("%.1fk", value / 1000)
    end
    return tostring(floor(value))
end

local holder = CreateFrame("Frame", "VanillaBonkBossBar", UIParent)
holder:SetWidth(SIZES.single.width)
holder:SetHeight(SIZES.single.nameHeight + SIZES.single.box)
holder:SetPoint("TOP", UIParent, "TOP", 0, TOP)
holder:SetFrameStrata("MEDIUM")
holder.below = 0
holder:Hide()

local bars = {}

local function SetLook(bar, look, size)
    if bar.look == look and bar.size == size then
        return
    end
    bar.look = look
    bar.box:SetBackdrop({
        bgFile = UI.FLAT, edgeFile = look.border, edgeSize = size.edge,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    })
    bar.box:SetBackdropColor(0, 0, 0, 0.85)
    bar.box:SetBackdropBorderColor(look.edge[1], look.edge[2], look.edge[3])
    bar.health:SetStatusBarColor(look.fill[1], look.fill[2], look.fill[3])
    bar.name:SetTextColor(look.name[1], look.name[2], look.name[3])
end

local function SetSize(bar, size)
    if bar.size == size then
        return
    end
    bar.size = size
    bar.look = nil
    bar:SetWidth(size.width)
    bar:SetHeight(size.nameHeight + size.box)
    bar.box:ClearAllPoints()
    bar.box:SetPoint("TOPLEFT", bar, "TOPLEFT", 0, -size.nameHeight)
    bar.box:SetPoint("TOPRIGHT", bar, "TOPRIGHT", 0, -size.nameHeight)
    bar.box:SetHeight(size.box)
    bar.health:ClearAllPoints()
    bar.health:SetPoint("TOPLEFT", bar.box, "TOPLEFT", size.inset, -size.inset)
    bar.health:SetPoint("BOTTOMRIGHT", bar.box, "BOTTOMRIGHT", -size.inset, size.inset)
    bar.trail:SetHeight(size.box - 2 * size.inset)
    bar.name:SetFont(UI.FONT, size.nameSize, "")
    bar.tag:SetFont(UI.FONT, size.tagSize, "")
    bar.value:SetFont(UI.NUMBER_FONT, size.valueSize, "")
    for _, skull in ipairs(bar.skulls) do
        skull:SetWidth(size.skull)
        skull:SetHeight(size.skull)
    end
    UI.SetDebuffRowLook(bar.debuffs, size.debuffs)
    bar.debuffs:ClearAllPoints()
    bar.debuffs:SetPoint("TOPLEFT", bar.box, "BOTTOMLEFT", size.inset, -size.debuffGap)
    bar.debuffText = nil
end

local function PlaceName(bar)
    local gap = 8
    local total = bar.name:GetStringWidth() + gap + bar.tag:GetStringWidth()
    bar.name:ClearAllPoints()
    bar.name:SetPoint("TOPLEFT", bar, "TOP", -total / 2, 0)
    bar.tag:ClearAllPoints()
    bar.tag:SetPoint("LEFT", bar.name, "RIGHT", gap, 0)
end

local function ShowEntryTooltip()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
    GameTooltip:AddDoubleLine(this.bossName or "", this.look and this.look.kind or "", 1, 0.82, 0, 1, 0.3, 0.3)
    GameTooltip:AddLine(Short(this.hp or 0) .. " / " .. Short(this.hpMax or 0) .. L[" health"], 1, 1, 1)
    if getn(this.affixNames) > 0 then
        GameTooltip:AddLine(table.concat(this.affixNames, ", "), 1, 0.82, 0, 1)
    end
    GameTooltip:Show()
end

local function Smooth()
    local step = min(1, arg1 * SMOOTHING)
    this.shown = this.shown + (this.target - this.shown) * step
    if this.trailShown > this.shown then
        this.trailShown = this.trailShown - max(0.002, (this.trailShown - this.shown) * arg1 * 2.5)
        if this.trailShown < this.shown then
            this.trailShown = this.shown
        end
    else
        this.trailShown = this.shown
    end
    this.health:SetValue(this.shown)
    this.trail:SetWidth(max(0.01, (this.size.width - 2 * this.size.inset) * this.trailShown))
end

local function CreateBar()
    local bar = CreateFrame("Frame", nil, holder)
    bar.name = UI.Text(bar, 13)
    bar.tag = UI.Text(bar, 10)

    bar.box = CreateFrame("Frame", nil, bar)
    bar.health = CreateFrame("StatusBar", nil, bar.box)
    bar.health:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar.health:SetMinMaxValues(0, 1)

    bar.trail = bar.box:CreateTexture(nil, "ARTWORK")
    bar.trail:SetTexture(UI.FLAT)
    bar.trail:SetVertexColor(1, 0.85, 0.6, 0.6)
    bar.trail:SetPoint("TOPLEFT", bar.health, "TOPLEFT", 0, 0)

    bar.edge = CreateFrame("Frame", nil, bar.box)
    bar.edge:SetAllPoints(bar.box)
    bar.edge:SetFrameLevel(bar.health:GetFrameLevel() + 2)

    bar.value = UI.Text(bar.edge, 12, UI.NUMBER_FONT)
    bar.value:SetPoint("CENTER", bar.health, "CENTER", 0, 0)

    bar.skulls = {}
    for side = 1, 2 do
        local skull = bar.edge:CreateTexture(nil, "OVERLAY")
        skull:SetTexture(SKULL)
        if side == 1 then
            skull:SetPoint("RIGHT", bar.box, "LEFT", 4, 0)
        else
            skull:SetPoint("LEFT", bar.box, "RIGHT", -4, 0)
        end
        bar.skulls[side] = skull
    end

    bar.debuffs = UI.DebuffRow(bar, UI.DEBUFF_LOOKS.bar)
    bar.debuffList = {}
    bar.affixNames = {}
    bar.shown, bar.trailShown, bar.target = 1, 1, 1

    bar:EnableMouse(true)
    bar:SetScript("OnEnter", ShowEntryTooltip)
    bar:SetScript("OnLeave", function() GameTooltip:Hide() end)
    bar:SetScript("OnUpdate", Smooth)
    bar:Hide()
    return bar
end

for index = 1, MAX_BARS do
    bars[index] = CreateBar()
end

local function FillBar(bar, entry, size)
    local fraction = entry.maxHealth > 0 and entry.health / entry.maxHealth or 0
    SetSize(bar, size)
    if not bar:IsShown() or bar.bossName ~= entry.name or bar.guid ~= entry.guid then
        bar.shown, bar.trailShown = fraction, fraction
    end
    bar.bossName = entry.name
    bar.guid = entry.guid
    bar.target = fraction
    bar.hp, bar.hpMax = entry.health, entry.maxHealth

    local look = entry.kind == "boss" and LOOKS.boss or LOOKS.mini
    SetLook(bar, look, size)
    bar.name:SetText(entry.name)
    bar.tag:SetText(look.tag)
    PlaceName(bar)
    bar.value:SetText(floor(fraction * 100 + 0.5) .. "%  |cffc8c8c8" .. Short(entry.health) .. " / " .. Short(entry.maxHealth) .. "|r")
    bar.affixNames = (entry.affixes and entry.affixes ~= "") and UI.Split(entry.affixes, ",") or {}
    if entry.debuffs ~= bar.debuffText or entry.guid ~= bar.debuffs.guid then
        bar.debuffText = entry.debuffs
        bar.debuffs:SetDebuffs(bar.debuffList, UI.ParseKeywordDebuffs(entry.debuffs, bar.debuffList), entry.guid)
    end
    bar:Show()
end

local function ShowSkulls(bar, left, right)
    if left then bar.skulls[1]:Show() else bar.skulls[1]:Hide() end
    if right then bar.skulls[2]:Show() else bar.skulls[2]:Hide() end
end

local function HideBosses()
    for _, bar in ipairs(bars) do
        bar:Hide()
        bar.bossName = nil
        bar.guid = nil
        bar.affixNames = {}
        bar.debuffText = nil
        bar.debuffs:SetDebuffs(bar.debuffList, 0, nil)
    end
    holder.below = 0
    holder:Hide()
end

local function LayOut(count)
    if count == 1 then
        local size = SIZES.single
        local bar = bars[1]
        bar:ClearAllPoints()
        bar:SetPoint("TOP", holder, "TOP", 0, 0)
        ShowSkulls(bar, true, true)
        holder:SetWidth(size.width)
        holder:SetHeight(size.nameHeight + size.box)
        holder.below = bar.debuffs:IsShown() and (bar.debuffs.height + 4) or 0
        return
    end
    local size = SIZES.group
    local y = 0
    local rows = ceil(count / PER_ROW)
    for row = 1, rows do
        local first = (row - 1) * PER_ROW + 1
        local last = min(count, first + PER_ROW - 1)
        local inRow = last - first + 1
        local debuffHeight = 0
        for index = first, last do
            local bar = bars[index]
            local column = index - first
            bar:ClearAllPoints()
            bar:SetPoint("TOP", holder, "TOP", (column - (inRow - 1) / 2) * (size.width + size.gapX), -y)
            local isBoss = bar.look == LOOKS.boss
            ShowSkulls(bar, isBoss and column == 0, isBoss and column == inRow - 1)
            if bar.debuffs:IsShown() then
                debuffHeight = max(debuffHeight, bar.debuffs.height + size.debuffGap)
            end
        end
        y = y + size.nameHeight + size.box + debuffHeight + (row < rows and size.rowGap or 0)
    end
    holder:SetWidth(PER_ROW * size.width + size.gapX)
    holder:SetHeight(SIZES.single.nameHeight + SIZES.single.box)
    holder.below = y - (SIZES.single.nameHeight + SIZES.single.box)
end

local function ShowBosses(fields)
    local count = min(MAX_BARS, tonumber(fields[2] or "") or 0)
    if count <= 0 then
        HideBosses()
        return
    end
    local size = count == 1 and SIZES.single or SIZES.group
    for index = 1, count do
        local base = 3 + (index - 1) * 7
        FillBar(bars[index], {
            name = fields[base] or "", health = tonumber(fields[base + 1]) or 0, maxHealth = tonumber(fields[base + 2]) or 0,
            kind = fields[base + 3], affixes = fields[base + 4], debuffs = fields[base + 5], guid = fields[base + 6],
        }, size)
    end
    for index = count + 1, MAX_BARS do
        bars[index]:Hide()
    end
    LayOut(count)
    holder:Show()
end

UI.Listen({
    ["boss"] = function(f)
        if f[2] and f[2] ~= "" then
            ShowBosses(f)
        else
            HideBosses()
        end
    end,
    ["start"] = HideBosses,
    ["end"] = HideBosses,
})
