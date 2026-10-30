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
local GLYPH_INDEX = 100
local BAR_SPEED = 8
local MODE_SPELLS, MODE_TYPES, MODE_HEALING = 1, 2, 3
local MODES = {
    { mode = MODE_SPELLS, label = L["Damage Done"] },
    { mode = MODE_TYPES, label = L["Damage Types"] },
    { mode = MODE_HEALING, label = L["Healing Done"] },
}
local HEAL_COLOR = UI.HEAL_COLOR
local ABSORB_COLOR = UI.ABSORB_COLOR

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

local mode = MODE_SPELLS
local spells = {}
local glyphs = {}
local support = {}
local seconds = 0
local rows = {}
local Refresh

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
        if option.mode == mode then
            option.text:SetTextColor(1, 1, 1)
        else
            option.text:SetTextColor(1, 0.82, 0)
        end
    end
end)

local function ToggleMenu()
    if menu:IsShown() then
        menu:Hide()
    else
        menu:Show()
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
end

local function ChooseMode(chosen)
    mode = chosen
    VanillaBonkMeterMode = mode
    meter.title:SetText(ModeLabel(mode))
    menu:Hide()
    for _, row in ipairs(rows) do
        row.key = nil
    end
    Refresh()
end

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
        ChooseMode(this.mode)
    end)
end

local picker = CreateFrame("Button", nil, meter)
picker:SetWidth(20)
picker:SetHeight(20)
picker:SetPoint("TOPLEFT", meter, "TOPLEFT", 4, -3)
picker:SetNormalTexture(ARROW_TEXTURE .. "-Up")
picker:SetPushedTexture(ARROW_TEXTURE .. "-Down")
picker:SetHighlightTexture(ARROW_TEXTURE .. "-Highlight")
picker:SetScript("OnClick", ToggleMenu)

local titleButton = CreateFrame("Button", nil, meter)
titleButton:SetHeight(HEADER - 4)
titleButton:SetPoint("LEFT", picker, "RIGHT", 2, 0)
titleButton:SetWidth(120)
titleButton:SetScript("OnClick", ToggleMenu)

meter.title = UI.Text(titleButton, 13)
meter.title:SetPoint("LEFT", titleButton, "LEFT", 2, 0)
meter.title:SetTextColor(1, 0.82, 0)
meter.title:SetText(ModeLabel(mode))

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
meter.eye:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    local count = HiddenCount()
    GameTooltip:AddLine(count .. (count == 1 and L[" hidden entry"] or L[" hidden entries"]), 1, 1, 1)
    GameTooltip:AddLine(L["Click to show everything again."], 0.75, 0.75, 0.75)
    GameTooltip:Show()
end)
meter.eye:SetScript("OnLeave", function() GameTooltip:Hide() end)
meter.eye:SetScript("OnClick", function()
    VanillaBonkMeterHidden = {}
    GameTooltip:Hide()
    PlaySound("igMainMenuOptionCheckBoxOn")
    Refresh()
end)

meter.empty = UI.Text(meter, 11)
meter.empty:SetPoint("TOPLEFT", meter, "TOPLEFT", PAD + 4, -(HEADER + PAD + 4))
meter.empty:SetTextColor(0.6, 0.6, 0.6)

local function AddPartLines(entry)
    for _, part in ipairs(entry.parts) do
        local kind = UI.DamageType(part.key)
        GameTooltip:AddDoubleLine(kind.name, Short(part.damage) .. " (" .. Percent(part.damage, entry.damage) .. "%)",
            kind.r, kind.g, kind.b, 1, 1, 1)
    end
end

local function SpellTooltip(entry, share)
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Damage"], Short(entry.damage), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Per second"], Short(seconds > 0 and entry.damage / seconds or 0), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Share"], share .. "%", 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Kills"], entry.kills or 0, 1, 0.82, 0, 1, 1, 1)
    if getn(entry.parts) > 1 then
        AddPartLines(entry)
    end
end

local function AddHideHint()
    GameTooltip:AddLine(L["Right-click to hide."], 0.6, 0.6, 0.6)
end

local function TypeTooltip(entry, share)
    local kind = UI.DamageType(entry.key)
    GameTooltip:AddDoubleLine(kind.name, Short(entry.damage) .. " (" .. share .. "%)", kind.r, kind.g, kind.b, 1, 1, 1)
    if kind.note then
        GameTooltip:AddLine(kind.note, 0.75, 0.75, 0.75)
    end
    for _, source in ipairs(entry.sources) do
        GameTooltip:AddDoubleLine(source.name, Short(source.damage), 1, 1, 1, 1, 1, 1)
    end
end

local function HealTooltip(entry, share)
    GameTooltip:AddLine(entry.name, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Healed"], Short(entry.healed), HEAL_COLOR.r, HEAL_COLOR.g, HEAL_COLOR.b, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Absorbed"], Short(entry.absorbed), ABSORB_COLOR.r, ABSORB_COLOR.g, ABSORB_COLOR.b, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Per second"], Short(seconds > 0 and entry.damage / seconds or 0), 1, 0.82, 0, 1, 1, 1)
    GameTooltip:AddDoubleLine(L["Share"], share .. "%", 1, 0.82, 0, 1, 1, 1)
end

local function ShowRowTooltip()
    local entry = this.entry
    if not entry then
        return
    end
    this.glow:Show()
    GameTooltip:SetOwner(this, "ANCHOR_LEFT")
    if entry.healed then
        HealTooltip(entry, this.share or 0)
    elseif entry.sources then
        TypeTooltip(entry, this.share or 0)
    else
        SpellTooltip(entry, this.share or 0)
    end
    AddHideHint()
    GameTooltip:Show()
end

local function HideRowEntry()
    if arg1 ~= "RightButton" or not this.entry then
        return
    end
    Hidden()[this.entry.hideKey] = true
    GameTooltip:Hide()
    this.glow:Hide()
    PlaySound("igMainMenuOptionCheckBoxOff")
    Refresh()
end

local function HideRowTooltip()
    this.glow:Hide()
    GameTooltip:Hide()
end

for index = 1, MAX_ROWS do
    local row = CreateFrame("Frame", nil, meter)
    local top = -(HEADER + PAD + (index - 1) * (ROW + ROW_GAP))
    row:SetHeight(ROW)
    row:SetPoint("TOPLEFT", meter, "TOPLEFT", PAD, top)
    row:SetPoint("TOPRIGHT", meter, "TOPRIGHT", -PAD, top)
    row:EnableMouse(true)
    row:SetScript("OnEnter", ShowRowTooltip)
    row:SetScript("OnLeave", HideRowTooltip)
    row:SetScript("OnMouseUp", HideRowEntry)

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
    rows[index] = row
end

local function PartColor(part)
    if part.color then
        return part.color
    end
    return UI.DamageType(part.key)
end

local function DrawRow(row)
    local entry = row.entry
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

local function Sources()
    local sources = {}
    for _, spell in pairs(spells) do
        if spell.icon then
            tinsert(sources, spell)
        end
    end
    for _, glyph in ipairs(glyphs) do
        local info = VanillaBonk_GlyphInfo and VanillaBonk_GlyphInfo(glyph.id)
        if info then
            tinsert(sources, {
                id = "g" .. glyph.id, index = GLYPH_INDEX + glyph.order, icon = info.icon ~= "" and info.icon or "INV_Misc_QuestionMark",
                name = info.name, damage = glyph.damage, kills = glyph.kills, types = glyph.types,
            })
        end
    end
    return sources
end

local function SpellEntries()
    local entries = {}
    for _, spell in ipairs(Sources()) do
        tinsert(entries, {
            id = spell.id or ("s" .. spell.index), hideKey = "s:" .. (spell.name or ""), index = spell.index, icon = spell.icon,
            name = spell.name or "", damage = spell.damage, kills = spell.kills, parts = UI.DamageParts(spell.types, spell.damage, spell.icon),
        })
    end
    return entries
end

local function TypeEntries()
    local byKey = {}
    local entries = {}
    for _, spell in ipairs(Sources()) do
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

local function HealEntries()
    local entries = {}
    for index, source in ipairs(support) do
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

local function AllEntries()
    if mode == MODE_TYPES then
        return TypeEntries()
    elseif mode == MODE_HEALING then
        return HealEntries()
    end
    return SpellEntries()
end

local function Entries()
    local hidden = Hidden()
    local shown = {}
    for _, entry in ipairs(AllEntries()) do
        if not hidden[entry.hideKey] then
            tinsert(shown, entry)
        end
    end
    return shown
end

Refresh = function()
    local width = MeterWidth()
    meter:SetWidth(width)
    local entries = Entries()
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
    for index, row in ipairs(rows) do
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
        meter.empty:SetText(mode == MODE_HEALING and L["No healing yet."] or L["No damage yet."])
        meter.empty:Show()
    else
        meter.empty:Hide()
    end
    meter:SetHeight(HEADER + PAD * 2 + max(1, count) * (ROW + ROW_GAP) - ROW_GAP)
    meter.total:SetText(Short(total) .. " |cffa0a0a0(" .. Short(seconds > 0 and total / seconds or 0) .. "/s)|r")
    if HiddenCount() > 0 then
        meter.eye:Show()
    else
        meter.eye:Hide()
    end
end

meter:SetScript("OnUpdate", function()
    local step = min(1, arg1 * BAR_SPEED)
    for _, row in ipairs(rows) do
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
    menu:Hide()
end)

local events = CreateFrame("Frame")
events:RegisterEvent("VARIABLES_LOADED")
events:SetScript("OnEvent", function()
    if VanillaBonkMeterMode == MODE_TYPES or VanillaBonkMeterMode == MODE_HEALING then
        mode = VanillaBonkMeterMode
    end
    meter.title:SetText(ModeLabel(mode))
end)

local handlers = {}

local function Spell(index)
    if not spells[index] then
        spells[index] = { index = index, damage = 0, kills = 0 }
    end
    return spells[index]
end

local inRun = false

local function ShowMeter()
    inRun = true
    if UI.Option("damageMeter", true) then
        meter:Show()
    else
        meter:Hide()
    end
end

function UI.ApplyDamageMeter()
    if inRun then
        ShowMeter()
    end
end

handlers["start"] = function()
    spells = {}
    glyphs = {}
    support = {}
    seconds = 0
    for _, row in ipairs(rows) do
        row.key = nil
    end
    Refresh()
    ShowMeter()
end

handlers["end"] = function()
    inRun = false
    meter:Hide()
end

handlers["state"] = function(f)
    seconds = tonumber(f[14] or "") or seconds
    if f[13] then
        for index, item in ipairs(UI.Split(f[13], ",")) do
            local parts = UI.Split(item, ":")
            local spell = Spell(index)
            spell.damage = tonumber(parts[1]) or 0
            spell.kills = tonumber(parts[2]) or 0
        end
    end
    if f[15] then
        for index, item in ipairs(UI.Split(f[15], ",")) do
            Spell(index).types = item
        end
    end
    Refresh()
    ShowMeter()
end

handlers["gmeter"] = function(f)
    glyphs = {}
    for order, item in ipairs(UI.Split(f[2] or "", ",")) do
        local _, _, id, damage, kills, types = strfind(item, "^(%d+):(%d+):(%d+):(.*)$")
        if id then
            tinsert(glyphs, { id = id, order = order, damage = tonumber(damage) or 0, kills = tonumber(kills) or 0, types = types })
        end
    end
    if mode ~= MODE_HEALING then
        Refresh()
    end
end

handlers["support"] = function(f)
    support = {}
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        local _, _, icon, healed, absorbed, name = strfind(item, "^([^:]*):(%d+):(%d+):(.+)$")
        if name then
            tinsert(support, {
                icon = icon ~= "" and icon or "INV_Misc_QuestionMark", name = name,
                healed = tonumber(healed) or 0, absorbed = tonumber(absorbed) or 0,
            })
        end
    end
    if mode == MODE_HEALING then
        Refresh()
    end
end

handlers["loadout"] = function(f)
    local index = 0
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        local parts = UI.Split(item, ":")
        if parts[1] == "w" or parts[1] == "e" then
            index = index + 1
            local spell = Spell(index)
            if spell.icon and spell.icon ~= parts[2] then
                spell.damage = 0
                spell.kills = 0
                spell.types = nil
            end
            spell.icon = parts[2] ~= "" and parts[2] or "INV_Misc_QuestionMark"
        end
    end
    for extra = index + 1, MAX_ROWS do
        spells[extra] = nil
    end
    Refresh()
end

handlers["pw"] = function(f)
    local index = tonumber(f[2])
    if index and spells[index] then
        spells[index].name = f[3]
        Refresh()
    end
end

UI.Listen(handlers)
