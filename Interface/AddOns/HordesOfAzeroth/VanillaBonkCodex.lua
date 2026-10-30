local L = VanillaBonkL
local PREFIX = "BONK~"
local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\FRIZQT__.TTF"
local NUMBER_FONT = "Fonts\\ARIALN.TTF"
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

local CLASSES = {
    { mask = 1,    name = L["Warrior"], plural = L["Warriors"], color = { 0.78, 0.61, 0.43 }, coords = { 0, 0.25, 0, 0.25 } },
    { mask = 2,    name = L["Paladin"], plural = L["Paladins"], color = { 0.96, 0.55, 0.73 }, coords = { 0, 0.25, 0.5, 0.75 } },
    { mask = 4,    name = L["Hunter"],  plural = L["Hunters"],  color = { 0.67, 0.83, 0.45 }, coords = { 0, 0.25, 0.25, 0.5 } },
    { mask = 8,    name = L["Rogue"],   plural = L["Rogues"],   color = { 1.00, 0.96, 0.41 }, coords = { 0.49609375, 0.7421875, 0, 0.25 } },
    { mask = 16,   name = L["Priest"],  plural = L["Priests"],  color = { 1.00, 1.00, 1.00 }, coords = { 0.49609375, 0.7421875, 0.25, 0.5 } },
    { mask = 64,   name = L["Shaman"],  plural = L["Shamans"],  color = { 0.00, 0.44, 0.87 }, coords = { 0.25, 0.49609375, 0.25, 0.5 } },
    { mask = 128,  name = L["Mage"],    plural = L["Mages"],    color = { 0.41, 0.80, 0.94 }, coords = { 0.25, 0.49609375, 0, 0.25 } },
    { mask = 256,  name = L["Warlock"], plural = L["Warlocks"], color = { 0.58, 0.51, 0.79 }, coords = { 0.7421875, 0.98828125, 0.25, 0.5 } },
    { mask = 1024, name = L["Druid"],   plural = L["Druids"],   color = { 1.00, 0.49, 0.04 }, coords = { 0.7421875, 0.98828125, 0, 0.25 } },
}

VanillaBonkCodex = {}

local book
local incoming
local pendingNpc
local atKeeper = false
local openRequested
local currentTab = "spells"
local classFilter = 0

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

local function CanSwitch(entry)
    if not book or not entry or not entry.owned or not POOL_KINDS[entry.kind] then
        return false
    end
    local pool = book.pool[entry.kind]
    return entry.off or pool.used < pool.slots
end

local function HasFlag(mask, flag)
    return math.mod(math.floor(mask / flag), 2) == 1
end

local function ClassNames(mask, plural)
    if mask == 0 then
        return L["All classes"]
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

local function SpellClasses(spell)
    if spell.evolvesFrom > 0 and book.weapons[spell.evolvesFrom] then
        return book.weapons[spell.evolvesFrom].classMask
    end
    return spell.classMask
end

local function MatchesFilter(spell)
    local mask = SpellClasses(spell)
    return classFilter == 0 or mask == 0 or HasFlag(mask, classFilter)
end

local function EvolutionNames(evolutions)
    local text = ""
    local count = getn(evolutions)
    for index, evolved in ipairs(evolutions) do
        if index > 1 then
            text = text .. (index == count and L[" or "] or ", ")
        end
        text = text .. evolved.name
    end
    return text
end

local tooltip = GameTooltip

local function AddLock(lock)
    tooltip:AddLine(" ")
    tooltip:AddLine(L["Locked"], 1, 0.3, 0.3)
    if lock then
        tooltip:AddLine(L["Quest: "] .. lock.name, 1, 0.6, 0.6)
        tooltip:AddLine(lock.description, 0.9, 0.9, 0.9, 1)
        VanillaBonkUI.AddQuestProgress(tooltip, lock)
    end
end

local function AddState(entry)
    if entry.locked then
        AddLock(book.locks[entry.kind .. entry.id])
    end
end

local function ShowSpellTooltip(owner, spell)
    local Tip = VanillaBonkSpellTip
    local evolved = spell.evolvesFrom > 0
    tooltip = Tip
    Tip:SetOwner(owner, "ANCHOR_RIGHT")
    Tip:SetLegendary(evolved)
    Tip:Title(spell.name, evolved and Tip.ORANGE or Tip.WHITE)
    local classes = ClassNames(evolved and SpellClasses(spell) or spell.classMask)
    Tip:AddDoubleLine(spell.spec or "", classes, Tip.SPEC[1], Tip.SPEC[2], Tip.SPEC[3], 0.62, 0.62, 0.62)
    local base = evolved and book.weapons[spell.evolvesFrom]
    if base then
        Tip:AddDoubleLine(L["Evolved from "] .. base.name, "", 1, 0.5, 0, 1, 1, 1, 11)
    end
    Tip:AddReach(spell.radius, spell.range)
    if spell.description ~= "" then
        Tip:AddLine(spell.description, 1, 0.82, 0)
    end
    Tip:AddFooter(nil, spell.school, spell.aoe)

    Tip:AddRule()
    if base then
        Tip:AddSmallLine(L("{1} evolves into this through a Legendary rank, offered from rank {2}.", base.name, EVOLVE_RANK), Tip.ORANGE)
    else
        local evolutions = book.evolutionOf[spell.id]
        if evolutions then
            Tip:AddSmallLine(L("From rank {1}, a Legendary rank can evolve it into {2}.", EVOLVE_RANK, EvolutionNames(evolutions)), Tip.ORANGE)
        end
    end
    if spell.starterMask > 0 then
        Tip:AddSmallLine(format(L["%s can choose it as their starter spell at the Run Master."], ClassNames(spell.starterMask, true)), { 0.6, 0.8, 1 })
    end
    AddState(spell)
    tooltip:Show()
end

local function ShowPassiveTooltip(owner, passive)
    tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    tooltip:AddLine(passive.name, 1, 0.82, 0)
    tooltip:AddLine(L["Passive (all classes)"], 0.7, 0.7, 0.7)
    tooltip:AddLine(passive.description, 1, 1, 1, 1)
    if passive.maxRank > 0 then
        tooltip:AddLine(" ")
        tooltip:AddLine(L["Max rank "] .. passive.maxRank, 1, 0.82, 0)
    end
    AddState(passive)
    tooltip:Show()
end

local function ShowCardTooltip(owner, card)
    local rarity = VanillaBonkUI.RARITY[card.rarity] or VanillaBonkUI.RARITY[0]
    tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    tooltip:AddLine(card.name, rarity.r, rarity.g, rarity.b)
    tooltip:AddLine(rarity.name .. L[" Darkmoon Card (all classes)"], 0.7, 0.7, 0.7)
    if card.description ~= "" then
        tooltip:AddLine(card.description, 1, 1, 1, 1)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(card.maxCopies == 1 and L["1 copy per run"] or L["Each copy adds a bit less than the one before."], 1, 0.82, 0, 1)
    AddState(card)
    tooltip:Show()
end

local function ShowGlyphTooltip(owner, glyph)
    local rarity = VanillaBonkUI.RARITY[glyph.rarity] or VanillaBonkUI.RARITY[0]
    tooltip = GameTooltip
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    tooltip:AddLine(glyph.name, rarity.r, rarity.g, rarity.b)
    tooltip:AddLine(rarity.name .. L[" Glyph (all classes)"], 0.7, 0.7, 0.7)
    if glyph.description ~= "" then
        tooltip:AddLine(glyph.description, 1, 1, 1, 1)
    end
    if glyph.drawback ~= "" then
        tooltip:AddLine(glyph.drawback, 1, 0.29, 0.23, 1)
    end
    tooltip:AddLine(" ")
    tooltip:AddLine(L["Offered after the first timed mini-boss and some floor bosses, up to 2 per run (6 on Mythic). Foresight adds one at the start of a run."], 1, 0.82, 0, 1)
    AddState(glyph)
    tooltip:Show()
end

local function HideTooltip()
    GameTooltip:Hide()
end

local TOOLTIPS = { w = ShowSpellTooltip, p = ShowPassiveTooltip, c = ShowCardTooltip, g = ShowGlyphTooltip }

local function ShowEntryTooltip(owner, entry, manage)
    if entry and TOOLTIPS[entry.kind] then
        TOOLTIPS[entry.kind](owner, entry)
        if entry.off then
            tooltip:AddLine(" ")
            tooltip:AddLine(L["Banned. It won't turn up in runs."], 1, 0.3, 0.3)
            if manage then
                tooltip:AddLine(L["Right-click to allow it again."], 0.4, 1, 0.4)
            end
            tooltip:Show()
        elseif not manage then
            return
        elseif CanSwitch(entry) then
            tooltip:AddLine(" ")
            tooltip:AddLine(L["Right-click to ban it from your runs."], 1, 0.82, 0)
            tooltip:Show()
        elseif book and entry.owned and POOL_KINDS[entry.kind] then
            local pool = book.pool[entry.kind]
            tooltip:AddLine(" ")
            tooltip:AddLine(pool.slots > 0 and (L["All your ban slots are in use ("] .. pool.used .. "/" .. pool.slots .. ").") or
                L["You have no ban slots yet."], 0.7, 0.7, 0.7, 1)
            tooltip:Show()
        end
    end
end

local function OnEnterEntry()
    ShowEntryTooltip(this, this.entry)
end

local UI = VanillaBonkUI

local window = UI.Window("VanillaBonkSpellbook", WIDTH, HEIGHT)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 30)
window.title:SetText(L["Spellbook"])
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

local Refresh

local TABS = {
    { key = "spells",     label = L["Spells"] },
    { key = "unlocks",    label = L["Passives"] },
    { key = "debuffs",    label = L["Debuffs"] },
    { key = "affixes",    label = L["Affixes"] },
    { key = "evolutions", label = L["Evolutions"] },
    { key = "rules",      label = L["Rules"] },
}

local eliteAffixes = {}

local function TabHasClasses()
    return currentTab == "spells" or currentTab == "evolutions"
end

local function TabHasInfoRows()
    return currentTab == "debuffs" or currentTab == "affixes"
end

local shownTabs = TABS

local function TabLabels()
    shownTabs = {}
    for _, tab in ipairs(TABS) do
        if (tab.key ~= "evolutions" or (book and getn(book.evolutions) > 0)) and
            (tab.key ~= "debuffs" or (book and book.debuffs and getn(book.debuffs) > 0)) and
            (tab.key ~= "affixes" or getn(eliteAffixes) > 0) and
            (tab.key ~= "rules" or (book and book.rules and getn(book.rules) > 0)) then
            tinsert(shownTabs, tab)
        end
    end
    local labels = {}
    for _, tab in ipairs(shownTabs) do
        tinsert(labels, tab.label)
    end
    return labels
end

local function UpdateTabs()
    UI.Tabs(window, TabLabels(), function(id)
        currentTab = shownTabs[id].key
        Refresh()
    end)
    local found = false
    for index, tab in ipairs(shownTabs) do
        if tab.key == currentTab then
            UI.SelectTab(window, index)
            found = true
        end
    end
    if not found then
        currentTab = shownTabs[1].key
        UI.SelectTab(window, 1)
    end
end

window.filters = {}

local function CreateFilterButton(index, mask, name)
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
        classFilter = this.mask
        PlaySound("igMainMenuOptionCheckBoxOn")
        Refresh()
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
    local all = CreateFilterButton(1, 0, L["All classes"])
    all.label = all:CreateFontString(nil, "OVERLAY")
    SetFont(all.label, NUMBER_FONT, 11, "OUTLINE")
    all.label:SetPoint("CENTER", all, "CENTER", 0, 0)
    all.label:SetText(L["All"])

    for index, class in ipairs(CLASSES) do
        local button = CreateFilterButton(index + 1, class.mask, class.name)
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

local function UpdateFilters()
    local shown = TabHasClasses()
    for _, button in ipairs(window.filters) do
        if shown then
            button:Show()
        else
            button:Hide()
        end
        if button.mask == classFilter then
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

local TogglePool

local function CreateCard(index)
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
    card.offText:SetText(L["OFF"])
    card.offTag:Hide()
    card.offText:Hide()

    window.cards[index] = card
    return card
end

local function PlaceCard(index, card)
    local column = math.mod(index - 1, 2)
    local row = math.floor((index - 1) / 2)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", window.list, "TOPLEFT", column * (CARD_WIDTH + 10), -row * (CARD_HEIGHT + CARD_GAP))
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

local function SortedSpells()
    local list = {}
    for _, spell in pairs(book.weapons) do
        if spell.evolvesFrom == 0 and MatchesFilter(spell) then
            tinsert(list, spell)
        end
    end
    table.sort(list, function(a, b)
        local ca, cb = FirstClassIndex(a.classMask), FirstClassIndex(b.classMask)
        if ca ~= cb then
            return ca < cb
        end
        local sa, sb = a.starterMask > 0, b.starterMask > 0
        if sa ~= sb then
            return sa
        end
        return a.name < b.name
    end)
    return list
end

local function SortedPassives()
    local list = {}
    for _, passive in pairs(book.passives) do
        tinsert(list, passive)
    end
    table.sort(list, function(a, b) return a.id < b.id end)
    return list
end

local function ShowCards(entries)
    for index, entry in ipairs(entries) do
        local card = window.cards[index] or CreateCard(index)
        PlaceCard(index, card)
        card.entry = entry
        card.icon:SetTexture(ICON_PATH .. (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark"))
        card.name:SetText(entry.name)

        local lock = book.locks[entry.kind .. entry.id]
        if entry.locked then
            card.detail:SetText(L["Locked by "] .. (lock and ("\"" .. lock.name .. "\"") or L["a quest"]))
        elseif entry.kind == "p" then
            card.detail:SetText(entry.maxRank > 0 and L["Unlocked, max rank "] .. entry.maxRank or L["Unlocked"])
        else
            local text = ClassNames(entry.classMask)
            if entry.starterMask > 0 and (classFilter == 0 or HasFlag(entry.starterMask, classFilter)) then
                text = text .. L[" starting spell"]
            end
            card.detail:SetText(text)
        end

        if entry.kind == "w" and book.evolutionOf[entry.id] then
            card.badge:SetText("|cffff9933>>|r")
        else
            card.badge:SetText("")
        end

        StyleCard(card, entry)
        if entry.off then
            card.name:SetTextColor(0.55, 0.55, 0.55)
            card.detail:SetText(L["|cffff6060Switched off: never offered|r"])
            SetDesaturation(card.icon, 1)
            card:SetBackdropColor(0.04, 0.04, 0.04, 0.6)
            card.offTag:Show()
            card.offText:Show()
        else
            card.offTag:Hide()
            card.offText:Hide()
        end
        if GetMouseFocus() == card then
            ShowEntryTooltip(GetMouseFocus(), entry)
        end
        card:Show()
    end
    for index = table.getn(entries) + 1, table.getn(window.cards) do
        window.cards[index]:Hide()
    end
    local rows = math.ceil(table.getn(entries) / 2)
    return rows * (CARD_HEIGHT + CARD_GAP)
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
        tinsert(parts, L("Up to {1} stacks", debuff.maxStacks))
    end
    if debuff.durationMs > 0 then
        tinsert(parts, L(getn(parts) > 0 and "lasts {1} sec" or "Lasts {1} sec", format("%g", debuff.durationMs / 1000)))
    end
    return table.concat(parts, L[", "])
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

local function ShowEvolutions()
    local shown, top = 0, 0
    local columns = EvolutionColumns()
    for _, base in ipairs(SortedSpells()) do
        local evolutions = book.evolutionOf[base.id]
        if evolutions then
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
    return top, shown
end

local rules = { section = 1, topics = {}, rows = {} }

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
        Refresh()
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

function Refresh(keepScroll)
    if not book then
        return
    end
    if currentTab == "rules" and book.rules and getn(book.rules) > 0 then
        UpdateTabs()
        UpdateFilters()
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        window.scroll:Hide()
        window.empty:SetText("")
        window.tally:SetText("")
        window.pool:SetText("")
        local name = rules.Show(book.rules)
        window.header:SetText(L["Rules|cff9d9d9d: "] .. name .. "|r")
        return
    end
    rules.Hide()
    window.scroll:Show()
    local scroll = keepScroll and window.scroll:GetVerticalScroll() or 0
    UpdateTabs()
    UpdateFilters()

    local height, count = 0, 0
    if not TabHasInfoRows() then
        for _, row in ipairs(window.debuffRows) do
            row:Hide()
        end
    end
    if TabHasInfoRows() then
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        for _, row in ipairs(window.evolutionRows) do
            row:Hide()
        end
        if currentTab == "affixes" then
            height, count = ShowInfoRows(eliteAffixes)
        else
            height, count = ShowInfoRows(book.debuffs, DescribeDebuffLimits)
        end
        window.empty:SetText(count == 0 and L["Nothing here yet."] or "")
    elseif currentTab == "evolutions" then
        for _, card in ipairs(window.cards) do
            card:Hide()
        end
        height, count = ShowEvolutions()
        window.empty:SetText(count == 0 and L["No evolutions for this class."] or "")
    else
        for _, row in ipairs(window.evolutionRows) do
            row:Hide()
        end
        local entries
        if currentTab == "unlocks" then
            entries = SortedPassives()
        else
            entries = SortedSpells()
        end
        height = ShowCards(entries)
        if table.getn(entries) > 0 then
            window.empty:SetText("")
        elseif TabHasClasses() and classFilter ~= 0 then
            window.empty:SetText(L["Nothing here for this class."])
        else
            window.empty:SetText(L["Nothing here yet."])
        end
    end

    window.list:SetHeight(max(LIST_HEIGHT, height))
    window.scroll:UpdateScrollChildRect()
    window.scroll:SetVerticalScroll(min(scroll, window.scroll:GetVerticalScrollRange()))

    local locked = 0
    for _, list in ipairs({ book.weapons, book.passives }) do
        for _, entry in pairs(list) do
            if entry.locked then
                locked = locked + 1
            end
        end
    end
    window.subtitle:SetText("|cffffffff" .. locked .. L[" locked by quests|r"])

    if TabHasClasses() or TabHasInfoRows() then
        window.tally:SetText("")
    else
        local owned, held = 0, 0
        for _, entry in pairs(book.passives) do
            if entry.owned then
                owned = owned + 1
            else
                held = held + 1
            end
        end
        window.tally:SetText(L("|cffffffff{1} owned|r|cff9d9d9d,|r |cffff6666{2} locked by quests|r", owned, held))
    end
    window.pool:SetText("")

    local className = L["All classes"]
    if TabHasClasses() then
        for _, class in ipairs(CLASSES) do
            if class.mask == classFilter then
                className = class.name
            end
        end
    end
    window.header:SetText(L("{1}|cff9d9d9d: {2} spells, {3} passives|r", className, book.spellCount, book.passiveCount))
end

TogglePool = function(entry)
    if not CanSwitch(entry) or window.buying then
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
        Refresh(true)
    end
end)

window:SetScript("OnHide", function()
    PlaySound("igSpellBookClose")
    atKeeper = false
    if window.fromGossip then
        window.fromGossip = nil
        if not window.gossipClosed then
            CloseGossip()
        end
    end
    window.gossipClosed = nil
end)

local function OpenFromGossip()
    window.fromGossip = true
    atKeeper = true
    window:Show()
    Refresh()
end

function VanillaBonkCodex.TakeOverGossip()
    local closeOnHide = GossipFrame:GetScript("OnHide")
    GossipFrame:SetScript("OnHide", nil)
    HideUIPanel(GossipFrame)
    GossipFrame:SetScript("OnHide", closeOnHide)
    OpenFromGossip()
end

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and pendingNpc then
        local npc = pendingNpc
        pendingNpc = nil
        if UnitName("npc") == npc then
            OpenFromGossip()
            return
        end
    elseif event == "GOSSIP_CLOSED" then
        pendingNpc = nil
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
    openRequested = true
    SendChatMessage(".bonk codex", "SAY")
end

local handlers = {}

handlers["cdx"] = function(f)
    incoming = {
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

handlers["cdxr"] = function(f)
    if not incoming or not f[2] or not f[3] then
        return
    end
    local sections = incoming.rules
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

handlers["cdxw"] = function(f)
    if not incoming then
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
    incoming.weapons[id] = spell
end

handlers["cdxwd"] = function(f)
    local spell = incoming and incoming.weapons[tonumber(f[2]) or 0]
    if spell then
        spell.description = f[3] or ""
        spell.school = f[4] or ""
        spell.spec = f[5] or ""
        spell.aoe = f[6] == "1"
        spell.radius = tonumber(f[7]) or 0
        spell.range = tonumber(f[8]) or 0
    end
end

handlers["cdxp"] = function(f)
    if not incoming then
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
    incoming.passives[id] = passive
end

handlers["cdxc"] = function(f)
    if not incoming then
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
    incoming.cards[id] = card
end

handlers["cdxcd"] = function(f)
    local card = incoming and incoming.cards[tonumber(f[2]) or 0]
    if card then
        card.description = f[3] or ""
    end
end

handlers["cdxk"] = function(f)
    if not incoming then
        return
    end
    tinsert(incoming.debuffs, {
        id = tonumber(f[2]) or 0,
        name = f[3] or "",
        icon = f[4] or "",
        maxStacks = tonumber(f[5]) or 1,
        durationMs = tonumber(f[6]) or 0,
        description = f[7] or "",
    })
end

handlers["affixinfo"] = function(f)
    local name = f[2]
    if not name or name == "" then
        return
    end
    for _, affix in ipairs(eliteAffixes) do
        if affix.name == name then
            affix.icon, affix.description = f[3] or "", f[4] or ""
            return
        end
    end
    tinsert(eliteAffixes, { name = name, icon = f[3] or "", description = f[4] or "" })
end

handlers["cdxg"] = function(f)
    if not incoming or not f[2] or f[2] == "" then
        return
    end
    local glyph = { kind = "g", id = tonumber(f[2]) or f[2], key = f[2] }
    ReadState(glyph, f[3])
    incoming.glyphs[f[2]] = glyph
end

handlers["cdxpool"] = function(f)
    if incoming and incoming.pool[f[2] or ""] then
        incoming.pool[f[2]] = { used = tonumber(f[3] or "") or 0, slots = tonumber(f[4] or "") or 0 }
    end
end

handlers["cdxban"] = function(f)
    if incoming and incoming.bans[f[2] or ""] then
        tinsert(incoming.bans[f[2]], { earned = f[3] == "1", tickets = tonumber(f[4] or "") or 0, label = f[5] or "", detail = f[6] or "" })
    end
end

handlers["cdxcs"] = function(f)
    if incoming and f[2] then
        incoming.stacks[tonumber(f[2]) or 0] = { one = f[3] or "", five = f[4] or "" }
    end
end

handlers["cdxtickets"] = function(f)
    if incoming then
        incoming.tickets = tonumber(f[2] or "") or 0
    end
end

handlers["cdxoff"] = function(f)
    if incoming and f[2] and f[3] then
        incoming.off[f[2] .. f[3]] = true
    end
end

handlers["cdxq"] = function(f)
    if incoming then
        incoming.locks[(f[2] or "") .. (f[3] or "")] = { name = f[4] or "", description = f[5] or "",
            progress = tonumber(f[6]) or 0, amount = tonumber(f[7]) or 1 }
    end
end

handlers["cdxend"] = function()
    if not incoming then
        return
    end
    local received = incoming
    incoming = nil

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
        glyph.name = text and text.name or (L["Glyph "] .. key)
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
    book = received
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
        openRequested = nil
        if received.npc ~= "" then
            atKeeper = true
        end
        Refresh(true)
    elseif received.npc ~= "" then
        classFilter = received.classMask
        if GossipFrame:IsVisible() and UnitName("npc") == received.npc then
            VanillaBonkCodex.TakeOverGossip()
        else
            pendingNpc = received.npc
        end
    elseif openRequested then
        openRequested = nil
        classFilter = received.classMask
        window:Show()
        Refresh()
    end
end

VanillaBonkCodex.ShowEntryTooltip = ShowEntryTooltip
VanillaBonkCodex.CanSwitch = CanSwitch
VanillaBonkCodex.TogglePool = function(entry)
    return TogglePool(entry)
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:RegisterEvent("PLAYER_MONEY")
events:SetScript("OnEvent", function()
    if event == "PLAYER_MONEY" then
        if window:IsShown() then
            Refresh(true)
        end
        return
    end
    if not arg1 or strsub(arg1, 1, strlen(PREFIX)) ~= PREFIX then
        return
    end
    local f = Split(strsub(arg1, strlen(PREFIX) + 1), "~")
    local handler = handlers[f[1]]
    if handler then
        handler(f)
    end
end)
