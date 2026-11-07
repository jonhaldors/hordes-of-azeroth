local L = VanillaBonkL
local UI = VanillaBonkUI

local Summary = UI.Module("summary")
Summary.run = {}
Summary.weapons = {}
Summary.passives = {}
Summary.support = {}
Summary.recap = {}

local PANEL_WIDTH = 720
local PAD_X = 30
local PAD_TOP = 24
local PAD_BOTTOM = 16
local LEFT_WIDTH = 196
local RIGHT_X = PAD_X + LEFT_WIDTH + 22
local RIGHT_WIDTH = PANEL_WIDTH - RIGHT_X - PAD_X
local STATS_TOP = 76
local STAT_ROW = 19
local HEADER_HEIGHT = 20
local ROW_HEIGHT = 18
local ROW_GAP = 3
local SUB_HEIGHT = 13
local SUB_GAP = 3
local SUB_INDENT = 18
local COLUMN_WIDTH = 44
local MAX_LINES = 12
local MAX_PARTS = 4
local TYPE_BAR_HEIGHT = 7
local LEGEND_LINE = 13
local FOOTER_HEIGHT = 24
local BUTTON_WIDTH = 110
local FADE = 0.3
local BAR_BRIGHTNESS = 0.8
local TAB_GAP = 18
local MODE_DAMAGE, MODE_HEALING = 1, 2
local TITLE_DEFEAT = { 1, 0.23, 0.15 }
local TITLE_VICTORY = { 1, 0.82, 0 }
local TITLE_HOME = { 0.35, 1, 0.35 }
local CLASS_ART = {
    WARRIOR = "WarriorArms", MAGE = "MageFire", HUNTER = "HunterMarksmanship", ROGUE = "RogueCombat", PRIEST = "PriestHoly",
    SHAMAN = "ShamanElementalCombat", DRUID = "DruidBalance", WARLOCK = "WarlockDestruction", PALADIN = "PaladinHoly",
}

local function Short(value)
    value = tonumber(value) or 0
    if value >= 1000000 then
        return format("%.2fm", value / 1000000)
    elseif value >= 10000 then
        return format("%.1fk", value / 1000)
    end
    return tostring(floor(value))
end

local function Thousands(value)
    local text = tostring(floor(tonumber(value) or 0))
    local result = ""
    while strlen(text) > 3 do
        result = "," .. strsub(text, -3) .. result
        text = strsub(text, 1, -4)
    end
    return text .. result
end

local function Percent(part, total)
    return total > 0 and floor(part * 100 / total + 0.5) or 0
end

local screen = CreateFrame("Frame", "VanillaBonkSummary", UIParent)
Summary.frame = screen
Summary.screen = screen
screen:SetAllPoints(UIParent)
screen:SetFrameStrata("DIALOG")
screen:EnableMouse(true)
screen:Hide()
tinsert(UISpecialFrames, "VanillaBonkSummary")

screen.dim = screen:CreateTexture(nil, "BACKGROUND")
screen.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
screen.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
screen.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
screen.dim:SetVertexColor(0, 0, 0, 1)

screen.wound = screen:CreateTexture(nil, "BORDER")
screen.wound:SetTexture("Interface\\FullScreenTextures\\LowHealth")
screen.wound:SetBlendMode("ADD")
screen.wound:SetAllPoints(screen.dim)
screen.wound:SetAlpha(0.6)

local panel = CreateFrame("Frame", nil, screen)
Summary.panel = panel
screen.panel = panel
panel:SetWidth(PANEL_WIDTH)
panel:SetHeight(300)
panel:SetPoint("CENTER", screen, "CENTER", 0, 20)
panel:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 16 })

panel.art = panel:CreateTexture(nil, "BACKGROUND")
panel.art:SetPoint("TOPLEFT", panel, "TOPLEFT", 5, -5)
panel.art:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -5, 5)
panel.shade = panel:CreateTexture(nil, "BORDER")
panel.shade:SetAllPoints(panel.art)
UI.Shade(panel.shade, 0.84, 0.52)

panel.title = panel:CreateFontString(nil, "OVERLAY")
panel.title:SetFont(UI.TITLE_FONT, 30, "OUTLINE")
panel.title:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -PAD_TOP)
panel.title:SetJustifyH("LEFT")

panel.best = UI.Text(panel, 11)
panel.best:SetPoint("BOTTOMLEFT", panel.title, "BOTTOMRIGHT", 12, 5)

panel.subtitle = UI.Text(panel, 11)
panel.subtitle:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -PAD_TOP - 38)
panel.subtitle:SetWidth(LEFT_WIDTH)
panel.subtitle:SetJustifyH("LEFT")
panel.subtitle:SetTextColor(0.9, 0.83, 0.64)

panel.stats = {}
for index = 1, 7 do
    local stat = UI.IconRow(panel, {
        width = LEFT_WIDTH, height = STAT_ROW - 2, iconSize = 13, labelSize = 11, valueSize = 13,
    })
    stat:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -PAD_TOP - STATS_TOP - (index - 1) * STAT_ROW)
    stat.label:SetTextColor(0.9, 0.83, 0.64)
    panel.stats[index] = stat
end

panel.divider = panel:CreateTexture(nil, "ARTWORK")
panel.divider:SetTexture(UI.FLAT)
panel.divider:SetWidth(1)
panel.divider:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X + LEFT_WIDTH + 10, -PAD_TOP)
panel.divider:SetGradientAlpha("VERTICAL", 1, 0.82, 0, 0.5, 1, 0.82, 0, 0)
panel.dividerLow = panel:CreateTexture(nil, "ARTWORK")
panel.dividerLow:SetTexture(UI.FLAT)
panel.dividerLow:SetWidth(1)
panel.dividerLow:SetPoint("TOP", panel.divider, "BOTTOM", 0, 0)
panel.dividerLow:SetGradientAlpha("VERTICAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.5)

Summary.mode = MODE_DAMAGE

panel.tabs = {}
for index, label in ipairs({ L["hoa.addon.damage_done"], L["hoa.addon.healing_done"] }) do
    local tab = CreateFrame("Button", nil, panel)
    tab.mode = index
    tab:SetHeight(HEADER_HEIGHT - 4)
    tab.text = UI.Text(tab, 12)
    tab.text:SetPoint("LEFT", tab, "LEFT", 0, 0)
    tab.text:SetText(label)
    tab:SetWidth(tab.text:GetStringWidth() + 2)
    tab.underline = tab:CreateTexture(nil, "ARTWORK")
    tab.underline:SetTexture(UI.FLAT)
    tab.underline:SetHeight(1)
    tab.underline:SetPoint("TOPLEFT", tab, "BOTTOMLEFT", 0, 1)
    tab.underline:SetPoint("TOPRIGHT", tab, "BOTTOMRIGHT", 0, 1)
    tab.underline:SetVertexColor(1, 0.82, 0, 0.8)
    tab:SetScript("OnClick", function()
        if Summary.mode ~= this.mode then
            Summary.mode = this.mode
            PlaySound("igCharacterInfoTab")
            Summary:Render()
        end
    end)
    UI.Hover(tab, function()
        if Summary.mode ~= this.mode then
            this.text:SetTextColor(1, 1, 1)
        end
    end, function()
        if Summary.mode ~= this.mode then
            this.text:SetTextColor(0.6, 0.6, 0.6)
        end
    end)
    local previous = panel.tabs[index - 1]
    if previous then
        tab:SetPoint("LEFT", previous, "RIGHT", TAB_GAP, 0)
    else
        tab:SetPoint("TOPLEFT", panel, "TOPLEFT", RIGHT_X, -PAD_TOP + 2)
    end
    panel.tabs[index] = tab
end

local COLUMNS = {
    [MODE_DAMAGE] = { L["hoa.addon.damage_2"], L["hoa.addon.share"], L["hoa.addon.kills_2"] },
    [MODE_HEALING] = { L["hoa.addon.healed"], L["hoa.addon.absorb"], L["hoa.addon.share"] },
}
local COLUMN_OFFSETS = { 2 * COLUMN_WIDTH, COLUMN_WIDTH, 0 }
panel.columns = {}
for index = 1, 3 do
    local label = UI.Text(panel, 10)
    label:SetJustifyH("RIGHT")
    label:SetTextColor(0.62, 0.62, 0.62)
    label:SetWidth(COLUMN_WIDTH)
    label.slot = index
    panel.columns[index] = label
end

panel.empty = UI.Text(panel, 11)
panel.empty:SetPoint("TOPLEFT", panel, "TOPLEFT", RIGHT_X, -PAD_TOP - HEADER_HEIGHT - 4)
panel.empty:SetTextColor(0.6, 0.6, 0.6)

function Summary:ShowTabs()
    for _, tab in ipairs(panel.tabs) do
        if tab.mode == self.mode then
            tab.text:SetTextColor(1, 0.82, 0)
            tab.underline:Show()
        else
            tab.text:SetTextColor(0.6, 0.6, 0.6)
            tab.underline:Hide()
        end
    end
    for index, label in ipairs(panel.columns) do
        label:ClearAllPoints()
        label:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD_X - COLUMN_OFFSETS[label.slot], -PAD_TOP - 1)
        label:SetText(COLUMNS[self.mode][index])
    end
end

local function ColumnText(parent, slot)
    local text = UI.Text(parent, 13, UI.NUMBER_FONT)
    text:SetJustifyH("RIGHT")
    text.slot = slot
    return text
end


local function AddRunLines(entry)
    GameTooltip:AddLine(" ")
    GameTooltip:AddDoubleLine(L("hoa.addon.1_damage", Short(entry.damage)), L(entry.kills == 1 and "hoa.addon.1_kill" or "hoa.addon.1_kills", Thousands(entry.kills)), 1, 1, 1, 0.6, 0.6, 0.6)
end

local function SpellLineTooltip(line, entry)
    if VanillaBonk_LoadoutTooltip and VanillaBonk_LoadoutTooltip(line, entry.name, { damage = entry.damage, kills = entry.kills }) then
        return
    end
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    local r, g, b = 1, 1, 1
    if entry.evolved then
        r, g, b = 1, 0.5, 0
    end
    GameTooltip:AddDoubleLine(entry.name, entry.level > 0 and L("hoa.addon.rank_1", entry.level) or "", r, g, b, 0.6, 0.6, 0.6)
    AddRunLines(entry)
    GameTooltip:Show()
end

local function EffectLineTooltip(line, entry)
    local kind = UI.DamageType(entry.school)
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.name, kind.r, kind.g, kind.b)
    if kind.note then
        GameTooltip:AddLine(kind.note, 1, 0.82, 0, 1)
    end
    GameTooltip:AddLine(L("hoa.addon.applied_by_1", entry.parent.name), 0.6, 0.6, 0.6, 1)
    AddRunLines(entry)
    GameTooltip:Show()
end

local function HealLineTooltip(line, entry)
    GameTooltip:SetOwner(line, "ANCHOR_RIGHT")
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.healed"], Thousands(entry.healed), UI.HEAL_COLOR.r, UI.HEAL_COLOR.g, UI.HEAL_COLOR.b, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.absorbed"], Thousands(entry.absorbed), UI.ABSORB_COLOR.r, UI.ABSORB_COLOR.g, UI.ABSORB_COLOR.b, 1, 1, 1)
    GameTooltip:Show()
end

local function ShowLineTooltip(line)
    local entry = line.entry
    if not entry then
        return
    end
    line.track:SetVertexColor(0.25, 0.2, 0.05, 0.8)
    if entry.healed then
        HealLineTooltip(line, entry)
    elseif entry.parent then
        EffectLineTooltip(line, entry)
    else
        SpellLineTooltip(line, entry)
    end
end

local function HideLineTooltip()
    this.track:SetVertexColor(0, 0, 0, 0.55)
    GameTooltip:Hide()
end

panel.lines = {}
for index = 1, MAX_LINES do
    local line = CreateFrame("Frame", nil, panel)
    line:SetWidth(RIGHT_WIDTH)
    line.icon = line:CreateTexture(nil, "ARTWORK")
    UI.CropIcon(line.icon)
    line.track = line:CreateTexture(nil, "BACKGROUND")
    line.track:SetTexture(UI.FLAT)
    line.track:SetVertexColor(0, 0, 0, 0.55)
    line.parts = {}
    for part = 1, MAX_PARTS do
        local fill = line:CreateTexture(nil, "BORDER")
        fill:SetTexture(UI.FLAT)
        line.parts[part] = fill
    end
    line.name = UI.Text(line, 11)
    line.name:SetJustifyH("LEFT")
    line.damage = ColumnText(line, 1)
    line.share = ColumnText(line, 2)
    line.kills = ColumnText(line, 3)
    UI.Hover(line, function() ShowLineTooltip(this) end, HideLineTooltip)
    line:Hide()
    panel.lines[index] = line
end

panel.typeBar = CreateFrame("Frame", nil, panel)
panel.typeBar:SetWidth(RIGHT_WIDTH)
panel.typeBar:SetHeight(TYPE_BAR_HEIGHT)
panel.typeBar:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1 })
panel.typeBar:SetBackdropColor(0, 0, 0, 1)
panel.typeBar:SetBackdropBorderColor(0, 0, 0, 1)
panel.typeBar.parts = {}
panel.legend = {}

local function TypeSegment(index)
    local segment = panel.typeBar.parts[index]
    if not segment then
        segment = panel.typeBar:CreateTexture(nil, "ARTWORK")
        segment:SetTexture(UI.FLAT)
        segment:SetHeight(TYPE_BAR_HEIGHT - 2)
        panel.typeBar.parts[index] = segment
    end
    return segment
end

local function LegendEntry(index)
    local entry = panel.legend[index]
    if not entry then
        entry = CreateFrame("Frame", nil, panel)
        entry:SetHeight(LEGEND_LINE)
        entry.swatch = entry:CreateTexture(nil, "ARTWORK")
        entry.swatch:SetTexture(UI.FLAT)
        entry.swatch:SetWidth(7)
        entry.swatch:SetHeight(7)
        entry.swatch:SetPoint("LEFT", entry, "LEFT", 0, 0)
        entry.text = UI.Text(entry, 10)
        entry.text:SetPoint("LEFT", entry.swatch, "RIGHT", 3, 0)
        entry.text:SetTextColor(0.85, 0.85, 0.85)
        panel.legend[index] = entry
    end
    return entry
end

panel.footerRule = panel:CreateTexture(nil, "ARTWORK")
panel.footerRule:SetTexture(UI.FLAT)
panel.footerRule:SetHeight(1)
panel.footerRule:SetWidth((PANEL_WIDTH - 2 * PAD_X) / 2)
panel.footerRule:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.55)
panel.footerRuleRight = panel:CreateTexture(nil, "ARTWORK")
panel.footerRuleRight:SetTexture(UI.FLAT)
panel.footerRuleRight:SetHeight(1)
panel.footerRuleRight:SetWidth((PANEL_WIDTH - 2 * PAD_X) / 2)
panel.footerRuleRight:SetPoint("LEFT", panel.footerRule, "RIGHT", 0, 0)
panel.footerRuleRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.55, 1, 0.82, 0, 0)

local build = CreateFrame("Frame", nil, panel)
Summary.build = build
panel.build = build
build:SetHeight(FOOTER_HEIGHT)
build.glyphLabel = UI.Text(build, 10)
build.glyphLabel:SetPoint("LEFT", build, "LEFT", 0, 0)
build.glyphLabel:SetTextColor(0.78, 0.72, 0.56)
build.glyphLabel:SetText(L["hoa.addon.glyphs"])
build.glyphs = {}
for index = 1, 3 do
    local ring = UI.Ring(build, 20, true)
    ring.icon = UI.RingArt(ring, "")
    UI.Hover(ring, function()
        if VanillaBonk_GlyphTooltip then
            VanillaBonk_GlyphTooltip(this, this.glyphId)
        end
    end)
    build.glyphs[index] = ring
end
build.passiveLabel = UI.Text(build, 10)
build.passiveLabel:SetTextColor(0.78, 0.72, 0.56)
build.passiveLabel:SetText(L["hoa.addon.passives"])
build.passives = {}
for index = 1, 6 do
    local slot = UI.IconButton(build, 17)
    slot.index = index
    UI.Hover(slot, function()
        if VanillaBonk_PassiveTooltip then
            VanillaBonk_PassiveTooltip(this, this.index)
        end
    end)
    build.passives[index] = slot
end

panel.earned = UI.Text(panel, 11)
panel.earned:SetJustifyH("CENTER")

panel.done = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, panel, "UIPanelButtonTemplate"))
panel.done:SetWidth(BUTTON_WIDTH)
panel.done:SetHeight(22)
panel.done:SetText(L["hoa.addon.continue"])

local RECAP_WIDTH = PANEL_WIDTH - 2 * PAD_X
local RECAP_GRAPH_TOP = 22
local RECAP_GRAPH_HEIGHT = 84
local RECAP_LEGEND_GAP = 6
local RECAP_LEGEND_LINE = 15
local RECAP_COLUMN = 3
local RECAP_LINE_TOP = 6
local RECAP_LINE_THICKNESS = 2
local RECAP_TICK_MIN = 3
local RECAP_TICK_MAX = 24
local RECAP_TICK_WIDTH = 3
local RECAP_TICK_HOVER_WIDTH = 5
local RECAP_HOVER_REACH = 4
local RECAP_TOOLTIP_GAP = 10
local RECAP_SLOTS = 100
local RECAP_SECONDS = 10
local RECAP_SKULL = 18
local RECAP_GREEN = { 0.31, 0.82, 0.35 }
local RECAP_BOSS_COLOR = { 0.62, 0.26, 0.68 }
local RECAP_SOURCE_COLORS = {
    { 0.70, 0.24, 0.18 },
    { 0.86, 0.46, 0.16 },
    { 0.80, 0.64, 0.18 },
    { 0.27, 0.58, 0.80 },
    { 0.55, 0.55, 0.55 },
}

local recapFrame = CreateFrame("Frame", nil, panel)
Summary.recapFrame = recapFrame
recapFrame:SetWidth(RECAP_WIDTH)
recapFrame:Hide()

recapFrame.rule = recapFrame:CreateTexture(nil, "ARTWORK")
recapFrame.rule:SetTexture(UI.FLAT)
recapFrame.rule:SetHeight(1)
recapFrame.rule:SetWidth(RECAP_WIDTH / 2)
recapFrame.rule:SetPoint("TOPLEFT", recapFrame, "TOPLEFT", 0, 0)
recapFrame.rule:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.55)
recapFrame.ruleRight = recapFrame:CreateTexture(nil, "ARTWORK")
recapFrame.ruleRight:SetTexture(UI.FLAT)
recapFrame.ruleRight:SetHeight(1)
recapFrame.ruleRight:SetWidth(RECAP_WIDTH / 2)
recapFrame.ruleRight:SetPoint("LEFT", recapFrame.rule, "RIGHT", 0, 0)
recapFrame.ruleRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.55, 1, 0.82, 0, 0)

recapFrame.title = UI.Text(recapFrame, 12)
recapFrame.title:SetPoint("TOPLEFT", recapFrame, "TOPLEFT", 0, -8)
recapFrame.title:SetTextColor(1, 0.82, 0)
recapFrame.title:SetText(L["hoa.addon.your_last_10_seconds"])
recapFrame.summary = UI.Text(recapFrame, 11)
recapFrame.summary:SetPoint("LEFT", recapFrame.title, "RIGHT", 10, 0)
recapFrame.summary:SetTextColor(0.8, 0.8, 0.8)

local graph = CreateFrame("Frame", nil, recapFrame)
Summary.graph = graph
graph:SetWidth(RECAP_WIDTH)
graph:SetHeight(RECAP_GRAPH_HEIGHT)
graph:SetPoint("TOPLEFT", recapFrame, "TOPLEFT", 0, -RECAP_GRAPH_TOP)
graph:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1 })
graph:SetBackdropColor(0, 0, 0, 0.5)
graph:SetBackdropBorderColor(0, 0, 0, 1)
graph.columns = {}
graph.ticks = {}
graph.inner = RECAP_WIDTH - 2

for second = 2, RECAP_SECONDS - 2, 2 do
    local x = 1 + graph.inner * second / RECAP_SECONDS
    local line = graph:CreateTexture(nil, "BORDER")
    line:SetTexture(UI.FLAT)
    line:SetVertexColor(1, 1, 1, 0.07)
    line:SetWidth(1)
    line:SetPoint("TOPLEFT", graph, "TOPLEFT", x, -1)
    line:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", x, 1)
    local label = UI.Text(graph, 9, UI.NUMBER_FONT)
    label:SetPoint("TOPLEFT", graph, "TOPLEFT", x + 3, -3)
    label:SetTextColor(0.47, 0.47, 0.47)
    label:SetText("-" .. (RECAP_SECONDS - second) .. "s")
end

graph.maxLabel = UI.Text(graph, 9, UI.NUMBER_FONT)
graph.maxLabel:SetPoint("TOPLEFT", graph, "TOPLEFT", 5, -RECAP_LINE_TOP - 3)
graph.maxLabel:SetTextColor(0.6, 0.9, 0.6)

graph.skull = graph:CreateTexture(nil, "OVERLAY")
graph.skull:SetTexture("Interface\\TargetingFrame\\UI-TargetingFrame-Skull")
graph.skull:SetWidth(RECAP_SKULL)
graph.skull:SetHeight(RECAP_SKULL)

for index = 1, floor(graph.inner / RECAP_COLUMN) do
    local column = {}
    column.area = graph:CreateTexture(nil, "ARTWORK")
    column.area:SetTexture(UI.FLAT)
    column.area:SetVertexColor(RECAP_GREEN[1], RECAP_GREEN[2], RECAP_GREEN[3], 0.18)
    column.area:SetWidth(RECAP_COLUMN)
    column.top = graph:CreateTexture(nil, "ARTWORK")
    column.top:SetTexture(UI.FLAT)
    column.top:SetVertexColor(RECAP_GREEN[1], RECAP_GREEN[2], RECAP_GREEN[3], 1)
    column.top:SetWidth(RECAP_COLUMN)
    graph.columns[index] = column
end

recapFrame.legend = {}

local function RecapTick(index)
    local tick = graph.ticks[index]
    if not tick then
        tick = graph:CreateTexture(nil, "OVERLAY")
        tick:SetTexture(UI.FLAT)
        tick:SetWidth(RECAP_TICK_WIDTH)
        graph.ticks[index] = tick
    end
    return tick
end

local function RecapLegend(index)
    local entry = recapFrame.legend[index]
    if not entry then
        entry = CreateFrame("Frame", nil, recapFrame)
        entry:SetHeight(RECAP_LEGEND_LINE)
        entry.swatch = entry:CreateTexture(nil, "ARTWORK")
        entry.swatch:SetTexture(UI.FLAT)
        entry.swatch:SetWidth(8)
        entry.swatch:SetHeight(8)
        entry.swatch:SetPoint("LEFT", entry, "LEFT", 0, 0)
        entry.icon = entry:CreateTexture(nil, "ARTWORK")
        entry.icon:SetWidth(13)
        entry.icon:SetHeight(13)
        entry.icon:SetPoint("LEFT", entry.swatch, "RIGHT", 4, 0)
        UI.CropIcon(entry.icon)
        entry.text = UI.Text(entry, 10)
        entry.text:SetPoint("LEFT", entry.icon, "RIGHT", 4, 0)
        entry.text:SetTextColor(0.85, 0.85, 0.85)
        recapFrame.legend[index] = entry
    end
    return entry
end

local function RecapColor(source)
    if source and (source.kind == "b" or source.kind == "m") then
        return RECAP_BOSS_COLOR
    end
    return RECAP_SOURCE_COLORS[source and source.index or 5] or RECAP_SOURCE_COLORS[5]
end

local function RecapLineY(permille)
    local floorY = 1 + RECAP_LINE_THICKNESS / 2
    local span = RECAP_GRAPH_HEIGHT - RECAP_LINE_TOP - floorY
    return floorY + span * max(0, min(1000, permille)) / 1000
end

local function RecapSlotX(slot)
    return 1 + graph.inner * min(RECAP_SLOTS, slot) / RECAP_SLOTS
end

function Summary:HealthAtSlot(slot)
    local health = self.recap.startHealth
    for _, event in ipairs(self.recap.events) do
        if event.slot > slot then
            break
        end
        health = event.health
    end
    return health
end

function Summary:DrawRecapLine()
    local count = getn(graph.columns)
    local previous
    for index, column in ipairs(graph.columns) do
        local slot = (index - 0.5) / count * RECAP_SLOTS
        local y = RecapLineY(index == count and 0 or self:HealthAtSlot(slot))
        local x = 1 + (index - 1) * RECAP_COLUMN
        column.area:ClearAllPoints()
        column.area:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", x, 1)
        column.area:SetHeight(max(0.5, y - 1))
        if y <= RecapLineY(0) then
            column.area:Hide()
        else
            column.area:Show()
        end
        local low = min(y, previous or y)
        local high = max(y, previous or y)
        column.top:ClearAllPoints()
        column.top:SetPoint("BOTTOMLEFT", graph, "BOTTOMLEFT", x, low - RECAP_LINE_THICKNESS / 2)
        column.top:SetHeight(high - low + RECAP_LINE_THICKNESS)
        previous = y
    end
end

function Summary:DrawRecapTicks()
    local biggest = 1
    for _, event in ipairs(self.recap.events) do
        if event.source > 0 then
            biggest = max(biggest, event.amount)
        end
    end
    for index, event in ipairs(self.recap.events) do
        local tick = RecapTick(index)
        local color = event.source == 0 and RECAP_GREEN or RecapColor(self.recap.sources[event.source])
        tick:SetVertexColor(color[1], color[2], color[3], 1)
        tick:SetHeight(max(RECAP_TICK_MIN, min(RECAP_TICK_MAX, RECAP_TICK_MAX * event.amount / biggest)))
        tick:ClearAllPoints()
        tick:SetPoint("BOTTOM", graph, "BOTTOMLEFT", RecapSlotX(event.slot), 2)
        tick:Show()
    end
    for index = getn(self.recap.events) + 1, getn(graph.ticks) do
        graph.ticks[index]:Hide()
    end
    local count = getn(self.recap.events)
    local lastAlive = count > 1 and self.recap.events[count - 1].health or self.recap.startHealth
    graph.skull:ClearAllPoints()
    graph.skull:SetPoint("CENTER", graph, "BOTTOMLEFT", RecapSlotX(RECAP_SLOTS) - RECAP_SKULL / 2 - 3, RecapLineY(lastAlive) + RECAP_SKULL / 2 + 3)
end

local function BlowText(source)
    if source.spell == "Melee" then
        return L("hoa.addon.1_s_melee_hit", source.name)
    end
    return source.spell ~= "" and L("hoa.addon.1_s_2", source.name, source.spell) or source.name
end

function Summary:HealthPoints(permille)
    return floor(self.recap.maxHealth * max(0, permille) / 1000 + 0.5)
end

local function SecondsBeforeDeath(slot)
    if slot >= RECAP_SLOTS then
        return L["hoa.addon.moment_of_death"]
    end
    return format(L["hoa.addon.1fs_before_death"], (RECAP_SLOTS - slot) * RECAP_SECONDS / RECAP_SLOTS)
end

function Summary:HealthLine(permille)
    return format(L["hoa.addon.health_s_s_d"], Thousands(self:HealthPoints(permille)), Thousands(self.recap.maxHealth), floor(max(0, permille) / 10 + 0.5))
end

function Summary:EventsNearX(x)
    local nearest, distance
    for _, event in ipairs(self.recap.events) do
        local gap = abs(RecapSlotX(event.slot) - x)
        if gap <= RECAP_HOVER_REACH and (not distance or gap < distance) then
            nearest, distance = event.slot, gap
        end
    end
    local found = {}
    if not nearest then
        return found, nil
    end
    for index, event in ipairs(self.recap.events) do
        if event.slot == nearest then
            tinsert(found, index)
        end
    end
    return found, nearest
end

function Summary:AddEventLines(indexes)
    local count = getn(self.recap.events)
    for _, index in ipairs(indexes) do
        local event = self.recap.events[index]
        if event.source == 0 then
            GameTooltip:AddDoubleLine(L["hoa.addon.healed"], "+" .. Thousands(event.amount), 0.85, 0.85, 0.85, RECAP_GREEN[1], RECAP_GREEN[2], RECAP_GREEN[3])
        else
            local source = self.recap.sources[event.source]
            local color = RecapColor(source)
            GameTooltip:AddDoubleLine(source and BlowText(source) or L["hoa.addon.unknown"], "-" .. Thousands(event.amount), color[1] + 0.25, color[2] + 0.25, color[3] + 0.25, 1, 0.42, 0.31)
        end
        if index == count and self.recap.overkill > 0 then
            GameTooltip:AddLine(L("hoa.addon.killing_blow_1_overkill", Thousands(self.recap.overkill)), 1, 0.42, 0.31)
        end
    end
    GameTooltip:AddLine(self:HealthLine(self.recap.events[indexes[getn(indexes)]].health), 1, 1, 1)
end

local function HighlightTicks(indexes)
    local lit = {}
    for _, index in ipairs(indexes) do
        lit[index] = true
    end
    for index, tick in ipairs(graph.ticks) do
        tick:SetWidth(lit[index] and RECAP_TICK_HOVER_WIDTH or RECAP_TICK_WIDTH)
    end
end

graph.hover = CreateFrame("Frame", nil, graph)
graph.hover:SetAllPoints(graph)
graph.hover:EnableMouse(true)

graph.cursor = graph.hover:CreateTexture(nil, "OVERLAY")
graph.cursor:SetTexture(UI.FLAT)
graph.cursor:SetVertexColor(1, 1, 1, 0.3)
graph.cursor:SetWidth(1)
graph.cursor:Hide()

graph.dot = graph.hover:CreateTexture(nil, "OVERLAY")
graph.dot:SetTexture(UI.FLAT)
graph.dot:SetVertexColor(1, 1, 1, 1)
graph.dot:SetWidth(5)
graph.dot:SetHeight(5)
graph.dot:Hide()

local function PlaceRecapTooltip(x, y)
    local half = GameTooltip:GetHeight() / 2
    y = max(half, min(RECAP_GRAPH_HEIGHT - half, y))
    GameTooltip:ClearAllPoints()
    if x < graph.inner / 2 then
        GameTooltip:SetPoint("LEFT", graph, "BOTTOMLEFT", x + RECAP_TOOLTIP_GAP, y)
    else
        GameTooltip:SetPoint("RIGHT", graph, "BOTTOMLEFT", x - RECAP_TOOLTIP_GAP, y)
    end
end

function Summary:ShowRecapHover(x)
    local indexes, eventSlot = self:EventsNearX(x)
    local slot = eventSlot or max(0, min(RECAP_SLOTS, (x - 1) * RECAP_SLOTS / graph.inner))
    local permille = eventSlot and self.recap.events[indexes[getn(indexes)]].health or self:HealthAtSlot(slot)
    local key = eventSlot and ("e" .. eventSlot) or ("s" .. floor(slot))
    local lineX = eventSlot and RecapSlotX(eventSlot) or x
    graph.cursor:ClearAllPoints()
    graph.cursor:SetPoint("TOP", graph, "TOPLEFT", lineX, -1)
    graph.cursor:SetPoint("BOTTOM", graph, "BOTTOMLEFT", lineX, 1)
    graph.cursor:Show()
    graph.dot:ClearAllPoints()
    graph.dot:SetPoint("CENTER", graph, "BOTTOMLEFT", lineX, RecapLineY(permille))
    graph.dot:Show()
    if graph.hover.key ~= key then
        graph.hover.key = key
        HighlightTicks(indexes)
        GameTooltip:SetOwner(graph.hover, "ANCHOR_NONE")
        GameTooltip:AddLine(SecondsBeforeDeath(slot), 1, 0.82, 0)
        if eventSlot then
            self:AddEventLines(indexes)
        else
            GameTooltip:AddLine(self:HealthLine(permille), 1, 1, 1)
        end
        GameTooltip:Show()
    end
    PlaceRecapTooltip(lineX, RecapLineY(permille))
end

local function HideRecapHover()
    graph.hover.key = nil
    graph.cursor:Hide()
    graph.dot:Hide()
    HighlightTicks({})
    GameTooltip:Hide()
end

graph.hover:SetScript("OnUpdate", function()
    if not MouseIsOver(this) then
        if this.key then
            HideRecapHover()
        end
        return
    end
    local cursorX = GetCursorPosition() / graph:GetEffectiveScale()
    Summary:ShowRecapHover(cursorX - graph:GetLeft())
end)

graph.hover:SetScript("OnHide", HideRecapHover)

function Summary:KillerText()
    local killer = self.recap.sources[self.recap.killer]
    if not killer then
        return ""
    end
    local blow = BlowText(killer)
    local numbers = Thousands(self.recap.killAmount)
    if self.recap.overkill > 0 then
        numbers = L("hoa.addon.1_2_overkill", numbers, Thousands(self.recap.overkill))
    end
    return L("hoa.addon.killed_by_cffff6a50_1_2_r", blow, numbers)
end

function Summary:FillRecapLegend()
    local x, row = 0, 0
    local shown = 0
    for index = 1, 5 do
        local source = self.recap.sources[index]
        if source then
            shown = shown + 1
            local entry = RecapLegend(shown)
            local color = RecapColor(source)
            entry.swatch:SetVertexColor(color[1], color[2], color[3])
            entry.icon:SetTexture(UI.ICON_PATH .. source.icon)
            local spell = (source.spell ~= "" and source.spell ~= "Melee") and (" |cff999999" .. source.spell .. "|r") or ""
            entry.text:SetText(source.name .. spell .. " |cffffffff" .. Thousands(source.damage) .. "|r")
            local width = 29 + entry.text:GetStringWidth()
            if x > 0 and x + width > RECAP_WIDTH then
                x = 0
                row = row + 1
            end
            entry:SetWidth(width)
            entry:ClearAllPoints()
            entry:SetPoint("TOPLEFT", recapFrame, "TOPLEFT", x, -(RECAP_GRAPH_TOP + RECAP_GRAPH_HEIGHT + RECAP_LEGEND_GAP + row * RECAP_LEGEND_LINE))
            entry:Show()
            x = x + width + 16
        end
    end
    for index = shown + 1, getn(recapFrame.legend) do
        recapFrame.legend[index]:Hide()
    end
    return row + 1
end

function Summary:LayoutRecap(y)
    recapFrame.summary:SetText(L("hoa.addon.took_cffffffff_1_r_healed_cffffffff_2_r", Thousands(self.recap.taken), Thousands(self.recap.healed)) .. self:KillerText())
    graph.maxLabel:SetText(Thousands(self.recap.maxHealth))
    self:DrawRecapLine()
    self:DrawRecapTicks()
    local rows = self:FillRecapLegend()
    local height = RECAP_GRAPH_TOP + RECAP_GRAPH_HEIGHT + RECAP_LEGEND_GAP + rows * RECAP_LEGEND_LINE
    recapFrame:SetHeight(height)
    recapFrame:ClearAllPoints()
    recapFrame:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -y)
    recapFrame:Show()
    return y + height
end

function Summary:Close()
    if self.screen.closing or not self.screen:IsShown() then
        return
    end
    self.screen.closing = true
    PlaySound("igMainMenuOptionCheckBoxOn")
end

panel.done:SetScript("OnClick", function() Summary:Close() end)

screen:SetScript("OnUpdate", function()
    local want = this.closing and 0 or 1
    if this.alpha ~= want then
        local step = arg1 / FADE
        this.alpha = want > this.alpha and min(want, this.alpha + step) or max(want, this.alpha - step)
        this:SetAlpha(this.alpha)
        if this.alpha <= 0 then
            this:Hide()
        end
    end
end)

screen:SetScript("OnHide", function()
    this.closing = false
end)

local function WeaponParts(weapon)
    local parts = {}
    local dots = 0
    for _, sub in ipairs(weapon.subs) do
        dots = dots + sub.damage
    end
    local direct = weapon.damage - dots
    if direct > 0 or getn(weapon.subs) == 0 then
        tinsert(parts, { key = weapon.school, damage = max(0, direct) })
    end
    for _, sub in ipairs(weapon.subs) do
        if sub.damage > 0 then
            tinsert(parts, { key = sub.school, damage = sub.damage })
        end
    end
    return parts
end

local function DrawBar(line, x, width, fraction, parts, total)
    line.track:ClearAllPoints()
    line.track:SetPoint("TOPLEFT", line, "TOPLEFT", x, 0)
    line.track:SetWidth(max(1, width))
    line.track:SetHeight(line:GetHeight())
    local filled = 0
    local barWidth = width * fraction
    for index, fill in ipairs(line.parts) do
        local part = parts[index]
        local partWidth = (part and total > 0) and barWidth * part.damage / total or 0
        if partWidth >= 0.5 then
            UI.ShadeBar(fill, part.color or UI.DamageType(part.key), filled / barWidth, (filled + partWidth) / barWidth, BAR_BRIGHTNESS)
            fill:ClearAllPoints()
            fill:SetPoint("TOPLEFT", line.track, "TOPLEFT", filled, 0)
            fill:SetWidth(partWidth)
            fill:SetHeight(line:GetHeight())
            fill:Show()
            filled = filled + partWidth
        else
            fill:Hide()
        end
    end
end

local function FillLine(line, entry, top, total, y)
    local sub = entry.parent ~= nil
    local height = sub and SUB_HEIGHT or ROW_HEIGHT
    local indent = sub and SUB_INDENT or 0
    line.entry = entry
    line:SetHeight(height)
    line:ClearAllPoints()
    line:SetPoint("TOPLEFT", panel, "TOPLEFT", RIGHT_X, -y)
    line.icon:SetTexture(UI.ICON_PATH .. entry.icon)
    line.icon:SetWidth(height)
    line.icon:SetHeight(height)
    line.icon:ClearAllPoints()
    line.icon:SetPoint("LEFT", line, "LEFT", indent, 0)

    local columnsWidth = 3 * COLUMN_WIDTH
    local barX = indent + height + 5
    local fullWidth = RIGHT_WIDTH - columnsWidth - ROW_HEIGHT - 11
    local barWidth = RIGHT_WIDTH - columnsWidth - barX - 6
    local parts
    if entry.healed then
        parts = { { color = UI.HEAL_COLOR, damage = entry.healed }, { color = UI.ABSORB_COLOR, damage = entry.absorbed } }
    elseif sub then
        parts = { { key = entry.school, damage = entry.damage } }
    else
        parts = WeaponParts(entry)
    end
    DrawBar(line, barX, barWidth, top > 0 and min(1, entry.damage / top * fullWidth / barWidth) or 0, parts, entry.damage)

    line.name:ClearAllPoints()
    line.name:SetPoint("LEFT", line, "LEFT", barX + 5, 0)
    line.name:SetFont(UI.FONT, sub and 10 or 11)
    for _, text in ipairs({ line.damage, line.share, line.kills }) do
        text:SetFont(UI.NUMBER_FONT, sub and 11 or 13)
        text:ClearAllPoints()
        text:SetPoint("RIGHT", line, "RIGHT", -COLUMN_OFFSETS[text.slot], 0)
        text:SetWidth(COLUMN_WIDTH)
        text:SetHeight(height)
    end
    if entry.healed then
        line.name:SetText("|cffffffff" .. entry.name .. "|r")
        line.damage:SetTextColor(1, 1, 1)
        line.share:SetTextColor(1, 1, 1)
        line.kills:SetTextColor(0.78, 0.78, 0.78)
        line.damage:SetText(Short(entry.healed))
        line.share:SetText(Short(entry.absorbed))
        line.kills:SetText(Percent(entry.damage, total) .. "%")
        line:Show()
        return height + ROW_GAP
    elseif sub then
        line.name:SetText("|cffc8c8c8" .. entry.name .. "|r")
        line.damage:SetTextColor(0.78, 0.78, 0.78)
        line.kills:SetTextColor(0.78, 0.78, 0.78)
    else
        local rank = entry.level > 0 and ("  |cffc8c8c8" .. L("hoa.addon.rank_1", entry.level) .. "|r") or ""
        local color = entry.evolved and "|cffff8000" or "|cffffffff"
        line.name:SetText(color .. entry.name .. "|r" .. rank)
        line.damage:SetTextColor(1, 1, 1)
        line.kills:SetTextColor(1, 1, 1)
    end
    line.share:SetTextColor(0.78, 0.78, 0.78)
    line.damage:SetText(Short(entry.damage))
    line.share:SetText(Percent(entry.damage, total) .. "%")
    line.kills:SetText(Thousands(entry.kills))
    line:Show()
    return height + (sub and SUB_GAP or ROW_GAP)
end

function Summary:TypeTotals()
    local byKey, list = {}, {}
    for _, weapon in ipairs(self.weapons) do
        for _, part in ipairs(WeaponParts(weapon)) do
            if not byKey[part.key] then
                byKey[part.key] = { key = part.key, damage = 0 }
                tinsert(list, byKey[part.key])
            end
            byKey[part.key].damage = byKey[part.key].damage + part.damage
        end
    end
    table.sort(list, function(a, b) return a.damage > b.damage end)
    for _, entry in ipairs(list) do
        local kind = UI.DamageType(entry.key)
        entry.color = kind
        entry.name = kind.name
    end
    return list
end

function Summary:SupportTotals()
    local healed, absorbed = 0, 0
    for _, source in ipairs(self.support) do
        healed = healed + source.healed
        absorbed = absorbed + source.absorbed
    end
    local list = {}
    for _, entry in ipairs({ { UI.HEAL_COLOR, L["hoa.addon.healed"], healed }, { UI.ABSORB_COLOR, L["hoa.addon.absorbed"], absorbed } }) do
        if entry[3] > 0 then
            tinsert(list, { color = entry[1], name = entry[2], damage = entry[3] })
        end
    end
    return list
end

local function FillTypes(y, total, types)
    panel.typeBar:ClearAllPoints()
    panel.typeBar:SetPoint("TOPLEFT", panel, "TOPLEFT", RIGHT_X, -y)
    local x = 1
    local width = RIGHT_WIDTH - 2
    for index, entry in ipairs(types) do
        local segment = TypeSegment(index)
        local segmentWidth = total > 0 and width * entry.damage / total or 0
        UI.ShadeBar(segment, entry.color, (x - 1) / width, (x - 1 + segmentWidth) / width, BAR_BRIGHTNESS)
        segment:ClearAllPoints()
        segment:SetPoint("TOPLEFT", panel.typeBar, "TOPLEFT", x, -1)
        segment:SetWidth(max(0.5, segmentWidth))
        if segmentWidth >= 0.5 then
            segment:Show()
        else
            segment:Hide()
        end
        x = x + segmentWidth
    end
    for index = getn(types) + 1, getn(panel.typeBar.parts) do
        panel.typeBar.parts[index]:Hide()
    end

    local legendX, legendY = 0, y + TYPE_BAR_HEIGHT + 4
    for index, entry in ipairs(types) do
        local legend = LegendEntry(index)
        legend.swatch:SetVertexColor(entry.color.r, entry.color.g, entry.color.b)
        legend.text:SetText(entry.name .. " " .. Percent(entry.damage, total) .. "%")
        local width = 10 + legend.text:GetStringWidth()
        if legendX > 0 and legendX + width > RIGHT_WIDTH then
            legendX = 0
            legendY = legendY + LEGEND_LINE
        end
        legend:SetWidth(width)
        legend:ClearAllPoints()
        legend:SetPoint("TOPLEFT", panel, "TOPLEFT", RIGHT_X + legendX, -legendY)
        legend:Show()
        legendX = legendX + width + 9
    end
    for index = getn(types) + 1, getn(panel.legend) do
        panel.legend[index]:Hide()
    end
    return legendY + LEGEND_LINE
end

function Summary:FillBuild()
    local x = build.glyphLabel:GetStringWidth() + 6
    local taken = VanillaBonk_GlyphsTaken and VanillaBonk_GlyphsTaken() or {}
    local shown = 0
    for index, ring in ipairs(build.glyphs) do
        local glyph = VanillaBonkGlyphInfo and VanillaBonkGlyphInfo[taken[index]]
        if glyph then
            ring.icon:SetTexture(UI.ICON_PATH .. (glyph.icon ~= "" and glyph.icon or "INV_Misc_QuestionMark"))
            ring.glyphId = taken[index]
            ring:ClearAllPoints()
            ring:SetPoint("LEFT", build, "LEFT", x, 0)
            ring:Show()
            x = x + 23
            shown = shown + 1
        else
            ring:Hide()
        end
    end
    if shown == 0 then
        build.glyphLabel:Hide()
        x = 0
    else
        build.glyphLabel:Show()
        x = x + 10
    end
    build.passiveLabel:ClearAllPoints()
    build.passiveLabel:SetPoint("LEFT", build, "LEFT", x, 0)
    if getn(self.passives) > 0 then
        build.passiveLabel:Show()
        x = x + build.passiveLabel:GetStringWidth() + 6
    else
        build.passiveLabel:Hide()
    end
    for index, slot in ipairs(build.passives) do
        if self.passives[index] then
            slot.icon:SetTexture(UI.ICON_PATH .. self.passives[index])
            slot:ClearAllPoints()
            slot:SetPoint("LEFT", build, "LEFT", x, 0)
            slot:Show()
            x = x + 20
        else
            slot:Hide()
        end
    end
    build:SetWidth(max(1, x))
    return x
end

function Summary:FillStats()
    local _, class = UnitClass("player")
    local stats = {
        { "INV_Misc_PocketWatch_01", L["hoa.addon.time"], UI.FormatTime(self.run.seconds) },
        { nil, L["hoa.addon.level"], self.run.level or "1" },
        { "INV_Misc_Bone_HumanSkull_01", L["hoa.addon.kills_2"], Thousands(self.run.kills) },
        { "Ability_Warrior_Challange", L["hoa.addon.elites"], Thousands(self.run.elites) },
        { "Ability_Rogue_Eviscerate", L["hoa.addon.mini_bosses"], Thousands(self.run.minis) },
        { "INV_Misc_Head_Dragon_01", L["hoa.addon.stage_bosses"], Thousands(self.run.bosses) },
        { "INV_Shield_06", L["hoa.addon.damage_taken"], "|cffff5a4a" .. Thousands(self.run.damageTaken) .. "|r" },
    }
    for index, stat in ipairs(panel.stats) do
        local data = stats[index]
        if data[1] then
            stat.icon:SetTexture(UI.ICON_PATH .. data[1])
            UI.CropIcon(stat.icon)
        else
            UI.SetRoundClassCrest(stat.icon, class)
        end
        stat.label:SetText(data[2])
        stat.value:SetText(data[3])
    end
    panel.art:SetTexture("Interface\\TalentFrame\\" .. (CLASS_ART[class or ""] or "MageArcane") .. "-TopLeft")
    UI.TalentArtCoords(panel.art, PANEL_WIDTH - 10, panel:GetHeight() - 10)
end

function Summary:Place()
    local level = (self.run.levelName and self.run.levelName ~= "") and self.run.levelName or self.run.difficulty
    if level and level ~= "" then
        return self.run.map .. " (" .. level .. ")"
    end
    return self.run.map ~= "" and self.run.map or L["hoa.addon.the_arena"]
end

function Summary:FillBestLevel()
    local best = tonumber(self.run.bestLevel or "") or 0
    if self.run.victory and best > (tonumber(self.run.bestBefore or "") or 0) then
        panel.best:SetText(L("hoa.addon.cff40ff40new_best_1_r", self.run.levelName or ""))
    else
        panel.best:SetText("")
    end
end

function Summary:FillHeading()
    local color
    if self.run.victory then
        color = TITLE_VICTORY
        panel.title:SetText(L["hoa.addon.victory"])
        local finale = tonumber(self.run.finaleSeconds or "") or 0
        panel.subtitle:SetText(finale > 0 and L("hoa.addon.you_cleared_1_and_survived_2_in_the_finale", self:Place(), UI.FormatTime(finale)) or
            L("hoa.addon.you_cleared_1_in_2", self:Place(), UI.FormatTime(self.run.seconds)))
    elseif self.run.wentHome then
        color = TITLE_HOME
        panel.title:SetText(L["hoa.addon.run_complete"])
        panel.subtitle:SetText(L("hoa.addon.you_left_1_on_stage_2_after_3", self:Place(), self.run.stage or "1", UI.FormatTime(self.run.seconds)))
    else
        color = TITLE_DEFEAT
        panel.title:SetText(L["hoa.addon.defeat"])
        panel.subtitle:SetText(L("hoa.addon.you_fell_on_stage_1_in_2_after_3", self.run.stage or "1", self:Place(), UI.FormatTime(self.run.seconds)))
    end
    panel.title:SetTextColor(color[1], color[2], color[3])
    self:FillBestLevel()
    if self.run.victory or self.run.wentHome then
        screen.wound:Hide()
    else
        screen.wound:Show()
    end

    local shards = tonumber(self.run.shards or "") or 0
    local tickets = "|cffc080ff" .. shards .. (shards == 1 and L["hoa.addon.darkmoon_ticket"] or L["hoa.addon.darkmoon_tickets"]) .. "|r"
    if self.run.wentHome then
        panel.earned:SetText(L("hoa.addon.you_earned_1_2_and_the_gear_in_the_extraction_vault", UI.FormatGold(self.run.gold), tickets))
    else
        panel.earned:SetText(L("hoa.addon.you_earned_1_and_2", UI.FormatGold(self.run.gold), tickets))
    end
end

local function LayoutFooter(y, buildWidth)
    panel.footerRule:ClearAllPoints()
    panel.footerRule:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -y)
    y = y + 8
    build:ClearAllPoints()
    build:SetPoint("TOPLEFT", panel, "TOPLEFT", PAD_X, -y)
    panel.done:ClearAllPoints()
    panel.done:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -PAD_X, -y - 1)
    local left = PAD_X + buildWidth + 12
    local right = PANEL_WIDTH - PAD_X - BUTTON_WIDTH - 12
    panel.earned:SetWidth(max(80, right - left))
    panel.earned:ClearAllPoints()
    panel.earned:SetPoint("LEFT", panel, "TOPLEFT", left, -y - FOOTER_HEIGHT / 2)
    return y + FOOTER_HEIGHT
end

function Summary:ModeEntries()
    local entries = {}
    if self.mode == MODE_HEALING then
        for _, source in ipairs(self.support) do
            tinsert(entries, source)
        end
        return entries
    end
    for _, weapon in ipairs(self.weapons) do
        tinsert(entries, weapon)
        for _, sub in ipairs(weapon.subs) do
            tinsert(entries, sub)
        end
    end
    return entries
end

function Summary:RenderLines()
    local entries = self:ModeEntries()
    local total, top = 0, 0
    for _, entry in ipairs(entries) do
        if not entry.parent then
            total = total + entry.damage
            top = max(top, entry.damage)
        end
    end

    local y = PAD_TOP + HEADER_HEIGHT
    for index, line in ipairs(panel.lines) do
        local entry = entries[index]
        if entry then
            y = y + FillLine(line, entry, top, total, y)
        else
            line.entry = nil
            line:Hide()
        end
    end

    local empty = getn(entries) == 0
    if empty then
        panel.empty:SetText(self.mode == MODE_HEALING and L["hoa.addon.no_healing_or_absorbs_this_run"] or L["hoa.addon.no_damage_this_run"])
        panel.empty:Show()
        y = y + 20
    else
        panel.empty:Hide()
    end
    local types = self.mode == MODE_HEALING and self:SupportTotals() or self:TypeTotals()
    if empty then
        panel.typeBar:Hide()
    else
        panel.typeBar:Show()
    end
    return FillTypes(y + 3, total, types)
end

function Summary:Render()
    self:ShowTabs()
    self:RenderLines()
end

function Summary:ShowSummary()
    if VanillaBonkResults then
        VanillaBonkResults:Hide()
    end

    self:FillHeading()

    table.sort(self.weapons, function(a, b) return a.damage > b.damage end)
    for _, weapon in ipairs(self.weapons) do
        table.sort(weapon.subs, function(a, b) return a.damage > b.damage end)
        for _, sub in ipairs(weapon.subs) do
            sub.parent = weapon
        end
    end
    table.sort(self.support, function(a, b) return a.damage > b.damage end)

    self.mode = MODE_HEALING
    local tallest = self:RenderLines()
    self.mode = MODE_DAMAGE
    tallest = max(tallest, self:RenderLines())
    self:ShowTabs()

    local columnBottom = max(tallest, PAD_TOP + STATS_TOP + 7 * STAT_ROW)
    local divider = columnBottom - PAD_TOP
    panel.divider:SetHeight(divider / 2)
    panel.dividerLow:SetHeight(divider / 2)
    local y = columnBottom + 12
    if not self.run.victory and not self.run.wentHome and self.recap.events and getn(self.recap.events) > 0 then
        y = self:LayoutRecap(y) + 10
    else
        recapFrame:Hide()
    end
    y = LayoutFooter(y, self:FillBuild())
    panel:SetHeight(y + PAD_BOTTOM)
    self:FillStats()

    screen.closing = false
    screen.alpha = 0
    screen:SetAlpha(0)
    screen:Show()
end

local function DamageTypeFor(name, icon)
    return UI.DAMAGE_TYPE_BY_KEYWORD[name or ""] or UI.DamageTypeFromIcon(icon)
end

UI.ListenHoa({
    HOA_LOADOUT = function(loadout)
        Summary:ApplyLoadout({ false, loadout.entries, loadout.spell_slots, loadout.passive_slots })
    end,
    HOA_DEATH_RECAP = function(recap)
        Summary:ApplyDeathRecap({
            false, recap.max_health, recap.start_health, recap.killer, recap.kill_amount, recap.overkill, recap.taken,
            recap.healed,
        })
    end,
    HOA_DEATH_SOURCE = function(source)
        Summary:ApplyDeathSource({ false, source.index, source.icon, source.name, source.spell, source.kind, source.damage })
    end,
    HOA_DEATH_EVENTS = function(events)
        Summary:ApplyDeathEvents({ false, events.text })
    end,
    HOA_RUN_SUMMARY = function(summary)
        Summary:ApplyRunSummary({ false, summary.damage_taken, summary.elites, summary.minis, summary.bosses })
    end,
    HOA_SUMMARY_WEAPON = function(weapon)
        Summary:ApplySummaryWeapon({
            false, weapon.icon, weapon.name, weapon.level, weapon.max_level, weapon.evolved and "1" or "0",
            weapon.damage, weapon.kills, weapon.school,
        })
    end,
    HOA_SUMMARY_SPELL = function(spell)
        Summary:ApplySummarySpell({ false, spell.icon, spell.name, spell.damage, spell.kills })
    end,
    HOA_SUMMARY_END = function()
        Summary:ShowSummary()
    end,
    HOA_RUN_SUPPORT = function(state)
        Summary:ApplySupport({ false, state.text })
    end,
})

Summary:OnRunStart(function(start)
    Summary.run.map = start.map_name or ""
    Summary.run.difficulty = start.difficulty or ""
    Summary.passives = {}
    Summary.support = {}
    Summary.recap = {}
    Summary.screen:Hide()
end):OnRunEnd(function(ending)
    Summary.run = {
        map = Summary.run.map or "", difficulty = Summary.run.difficulty or "",
        wentHome = ending.went_home, seconds = ending.seconds, kills = ending.kills, gold = ending.gold,
        level = ending.player_level, stage = ending.stage, shards = ending.shards,
        victory = ending.victory, bestLevel = ending.best_level, bestBefore = ending.best_before,
        levelName = ending.level_name, finaleSeconds = ending.finale_seconds,
    }
    Summary.weapons = {}
end)

function Summary:ApplyDeathRecap(f)
    self.recap = {
        maxHealth = tonumber(f[2]) or 0,
        startHealth = tonumber(f[3]) or 1000,
        killer = tonumber(f[4]) or 0,
        killAmount = tonumber(f[5]) or 0,
        overkill = tonumber(f[6]) or 0,
        taken = tonumber(f[7]) or 0,
        healed = tonumber(f[8]) or 0,
        sources = {},
        events = {},
    }
end

function Summary:ApplyDeathSource(f)
    local index = tonumber(f[2])
    if not self.recap.sources or not index then
        return
    end
    self.recap.sources[index] = {
        index = index,
        icon = f[3] ~= "" and f[3] or "INV_Misc_QuestionMark",
        name = f[4] or "",
        spell = f[5] or "",
        kind = f[6] or "",
        damage = tonumber(f[7]) or 0,
    }
end

function Summary:ApplyDeathEvents(f)
    if not self.recap.events then
        return
    end
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        local parts = UI.Split(item, ":")
        local slot, source, amount, health = tonumber(parts[1]), tonumber(parts[2]), tonumber(parts[3]), tonumber(parts[4])
        if slot and source and amount and health then
            tinsert(self.recap.events, { slot = slot, source = source, amount = amount, health = health })
        end
    end
end

function Summary:ApplySupport(f)
    self.support = {}
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        local _, _, icon, healed, absorbed, name = strfind(item, "^([^:]*):(%d+):(%d+):(.+)$")
        healed, absorbed = tonumber(healed or "") or 0, tonumber(absorbed or "") or 0
        if name and healed + absorbed > 0 then
            tinsert(self.support, {
                icon = icon ~= "" and icon or "INV_Misc_QuestionMark", name = name,
                healed = healed, absorbed = absorbed, damage = healed + absorbed,
            })
        end
    end
end

function Summary:ApplyLoadout(f)
    self.passives = {}
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        local parts = UI.Split(item, ":")
        if parts[1] == "p" and parts[2] and parts[2] ~= "" then
            tinsert(self.passives, parts[2])
        end
    end
end

function Summary:ApplyRunSummary(f)
    self.run.damageTaken = tonumber(f[2]) or 0
    self.run.elites = tonumber(f[3]) or 0
    self.run.minis = tonumber(f[4]) or 0
    self.run.bosses = tonumber(f[5]) or 0
end

function Summary:ApplySummaryWeapon(f)
    local icon = f[2] ~= "" and f[2] or "INV_Misc_QuestionMark"
    local name = f[3] == "Melee" and L["hoa.addon.melee"] or f[3] or ""
    local school = UI.DAMAGE_TYPES[f[9] or ""] and f[9] or DamageTypeFor(name, icon)
    tinsert(self.weapons, {
        icon = icon,
        name = name,
        level = tonumber(f[4]) or 1,
        maxLevel = tonumber(f[5]) or 0,
        evolved = f[6] == "1",
        damage = tonumber(f[7]) or 0,
        kills = tonumber(f[8]) or 0,
        school = school,
        subs = {},
    })
end

function Summary:ApplySummarySpell(f)
    local weapon = self.weapons[getn(self.weapons)]
    if not weapon then
        return
    end
    local icon = f[2] ~= "" and f[2] or "INV_Misc_QuestionMark"
    tinsert(weapon.subs, {
        icon = icon,
        name = f[3] or "",
        damage = tonumber(f[4]) or 0,
        kills = tonumber(f[5]) or 0,
        school = DamageTypeFor(f[3], icon),
    })
end

