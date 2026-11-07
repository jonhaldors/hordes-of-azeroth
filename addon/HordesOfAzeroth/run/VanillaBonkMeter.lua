local L = VanillaBonkL
local UI = VanillaBonkUI

local MAX_WIDTH = 304
local MIN_WIDTH = 220
local HERO_BAR_HALF = 372
local EDGE = 20
local HEADER = 24
local ROW = 20
local ROW_GAP = 2
local PAD = 5
local MAX_ROWS = 10
local MAX_PARTS = 4
local BAR_BRIGHTNESS = 0.8
local BORDER_TEXTURE = "Interface\\Tooltips\\UI-Tooltip-Border"
local ARROW_TEXTURE = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown"
local EYE_TEXTURE = "Interface\\Icons\\Ability_EyeOfTheOwl"
local EYE_SIZE = 16
local PARTY_ROWS = 4
local PARTY_CLOSED_TEXTURE = "Interface\\ChatFrame\\UI-ChatIcon-ScrollUp-Up"
local PARTY_OPEN_TEXTURE = "Interface\\ChatFrame\\UI-ChatIcon-ScrollDown-Up"
local CLASS_TOKENS = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST", [7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }
local GLYPH_INDEX = 100
local OTHER_INDEX = 200
local OTHER_FIELDS = 5
local BAR_SPEED = 8
local MODE_SPELLS, MODE_TYPES, MODE_HEALING = 1, 2, 3
local MODES = {
    { mode = MODE_SPELLS, label = L["hoa.addon.damage_done"] },
    { mode = MODE_TYPES, label = L["hoa.addon.damage_types"] },
    { mode = MODE_HEALING, label = L["hoa.addon.healing_done"] },
}
local HEAL_COLOR = UI.HEAL_COLOR
local ABSORB_COLOR = UI.ABSORB_COLOR

local Meter = UI.Module("meter")
Meter.mode = MODE_SPELLS
Meter.spells = {}
Meter.glyphs = {}
Meter.others = {}
Meter.support = {}
Meter.party = {}
Meter.seconds = 0
Meter.rows = {}
Meter.inRun = false

local function Short(value)
    if value >= 1000000 then
        return format("%.2fM", value / 1000000)
    elseif value >= 10000 then
        return format("%.1fK", value / 1000)
    elseif value >= 1000 then
        return format("%.2fK", value / 1000)
    end
    return format("%d", floor(value))
end

local function Percent(part, total)
    return total > 0 and floor(part * 100 / total + 0.5) or 0
end

local function ModeLabel(mode)
    for _, entry in ipairs(MODES) do
        if entry.mode == mode then
            return entry.label
        end
    end
    return MODES[1].label
end

local function Framed(frame, alpha)
    frame:SetBackdrop({
        bgFile = UI.FLAT, edgeFile = BORDER_TEXTURE, tile = false, edgeSize = 12,
        insets = { left = 3, right = 3, top = 3, bottom = 3 },
    })
    frame:SetBackdropColor(0.04, 0.04, 0.05, alpha)
    frame:SetBackdropBorderColor(0.55, 0.5, 0.42)
end

local meter = CreateFrame("Frame", "VanillaBonkMeter", UIParent)
meter:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -EDGE, EDGE)
meter:SetWidth(MAX_WIDTH)
meter:SetHeight(HEADER + PAD * 2 + ROW)
meter:SetFrameStrata("LOW")
Framed(meter, 0.62)
meter:Hide()

meter.header = meter:CreateTexture(nil, "BORDER")
meter.header:SetTexture(UI.FLAT)
meter.header:SetGradientAlpha("VERTICAL", 0.1, 0.08, 0.05, 0.9, 0.24, 0.19, 0.12, 0.9)
meter.header:SetPoint("TOPLEFT", meter, "TOPLEFT", 3, -3)
meter.header:SetPoint("TOPRIGHT", meter, "TOPRIGHT", -3, -3)
meter.header:SetHeight(HEADER - 4)

meter.rule = meter:CreateTexture(nil, "ARTWORK")
meter.rule:SetTexture(UI.FLAT)
meter.rule:SetVertexColor(0.55, 0.45, 0.25, 0.8)
meter.rule:SetHeight(1)
meter.rule:SetPoint("TOPLEFT", meter.header, "BOTTOMLEFT", 0, 0)
meter.rule:SetPoint("TOPRIGHT", meter.header, "BOTTOMRIGHT", 0, 0)

Meter.meter = meter

local menu = CreateFrame("Frame", nil, meter)
menu:SetFrameStrata("DIALOG")
Framed(menu, 0.92)
menu:SetPoint("BOTTOMLEFT", meter, "TOPLEFT", 0, -2)
menu:SetWidth(132)
menu:SetHeight(getn(MODES) * 18 + 10)
menu:Hide()
menu.options = {}
menu:SetScript("OnShow", function()
    for _, option in ipairs(this.options) do
        if option.mode == Meter.mode then
            option.text:SetTextColor(1, 1, 1)
        else
            option.text:SetTextColor(1, 0.82, 0)
        end
    end
end)

function Meter:ToggleMenu()
    if self.menu:IsShown() then
        self.menu:Hide()
    else
        self.menu:Show()
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
end

function Meter:ChooseMode(chosen)
    self.mode = chosen
    VanillaBonkMeterMode = chosen
    self.meter.title:SetText(ModeLabel(chosen))
    self.menu:Hide()
    for _, row in ipairs(self.rows) do
        row.key = nil
    end
    self:Refresh()
end

Meter.menu = menu

for index, entry in ipairs(MODES) do
    local option = CreateFrame("Button", nil, menu)
    option:SetHeight(18)
    option:SetPoint("TOPLEFT", menu, "TOPLEFT", 5, -5 - (index - 1) * 18)
    option:SetPoint("TOPRIGHT", menu, "TOPRIGHT", -5, -5 - (index - 1) * 18)
    option.mode = entry.mode
    option.text = UI.Text(option, 11)
    option.text:SetPoint("LEFT", option, "LEFT", 6, 0)
    option.text:SetText(entry.label)
    option.glow = option:CreateTexture(nil, "BACKGROUND")
    option.glow:SetTexture(UI.FLAT)
    option.glow:SetAllPoints(option)
    option.glow:SetVertexColor(1, 0.82, 0, 0.18)
    option.glow:Hide()
    tinsert(menu.options, option)
    option:SetScript("OnEnter", function() this.glow:Show() end)
    option:SetScript("OnLeave", function() this.glow:Hide() end)
    option:SetScript("OnClick", function()
        PlaySound("igCharacterInfoTab")
        Meter:ChooseMode(this.mode)
    end)
end

local picker = CreateFrame("Button", nil, meter)
picker:SetWidth(20)
picker:SetHeight(20)
picker:SetPoint("TOPLEFT", meter, "TOPLEFT", 4, -3)
picker:SetNormalTexture(ARROW_TEXTURE .. "-Up")
picker:SetPushedTexture(ARROW_TEXTURE .. "-Down")
picker:SetHighlightTexture(ARROW_TEXTURE .. "-Highlight")
picker:SetScript("OnClick", function() Meter:ToggleMenu() end)
Meter.picker = picker

local titleButton = CreateFrame("Button", nil, meter)
titleButton:SetHeight(HEADER - 4)
titleButton:SetPoint("LEFT", picker, "RIGHT", 2, 0)
titleButton:SetWidth(120)
titleButton:SetScript("OnClick", function() Meter:ToggleMenu() end)
Meter.titleButton = titleButton

meter.title = UI.Text(titleButton, 13)
meter.title:SetPoint("LEFT", titleButton, "LEFT", 2, 0)
meter.title:SetTextColor(1, 0.82, 0)
meter.title:SetText(ModeLabel(Meter.mode))

meter.total = UI.Text(meter, 12, UI.NUMBER_FONT)
meter.total:SetPoint("RIGHT", meter.header, "RIGHT", -6, 0)
meter.total:SetJustifyH("RIGHT")

local function Hidden()
    if type(VanillaBonkMeterHidden) ~= "table" then
        VanillaBonkMeterHidden = {}
    end
    return VanillaBonkMeterHidden
end

local function HiddenCount()
    local count = 0
    for _ in pairs(Hidden()) do
        count = count + 1
    end
    return count
end

meter.eye = CreateFrame("Button", nil, meter)
meter.eye:SetWidth(EYE_SIZE)
meter.eye:SetHeight(EYE_SIZE)
meter.eye:SetPoint("RIGHT", meter.total, "LEFT", -6, 0)
meter.eye.icon = meter.eye:CreateTexture(nil, "ARTWORK")
meter.eye.icon:SetAllPoints(meter.eye)
meter.eye.icon:SetTexture(EYE_TEXTURE)
meter.eye.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
meter.eye.icon:SetVertexColor(0.55, 0.55, 0.55)
meter.eye.slash = UI.Text(meter.eye, 14, UI.NUMBER_FONT, "OUTLINE")
meter.eye.slash:SetPoint("CENTER", meter.eye, "CENTER", 0, 0)
meter.eye.slash:SetTextColor(0.9, 0.15, 0.1)
meter.eye.slash:SetText("/")
meter.eye:Hide()
UI.Hover(meter.eye, function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    local count = HiddenCount()
    GameTooltip:AddLine(L(count == 1 and "hoa.addon.1_hidden_entry" or "hoa.addon.1_hidden_entries", count), 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.click_to_show_everything_again"], 0.75, 0.75, 0.75)
    GameTooltip:Show()
end)
meter.eye:SetScript("OnClick", function()
    VanillaBonkMeterHidden = {}
    GameTooltip:Hide()
    PlaySound("igMainMenuOptionCheckBoxOn")
    Meter:Refresh()
end)

meter.empty = UI.Text(meter, 11)
meter.empty:SetPoint("TOPLEFT", meter, "TOPLEFT", PAD + 4, -(HEADER + PAD + 4))
meter.empty:SetTextColor(0.6, 0.6, 0.6)

function Meter:AddPartLines(entry)
    for _, part in ipairs(entry.parts) do
        local kind = UI.DamageType(part.key)
        GameTooltip:AddDoubleLine(kind.name, Short(part.damage) .. " (" .. Percent(part.damage, entry.damage) .. "%)",
            kind.r, kind.g, kind.b, 1, 1, 1)
    end
end

function Meter:SpellTooltip(entry, share)
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.damage_2"], Short(entry.damage), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.per_second"], Short(self.seconds > 0 and entry.damage / self.seconds or 0), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.share"], share .. "%", 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.kills_2"], entry.kills or 0, 1, 0.82, 0, 1, 1, 1)
    if getn(entry.parts) > 1 then
        self:AddPartLines(entry)
    end
end

local function AddHideHint()
    GameTooltip:AddLine(L["hoa.addon.right_click_to_hide"], 0.6, 0.6, 0.6)
end

function Meter:TypeTooltip(entry, share)
    local kind = UI.DamageType(entry.key)
    GameTooltip:AddDoubleLine(kind.name, Short(entry.damage) .. " (" .. share .. "%)", kind.r, kind.g, kind.b, 1, 1, 1)
    if kind.note then
        GameTooltip:AddLine(kind.note, 0.75, 0.75, 0.75)
    end
    for _, source in ipairs(entry.sources) do
        GameTooltip:AddDoubleLine(source.name, Short(source.damage), 1, 1, 1, 1, 1, 1)
    end
end

function Meter:HealTooltip(entry, share)
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.healed"], Short(entry.healed), HEAL_COLOR.r, HEAL_COLOR.g, HEAL_COLOR.b, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.absorbed"], Short(entry.absorbed), ABSORB_COLOR.r, ABSORB_COLOR.g, ABSORB_COLOR.b, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.per_second"], Short(self.seconds > 0 and entry.damage / self.seconds or 0), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.share"], share .. "%", 1, 0.82, 0, 1, 1, 1)
end

function Meter:ShowRowTooltip(frame)
    local entry = frame.entry
    if not entry then
        return
    end
    frame.glow:Show()
    GameTooltip:SetOwner(frame, "ANCHOR_LEFT")
    if entry.healed then
        self:HealTooltip(entry, frame.share or 0)
    elseif entry.sources then
        self:TypeTooltip(entry, frame.share or 0)
    else
        self:SpellTooltip(entry, frame.share or 0)
    end
    AddHideHint()
    GameTooltip:Show()
end

function Meter:HideRowEntry(frame, button)
    if button ~= "RightButton" or not frame.entry then
        return
    end
    Hidden()[frame.entry.hideKey] = true
    GameTooltip:Hide()
    frame.glow:Hide()
    PlaySound("igMainMenuOptionCheckBoxOff")
    self:Refresh()
end

function Meter:HideRowTooltip(frame)
    frame.glow:Hide()
    GameTooltip:Hide()
end

for index = 1, MAX_ROWS do
    local row = CreateFrame("Frame", nil, meter)
    local top = -(HEADER + PAD + (index - 1) * (ROW + ROW_GAP))
    row:SetHeight(ROW)
    row:SetPoint("TOPLEFT", meter, "TOPLEFT", PAD, top)
    row:SetPoint("TOPRIGHT", meter, "TOPRIGHT", -PAD, top)
    row:EnableMouse(true)
    row:SetScript("OnEnter", function() Meter:ShowRowTooltip(this) end)
    row:SetScript("OnLeave", function() Meter:HideRowTooltip(this) end)
    row:SetScript("OnMouseUp", function() Meter:HideRowEntry(this, arg1) end)

    row.frame = row:CreateTexture(nil, "BACKGROUND")
    row.frame:SetTexture(UI.FLAT)
    row.frame:SetVertexColor(0, 0, 0, 0.9)
    row.frame:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.frame:SetWidth(ROW)
    row.frame:SetHeight(ROW)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetPoint("TOPLEFT", row.frame, "TOPLEFT", 1, -1)
    row.icon:SetPoint("BOTTOMRIGHT", row.frame, "BOTTOMRIGHT", -1, 1)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.track = row:CreateTexture(nil, "BACKGROUND")
    row.track:SetTexture(UI.FLAT)
    row.track:SetVertexColor(0, 0, 0, 0.55)
    row.track:SetPoint("TOPLEFT", row.frame, "TOPRIGHT", 2, 0)
    row.track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)

    row.glow = row:CreateTexture(nil, "OVERLAY")
    row.glow:SetTexture(UI.FLAT)
    row.glow:SetVertexColor(1, 1, 1, 0.12)
    row.glow:SetAllPoints(row.track)
    row.glow:Hide()

    row.parts = {}
    for part = 1, MAX_PARTS do
        local fill = row:CreateTexture(nil, "BORDER")
        fill:SetTexture(UI.FLAT)
        fill:SetHeight(ROW)
        fill:Hide()
        row.parts[part] = fill
    end

    row.value = UI.Text(row, 13, UI.NUMBER_FONT)
    row.value:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    row.value:SetJustifyH("RIGHT")
    row.name = UI.Text(row, 11)
    row.name:SetPoint("LEFT", row.track, "LEFT", 5, 0)
    row.name:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
    row.name:SetJustifyH("LEFT")

    row.shown = 0
    row.target = 0
    row:Hide()
    Meter.rows[index] = row
end

local function PartColor(part)
    if part.color then
        return part.color
    end
    return UI.DamageType(part.key)
end

local function DrawRow(row)    local entry = row.entry
    local width = row.barWidth * row.shown
    local x = 0
    for index, fill in ipairs(row.parts) do
        local part = entry and entry.parts[index]
        local partWidth = (part and entry.damage > 0) and width * part.damage / entry.damage or 0
        if partWidth >= 0.5 then
            local color = PartColor(part)
            UI.ShadeBar(fill, color, x / width, (x + partWidth) / width, BAR_BRIGHTNESS)
            fill:SetWidth(partWidth)
            fill:ClearAllPoints()
            fill:SetPoint("TOPLEFT", row.track, "TOPLEFT", x, 0)
            fill:Show()
            x = x + partWidth
        else
            fill:Hide()
        end
    end
end

function Meter:Sources()
    local sources = {}
    for _, spell in pairs(self.spells) do
        if spell.icon then
            tinsert(sources, spell)
        end
    end
    for _, glyph in ipairs(self.glyphs) do
        local info = VanillaBonk_GlyphInfo and VanillaBonk_GlyphInfo(glyph.id)
        if info then
            tinsert(sources, {
                id = "g" .. glyph.id, index = GLYPH_INDEX + glyph.order, icon = info.icon ~= "" and info.icon or "INV_Misc_QuestionMark",
                name = info.name, damage = glyph.damage, kills = glyph.kills, types = glyph.types,
            })
        end
    end
    for _, other in ipairs(self.others) do
        tinsert(sources, other)
    end
    return sources
end

function Meter:SpellEntries()
    local entries = {}
    for _, spell in ipairs(self:Sources()) do
        tinsert(entries, {
            id = spell.id or ("s" .. spell.index), hideKey = "s:" .. (spell.name or ""), index = spell.index, icon = spell.icon,
            name = spell.name or "", damage = spell.damage, kills = spell.kills, parts = UI.DamageParts(spell.types, spell.damage, spell.icon),
        })
    end
    return entries
end

function Meter:TypeEntries()
    local byKey = {}
    local entries = {}
    for _, spell in ipairs(self:Sources()) do
        if spell.icon then
            for _, part in ipairs(UI.DamageParts(spell.types, spell.damage, spell.icon)) do
                local entry = byKey[part.key]
                if not entry then
                    local kind = UI.DamageType(part.key)
                    entry = { id = "t" .. part.key, hideKey = "t:" .. part.key, key = part.key, icon = kind.icon, name = kind.name, damage = 0,
                        sources = {}, index = 0 }
                    byKey[part.key] = entry
                    tinsert(entries, entry)
                end
                entry.damage = entry.damage + part.damage
                tinsert(entry.sources, { name = spell.name or "", damage = part.damage })
            end
        end
    end
    for _, entry in ipairs(entries) do
        entry.parts = { { key = entry.key, damage = entry.damage } }
        table.sort(entry.sources, function(a, b) return a.damage > b.damage end)
    end
    return entries
end

function Meter:HealEntries()
    local entries = {}
    for index, source in ipairs(self.support) do
        local total = source.healed + source.absorbed
        if total > 0 then
            tinsert(entries, {
                id = "h" .. source.name, hideKey = "h:" .. source.name, index = index, icon = source.icon, name = source.name, damage = total,
                healed = source.healed, absorbed = source.absorbed,
                parts = { { color = HEAL_COLOR, damage = source.healed }, { color = ABSORB_COLOR, damage = source.absorbed } },
            })
        end
    end
    return entries
end

local function MeterWidth()
    local room = floor(UIParent:GetWidth() / 2 - HERO_BAR_HALF - EDGE * 2)
    return max(MIN_WIDTH, min(MAX_WIDTH, room))
end

function Meter:AllEntries()
    if self.mode == MODE_TYPES then
        return self:TypeEntries()
    elseif self.mode == MODE_HEALING then
        return self:HealEntries()
    end
    return self:SpellEntries()
end

function Meter:Entries()
    local hidden = Hidden()
    local shown = {}
    for _, entry in ipairs(self:AllEntries()) do
        if not hidden[entry.hideKey] then
            tinsert(shown, entry)
        end
    end
    return shown
end

function Meter:Refresh()
    local width = MeterWidth()
    local meter = self.meter
    meter:SetWidth(width)
    local entries = self:Entries()
    local total, top = 0, 0
    for _, entry in ipairs(entries) do
        total = total + entry.damage
        top = max(top, entry.damage)
    end
    table.sort(entries, function(a, b)
        if a.damage ~= b.damage then
            return a.damage > b.damage
        end
        return a.index < b.index
    end)

    local count = min(getn(entries), MAX_ROWS)
    for index, row in ipairs(self.rows) do
        local entry = entries[index]
        if index <= count and entry then
            row.entry = entry
            row.share = Percent(entry.damage, total)
            row.target = top > 0 and entry.damage / top or 0
            row.barWidth = width - PAD * 2 - ROW - 2
            if row.key ~= entry.id then
                row.key = entry.id
                row.shown = row.target
            end
            row.icon:SetTexture(UI.ICON_PATH .. entry.icon)
            row.name:SetText(index .. ". " .. entry.name)
            row.value:SetText(Short(entry.damage))
            DrawRow(row)
            row:Show()
        else
            row.entry = nil
            row.key = nil
            row:Hide()
        end
    end
    if count == 0 then
        meter.empty:SetText(self.mode == MODE_HEALING and L["hoa.addon.no_healing_yet"] or L["hoa.addon.no_damage_yet"])
        meter.empty:Show()
    else
        meter.empty:Hide()
    end
    meter:SetHeight(HEADER + PAD * 2 + max(1, count) * (ROW + ROW_GAP) - ROW_GAP)
    meter.total:SetText(Short(total) .. " |cffa0a0a0(" .. Short(self.seconds > 0 and total / self.seconds or 0) .. "/s)|r")
    if HiddenCount() > 0 then
        meter.eye:Show()
    else
        meter.eye:Hide()
    end
end

meter:SetScript("OnUpdate", function()
    local step = min(1, arg1 * BAR_SPEED)
    for _, row in ipairs(Meter.rows) do
        if row:IsShown() and row.shown ~= row.target then
            local shown = row.shown + (row.target - row.shown) * step
            if abs(shown - row.target) < 0.002 then
                shown = row.target
            end
            row.shown = shown
            DrawRow(row)
        end
    end
end)

meter:SetScript("OnHide", function()
    Meter.menu:Hide()
end)

local partyFrame = CreateFrame("Frame", nil, meter)
partyFrame:SetPoint("BOTTOMLEFT", meter, "TOPLEFT", 0, 2)
partyFrame:SetPoint("BOTTOMRIGHT", meter, "TOPRIGHT", 0, 2)
partyFrame:SetHeight(HEADER)
Framed(partyFrame, 0.62)
partyFrame:Hide()
Meter.partyFrame = partyFrame

partyFrame.header = partyFrame:CreateTexture(nil, "BORDER")
partyFrame.header:SetTexture(UI.FLAT)
partyFrame.header:SetGradientAlpha("VERTICAL", 0.1, 0.08, 0.05, 0.9, 0.24, 0.19, 0.12, 0.9)
partyFrame.header:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", 3, -3)
partyFrame.header:SetPoint("TOPRIGHT", partyFrame, "TOPRIGHT", -3, -3)
partyFrame.header:SetHeight(HEADER - 4)

partyFrame.toggle = CreateFrame("Button", nil, partyFrame)
partyFrame.toggle:SetAllPoints(partyFrame.header)
partyFrame.toggle:SetScript("OnClick", function()
    VanillaBonkPartyMeterOpen = not VanillaBonkPartyMeterOpen
    PlaySound(VanillaBonkPartyMeterOpen and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
    Meter:RefreshParty()
end)

partyFrame.title = UI.Text(partyFrame.toggle, 13)
partyFrame.title:SetPoint("LEFT", partyFrame.header, "LEFT", 6, 0)
partyFrame.title:SetTextColor(1, 0.82, 0)
partyFrame.title:SetText(L["hoa.addon.party_damage"])

partyFrame.total = UI.Text(partyFrame.toggle, 12, UI.NUMBER_FONT)
partyFrame.total:SetPoint("RIGHT", partyFrame.header, "RIGHT", -6, 0)
partyFrame.total:SetJustifyH("RIGHT")

partyFrame.arrow = partyFrame.toggle:CreateTexture(nil, "OVERLAY")
partyFrame.arrow:SetWidth(EYE_SIZE + 2)
partyFrame.arrow:SetHeight(EYE_SIZE + 2)
partyFrame.arrow:SetPoint("RIGHT", partyFrame.total, "LEFT", -4, 0)

partyFrame.rows = {}
for index = 1, PARTY_ROWS do
    local row = CreateFrame("Frame", nil, partyFrame)
    local top = -(HEADER + PAD + (index - 1) * (ROW + ROW_GAP))
    row:SetHeight(ROW)
    row:SetPoint("TOPLEFT", partyFrame, "TOPLEFT", PAD, top)
    row:SetPoint("TOPRIGHT", partyFrame, "TOPRIGHT", -PAD, top)
    row.crest = row:CreateTexture(nil, "ARTWORK")
    row.crest:SetWidth(ROW)
    row.crest:SetHeight(ROW)
    row.crest:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.track = row:CreateTexture(nil, "BACKGROUND")
    row.track:SetTexture(UI.FLAT)
    row.track:SetVertexColor(0, 0, 0, 0.55)
    row.track:SetPoint("TOPLEFT", row.crest, "TOPRIGHT", 2, 0)
    row.track:SetPoint("BOTTOMRIGHT", row, "BOTTOMRIGHT", 0, 0)
    row.fill = row:CreateTexture(nil, "BORDER")
    row.fill:SetTexture(UI.FLAT)
    row.fill:SetPoint("TOPLEFT", row.track, "TOPLEFT", 0, 0)
    row.fill:SetHeight(ROW)
    row.value = UI.Text(row, 13, UI.NUMBER_FONT)
    row.value:SetPoint("RIGHT", row, "RIGHT", -5, 0)
    row.value:SetJustifyH("RIGHT")
    row.name = UI.Text(row, 11)
    row.name:SetPoint("LEFT", row.track, "LEFT", 5, 0)
    row.name:SetPoint("RIGHT", row.value, "LEFT", -4, 0)
    row.name:SetJustifyH("LEFT")
    row:Hide()
    partyFrame.rows[index] = row
end

function Meter:RefreshParty()
    local partyFrame = self.partyFrame
    if getn(self.party) < 2 then
        partyFrame:Hide()
        return
    end
    local members = {}
    local total, top = 0, 0
    for _, member in ipairs(self.party) do
        tinsert(members, member)
        total = total + member.damage
        top = max(top, member.damage)
    end
    table.sort(members, function(a, b) return a.damage > b.damage end)
    partyFrame.total:SetText(Short(total) .. " |cffa0a0a0(" .. Short(self.seconds > 0 and total / self.seconds or 0) .. "/s)|r")
    local open = VanillaBonkPartyMeterOpen
    partyFrame.arrow:SetTexture(open and PARTY_OPEN_TEXTURE or PARTY_CLOSED_TEXTURE)
    local barWidth = self.meter:GetWidth() - PAD * 2 - ROW - 2
    local count = 0
    for index, row in ipairs(partyFrame.rows) do
        local member = members[index]
        if open and member then
            count = index
            local class = CLASS_TOKENS[member.class or 0]
            local color = RAID_CLASS_COLORS and class and RAID_CLASS_COLORS[class]
            UI.SetClassCrest(row.crest, class)
            if color then
                row.fill:SetVertexColor(color.r * BAR_BRIGHTNESS, color.g * BAR_BRIGHTNESS, color.b * BAR_BRIGHTNESS, 0.9)
            else
                row.fill:SetVertexColor(0.5, 0.5, 0.5, 0.9)
            end
            row.fill:SetWidth(max(1, barWidth * (top > 0 and member.damage / top or 0)))
            row.name:SetText(index .. ". " .. member.name)
            row.value:SetText(Short(member.damage) .. "  |cffc8c8c8" .. Percent(member.damage, total) .. "%|r")
            row:Show()
        else
            row:Hide()
        end
    end
    partyFrame:SetHeight(count > 0 and HEADER + PAD * 2 + count * (ROW + ROW_GAP) - ROW_GAP or HEADER)
    partyFrame:Show()
end

function partyFrame.Refresh()
    Meter:RefreshParty()
end

Meter:Listen({
    VARIABLES_LOADED = function()
        if VanillaBonkMeterMode == MODE_TYPES or VanillaBonkMeterMode == MODE_HEALING then
            Meter.mode = VanillaBonkMeterMode
        end
        Meter.meter.title:SetText(ModeLabel(Meter.mode))
    end,
})

local function TildeFields(text)
    local fields = { false }
    for _, part in ipairs(UI.Split(text or "", "~")) do
        tinsert(fields, part)
    end
    return fields
end

function Meter:Spell(index)
    local spell = self.spells[index]
    if not spell then
        spell = { index = index, damage = 0, kills = 0 }
        self.spells[index] = spell
    end
    return spell
end

function Meter:ShowMeter()
    self.inRun = true
    if UI.Option("damageMeter", true) then
        self.meter:Show()
    else
        self.meter:Hide()
    end
end

function Meter:ApplyDamageMeter()
    if self.inRun then
        self:ShowMeter()
    end
end

function UI.ApplyDamageMeter()
    Meter:ApplyDamageMeter()
end

function Meter:HandleGlyphMeter(text)
    self.glyphs = {}
    for order, item in ipairs(UI.Split(text or "", ",")) do
        local _, _, id, damage, kills, types = strfind(item, "^(%d+):(%d+):(%d+):(.*)$")
        if id then
            tinsert(self.glyphs, { id = id, order = order, damage = tonumber(damage) or 0, kills = tonumber(kills) or 0, types = types })
        end
    end
    if self.mode ~= MODE_HEALING then
        self:Refresh()
    end
end

function Meter:HandleOtherMeter(text)
    local f = TildeFields(text)
    self.others = {}
    local field = 2
    while f[field + OTHER_FIELDS - 1] do
        local order = getn(self.others) + 1
        tinsert(self.others, {
            id = "x" .. f[field + 1], index = OTHER_INDEX + order, icon = f[field] ~= "" and f[field] or "INV_Misc_QuestionMark",
            name = f[field + 1] == "Melee" and L["hoa.addon.melee"] or f[field + 1], damage = tonumber(f[field + 2]) or 0, kills = tonumber(f[field + 3]) or 0, types = f[field + 4],
        })
        field = field + OTHER_FIELDS
    end
    if self.mode ~= MODE_HEALING then
        self:Refresh()
    end
end

function Meter:HandlePartyMeter(text)
    local f = TildeFields(text)
    self.party = {}
    local field = 2
    while f[field + 2] do
        tinsert(self.party, { name = f[field], damage = tonumber(f[field + 1]) or 0, class = tonumber(f[field + 2]) })
        field = field + 3
    end
    self:RefreshParty()
end

function Meter:HandleSupport(text)
    self.support = {}
    for _, item in ipairs(UI.Split(text or "", ",")) do
        local _, _, icon, healed, absorbed, name = strfind(item, "^([^:]*):(%d+):(%d+):(.+)$")
        if name then
            tinsert(self.support, {
                icon = icon ~= "" and icon or "INV_Misc_QuestionMark", name = name,
                healed = tonumber(healed) or 0, absorbed = tonumber(absorbed) or 0,
            })
        end
    end
    if self.mode == MODE_HEALING then
        self:Refresh()
    end
end

function Meter:HandleLoadout(entries)
    local index = 0
    for _, item in ipairs(UI.Split(entries or "", ",")) do
        local parts = UI.Split(item, ":")
        if parts[1] == "w" or parts[1] == "e" then
            index = index + 1
            local spell = self:Spell(index)
            if spell.icon and spell.icon ~= parts[2] then
                spell.damage = 0
                spell.kills = 0
                spell.types = nil
            end
            spell.icon = parts[2] ~= "" and parts[2] or "INV_Misc_QuestionMark"
        end
    end
    for extra = index + 1, MAX_ROWS do
        self.spells[extra] = nil
    end
    self:Refresh()
end

function Meter:HandleState(state)
    self.seconds = tonumber(state.total_s) or self.seconds
    local stats = state.weapon_stats
    if stats then
        for index, item in ipairs(UI.Split(stats, ",")) do
            local parts = UI.Split(item, ":")
            local spell = self:Spell(index)
            spell.damage = tonumber(parts[1]) or 0
            spell.kills = tonumber(parts[2]) or 0
        end
    end
    local types = state.damage_types
    if types then
        for index, item in ipairs(UI.Split(types, ",")) do
            self:Spell(index).types = item
        end
    end
    self:Refresh()
    self:ShowMeter()
end

function Meter:StartRun()
    self.spells = {}
    self.glyphs = {}
    self.others = {}
    self.support = {}
    self.party = {}
    self:RefreshParty()
    self.seconds = 0
    for _, row in ipairs(self.rows) do
        row.key = nil
    end
    self:Refresh()
    self:ShowMeter()
end

function Meter:EndRun()
    self.inRun = false
    self.meter:Hide()
end

UI.ListenHoa({
    HOA_LOADOUT = function(loadout)
        Meter:HandleLoadout(loadout.entries)
    end,
    HOA_WEAPON_INFO = function(weapon)
        local index = tonumber(weapon.index)
        if index and index > 0 then
            Meter:Spell(index).name = weapon.name
            Meter:Refresh()
        end
    end,
    HOA_RUN_SUPPORT = function(state)
        Meter:HandleSupport(state.text)
    end,
    HOA_RUN_GLYPH_METER = function(state)
        Meter:HandleGlyphMeter(state.text)
    end,
    HOA_RUN_OTHER_METER = function(state)
        Meter:HandleOtherMeter(state.text)
    end,
    HOA_RUN_PARTY_METER = function(state)
        Meter:HandlePartyMeter(state.text)
    end,
    HOA_RUN_STATE = function(state)
        Meter:HandleState(state)
    end,
})
Meter:OnRunStart(function()
    Meter:StartRun()
end):OnRunEnd(function()
    Meter:EndRun()
end)

