local L = VanillaBonkL
local UI = VanillaBonkUI
local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = VanillaBonkUI.FONT
local NUMBER_FONT = VanillaBonkUI.NUMBER_FONT
local ICON_PATH = "Interface\\Icons\\"
local CLASS_ICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"

local WIDTH = 680
local HEIGHT = 560
local LIST_WIDTH = WIDTH - 66
local LIST_HEIGHT = HEIGHT - 150
local CARD_WIDTH = 296
local CARD_HEIGHT = 46
local CARD_GAP = 6
local EVOLUTION_LINE = 40
local EVOLUTION_GAP = 4
local EVOLUTION_PART_WIDTH = 176
local EVOLUTION_RESULTS_LEFT = 228
local EVOLUTION_ARROW = "Interface\\ChatFrame\\ChatFrameExpandArrow"
local EVOLVE_RANK = 10
local DIVIDER_HEIGHT = 26

local CLASSES = {
    { mask = 1,    name = L["hoa.addon.warrior"], plural = L["hoa.addon.warriors"], color = { 0.78, 0.61, 0.43 }, coords = { 0, 0.25, 0, 0.25 } },
    { mask = 2,    name = L["hoa.addon.paladin"], plural = L["hoa.addon.paladins"], color = { 0.96, 0.55, 0.73 }, coords = { 0, 0.25, 0.5, 0.75 } },
    { mask = 4,    name = L["hoa.addon.hunter"],  plural = L["hoa.addon.hunters"],  color = { 0.67, 0.83, 0.45 }, coords = { 0, 0.25, 0.25, 0.5 } },
    { mask = 8,    name = L["hoa.addon.rogue"],   plural = L["hoa.addon.rogues"],   color = { 1.00, 0.96, 0.41 }, coords = { 0.49609375, 0.7421875, 0, 0.25 } },
    { mask = 16,   name = L["hoa.addon.priest"],  plural = L["hoa.addon.priests"],  color = { 1.00, 1.00, 1.00 }, coords = { 0.49609375, 0.7421875, 0.25, 0.5 } },
    { mask = 64,   name = L["hoa.addon.shaman"],  plural = L["hoa.addon.shamans"],  color = { 0.00, 0.44, 0.87 }, coords = { 0.25, 0.49609375, 0.25, 0.5 } },
    { mask = 128,  name = L["hoa.addon.mage"],    plural = L["hoa.addon.mages"],    color = { 0.41, 0.80, 0.94 }, coords = { 0.25, 0.49609375, 0, 0.25 } },
    { mask = 256,  name = L["hoa.addon.warlock"], plural = L["hoa.addon.warlocks"], color = { 0.58, 0.51, 0.79 }, coords = { 0.7421875, 0.98828125, 0.25, 0.5 } },
    { mask = 1024, name = L["hoa.addon.druid"],   plural = L["hoa.addon.druids"],   color = { 1.00, 0.49, 0.04 }, coords = { 0.7421875, 0.98828125, 0, 0.25 } },
}

VanillaBonkCodex = {}

local Codex = UI.Module("codex")
Codex.currentTab = "spells"
Codex.classFilter = 0
Codex.eliteAffixes = {}
Codex.shownTabs = {}
Codex.tooltip = GameTooltip
Codex.atKeeper = false

local function Split(text, separator)
    local fields = {}
    local start = 1
    while true do
        local found = strfind(text, separator, start, true)
        if not found then
            tinsert(fields, strsub(text, start))
            return fields
        end
        tinsert(fields, strsub(text, start, found - 1))
        start = found + 1
    end
end

local function SetFont(fontString, font, size, flags)
    fontString:SetFont(font, size, flags or "")
end

local function ReadState(entry, locked)
    entry.owned = (tonumber(locked or "") or 1) == 0
    entry.locked = not entry.owned
end

local POOL_KINDS = { c = true, g = true }

function Codex:CanSwitch(entry)
    if not self.book or not entry or not entry.owned or not POOL_KINDS[entry.kind] then
        return false
    end
    local pool = self.book.pool[entry.kind]
    return entry.off or pool.used < pool.slots
end

local function HasFlag(mask, flag)
    return math.mod(math.floor(mask / flag), 2) == 1
end

local function ClassNames(mask, plural)
    if mask == 0 then
        return L["hoa.addon.all_classes"]
    end
    local names = {}
    for _, class in ipairs(CLASSES) do
        if HasFlag(mask, class.mask) then
            tinsert(names, plural and class.plural or class.name)
        end
    end
    return table.concat(names, ", ")
end

local function FirstClassIndex(mask)
    for index, class in ipairs(CLASSES) do
        if HasFlag(mask, class.mask) then
            return index
        end
    end
    return table.getn(CLASSES) + 1
end

function Codex:SpellClasses(spell)
    if spell.evolvesFrom > 0 and self.book.weapons[spell.evolvesFrom] then
        return self.book.weapons[spell.evolvesFrom].classMask
    end
    return spell.classMask
end

function Codex:MatchesFilter(spell)
    local mask = self:SpellClasses(spell)
    return self.classFilter == 0 or mask == 0 or HasFlag(mask, self.classFilter)
end

local function EvolutionNames(evolutions)
    local text = ""
    local count = getn(evolutions)
    for index, evolved in ipairs(evolutions) do
        if index > 1 then
            text = text .. (index == count and L["hoa.addon.or"] or ", ")
        end
        text = text .. evolved.name
    end
    return text
end

function Codex:AddLock(lock)
    self.tooltip:AddLine(" ")
    self.tooltip:AddLine(L["hoa.addon.locked"], 1, 0.3, 0.3)
    if lock then
        self.tooltip:AddLine(L("hoa.addon.quest_1", lock.name), 1, 0.6, 0.6)
        self.tooltip:AddLine(lock.description, 0.9, 0.9, 0.9, 1)
        VanillaBonkUI.AddQuestProgress(self.tooltip, lock)
    end
end

function Codex:AddState(entry)
    if entry.locked then
        self:AddLock(self.book.locks[entry.kind .. entry.id])
    end
end

function Codex:ShowSpellTooltip(owner, spell)
    local Tip = VanillaBonkSpellTip
    local evolved = spell.evolvesFrom > 0
    self.tooltip = Tip
    Tip:SetOwner(owner, "ANCHOR_RIGHT")
    Tip:SetLegendary(evolved)
    Tip:Title(spell.name, evolved and Tip.ORANGE or Tip.WHITE)
    local classes = ClassNames(evolved and self:SpellClasses(spell) or spell.classMask)
    Tip:AddDoubleLine(spell.spec or "", classes, Tip.SPEC[1], Tip.SPEC[2], Tip.SPEC[3], 0.62, 0.62, 0.62)
    local base = evolved and self.book.weapons[spell.evolvesFrom]
    if base then
        Tip:AddDoubleLine(L("hoa.addon.evolved_from_1", base.name), "", 1, 0.5, 0, 1, 1, 1, 11)
    end
    Tip:AddReach(spell.radius, spell.range)
    if spell.description ~= "" then
        Tip:AddLine(spell.description, 1, 0.82, 0)
    end
    Tip:AddFooter(nil, spell.school, spell.aoe)

    Tip:AddRule()
    if base then
        Tip:AddSmallLine(L("hoa.addon.evolves_from_1_through_a_legendary_rank_offered_at_rank_2_or", base.name, EVOLVE_RANK), Tip.ORANGE)
    else
        local evolutions = self.book.evolutionOf[spell.id]
        if evolutions then
            Tip:AddSmallLine(L("hoa.addon.can_evolve_into_2_through_a_legendary_rank_offered_at_rank_1", EVOLVE_RANK, EvolutionNames(evolutions)), Tip.ORANGE)
        end
    end
    if spell.starterMask > 0 then
        Tip:AddSmallLine(format(L["hoa.addon.s_can_choose_it_as_their_starter_spell_at_the_run_master"], ClassNames(spell.starterMask, true)), { 0.6, 0.8, 1 })
    end
    self:AddState(spell)
    self.tooltip:Show()
end

function Codex:ShowPassiveTooltip(owner, passive)
    self.tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    self.tooltip:AddLine(passive.name, 1, 0.82, 0)
    self.tooltip:AddLine(L["hoa.addon.passive_all_classes"], 0.7, 0.7, 0.7)
    self.tooltip:AddLine(passive.description, 1, 1, 1, 1)
    if passive.maxRank > 0 then
        self.tooltip:AddLine(" ")
        self.tooltip:AddLine(L("hoa.addon.max_rank_1", passive.maxRank), 1, 0.82, 0)
    end
    self:AddState(passive)
    self.tooltip:Show()
end

function Codex:ShowCardTooltip(owner, card)
    local rarity = VanillaBonkUI.RARITY[card.rarity] or VanillaBonkUI.RARITY[0]
    self.tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    self.tooltip:AddLine(card.name, rarity.r, rarity.g, rarity.b)
    self.tooltip:AddLine(L("hoa.addon.1_darkmoon_card_all_classes", rarity.name), 0.7, 0.7, 0.7)
    if card.description ~= "" then
        self.tooltip:AddLine(card.description, 1, 1, 1, 1)
    end
    self.tooltip:AddLine(" ")
    self.tooltip:AddLine(card.maxCopies == 1 and L["hoa.addon.1_copy_per_run"] or L["hoa.addon.each_copy_adds_a_bit_less_than_the_one_before"], 1, 0.82, 0, 1)
    self:AddState(card)
    self.tooltip:Show()
end

function Codex:ShowGlyphTooltip(owner, glyph)
    local rarity = VanillaBonkUI.RARITY[glyph.rarity] or VanillaBonkUI.RARITY[0]
    self.tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    self.tooltip:AddLine(glyph.name, rarity.r, rarity.g, rarity.b)
    self.tooltip:AddLine(L("hoa.addon.1_glyph_all_classes", rarity.name), 0.7, 0.7, 0.7)
    if glyph.description ~= "" then
        self.tooltip:AddLine(glyph.description, 1, 1, 1, 1)
    end
    if glyph.drawback ~= "" then
        self.tooltip:AddLine(glyph.drawback, 1, 0.29, 0.23, 1)
    end
    self.tooltip:AddLine(" ")
    self.tooltip:AddLine(L["hoa.addon.offered_after_the_first_timed_mini_boss_and_the_first_two_st"], 1, 0.82, 0, 1)
    self:AddState(glyph)
    self.tooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

Codex.tooltips = { w = Codex.ShowSpellTooltip, p = Codex.ShowPassiveTooltip, c = Codex.ShowCardTooltip, g = Codex.ShowGlyphTooltip }

function Codex:ShowEntryTooltip(owner, entry, manage)
    local show = entry and self.tooltips[entry.kind]
    if show then
        show(self, owner, entry)
        if entry.off then
            self.tooltip:AddLine(" ")
            self.tooltip:AddLine(L["hoa.addon.banned_it_won_t_turn_up_in_runs"], 1, 0.3, 0.3)
            if manage then
                self.tooltip:AddLine(L["hoa.addon.right_click_to_allow_it_again"], 0.4, 1, 0.4)
            end
            self.tooltip:Show()
        elseif not manage then
            return
        elseif self:CanSwitch(entry) then
            self.tooltip:AddLine(" ")
            self.tooltip:AddLine(L["hoa.addon.right_click_to_ban_it_from_your_runs"], 1, 0.82, 0)
            self.tooltip:Show()
        elseif self.book and entry.owned and POOL_KINDS[entry.kind] then
            local pool = self.book.pool[entry.kind]
            self.tooltip:AddLine(" ")
            self.tooltip:AddLine(pool.slots > 0 and L("hoa.addon.all_your_ban_slots_are_in_use_1_2", pool.used, pool.slots) or
                L["hoa.addon.you_have_no_ban_slots_yet"], 0.7, 0.7, 0.7, 1)
            self.tooltip:Show()
        end
    end
end

local function OnEnterEntry()
    Codex:ShowEntryTooltip(this, this.entry)
end

local window = UI.Window("VanillaBonkSpellbook", WIDTH, HEIGHT)
Codex.window = window
window:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
window.title:SetText(L["hoa.addon.spellbook"])
window.subtitle = window.headerRight

window.pane = UI.Pane(window, UI.CONTENT_LEFT, UI.CONTENT_TOP, WIDTH - UI.CONTENT_LEFT - UI.CONTENT_RIGHT,
    HEIGHT - UI.CONTENT_TOP - UI.CONTENT_BOTTOM, "Interface\\Glues\\LoadingScreens\\LoadScreenScholomance", 0.7)
window.pane:SetFrameLevel(window:GetFrameLevel() + 1)

window.scroll = CreateFrame("ScrollFrame", "VanillaBonkSpellbookScroll", window, "UIPanelScrollFrameTemplate")
window.scroll:SetPoint("TOPLEFT", window, "TOPLEFT", 26, -114)
window.scroll:SetWidth(LIST_WIDTH)
window.scroll:SetHeight(LIST_HEIGHT)
window.scroll:SetFrameLevel(window.pane:GetFrameLevel() + 2)

window.list = CreateFrame("Frame", nil, window.scroll)
window.list:SetWidth(LIST_WIDTH)
window.list:SetHeight(LIST_HEIGHT)
window.scroll:SetScrollChild(window.list)

window.empty = window.list:CreateFontString(nil, "OVERLAY")
SetFont(window.empty, FONT, 12)
window.empty:SetPoint("TOP", window.list, "TOP", 0, -40)
window.empty:SetTextColor(0.6, 0.6, 0.6)

local TABS = {
    { key = "spells",     label = L["hoa.addon.spells"] },
    { key = "unlocks",    label = L["hoa.addon.passives"] },
    { key = "debuffs",    label = L["hoa.addon.debuffs"] },
    { key = "affixes",    label = L["hoa.addon.affixes"] },
    { key = "evolutions", label = L["hoa.addon.evolutions"] },
    { key = "rules",      label = L["hoa.addon.rules"] },
}

function Codex:TabHasClasses()
    return self.currentTab == "spells" or self.currentTab == "evolutions"
end

function Codex:TabHasInfoRows()
    return self.currentTab == "debuffs" or self.currentTab == "affixes"
end

Codex.shownTabs = TABS

function Codex:TabLabels()
    self.shownTabs = {}
    for _, tab in ipairs(TABS) do
        if (tab.key ~= "evolutions" or (self.book and getn(self.book.evolutions) > 0)) and
            (tab.key ~= "debuffs" or (self.book and self.book.debuffs and getn(self.book.debuffs) > 0)) and
            (tab.key ~= "affixes" or getn(self.eliteAffixes) > 0) and
            (tab.key ~= "rules" or (self.book and self.book.rules and getn(self.book.rules) > 0)) then
            tinsert(self.shownTabs, tab)
        end
    end
    local labels = {}
    for _, tab in ipairs(self.shownTabs) do
        tinsert(labels, tab.label)
    end
    return labels
end

function Codex:UpdateTabs()
    UI.Tabs(window, self:TabLabels(), function(id)
        Codex.currentTab = Codex.shownTabs[id].key
        Codex:Refresh()
    end)
    local found = false
    for index, tab in ipairs(self.shownTabs) do
        if tab.key == self.currentTab then
            UI.SelectTab(window, index)
            found = true
        end
    end
    if not found then
        self.currentTab = self.shownTabs[1].key
        UI.SelectTab(window, 1)
    end
end

window.filters = {}

function Codex:CreateFilterButton(index, mask, name)
    local button = CreateFrame("Button", nil, window)
    button:SetWidth(26)
    button:SetHeight(26)
    button:SetPoint("TOPLEFT", window, "TOPLEFT", 28 + (index - 1) * 30, -82)
    button:SetFrameLevel(window.pane:GetFrameLevel() + 2)
    button:SetBackdrop({
        bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    button.mask = mask
    button.name = name
    button:SetScript("OnClick", function()
        Codex.classFilter = this.mask
        PlaySound("igMainMenuOptionCheckBoxOn")
        Codex:Refresh()
    end)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_BOTTOM")
        GameTooltip:AddLine(this.name, 1, 0.82, 0)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", HideTooltip)
    tinsert(window.filters, button)
    return button
end

do
    local all = Codex:CreateFilterButton(1, 0, L["hoa.addon.all_classes"])
    all.label = all:CreateFontString(nil, "OVERLAY")
    SetFont(all.label, NUMBER_FONT, 11, "OUTLINE")
    all.label:SetPoint("CENTER", all, "CENTER", 0, 0)
    all.label:SetText(L["hoa.addon.all"])

    for index, class in ipairs(CLASSES) do
        local button = Codex:CreateFilterButton(index + 1, class.mask, class.name)
        button.icon = button:CreateTexture(nil, "ARTWORK")
        button.icon:SetTexture(CLASS_ICONS)
        button.icon:SetTexCoord(class.coords[1], class.coords[2], class.coords[3], class.coords[4])
        button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
end

window.tally = window:CreateFontString(nil, "OVERLAY")
SetFont(window.tally, FONT, 12)
window.tally:SetPoint("LEFT", window, "TOPLEFT", 30, -95)
window.tally:SetShadowColor(0, 0, 0, 1)
window.tally:SetShadowOffset(1, -1)

window.pool = window:CreateFontString(nil, "OVERLAY")
SetFont(window.pool, FONT, 11)
window.pool:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", 30, 22)
window.pool:SetShadowColor(0, 0, 0, 1)
window.pool:SetShadowOffset(1, -1)

function Codex:UpdateFilters()
    local shown = self:TabHasClasses()
    for _, button in ipairs(window.filters) do
        if shown then
            button:Show()
        else
            button:Hide()
        end
        if button.mask == self.classFilter then
            button:SetBackdropColor(0.35, 0.25, 0.05, 0.9)
            button:SetBackdropBorderColor(1, 0.82, 0, 1)
            if button.icon then
                button.icon:SetAlpha(1)
            end
        else
            button:SetBackdropColor(0, 0, 0, 0.6)
            button:SetBackdropBorderColor(0.3, 0.3, 0.3, 1)
            if button.icon then
                button.icon:SetAlpha(0.55)
            end
        end
    end
end

window.cards = {}

function Codex:CreateCard(index)
    local card = CreateFrame("Button", nil, window.list)
    card:SetWidth(CARD_WIDTH)
    card:SetHeight(CARD_HEIGHT)
    card:SetBackdrop({
        bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    card:SetScript("OnEnter", function()
        this:SetBackdropBorderColor(1, 0.82, 0, 1)
        OnEnterEntry()
    end)
    card:SetScript("OnLeave", function()
        this:SetBackdropBorderColor(this.border[1], this.border[2], this.border[3], 1)
        HideTooltip()
    end)

    card.icon = card:CreateTexture(nil, "ARTWORK")
    card.icon:SetWidth(34)
    card.icon:SetHeight(34)
    card.icon:SetPoint("LEFT", card, "LEFT", 7, 0)
    card.slot = card:CreateTexture(nil, "OVERLAY")
    card.slot:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    card.slot:SetWidth(62)
    card.slot:SetHeight(62)
    card.slot:SetPoint("CENTER", card.icon, "CENTER", 0, 0)

    card.name = card:CreateFontString(nil, "OVERLAY")
    SetFont(card.name, FONT, 13)
    card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 9, -2)
    card.name:SetWidth(CARD_WIDTH - 84)
    card.name:SetJustifyH("LEFT")

    card.detail = card:CreateFontString(nil, "OVERLAY")
    SetFont(card.detail, FONT, 10)
    card.detail:SetPoint("BOTTOMLEFT", card.icon, "BOTTOMRIGHT", 9, 2)
    card.detail:SetWidth(CARD_WIDTH - 60)
    card.detail:SetJustifyH("LEFT")

    card.badge = card:CreateFontString(nil, "OVERLAY")
    SetFont(card.badge, NUMBER_FONT, 11, "OUTLINE")
    card.badge:SetPoint("TOPRIGHT", card, "TOPRIGHT", -6, -5)

    card.offTag = card:CreateTexture(nil, "OVERLAY")
    card.offTag:SetTexture(FLAT)
    card.offTag:SetVertexColor(0.55, 0.06, 0.06, 1)
    card.offTag:SetWidth(30)
    card.offTag:SetHeight(15)
    card.offTag:SetPoint("RIGHT", card, "RIGHT", -10, 0)
    card.offText = card:CreateFontString(nil, "OVERLAY")
    SetFont(card.offText, FONT, 10)
    card.offText:SetPoint("CENTER", card.offTag, "CENTER", 0, 0)
    card.offText:SetText(L["hoa.addon.off"])
    card.offTag:Hide()
    card.offText:Hide()

    window.cards[index] = card
    return card
end

local function PlaceCard(card, column, top)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", window.list, "TOPLEFT", column * (CARD_WIDTH + 10), -top)
end

window.dividers = {}

local function CreateDivider(index)
    local divider = CreateFrame("Frame", nil, window.list)
    divider:SetWidth(LIST_WIDTH - 8)
    divider:SetHeight(DIVIDER_HEIGHT)
    divider.label = divider:CreateFontString(nil, "OVERLAY")
    SetFont(divider.label, FONT, 12)
    divider.label:SetPoint("LEFT", divider, "LEFT", 4, -2)
    divider.line = divider:CreateTexture(nil, "ARTWORK")
    divider.line:SetTexture(FLAT)
    divider.line:SetHeight(1)
    divider.line:SetPoint("LEFT", divider.label, "RIGHT", 8, 0)
    divider.line:SetPoint("RIGHT", divider, "RIGHT", -4, -2)
    window.dividers[index] = divider
    return divider
end

local function SpellGroup(spell)
    return FirstClassIndex(spell.classMask) .. ":" .. (spell.spec or "")
end

function Codex:SpellGroupLabel(spell)
    local name = spell.spec ~= "" and spell.spec or L["hoa.addon.other_spells"]
    if self.classFilter == 0 then
        return name .. "  |cff9d9d9d" .. ClassNames(spell.classMask) .. "|r"
    end
    return name
end

function Codex:ShowDivider(index, top, spell)
    local divider = window.dividers[index] or CreateDivider(index)
    local class = CLASSES[FirstClassIndex(spell.classMask)]
    local color = class and class.color or { 1, 0.82, 0 }
    divider:ClearAllPoints()
    divider:SetPoint("TOPLEFT", window.list, "TOPLEFT", 0, -top)
    divider.label:SetText(self:SpellGroupLabel(spell))
    divider.label:SetTextColor(color[1], color[2], color[3])
    divider.line:SetVertexColor(color[1], color[2], color[3], 0.45)
    divider:Show()
end

local function HideDividers(from)
    for index = from, table.getn(window.dividers) do
        window.dividers[index]:Hide()
    end
end

local function StyleCard(card, entry)
    if entry.locked then
        card.border = { 0.35, 0.1, 0.1 }
        card:SetBackdropColor(0.1, 0.02, 0.02, 0.72)
        card.name:SetTextColor(0.65, 0.65, 0.65)
        card.detail:SetTextColor(1, 0.4, 0.4)
        SetDesaturation(card.icon, 1)
    else
        card.border = { 0, 0, 0 }
        card:SetBackdropColor(0, 0, 0, 0.62)
        card.name:SetTextColor(1, 0.82, 0)
        card.detail:SetTextColor(0.75, 0.75, 0.75)
        SetDesaturation(card.icon, nil)
    end
    card:SetBackdropBorderColor(card.border[1], card.border[2], card.border[3], 1)
end

window.evolutionRows = {}
window.debuffRows = {}

local function CreatePart(row)
    local part = CreateFrame("Button", nil, row)
    part:SetHeight(40)
    part:SetWidth(176)
    part:SetScript("OnEnter", function()
        this.icon:SetVertexColor(1, 1, 0.7)
        OnEnterEntry()
    end)
    part:SetScript("OnLeave", function()
        this.icon:SetVertexColor(1, 1, 1)
        HideTooltip()
    end)

    part.icon = part:CreateTexture(nil, "ARTWORK")
    part.icon:SetWidth(34)
    part.icon:SetHeight(34)
    part.icon:SetPoint("LEFT", part, "LEFT", 0, 0)

    part.name = part:CreateFontString(nil, "OVERLAY")
    SetFont(part.name, FONT, 11)
    part.name:SetPoint("LEFT", part.icon, "RIGHT", 7, 0)
    part.name:SetWidth(134)
    part.name:SetJustifyH("LEFT")
    return part
end

local function CreateEvolutionRow(index)
    local row = CreateFrame("Frame", nil, window.list)
    row:SetWidth(LIST_WIDTH - 8)
    row:SetBackdrop({
        bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    row:SetBackdropColor(0, 0, 0, 0.62)
    row:SetBackdropBorderColor(0, 0, 0, 0.85)

    row.base = CreatePart(row)
    row.base:SetPoint("LEFT", row, "LEFT", 6, 0)
    row.arrow = row:CreateTexture(nil, "OVERLAY")
    row.arrow:SetTexture(EVOLUTION_ARROW)
    row.arrow:SetWidth(24)
    row.arrow:SetHeight(24)
    row.arrow:SetPoint("LEFT", row.base, "RIGHT", 10, 0)
    row.results = {}

    window.evolutionRows[index] = row
    return row
end

local function EvolutionColumns()
    return max(1, math.floor((LIST_WIDTH - 14 - EVOLUTION_RESULTS_LEFT) / EVOLUTION_PART_WIDTH))
end

local function PlaceEvolution(row, index, columns)
    local part = row.results[index]
    if not part then
        part = CreatePart(row)
        row.results[index] = part
    end
    local column = math.mod(index - 1, columns)
    local line = math.floor((index - 1) / columns)
    part:ClearAllPoints()
    part:SetPoint("TOPLEFT", row, "TOPLEFT", EVOLUTION_RESULTS_LEFT + column * EVOLUTION_PART_WIDTH, -(3 + line * EVOLUTION_LINE))
    return part
end

local function FillPart(part, entry)
    part.entry = entry
    part.icon:SetTexture(ICON_PATH .. (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark"))
    part.name:SetText(entry.name)
    if entry.locked then
        part.name:SetTextColor(1, 0.4, 0.4)
        SetDesaturation(part.icon, 1)
    else
        part.name:SetTextColor(1, 1, 1)
        SetDesaturation(part.icon, nil)
    end
end

function Codex:SortedSpells()
    local list = {}
    for _, spell in pairs(self.book.weapons) do
        if spell.evolvesFrom == 0 and self:MatchesFilter(spell) then
            tinsert(list, spell)
        end
    end
    table.sort(list, function(a, b)
        local ca, cb = FirstClassIndex(a.classMask), FirstClassIndex(b.classMask)
        if ca ~= cb then
            return ca < cb
        end
        local ta, tb = a.specId or 0, b.specId or 0
        if ta ~= tb then
            return tb == 0 or (ta ~= 0 and ta < tb)
        end
        local pa, pb = a.spec or "", b.spec or ""
        if pa ~= pb then
            return pb == "" or (pa ~= "" and pa < pb)
        end
        local sa, sb = a.starterMask > 0, b.starterMask > 0
        if sa ~= sb then
            return sa
        end
        return a.name < b.name
    end)
    return list
end

function Codex:SortedPassives()
    local list = {}
    for _, passive in pairs(self.book.passives) do
        tinsert(list, passive)
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

function Codex:ShowCards(entries, grouped)
    local top, column, dividers, group = 0, 0, 0, nil
    for index, entry in ipairs(entries) do
        if grouped and SpellGroup(entry) ~= group then
            if column > 0 then
                top = top + CARD_HEIGHT + CARD_GAP
                column = 0
            end
            group = SpellGroup(entry)
            dividers = dividers + 1
            self:ShowDivider(dividers, top, entry)
            top = top + DIVIDER_HEIGHT
        end
        local card = window.cards[index] or self:CreateCard(index)
        PlaceCard(card, column, top)
        card.entry = entry
        card.icon:SetTexture(ICON_PATH .. (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark"))
        card.name:SetText(entry.name)

        local lock = self.book.locks[entry.kind .. entry.id]
        if entry.locked then
            card.detail:SetText(lock and L("hoa.addon.locked_by_1", lock.name) or L["hoa.addon.locked_by_a_quest"])
        elseif entry.kind == "p" then
            card.detail:SetText(entry.maxRank > 0 and L("hoa.addon.unlocked_max_rank_1", entry.maxRank) or L["hoa.addon.unlocked"])
        else
            local text = ClassNames(entry.classMask)
            if entry.starterMask > 0 and (self.classFilter == 0 or HasFlag(entry.starterMask, self.classFilter)) then
                text = L("hoa.addon.1_starter_spell", text)
            end
            card.detail:SetText(text)
        end

        if entry.kind == "w" and self.book.evolutionOf[entry.id] then
            card.badge:SetText("|cffff9933>>|r")
        else
            card.badge:SetText("")
        end

        StyleCard(card, entry)
        if entry.off then
            card.name:SetTextColor(0.55, 0.55, 0.55)
            card.detail:SetText(L["hoa.addon.cffff6060disabled_never_offered_in_runs_r"])
            SetDesaturation(card.icon, 1)
            card:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
            card.offTag:Show()
            card.offText:Show()
        else
            card.offTag:Hide()
            card.offText:Hide()
        end
        if GetMouseFocus() == card then
            self:ShowEntryTooltip(GetMouseFocus(), entry)
        end
        card:Show()
        if column == 1 then
            top = top + CARD_HEIGHT + CARD_GAP
            column = 0
        else
            column = 1
        end
    end
    for index = table.getn(entries) + 1, table.getn(window.cards) do
        window.cards[index]:Hide()
    end
    HideDividers(dividers + 1)
    if column > 0 then
        top = top + CARD_HEIGHT + CARD_GAP
    end
    return top
end

local DEBUFF_ICON = 32
local DEBUFF_TEXT_LEFT = 52
local DEBUFF_LINE = 14

local function CreateDebuffRow(index)
    local row = CreateFrame("Frame", nil, window.list)
    row:SetWidth(LIST_WIDTH - 8)
    row:SetBackdrop({
        bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    row:SetBackdropColor(0, 0, 0, 0.62)
    row:SetBackdropBorderColor(0, 0, 0, 0.85)

    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(DEBUFF_ICON)
    row.icon:SetHeight(DEBUFF_ICON)
    row.icon:SetPoint("TOPLEFT", row, "TOPLEFT", 10, -9)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)

    row.name = row:CreateFontString(nil, "OVERLAY")
    SetFont(row.name, FONT, 13)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", DEBUFF_TEXT_LEFT, -9)
    row.name:SetTextColor(1, 0.82, 0)

    row.meta = row:CreateFontString(nil, "OVERLAY")
    SetFont(row.meta, FONT, 10)
    row.meta:SetPoint("LEFT", row.name, "RIGHT", 10, 0)
    row.meta:SetTextColor(0.6, 0.6, 0.6)

    row.text = row:CreateFontString(nil, "OVERLAY")
    SetFont(row.text, FONT, 11)
    row.text:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -4)
    row.text:SetWidth(LIST_WIDTH - 8 - DEBUFF_TEXT_LEFT - 12)
    row.text:SetJustifyH("LEFT")
    row.text:SetTextColor(1, 1, 1)

    window.debuffRows[index] = row
    return row
end

local function DescribeDebuffLimits(debuff)
    local parts = {}
    if debuff.maxStacks > 1 then
        tinsert(parts, L("hoa.addon.up_to_1_stacks", debuff.maxStacks))
    end
    if debuff.durationMs > 0 then
        tinsert(parts, L(getn(parts) > 0 and "hoa.addon.lasts_1_sec_2" or "hoa.addon.lasts_1_sec", format("%g", debuff.durationMs / 1000)))
    end
    return table.concat(parts, L["hoa.addon.empty"])
end

local function ShowInfoRows(entries, describe)
    local top = 0
    local count = entries and getn(entries) or 0
    for index = 1, count do
        local entry = entries[index]
        local row = window.debuffRows[index] or CreateDebuffRow(index)
        row.icon:SetTexture(ICON_PATH .. (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark"))
        row.name:SetText(entry.name)
        row.meta:SetText(describe and describe(entry) or "")
        row.text:SetText(entry.description)
        local textHeight = row.text:GetHeight()
        if textHeight < 1 then
            textHeight = math.ceil(row.text:GetStringWidth() / row.text:GetWidth() + 0.25) * DEBUFF_LINE
        end
        local height = max(DEBUFF_ICON + 18, 9 + DEBUFF_LINE + 4 + textHeight + 10)
        row:SetHeight(height)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", window.list, "TOPLEFT", 0, -top)
        row:Show()
        top = top + height + EVOLUTION_GAP
    end
    for index = count + 1, table.getn(window.debuffRows) do
        window.debuffRows[index]:Hide()
    end
    return top, count
end

function Codex:ShowEvolutions()
    local shown, top, dividers, group = 0, 0, 0, nil
    local columns = EvolutionColumns()
    for _, base in ipairs(self:SortedSpells()) do
        local evolutions = self.book.evolutionOf[base.id]
        if evolutions then
            if SpellGroup(base) ~= group then
                group = SpellGroup(base)
                dividers = dividers + 1
                self:ShowDivider(dividers, top, base)
                top = top + DIVIDER_HEIGHT
            end
            shown = shown + 1
            local row = window.evolutionRows[shown] or CreateEvolutionRow(shown)
            local count = table.getn(evolutions)
            local height = math.ceil(count / columns) * EVOLUTION_LINE + 6
            row:SetHeight(height)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", window.list, "TOPLEFT", 0, -top)
            FillPart(row.base, base)
            for index, evolved in ipairs(evolutions) do
                local part = PlaceEvolution(row, index, columns)
                FillPart(part, evolved)
                if not evolved.locked then
                    part.name:SetTextColor(1, 0.65, 0.2)
                end
                part:Show()
            end
            for index = count + 1, table.getn(row.results) do
                row.results[index]:Hide()
            end
            row:Show()
            top = top + height + EVOLUTION_GAP
        end
    end
    for index = shown + 1, table.getn(window.evolutionRows) do
        window.evolutionRows[index]:Hide()
    end
    HideDividers(dividers + 1)
    return top, shown
end

local rules = { section = 1, topics = {}, rows = {} }
Codex.rules = rules

do
    local SIDE_WIDTH = 140
    local TOPIC_HEIGHT = 24
    local PAGE_LEFT = SIDE_WIDTH + 14
    local PAGE_WIDTH = LIST_WIDTH - PAGE_LEFT - 24
    local LINE_GAP = 7
    local LINE_HEIGHT = 14
    local GOLD = "|cffffd100"
    local TEXT = "|cffe6e6e6"

    local frame = CreateFrame("Frame", nil, window)
    frame:SetPoint("TOPLEFT", window, "TOPLEFT", 26, -84)
    frame:SetWidth(LIST_WIDTH)
    frame:SetHeight(LIST_HEIGHT + 30)
    frame:SetFrameLevel(window.pane:GetFrameLevel() + 2)
    frame:Hide()
    rules.frame = frame

    local side = frame:CreateTexture(nil, "BACKGROUND")
    side:SetTexture(0, 0, 0, 0.35)
    side:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    side:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    side:SetWidth(SIDE_WIDTH)
    local edge = frame:CreateTexture(nil, "BORDER")
    edge:SetTexture(0.23, 0.2, 0.14, 1)
    edge:SetPoint("TOPLEFT", side, "TOPRIGHT", 0, 0)
    edge:SetPoint("BOTTOMLEFT", side, "BOTTOMRIGHT", 0, 0)
    edge:SetWidth(1)

    local scroll = CreateFrame("ScrollFrame", "VanillaBonkRulesScroll", frame, "UIPanelScrollFrameTemplate")
    scroll:SetPoint("TOPLEFT", frame, "TOPLEFT", PAGE_LEFT, -4)
    scroll:SetWidth(PAGE_WIDTH)
    scroll:SetHeight(LIST_HEIGHT + 22)
    local page = CreateFrame("Frame", nil, scroll)
    page:SetWidth(PAGE_WIDTH)
    page:SetHeight(LIST_HEIGHT)
    scroll:SetScrollChild(page)

    page.heading = page:CreateFontString(nil, "OVERLAY")
    SetFont(page.heading, FONT, 15)
    page.heading:SetTextColor(1, 0.82, 0)
    page.heading:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -2)

    local function SelectTopic(index)
        rules.section = index
        PlaySound("igMainMenuOptionCheckBoxOn")
        Codex:Refresh()
    end

    local function CreateTopic(index)
        local topic = CreateFrame("Button", nil, frame)
        topic:SetWidth(SIDE_WIDTH)
        topic:SetHeight(TOPIC_HEIGHT)
        topic:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, -4 - (index - 1) * TOPIC_HEIGHT)
        topic.glow = topic:CreateTexture(nil, "ARTWORK")
        topic.glow:SetTexture(FLAT)
        topic.glow:SetAllPoints(topic)
        topic.glow:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.25, 1, 0.82, 0, 0.05)
        topic.bar = topic:CreateTexture(nil, "OVERLAY")
        topic.bar:SetTexture(1, 0.82, 0, 1)
        topic.bar:SetPoint("TOPLEFT", topic, "TOPLEFT", 0, 0)
        topic.bar:SetPoint("BOTTOMLEFT", topic, "BOTTOMLEFT", 0, 0)
        topic.bar:SetWidth(2)
        topic.label = topic:CreateFontString(nil, "OVERLAY")
        SetFont(topic.label, FONT, 12)
        topic.label:SetPoint("LEFT", topic, "LEFT", 10, 0)
        topic:SetHighlightTexture(FLAT)
        topic:GetHighlightTexture():SetVertexColor(1, 0.82, 0, 0.08)
        topic.index = index
        topic:SetScript("OnClick", function() SelectTopic(this.index) end)
        rules.topics[index] = topic
        return topic
    end

    local function ShowLineTooltip()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:AddLine(this.label or rules.sections[rules.section].name, 1, 0.82, 0)
        UI.AddGlossary(GameTooltip, { this.plain })
        if GameTooltip:NumLines() > 2 then
            GameTooltip:Show()
        else
            GameTooltip:Hide()
        end
    end

    local function CreateLine(index)
        local row = CreateFrame("Button", nil, page)
        row:SetWidth(PAGE_WIDTH)
        row.dot = row:CreateTexture(nil, "ARTWORK")
        row.dot:SetTexture(1, 0.82, 0, 1)
        row.dot:SetWidth(4)
        row.dot:SetHeight(4)
        row.dot:SetPoint("TOPLEFT", row, "TOPLEFT", 1, -5)
        row.text = row:CreateFontString(nil, "OVERLAY")
        SetFont(row.text, FONT, 12)
        row.text:SetPoint("TOPLEFT", row, "TOPLEFT", 12, 0)
        row.text:SetWidth(PAGE_WIDTH - 14)
        row.text:SetJustifyH("LEFT")
        row:SetScript("OnEnter", ShowLineTooltip)
        row:SetScript("OnLeave", HideTooltip)
        rules.rows[index] = row
        return row
    end

    local function FillLine(row, line)
        local label = line.label
        row.label, row.plain = label, (label and (label .. ": ") or "") .. line.text
        local text = TEXT .. UI.HighlightGlossary(line.text, TEXT) .. "|r"
        if label then
            text = GOLD .. label .. ":|r " .. text
        end
        row.text:SetText(text)
        local height = row.text:GetHeight()
        if height < 1 then
            height = math.ceil(row.text:GetStringWidth() / row.text:GetWidth() + 0.25) * LINE_HEIGHT
        end
        row:SetHeight(height)
        return height
    end

    function rules.Show(sections)
        rules.sections = sections
        if rules.section > getn(sections) then
            rules.section = 1
        end
        for index, section in ipairs(sections) do
            local topic = rules.topics[index] or CreateTopic(index)
            local selected = index == rules.section
            topic.label:SetText(section.name)
            if selected then
                topic.label:SetTextColor(1, 1, 1)
                topic.glow:Show()
                topic.bar:Show()
            else
                topic.label:SetTextColor(1, 0.82, 0)
                topic.glow:Hide()
                topic.bar:Hide()
            end
            topic:Show()
        end
        for index = getn(sections) + 1, getn(rules.topics) do
            rules.topics[index]:Hide()
        end

        local section = sections[rules.section]
        page.heading:SetText(section.name)
        local top = page.heading:GetHeight() + 12
        for index, line in ipairs(section.lines) do
            local row = rules.rows[index] or CreateLine(index)
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", page, "TOPLEFT", 0, -top)
            top = top + FillLine(row, line) + LINE_GAP
            row:Show()
        end
        for index = getn(section.lines) + 1, getn(rules.rows) do
            rules.rows[index]:Hide()
        end
        page:SetHeight(max(LIST_HEIGHT, top))
        scroll:UpdateScrollChildRect()
        scroll:SetVerticalScroll(0)
        frame:Show()
        return section.name
    end

    function rules.Hide()
        frame:Hide()
    end
end

function Codex:Refresh(keepScroll)
    if not self.book then
        return
    end
    if self.currentTab == "rules" and self.book.rules and getn(self.book.rules) > 0 then
        self:UpdateTabs()
        self:UpdateFilters()
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        window.scroll:Hide()
        window.empty:SetText("")
        window.tally:SetText("")
        window.pool:SetText("")
        local name = rules.Show(self.book.rules)
        window.header:SetText(L("hoa.addon.rules_cff9d9d9d_1_r", name))
        return
    end
    rules.Hide()
    window.scroll:Show()
    local scroll = keepScroll and window.scroll:GetVerticalScroll() or 0
    self:UpdateTabs()
    self:UpdateFilters()

    local height, count = 0, 0
    if not self:TabHasInfoRows() then
        for _, row in ipairs(window.debuffRows) do
            row:Hide()
        end
    end
    if self:TabHasInfoRows() then
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        for _, row in ipairs(window.evolutionRows) do
            row:Hide()
        end
        HideDividers(1)
        if self.currentTab == "affixes" then
            height, count = ShowInfoRows(self.eliteAffixes)
        else
            height, count = ShowInfoRows(self.book.debuffs, DescribeDebuffLimits)
        end
        window.empty:SetText(count == 0 and L["hoa.addon.nothing_here_yet"] or "")
    elseif self.currentTab == "evolutions" then
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        height, count = self:ShowEvolutions()
        window.empty:SetText(count == 0 and L["hoa.addon.no_evolutions_for_this_class"] or "")
    else
        for _, row in ipairs(window.evolutionRows) do
            row:Hide()
        end
        local entries
        if self.currentTab == "unlocks" then
            entries = self:SortedPassives()
        else
            entries = self:SortedSpells()
        end
        height = self:ShowCards(entries, self.currentTab == "spells")
        if table.getn(entries) > 0 then
            window.empty:SetText("")
        elseif self:TabHasClasses() and self.classFilter ~= 0 then
            window.empty:SetText(L["hoa.addon.nothing_here_for_this_class"])
        else
            window.empty:SetText(L["hoa.addon.nothing_here_yet"])
        end
    end

    window.list:SetHeight(max(LIST_HEIGHT, height))
    window.scroll:UpdateScrollChildRect()
    window.scroll:SetVerticalScroll(min(scroll, window.scroll:GetVerticalScrollRange()))

    local locked = 0
    for _, list in ipairs({ self.book.weapons, self.book.passives }) do
        for _, entry in pairs(list) do
            if entry.locked then
                locked = locked + 1
            end
        end
    end
    window.subtitle:SetText("|cffffffff" .. L("hoa.addon.1_locked_by_quests", locked) .. "|r")

    if self:TabHasClasses() or self:TabHasInfoRows() then
        window.tally:SetText("")
    else
        local owned, held = 0, 0
        for _, entry in pairs(self.book.passives) do
            if entry.owned then
                owned = owned + 1
            else
                held = held + 1
            end
        end
        window.tally:SetText(L("hoa.addon.cffffffff_1_owned_r_cff9d9d9d_r_cffff6666_2_locked_by_quests", owned, held))
    end
    window.pool:SetText("")

    local className = L["hoa.addon.all_classes"]
    if self:TabHasClasses() then
        for _, class in ipairs(CLASSES) do
            if class.mask == self.classFilter then
                className = class.name
            end
        end
    end
    window.header:SetText(L("hoa.addon.1_cff9d9d9d_2_spells_3_passives_r", className, self.book.spellCount, self.book.passiveCount))
end

function Codex:TogglePool(entry)
    if not self:CanSwitch(entry) or window.buying then
        return false
    end
    window.buying = GetTime()
    PlaySound(entry.off and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
    SendChatMessage(".bonk pool " .. entry.kind .. " " .. entry.id .. (entry.off and " on" or " off"), "SAY")
    return true
end

window:SetScript("OnShow", function()
    PlaySound("igSpellBookOpen")
    UI.SetPortrait(window)
end)

window:SetScript("OnUpdate", function()
    if this.buying and GetTime() - this.buying > 3 then
        this.buying = nil
        Codex:Refresh(true)
    end
end)

window:SetScript("OnHide", function()
    PlaySound("igSpellBookClose")
    Codex.atKeeper = false
    if window.fromGossip then
        window.fromGossip = nil
        if not window.gossipClosed then
            CloseGossip()
        end
    end
    window.gossipClosed = nil
end)

function Codex:OpenFromGossip()
    window.fromGossip = true
    self.atKeeper = true
    window:Show()
    self:Refresh()
end

function VanillaBonkCodex.TakeOverGossip()
    local closeOnHide = GossipFrame:GetScript("OnHide")
    GossipFrame:SetScript("OnHide", nil)
    HideUIPanel(GossipFrame)
    GossipFrame:SetScript("OnHide", closeOnHide)
    Codex:OpenFromGossip()
end

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and Codex.pendingNpc then
        local npc = Codex.pendingNpc
        Codex.pendingNpc = nil
        if UI.TalkingTo(npc) then
            Codex:OpenFromGossip()
            return
        end
    elseif event == "GOSSIP_CLOSED" then
        Codex.pendingNpc = nil
        if window.fromGossip and window:IsShown() then
            window.gossipClosed = true
            window:Hide()
        end
    end
    PreviousGossipOnEvent()
end

SLASH_VANILLABONKSPELLBOOK1 = "/spellbook"
SLASH_VANILLABONKSPELLBOOK2 = "/codex"
SlashCmdList["VANILLABONKSPELLBOOK"] = function()
    if window:IsShown() then
        window:Hide()
        return
    end
    Codex.openRequested = true
    SendChatMessage(".bonk codex", "SAY")
end

function Codex:BeginCodex(f)
    self.incoming = {
        npc = f[2] or "",
        classMask = tonumber(f[3]) or 0,
        deck = f[4] == "1",
        weapons = {},
        passives = {},
        cards = {},
        glyphs = {},
        debuffs = {},
        pool = { c = { used = 0, slots = 0 }, g = { used = 0, slots = 0 } },
        bans = { c = {}, g = {} },
        stacks = {},
        tickets = 0,
        off = {},
        locks = {},
        rules = {},
    }
end

function Codex:AddRuleLine(f)
    if not self.incoming or not f[2] or not f[3] then
        return
    end
    local sections = self.incoming.rules
    local last = sections[getn(sections)]
    if not last or last.name ~= f[2] then
        last = { name = f[2], lines = {} }
        tinsert(sections, last)
    end
    if f[4] then
        tinsert(last.lines, { label = f[3] ~= "" and f[3] or nil, text = f[4] })
    else
        tinsert(last.lines, { text = f[3] })
    end
end

function Codex:AddWeapon(f)
    if not self.incoming then
        return
    end
    local id = tonumber(f[2]) or 0
    local spell = {
        kind = "w",
        id = id,
        name = f[3] or "",
        icon = f[4] or "",
        classMask = tonumber(f[5]) or 0,
        starterMask = tonumber(f[6]) or 0,
        evolvesFrom = tonumber(f[7]) or 0,
        description = "",
    }
    ReadState(spell, f[8])
    self.incoming.weapons[id] = spell
end

function Codex:AddWeaponDetail(f)
    local spell = self.incoming and self.incoming.weapons[tonumber(f[2]) or 0]
    if spell then
        spell.description = f[3] or ""
        spell.school = f[4] or ""
        spell.spec = f[5] or ""
        spell.aoe = f[6] == "1"
        spell.radius = tonumber(f[7]) or 0
        spell.range = tonumber(f[8]) or 0
        spell.specId = tonumber(f[9]) or 0
    end
end

function Codex:AddPassive(f)
    if not self.incoming then
        return
    end
    local id = tonumber(f[2]) or 0
    local passive = {
        kind = "p",
        id = id,
        name = f[3] or "",
        icon = f[4] or "",
        maxRank = tonumber(f[5]) or 1,
        description = f[7] or "",
    }
    ReadState(passive, f[6])
    self.incoming.passives[id] = passive
end

function Codex:AddCard(f)
    if not self.incoming then
        return
    end
    local id = tonumber(f[2]) or 0
    local card = {
        kind = "c",
        id = id,
        name = f[3] or "",
        icon = f[4] or "",
        rarity = tonumber(f[5]) or 0,
        maxCopies = tonumber(f[6]) or 1,
        description = "",
    }
    ReadState(card, f[7])
    self.incoming.cards[id] = card
end

function Codex:AddCardDetail(f)
    local card = self.incoming and self.incoming.cards[tonumber(f[2]) or 0]
    if card then
        card.description = f[3] or ""
    end
end

function Codex:AddDebuff(f)
    if not self.incoming then
        return
    end
    tinsert(self.incoming.debuffs, {
        id = tonumber(f[2]) or 0,
        name = f[3] or "",
        icon = f[4] or "",
        maxStacks = tonumber(f[5]) or 1,
        durationMs = tonumber(f[6]) or 0,
        description = f[7] or "",
    })
end

function Codex:AddAffix(f)
    local name = f[2]
    if not name or name == "" then
        return
    end
    for _, affix in ipairs(self.eliteAffixes) do
        if affix.name == name then
            affix.icon, affix.description = f[3] or "", f[4] or ""
            return
        end
    end
    tinsert(self.eliteAffixes, { name = name, icon = f[3] or "", description = f[4] or "" })
end

function Codex:AddGlyph(f)
    if not self.incoming or not f[2] or f[2] == "" then
        return
    end
    local glyph = { kind = "g", id = tonumber(f[2]) or f[2], key = f[2] }
    ReadState(glyph, f[3])
    self.incoming.glyphs[f[2]] = glyph
end

function Codex:SetPool(f)
    if self.incoming and self.incoming.pool[f[2] or ""] then
        self.incoming.pool[f[2]] = { used = tonumber(f[3] or "") or 0, slots = tonumber(f[4] or "") or 0 }
    end
end

function Codex:AddBan(f)
    if self.incoming and self.incoming.bans[f[2] or ""] then
        tinsert(self.incoming.bans[f[2]], { earned = f[3] == "1", tickets = tonumber(f[4] or "") or 0, label = f[5] or "", detail = f[6] or "" })
    end
end

function Codex:AddCardStacks(f)
    if self.incoming and f[2] then
        self.incoming.stacks[tonumber(f[2]) or 0] = { one = f[3] or "", five = f[4] or "" }
    end
end

function Codex:SetTickets(f)
    if self.incoming then
        self.incoming.tickets = tonumber(f[2] or "") or 0
    end
end

function Codex:AddOff(f)
    if self.incoming and f[2] and f[3] then
        self.incoming.off[f[2] .. f[3]] = true
    end
end

function Codex:AddQuestLock(f)
    if self.incoming then
        self.incoming.locks[(f[2] or "") .. (f[3] or "")] = { name = f[4] or "", description = f[5] or "",
            progress = tonumber(f[6]) or 0, amount = tonumber(f[7]) or 1 }
    end
end

function Codex:FinishCodex()
    if not self.incoming then
        return
    end
    local received = self.incoming
    self.incoming = nil

    received.evolutions = {}
    received.evolutionOf = {}
    received.spellCount = 0
    for _, spell in pairs(received.weapons) do
        if spell.evolvesFrom > 0 then
            tinsert(received.evolutions, spell)
            received.evolutionOf[spell.evolvesFrom] = received.evolutionOf[spell.evolvesFrom] or {}
            tinsert(received.evolutionOf[spell.evolvesFrom], spell)
        else
            received.spellCount = received.spellCount + 1
        end
    end
    for _, evolutions in pairs(received.evolutionOf) do
        table.sort(evolutions, function(a, b)
            return a.id < b.id
        end)
    end
    received.passiveCount = 0
    for _ in pairs(received.passives) do
        received.passiveCount = received.passiveCount + 1
    end
    received.cardCount = 0
    for _ in pairs(received.cards) do
        received.cardCount = received.cardCount + 1
    end
    received.glyphCount = 0
    for key, glyph in pairs(received.glyphs) do
        local text = VanillaBonkGlyphInfo and VanillaBonkGlyphInfo[key]
        glyph.name = text and text.name or L("hoa.addon.glyph_1", key)
        glyph.icon = text and text.icon or ""
        glyph.rarity = text and text.rarity or 0
        glyph.description = text and text.description or ""
        glyph.drawback = text and text.drawback or ""
        received.glyphCount = received.glyphCount + 1
    end
    for kind, list in pairs({ w = received.weapons, p = received.passives, c = received.cards, g = received.glyphs }) do
        for _, entry in pairs(list) do
            entry.off = received.off[kind .. entry.id] and true or nil
        end
    end
    self.book = received
    window.buying = nil
    if VanillaBonkCodex.onBook then
        VanillaBonkCodex.onBook()
    end

    if received.deck then
        VanillaBonkDeck.Open(received)
        return
    end
    if VanillaBonkDeck.IsShown() then
        VanillaBonkDeck.Refresh(received)
    end

    if window:IsShown() then
        self.openRequested = nil
        if received.npc ~= "" then
            self.atKeeper = true
        end
        self:Refresh(true)
    elseif received.npc ~= "" then
        self.classFilter = received.classMask
        if GossipFrame:IsVisible() and UI.TalkingTo(received.npc) then
            VanillaBonkCodex.TakeOverGossip()
        else
            self.pendingNpc = received.npc
        end
    elseif self.openRequested then
        self.openRequested = nil
        self.classFilter = received.classMask
        window:Show()
        self:Refresh()
    end
end

local handlers = {}
handlers["cdx"] = function(f) Codex:BeginCodex(f) end
handlers["cdxr"] = function(f) Codex:AddRuleLine(f) end
handlers["cdxw"] = function(f) Codex:AddWeapon(f) end
handlers["cdxwd"] = function(f) Codex:AddWeaponDetail(f) end
handlers["cdxp"] = function(f) Codex:AddPassive(f) end
handlers["cdxc"] = function(f) Codex:AddCard(f) end
handlers["cdxcd"] = function(f) Codex:AddCardDetail(f) end
handlers["cdxk"] = function(f) Codex:AddDebuff(f) end
handlers["affixinfo"] = function(f) Codex:AddAffix(f) end
handlers["cdxg"] = function(f) Codex:AddGlyph(f) end
handlers["cdxpool"] = function(f) Codex:SetPool(f) end
handlers["cdxban"] = function(f) Codex:AddBan(f) end
handlers["cdxcs"] = function(f) Codex:AddCardStacks(f) end
handlers["cdxtickets"] = function(f) Codex:SetTickets(f) end
handlers["cdxoff"] = function(f) Codex:AddOff(f) end
handlers["cdxq"] = function(f) Codex:AddQuestLock(f) end
handlers["cdxend"] = function() Codex:FinishCodex() end

VanillaBonkCodex.ShowEntryTooltip = function(owner, entry, manage)
    return Codex:ShowEntryTooltip(owner, entry, manage)
end
VanillaBonkCodex.CanSwitch = function(entry)
    return Codex:CanSwitch(entry)
end
VanillaBonkCodex.TogglePool = function(entry)
    return Codex:TogglePool(entry)
end
function Refresh(keepScroll)
    return Codex:Refresh(keepScroll)
end

VanillaBonkUI.ListenHoa({
    HOA_CODEX = function(entry)
        if strsub(entry.kind, 1, 3) ~= "cdx" then
            return
        end
        local f = { entry.kind }
        for _, part in ipairs(Split(entry.line or "", "~")) do
            tinsert(f, part)
        end
        local handler = handlers[entry.kind]
        if handler then
            handler(f)
        end
    end,
    HOA_AFFIX_INFO = function(info)
        handlers["affixinfo"]({ false, info.name, info.icon, info.description })
    end,
})

Codex:OnMoney(function()
    if Codex.window:IsShown() then
        Codex:Refresh(true)
    end
end)
