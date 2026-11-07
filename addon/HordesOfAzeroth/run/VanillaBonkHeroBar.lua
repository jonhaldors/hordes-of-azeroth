local L = VanillaBonkL
local UI = VanillaBonkUI

local SPELL_SLOTS = 5
local PASSIVE_SLOTS = 6
local BAR_ART = "Interface\\MainMenuBar\\UI-MainMenuBar-Dwarf"
local GRYPHON_ART = "Interface\\MainMenuBar\\UI-MainMenuBar-EndCap-Dwarf"
local LEVEL_PLATE_ART = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\LevelPlate"
local RECESS_ART = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\SlotRecess"
local SPELL_SIZE = 44
local PASSIVE_SIZE = 32
local SPELL_GAP = 6
local PASSIVE_GAP = 5
local GROUP_GAP = 14
local RECESS_INSET = 6
local RAIL_HEIGHT = 12
local RUN_PLATE_HEIGHT = 64
local CAMP_PLATE_HEIGHT = 52
local CAMP_WIDTH = 520
local GRYPHON_VISIBLE = 58
local GRYPHON_SCALE = 0.85
local GRYPHON_ANCHOR = 62
local GRYPHON_BODY_EDGE = 100
local GRYPHON_HEAD_EDGE = 120
local LEVEL_PLATE_WIDTH = 50
local LEVEL_PLATE_HEIGHT = 34
local LEVEL_PLATE_RAISE = 1
local DASH_SIZE = 32
local BAR_SCALE = 0.85

local HeroBar = UI.Module("heroBar")

HeroBar.run = { spells = {}, passives = {}, info = {}, stats = {} }
HeroBar.inRun = false

local root = CreateFrame("Frame", "VanillaBonkHeroBar", UIParent)
root:SetWidth(1)
root:SetHeight(1)
root:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 0)
root:SetScale(BAR_SCALE)

local runFrame = CreateFrame("Frame", nil, root)
runFrame:SetAllPoints(root)
local campFrame = CreateFrame("Frame", nil, root)
campFrame:SetAllPoints(root)

HeroBar.root = root
HeroBar.runFrame = runFrame
HeroBar.campFrame = campFrame

local function BarTexture(parent, layer, left, right, top, bottom)
    local texture = parent:CreateTexture(nil, layer)
    texture:SetTexture(BAR_ART)
    texture:SetTexCoord(left / 256, right / 256, top / 256, bottom / 256)
    return texture
end

local function GryphonSize(plateHeight)
    return (plateHeight + RAIL_HEIGHT) * 128 / GRYPHON_VISIBLE * GRYPHON_SCALE
end

local function GryphonInset(plateHeight, edge)
    return GryphonSize(plateHeight) * (edge - GRYPHON_ANCHOR) / 128
end

local function AddRail(plate, width)
    local art = CreateFrame("Frame", nil, plate)
    art:SetAllPoints(plate)
    art:SetFrameLevel(plate:GetFrameLevel() + 2)
    local function Piece(left, right, x, pieceWidth, flip)
        local texture = BarTexture(art, "ARTWORK", flip and right or left, flip and left or right, 203, 213)
        texture:SetWidth(pieceWidth)
        texture:SetHeight(RAIL_HEIGHT)
        texture:SetPoint("TOPLEFT", plate, "TOPLEFT", x, 0)
    end
    Piece(0, 53, 0, 53)
    Piece(0, 53, width - 53, 53, true)
    local half = width / 2
    local x = 53
    while x < half do
        local pieceWidth = min(52, half - x)
        Piece(53, 53 + pieceWidth, x, pieceWidth)
        Piece(53, 53 + pieceWidth, width - x - pieceWidth, pieceWidth, true)
        x = x + 52
    end
    return art
end

local function AddRailBar(plate, plateHeight, r, g, b)
    local inset = GryphonInset(plateHeight, GRYPHON_HEAD_EDGE)
    local scale = RAIL_HEIGHT / 10
    local bar = CreateFrame("StatusBar", nil, plate)
    bar:SetPoint("TOPLEFT", plate, "TOPLEFT", inset, -3 * scale)
    bar:SetPoint("BOTTOMRIGHT", plate, "TOPRIGHT", -inset, -9 * scale)
    bar:SetFrameLevel(plate:GetFrameLevel() + 1)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(r, g, b)
    bar:SetMinMaxValues(0, 1)
    bar.back = bar:CreateTexture(nil, "BACKGROUND")
    bar.back:SetTexture(UI.FLAT)
    bar.back:SetVertexColor(0.03, 0.02, 0.02, 1)
    bar.back:SetAllPoints(bar)
    return bar
end

local function AddGryphons(plate, plateHeight)
    local size = GryphonSize(plateHeight)
    local holder = CreateFrame("Frame", nil, plate)
    holder:SetAllPoints(plate)
    holder:SetFrameLevel(plate:GetFrameLevel() + 6)
    for side = 1, 2 do
        local texture = holder:CreateTexture(nil, "OVERLAY")
        texture:SetTexture(GRYPHON_ART)
        texture:SetWidth(size)
        texture:SetHeight(size)
        if side == 1 then
            texture:SetPoint("BOTTOMLEFT", plate, "BOTTOMLEFT", -size * GRYPHON_ANCHOR / 128, 0)
        else
            texture:SetTexCoord(1, 0, 0, 1)
            texture:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", size * GRYPHON_ANCHOR / 128, 0)
        end
    end
end

local function CreatePlate(parent, width, plateHeight)
    local plate = CreateFrame("Frame", nil, parent)
    plate:SetWidth(width)
    plate:SetHeight(plateHeight + RAIL_HEIGHT)
    plate:SetPoint("BOTTOM", root, "BOTTOM", 0, 0)
    local fill = BarTexture(plate, "BACKGROUND", 60, 230, 88, 124)
    fill:SetPoint("BOTTOMLEFT", plate, "BOTTOMLEFT", 0, 4)
    fill:SetPoint("TOPRIGHT", plate, "BOTTOMRIGHT", 0, plateHeight - 4)
    local top = BarTexture(plate, "BORDER", 60, 230, 84, 88)
    top:SetHeight(4)
    top:SetPoint("TOPLEFT", plate, "BOTTOMLEFT", 0, plateHeight)
    top:SetPoint("TOPRIGHT", plate, "BOTTOMRIGHT", 0, plateHeight)
    local bottom = BarTexture(plate, "BORDER", 60, 230, 124, 128)
    bottom:SetHeight(4)
    bottom:SetPoint("BOTTOMLEFT", plate, "BOTTOMLEFT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", plate, "BOTTOMRIGHT", 0, 0)
    plate.rail = AddRail(plate, width)
    AddGryphons(plate, plateHeight)
    return plate
end

local function AddRecess(plate, x, centerY, width, height, inset)
    inset = inset or RECESS_INSET
    local outerWidth, outerHeight = width + 2 * inset, height + 2 * inset
    local capWidth = min(outerHeight / 4, outerWidth / 2)
    local function Piece(left, right)
        local texture = plate:CreateTexture(nil, "BORDER")
        texture:SetTexture(RECESS_ART)
        texture:SetTexCoord(left, right, 0, 1)
        texture:SetHeight(outerHeight)
        return texture
    end
    local bottomY = centerY - outerHeight / 2
    local leftCap = Piece(0, 0.25)
    leftCap:SetWidth(capWidth)
    leftCap:SetPoint("BOTTOMLEFT", plate, "BOTTOMLEFT", x - inset, bottomY)
    local rightCap = Piece(0.75, 1)
    rightCap:SetWidth(capWidth)
    rightCap:SetPoint("BOTTOMRIGHT", plate, "BOTTOMLEFT", x + width + inset, bottomY)
    local middle = Piece(0.25, 0.75)
    middle:SetPoint("TOPLEFT", leftCap, "TOPRIGHT", 0, 0)
    middle:SetPoint("BOTTOMRIGHT", rightCap, "BOTTOMLEFT", 0, 0)
end

local function AddDock(plate, x, centerY, size)
    local dock = CreateFrame("Frame", nil, plate)
    dock:SetWidth(size)
    dock:SetHeight(size)
    dock:SetPoint("CENTER", plate, "BOTTOMLEFT", x + size / 2, centerY)
    return dock
end

local function AddLevelPlate(plate, plateHeight)
    local level = CreateFrame("Frame", nil, plate)
    level:SetWidth(LEVEL_PLATE_WIDTH)
    level:SetHeight(LEVEL_PLATE_HEIGHT)
    level:SetPoint("CENTER", plate, "BOTTOM", 0, plateHeight + RAIL_HEIGHT + LEVEL_PLATE_RAISE)
    level:SetFrameLevel(plate:GetFrameLevel() + 5)
    level.art = level:CreateTexture(nil, "ARTWORK")
    level.art:SetTexture(LEVEL_PLATE_ART)
    level.art:SetTexCoord(0, 1, 0, 87 / 128)
    level.art:SetAllPoints(level)
    level.text = UI.Text(level, 20, UI.TITLE_FONT)
    level.text:SetPoint("CENTER", level, "CENTER", 0, 0)
    level.text:SetTextColor(1, 0.82, 0)
    level:EnableMouse(true)
    return level
end

local function AddRailHover(plate)
    local hover = CreateFrame("Frame", nil, plate)
    hover:SetPoint("TOPLEFT", plate, "TOPLEFT", 0, 0)
    hover:SetPoint("BOTTOMRIGHT", plate, "TOPRIGHT", 0, -RAIL_HEIGHT)
    hover:SetFrameLevel(plate:GetFrameLevel() + 4)
    hover:EnableMouse(true)
    return hover
end

local spellRowWidth = SPELL_SLOTS * SPELL_SIZE + (SPELL_SLOTS - 1) * SPELL_GAP
local wingWidth = 3 * PASSIVE_SIZE + 2 * PASSIVE_GAP
local runMargin = ceil(GryphonInset(RUN_PLATE_HEIGHT, GRYPHON_BODY_EDGE)) + 4
local runWidth = 2 * runMargin + 2 * PASSIVE_SIZE + 2 * wingWidth + spellRowWidth + 4 * GROUP_GAP
local runCenterY = RUN_PLATE_HEIGHT / 2

local runPlate = CreatePlate(runFrame, runWidth, RUN_PLATE_HEIGHT)
local spellBar = runPlate
HeroBar.runPlate = runPlate
HeroBar.spellBar = spellBar

local runLayout = {}
do
    local x = runMargin
    local function Group(name, count, size, gap)
        local width = count * size + (count - 1) * gap
        AddRecess(runPlate, x, runCenterY, width, size)
        runLayout[name] = { x = x, size = size, gap = gap }
        x = x + width + GROUP_GAP
    end
    Group("dash", 1, PASSIVE_SIZE, 0)
    Group("left", 3, PASSIVE_SIZE, PASSIVE_GAP)
    Group("spells", SPELL_SLOTS, SPELL_SIZE, SPELL_GAP)
    Group("right", 3, PASSIVE_SIZE, PASSIVE_GAP)
    Group("hearth", 1, PASSIVE_SIZE, 0)
end

local runDashDock = AddDock(runPlate, runLayout.dash.x, runCenterY, PASSIVE_SIZE)
UI.HearthDock = AddDock(runPlate, runLayout.hearth.x, runCenterY, PASSIVE_SIZE)
HeroBar.runDashDock = runDashDock

local xpBar = AddRailBar(runPlate, RUN_PLATE_HEIGHT, 0.58, 0.0, 0.55)
local xpText = UI.Text(runPlate.rail, 10, UI.NUMBER_FONT, "OUTLINE")
xpText:SetPoint("CENTER", runPlate, "TOP", runWidth / 4, -RAIL_HEIGHT / 2)
local xpHover = AddRailHover(runPlate)
HeroBar.xpBar = xpBar
HeroBar.xpText = xpText
HeroBar.xpHover = xpHover

local levelRing = AddLevelPlate(runPlate, RUN_PLATE_HEIGHT)
root.levelPlate = levelRing
VanillaBonkLevelRing = levelRing
HeroBar.levelRing = levelRing

UI.GlyphAnchor = CreateFrame("Frame", nil, runPlate)
UI.GlyphAnchor:SetWidth(1)
UI.GlyphAnchor:SetHeight(1)
UI.GlyphAnchor:SetPoint("BOTTOMLEFT", runPlate, "TOPLEFT", ceil(GryphonInset(RUN_PLATE_HEIGHT, GRYPHON_HEAD_EDGE)) + 8, 3)

local spellSlots, passiveSlots = {}, {}
HeroBar.spellSlots = spellSlots
HeroBar.passiveSlots = passiveSlots

local LOCKED_SLOTS = {
    spell = { talent = L["hoa.addon.spell_slot"], start = 3, ranks = {
        { quest = L["hoa.addon.renowned"], quests = 25 }, { quests = 45 },
    } },
    passive = { talent = L["hoa.addon.passive_slot"], start = 3, ranks = {
        { quest = L["hoa.addon.trusted_adventurer"], quests = 15 }, { quests = 35 }, { quests = 55 },
    } },
}

function HeroBar:AddPassiveLines(entry)
    local info = self.run.info[entry.index] or {}
    GameTooltip:AddDoubleLine(info.name or "?", (entry.max > 0 and L("hoa.addon.rank_1_2", entry.rank, entry.max) or L("hoa.addon.rank_1", entry.rank)), 1, 1, 1, 0.6, 0.6, 0.6)
    GameTooltip:AddLine(L["hoa.addon.passive"], 0.6, 0.6, 0.6)
    if info.description and info.description ~= "" then
        GameTooltip:AddLine(info.description, 1, 0.82, 0, 1)
    end
end

local function BestRarity(ranks)
    local best = 0
    for index = 1, strlen(ranks or "") do
        best = max(best, tonumber(strsub(ranks, index, index)) or 0)
    end
    return best
end

function HeroBar:ShowSpellTip(owner, anchor, entry, stat)
    local Tip = VanillaBonkSpellTip
    local info = self.run.info[entry.index] or {}
    local evolved = entry.kind == "e"
    local rarity = UI.RARITY[evolved and 4 or BestRarity(info.ranks)]
    Tip:SetOwner(owner, anchor)
    Tip:SetLegendary(evolved)
    Tip:Title(info.name or "?", { rarity.r, rarity.g, rarity.b })
    if evolved and info.evolvedFrom and info.evolvedFrom ~= "" then
        Tip:AddSmallLine(L("hoa.addon.evolved_from_1", info.evolvedFrom), Tip.ORANGE)
    end

    local headerColor = info.faster and Tip.GREEN or Tip.WHITE
    Tip:AddDoubleLine(((entry.max or 0) > 0 and entry.rank >= entry.max) and L["hoa.addon.max_rank"] or L("hoa.addon.rank_1", entry.rank), Tip.ReachText(info.radius, info.range, info.currentRadius, info.currentRange),
        0.62, 0.62, 0.62, 1, 1, 1)
    if info.header and info.header ~= "" then
        Tip:AddDoubleLine(L["hoa.addon.instant"], info.header, 1, 1, 1, headerColor[1], headerColor[2], headerColor[3])
    end
    if info.description and info.description ~= "" then
        Tip:AddLine(info.description, 1, 0.82, 0)
    end
    if info.line and info.line ~= "" then
        Tip:AddSmallLine(L["hoa.addon.upgrades"], Tip.GOLD)
        Tip:AddSmallLine(info.line, Tip.GREEN)
    end
    Tip:AddFooter(info.spec, info.school, info.aoe)
    if stat and (stat.damage or 0) > 0 then
        local total = 0
        for _, other in pairs(self.run.stats) do
            total = total + other.damage
        end
        local share = total > 0 and floor(stat.damage / total * 100 + 0.5) or 0
        Tip:AddRule()
        Tip:AddDoubleLine(L("hoa.addon.1_damage_2_of_total", VanillaBonkUI.Short(stat.damage), share), L((stat.kills or 0) == 1 and "hoa.addon.1_kill" or "hoa.addon.1_kills", stat.kills or 0),
            0.62, 0.62, 0.62, 0.62, 0.62, 0.62, 11)
    end
    Tip:Show()
end

function HeroBar:ShowEntry(owner, anchor, entry, stat)
    if entry.kind == "p" then
        GameTooltip:SetOwner(owner, anchor)
        self:AddPassiveLines(entry)
        GameTooltip:Show()
    else
        self:ShowSpellTip(owner, anchor, entry, stat)
    end
end

function HeroBar:ShowSlotTooltip(slot)
    GameTooltip:SetOwner(slot, "ANCHOR_TOP")
    local entry = slot.entry
    if slot.locked then
        local kind = slot.isSpell and "spell" or "passive"
        local unlock = LOCKED_SLOTS[kind]
        local rank = max(1, slot.slotIndex - unlock.start)
        local need = unlock.ranks[rank] or unlock.ranks[getn(unlock.ranks)]
        GameTooltip:AddLine(slot.isSpell and L["hoa.addon.locked_spell_slot"] or L["hoa.addon.locked_passive_slot"], 1, 1, 1)
        if rank == 1 then
            GameTooltip:AddLine(L("hoa.addon.buy_1_from_sayge_at_the_inn_to_unlock_it", unlock.talent), 1, 0.82, 0, 1)
            GameTooltip:AddLine(L("hoa.addon.sayge_sells_it_once_you_finish_the_quest_1_complete_2_quests", need.quest, need.quests),
                0.6, 0.6, 0.6, 1)
        else
            GameTooltip:AddLine(L("hoa.addon.buy_rank_1_of_2_from_sayge_at_the_inn_to_unlock_it", rank, unlock.talent), 1, 0.82, 0, 1)
            GameTooltip:AddLine(L("hoa.addon.sayge_sells_rank_1_once_you_have_completed_2_quests", rank, need.quests), 0.6, 0.6, 0.6, 1)
        end
        GameTooltip:Show()
        return
    end
    if not entry then
        if slot.isSpell then
            GameTooltip:AddLine(L["hoa.addon.empty_spell_slot"], 1, 1, 1)
            GameTooltip:AddLine(L["hoa.addon.level_ups_can_offer_a_new_spell_while_a_slot_is_free"], 1, 0.82, 0, 1)
            GameTooltip:AddLine(L("hoa.addon.up_to_1_spells_per_run", SPELL_SLOTS), 0.6, 0.6, 0.6)
        else
            GameTooltip:AddLine(L["hoa.addon.empty_passive_slot"], 1, 1, 1)
            GameTooltip:AddLine(L("hoa.addon.up_to_1_passives_per_run", PASSIVE_SLOTS), 0.6, 0.6, 0.6)
        end
        GameTooltip:Show()
        return
    end

    self:ShowEntry(slot, "ANCHOR_TOP", entry, self.run.stats[slot.spellIndex])
end

function HeroBar:ShowEntryTooltip(owner, entry, stat)
    self:ShowEntry(owner, "ANCHOR_RIGHT", entry, stat)
end

function VanillaBonk_LoadoutTooltip(owner, name, stat)
    for _, entry in ipairs(HeroBar.run.spells) do
        local info = HeroBar.run.info[entry.index]
        if info and info.name == name then
            HeroBar:ShowEntryTooltip(owner, entry, stat)
            return true
        end
    end
    return false
end

function VanillaBonk_SpellTooltip(owner, index)
    local entry = HeroBar.run.spells[index]
    if not entry then
        return false
    end
    HeroBar:ShowEntryTooltip(owner, entry, HeroBar.run.stats[index])
    return true
end

function VanillaBonk_PassiveTooltip(owner, index)
    local entry = HeroBar.run.passives[index]
    if not entry then
        return false
    end
    HeroBar:ShowEntryTooltip(owner, entry)
    return true
end

function VanillaBonkUI.Short(value)
    value = tonumber(value) or 0
    if value >= 1000000 then
        return format("%.2fm", value / 1000000)
    elseif value >= 10000 then
        return format("%.1fk", value / 1000)
    end
    return tostring(floor(value))
end

local STEEL = { 0.62, 0.62, 0.66 }

local function StyleBadge(slot)
    local badge = slot.badge
    badge:SetWidth(slot.isSpell and 16 or 13)
    badge:SetHeight(slot.isSpell and 14 or 11)
    badge:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", 0, 0)
    badge.disc:SetTexture(UI.FLAT)
    badge.disc:SetVertexColor(0.05, 0.05, 0.06, 0.9)
    badge.disc:SetAllPoints(badge)
    badge.rim:SetTexture(UI.FLAT)
    badge.rim:SetVertexColor(STEEL[1], STEEL[2], STEEL[3], 0.9)
    badge.rim:SetPoint("TOPLEFT", badge, "TOPLEFT", 0, 0)
    badge.rim:SetPoint("TOPRIGHT", badge, "TOPRIGHT", 0, 0)
    badge.rim:SetHeight(1)
    badge.edge:SetTexture(UI.FLAT)
    badge.edge:SetVertexColor(STEEL[1], STEEL[2], STEEL[3], 0.9)
    badge.edge:SetPoint("TOPLEFT", badge, "TOPLEFT", 0, 0)
    badge.edge:SetPoint("BOTTOMLEFT", badge, "BOTTOMLEFT", 0, 0)
    badge.edge:SetWidth(1)
    slot.rank:SetPoint("CENTER", badge, "CENTER", 1, 0)
end

local COUNTDOWN_MIN_INTERVAL = 2
local COUNTDOWN_HIDE_BELOW = 1

local function CountdownColor(remaining)
    if remaining <= 3 then
        return 0.3, 1, 0.3
    elseif remaining <= 6 then
        return 1, 0.85, 0.2
    end
    return 1, 0.25, 0.2
end

local function CreateSlot(parent, size, isSpell)
    local slot = CreateFrame("Button", nil, parent)
    slot:SetWidth(size)
    slot:SetHeight(size)
    slot.isSpell = isSpell
    slot.back = BarTexture(slot, "BACKGROUND", 52, 84, 217, 249)
    slot.back:SetAllPoints(slot)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetAllPoints(slot)
    UI.CropIcon(slot.icon)
    slot.frame = slot:CreateTexture(nil, "OVERLAY")
    slot.frame:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    slot.frame:SetWidth(size * 66 / 36)
    slot.frame:SetHeight(size * 66 / 36)
    UI.CenterSlotFrame(slot.frame, slot, size)

    local top = CreateFrame("Frame", nil, slot)
    top:SetAllPoints(slot)
    top:SetFrameLevel(slot:GetFrameLevel() + 3)

    slot.shade = slot:CreateTexture(nil, "ARTWORK")
    slot.shade:SetTexture(UI.FLAT)
    slot.shade:SetVertexColor(0, 0, 0, 0.6)
    slot.shade:SetAllPoints(slot)
    slot.shade:Hide()
    slot.lock = top:CreateTexture(nil, "OVERLAY")
    slot.lock:SetTexture("Interface\\ChatFrame\\UI-ChatFrame-LockIcon")
    slot.lock:SetWidth(isSpell and 20 or 17)
    slot.lock:SetHeight(isSpell and 20 or 17)
    slot.lock:SetPoint("CENTER", slot, "CENTER", 0, 0)
    slot.lock:Hide()

    if isSpell then
        slot.cooldown = CreateFrame("Model", nil, slot, "CooldownFrameTemplate")
        slot.cooldown:ClearAllPoints()
        slot.cooldown:SetAllPoints(slot)
        slot.cooldown:SetScale(size / 36)
        slot.glow = top:CreateTexture(nil, "OVERLAY")
        slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.glow:SetBlendMode("ADD")
        slot.glow:SetWidth(size * 62 / 36)
        slot.glow:SetHeight(size * 62 / 36)
        slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.ready = top:CreateTexture(nil, "OVERLAY")
        slot.ready:SetTexture("Interface\\Buttons\\UI-AutoCastableOverlay")
        slot.ready:SetWidth(size * 64 / 40)
        slot.ready:SetHeight(size * 64 / 40)
        slot.ready:SetPoint("CENTER", slot, "CENTER", 0, 0)
        slot.reachMark = top:CreateTexture(nil, "OVERLAY")
        slot.reachMark:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
        slot.reachMark:SetWidth(10)
        slot.reachMark:SetHeight(10)
        slot.reachMark:SetPoint("TOPLEFT", slot, "TOPLEFT", 2, -2)
        slot.reachMark:Hide()
        slot:SetScript("OnClick", function()
            if IsAltKeyDown() and this.entry and not this.locked then
                UI.ChooseReachRingSlot(this.entry.index)
            end
        end)
    end

    slot.highlight = slot:CreateTexture(nil, "HIGHLIGHT")
    slot.highlight:SetTexture("Interface\\Buttons\\ButtonHilight-Square")
    slot.highlight:SetBlendMode("ADD")
    slot.highlight:SetAllPoints(slot)

    local badge = CreateFrame("Frame", nil, slot)
    badge:SetFrameLevel(top:GetFrameLevel() + 1)
    badge.rim = badge:CreateTexture(nil, "ARTWORK")
    badge.edge = badge:CreateTexture(nil, "ARTWORK")
    badge.disc = badge:CreateTexture(nil, "BORDER")
    slot.badge = badge
    slot.rank = UI.Text(badge, isSpell and 11 or 10, UI.NUMBER_FONT, "OUTLINE")
    StyleBadge(slot)

    if isSpell then
        slot.countdown = UI.Text(top, 20, UI.NUMBER_FONT, "THICKOUTLINE")
        slot.countdown:SetPoint("CENTER", slot, "CENTER", 1, 0)
    end

    UI.Hover(slot, function()
        HeroBar:ShowSlotTooltip(this)
    end)
    return slot
end

local function PlaceInGroup(slot, group, position)
    local x = group.x + (position - 1) * (group.size + group.gap)
    slot:SetPoint("CENTER", runPlate, "BOTTOMLEFT", x + group.size / 2, runCenterY)
end

for index = 1, SPELL_SLOTS do
    local slot = CreateSlot(runPlate, SPELL_SIZE, true)
    PlaceInGroup(slot, runLayout.spells, index)
    spellSlots[index] = slot
end
for index = 1, PASSIVE_SLOTS do
    local slot = CreateSlot(runPlate, PASSIVE_SIZE, false)
    if index <= 3 then
        PlaceInGroup(slot, runLayout.left, index)
    else
        PlaceInGroup(slot, runLayout.right, index - 3)
    end
    passiveSlots[index] = slot
end

function HeroBar:RestartCooldown(slot)
    local info = slot.entry and self.run.info[slot.entry.index]
    if not info or not info.interval or info.interval <= 0 or info.held then
        slot.cooldown:Hide()
        slot.cycleStart = nil
        return
    end
    local interval = info.interval / 1000
    if not slot.cycleStart then
        slot.cycleStart = GetTime() - max(0, interval - (info.nextCast or 0) / 1000)
    end
    while GetTime() - slot.cycleStart >= interval do
        slot.cycleStart = slot.cycleStart + interval
    end
    CooldownFrame_SetTimer(slot.cooldown, slot.cycleStart, interval, 1)
end

function HeroBar:UpdateCountdown(slot)
    local info = slot.entry and self.run.info[slot.entry.index]
    local interval = info and info.interval and info.interval / 1000 or 0
    local remaining = slot.cycleStart and interval - (GetTime() - slot.cycleStart) or 0
    if info and not info.held and UI.Option("cooldownNumbers", true) and interval >= COUNTDOWN_MIN_INTERVAL and remaining >= COUNTDOWN_HIDE_BELOW then
        slot.countdown:SetText(floor(remaining))
        slot.countdown:SetTextColor(CountdownColor(remaining))
        slot.countdown:Show()
    else
        slot.countdown:Hide()
    end
end

function HeroBar:RefreshReachMark(slot)
    if not slot.reachMark then
        return
    end
    if slot.entry and self.run.reachSlot and slot.entry.index == self.run.reachSlot then
        local color = UI.ReachRingColor()
        slot.reachMark:SetVertexColor(color.r, color.g, color.b)
        slot.reachMark:Show()
    else
        slot.reachMark:Hide()
    end
end

function HeroBar:UpdateSlot(slot, entry)
    slot.entry = entry
    self:RefreshReachMark(slot)
    if not entry then
        slot.icon:Hide()
        slot.badge:Hide()
        if slot.countdown then
            slot.countdown:Hide()
        end
        if slot.glow then
            slot.glow:Hide()
            slot.ready:Hide()
            slot.cooldown:Hide()
        end
        return
    end
    slot.icon:SetTexture(UI.ICON_PATH .. entry.icon)
    UI.CropIcon(slot.icon)
    slot.icon:Show()
    slot.badge:Show()
    slot.rank:SetText(entry.rank)
    if not slot.glow then
        slot.rank:SetTextColor(1, 1, 1)
        return
    end

    local info = self.run.info[entry.index] or {}
    local best = 0
    if entry.kind == "e" then
        best = 4
    elseif info.ranks then
        for index = 1, strlen(info.ranks) do
            best = max(best, tonumber(strsub(info.ranks, index, index)) or 0)
        end
    end
    if best > 0 then
        local color = UI.RARITY[best]
        slot.glow:SetVertexColor(color.r, color.g, color.b)
        slot.glow:Show()
    else
        slot.glow:Hide()
    end
    if entry.kind == "e" then
        slot.rank:SetTextColor(1, 0.82, 0)
    else
        slot.rank:SetTextColor(1, 1, 1)
    end
    if info.chance and info.chance ~= "" and entry.kind ~= "e" and tonumber(info.chanceValue or 0) > 0 then
        slot.ready:Show()
    else
        slot.ready:Hide()
    end
    slot.cycleStart = nil
    self:RestartCooldown(slot)
end

function HeroBar:SetLocked(slot, locked)
    slot.locked = locked
    if locked then
        slot.shade:Show()
        slot.lock:Show()
    else
        slot.shade:Hide()
        slot.lock:Hide()
    end
end

function HeroBar:RefreshSlots()
    for index = 1, SPELL_SLOTS do
        self:UpdateSlot(spellSlots[index], self.run.spells[index])
        self:SetLocked(spellSlots[index], not self.run.spells[index] and index > (self.run.spellSlots or SPELL_SLOTS))
        spellSlots[index].spellIndex = index
        spellSlots[index].slotIndex = index
    end
    for index = 1, PASSIVE_SLOTS do
        self:UpdateSlot(passiveSlots[index], self.run.passives[index])
        self:SetLocked(passiveSlots[index], not self.run.passives[index] and index > (self.run.passiveSlots or PASSIVE_SLOTS))
        passiveSlots[index].slotIndex = index
    end
end

function HeroBar:RunHeld()
    local offer, vendor, gear = getglobal("VanillaBonkOffer"), getglobal("VanillaBonkVendor"), getglobal("VanillaBonkGear")
    return (offer and offer.open) or (vendor and vendor.open) or (gear and gear.open) or (UI.MenuPaused and UI.MenuPaused())
end

function UI.RunHeld()
    return HeroBar:RunHeld()
end

function HeroBar:HoldCooldowns(elapsed)
    for _, slot in ipairs(self.spellSlots) do
        local info = slot.entry and self.run.info[slot.entry.index]
        if slot.cycleStart and info and info.interval then
            slot.cycleStart = slot.cycleStart + elapsed
            CooldownFrame_SetTimer(slot.cooldown, slot.cycleStart, info.interval / 1000, 1)
        end
    end
end

spellBar:SetScript("OnUpdate", function()
    if HeroBar:RunHeld() then
        HeroBar:HoldCooldowns(arg1)
        return
    end
    this.elapsed = (this.elapsed or 0) + arg1
    if this.elapsed < 0.1 then
        return
    end
    this.elapsed = 0
    for _, slot in ipairs(HeroBar.spellSlots) do
        local info = slot.entry and HeroBar.run.info[slot.entry.index]
        if slot.cycleStart and info and info.interval and GetTime() - slot.cycleStart >= info.interval / 1000 then
            HeroBar:RestartCooldown(slot)
        end
        HeroBar:UpdateCountdown(slot)
    end
end)

local campPlate = CreatePlate(campFrame, CAMP_WIDTH, CAMP_PLATE_HEIGHT)
local campCenterY = CAMP_PLATE_HEIGHT / 2
local campMargin = ceil(GryphonInset(CAMP_PLATE_HEIGHT, GRYPHON_BODY_EDGE)) + 4
AddRecess(campPlate, campMargin, campCenterY, DASH_SIZE, DASH_SIZE)
local campDashDock = AddDock(campPlate, campMargin, campCenterY, DASH_SIZE)
HeroBar.campPlate = campPlate
HeroBar.campDashDock = campDashDock

local masteryBar = AddRailBar(campPlate, CAMP_PLATE_HEIGHT, 0.95, 0.65, 0.15)
local masteryText = UI.Text(campPlate.rail, 10, UI.NUMBER_FONT, "OUTLINE")
masteryText:SetPoint("CENTER", campPlate, "TOP", CAMP_WIDTH / 4, -RAIL_HEIGHT / 2)
local masteryHover = AddRailHover(campPlate)
local masteryLevel = AddLevelPlate(campPlate, CAMP_PLATE_HEIGHT)

local masteryName = UI.Text(campPlate, 14)
masteryName:SetPoint("RIGHT", campPlate, "BOTTOM", -LEVEL_PLATE_WIDTH / 2 - 10, campCenterY)
masteryName:SetJustifyH("RIGHT")
local masteryPoints = UI.Text(campPlate, 13)
masteryPoints:SetPoint("LEFT", campPlate, "BOTTOM", LEVEL_PLATE_WIDTH / 2 + 10, campCenterY)
masteryPoints:SetTextColor(0.25, 1, 0.25)

HeroBar.masteryBar = masteryBar
HeroBar.masteryText = masteryText
HeroBar.masteryHover = masteryHover
HeroBar.masteryLevel = masteryLevel
HeroBar.masteryName = masteryName
HeroBar.masteryPoints = masteryPoints

function HeroBar:ShowMasteryTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    local mastery = self.mastery
    if not mastery then
        GameTooltip:AddLine(L["hoa.addon.class_mastery"], 1, 1, 1)
        GameTooltip:Show()
        return
    end
    GameTooltip:AddDoubleLine(L("hoa.addon.1_mastery", mastery.class), mastery.level .. " / " .. mastery.maxLevel, 1, 1, 1, 0.6, 0.6, 0.6)
    if mastery.next > 0 then
        GameTooltip:AddLine(L("hoa.addon.1_2_experience", mastery.xp, mastery.next), 1, 1, 1)
    end
    GameTooltip:AddLine(L("hoa.addon.1_runs_earn_mastery_experience_for_each_minute_survived_and_", mastery.class), 1, 0.82, 0, 1)
    if not mastery.trees then
        GameTooltip:AddLine(L["hoa.addon.your_class_s_talent_trees_aren_t_available_yet_the_experienc"], 0.6, 0.6, 0.6, 1)
    elseif mastery.unspent > 0 then
        GameTooltip:AddLine(L(mastery.unspent == 1 and "hoa.addon.you_have_1_unspent_talent_point_spend_it_at_the_talent_train"
            or "hoa.addon.you_have_1_unspent_talent_points_spend_them_at_the_talent_tr", mastery.unspent), 0.25, 1, 0.25, 1)
    end
    GameTooltip:Show()
end

UI.Hover({ masteryHover, masteryLevel }, function()
    HeroBar:ShowMasteryTooltip(this)
end)

function HeroBar:RefreshMastery()
    local mastery = self.mastery
    if not mastery then
        self.masteryBar:SetValue(0)
        self.masteryText:SetText("")
        self.masteryLevel.text:SetText("")
        self.masteryName:SetText(L["hoa.addon.cffffd100class_mastery_r"])
        self.masteryPoints:SetText("")
        return
    end
    if mastery.next > 0 then
        self.masteryBar:SetMinMaxValues(0, mastery.next)
        self.masteryBar:SetValue(min(mastery.xp, mastery.next))
        self.masteryText:SetText(mastery.xp .. " / " .. mastery.next)
    else
        self.masteryBar:SetMinMaxValues(0, 1)
        self.masteryBar:SetValue(1)
        self.masteryText:SetText(L["hoa.addon.max_level"])
    end
    self.masteryName:SetText("|cffffd100" .. L("hoa.addon.1_mastery", mastery.class) .. "|r")
    self.masteryLevel.text:SetText(mastery.level)
    if not mastery.trees then
        self.masteryPoints:SetText(L["hoa.addon.cffaaaaaatrees_coming_soon_r"])
    elseif mastery.unspent > 0 then
        self.masteryPoints:SetText(L(mastery.unspent == 1 and "hoa.addon.1_talent_point_to_spend" or "hoa.addon.1_talent_points_to_spend", mastery.unspent))
    else
        self.masteryPoints:SetText("")
    end
end

local wallet = CreateFrame("Frame", nil, campFrame)
wallet:SetWidth(240)
wallet:SetHeight(18)
wallet:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -10, 66)
wallet:SetScale(1 / BAR_SCALE)
wallet.text = UI.Text(wallet, 13)
wallet.text:SetPoint("RIGHT", wallet, "RIGHT", 0, 0)
wallet.text:SetJustifyH("RIGHT")
HeroBar.wallet = wallet
UI.Hover(wallet, function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:AddLine(L["hoa.addon.account"], 1, 1, 1)
    GameTooltip:AddDoubleLine(L["hoa.addon.gold"], UI.FormatGold(GetMoney()), 1, 0.82, 0, 1, 1, 1)
    if HeroBar.run.shards then
        GameTooltip:AddDoubleLine(L["hoa.addon.darkmoon_tickets_2"], "|cffc080ff" .. HeroBar.run.shards .. "|r", 1, 0.82, 0, 1, 1, 1)
    end
    GameTooltip:AddLine(L["hoa.addon.shared_by_all_your_characters"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end)

function HeroBar:RefreshWallet()
    local text = UI.FormatGold(GetMoney())
    if self.run.shards then
        text = text .. "    |cffc080ff" .. L(self.run.shards == 1 and "hoa.addon.1_darkmoon_ticket" or "hoa.addon.1_darkmoon_tickets", self.run.shards) .. "|r"
    end
    self.wallet.text:SetText(text)
    self.wallet:SetWidth(self.wallet.text:GetStringWidth() + 4)
end

local DASH_ICON = "Ability_Rogue_Sprint"
local BLINK_ICON = "Spell_Arcane_Blink"
local DASH_ARC = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\DashArc"
local DASH_ARC_FRAMES = 32
local DASH_ARC_COLUMNS = 8
local DASH_ARC_ROWS = 4
local DASH_ARC_SCALE = 1.3
HeroBar.dash = { charges = 0, max = 0, cooldown = 0, key = L["hoa.addon.shift"] }

local dashButton = UI.Slot(root, DASH_SIZE)
dashButton:Hide()
dashButton.dashIcon = dashButton.icon
dashButton.dashIcon:SetTexture(UI.ICON_PATH .. DASH_ICON)
UI.CropIcon(dashButton.dashIcon)
dashButton.blinkIcon = dashButton:CreateTexture(nil, "ARTWORK")
dashButton.blinkIcon:SetTexture(UI.ICON_PATH .. BLINK_ICON)
UI.CropIcon(dashButton.blinkIcon)
dashButton.blinkIcon:SetAllPoints(dashButton)
dashButton.blinkIcon:Hide()
dashButton.cooldown = CreateFrame("Model", nil, dashButton, "CooldownFrameTemplate")
dashButton.cooldown:ClearAllPoints()
dashButton.cooldown:SetAllPoints(dashButton)
dashButton.cooldown:SetScale(DASH_SIZE / 36)
local dashText = CreateFrame("Frame", nil, dashButton)
dashText:SetAllPoints(dashButton)
dashText:SetFrameLevel(dashButton:GetFrameLevel() + 3)
dashButton.arc = dashText:CreateTexture(nil, "OVERLAY")
dashButton.arc:SetTexture(DASH_ARC)
dashButton.arc:SetWidth(DASH_SIZE * DASH_ARC_SCALE)
dashButton.arc:SetHeight(DASH_SIZE * DASH_ARC_SCALE)
dashButton.arc:SetPoint("CENTER", dashButton, "CENTER", 0, 0)
dashButton.arc:Hide()
dashButton.count = UI.Text(dashText, 14, UI.NUMBER_FONT, "THICKOUTLINE")
dashButton.count:SetPoint("BOTTOMRIGHT", dashButton, "BOTTOMRIGHT", -1, 1)
HeroBar.dashButton = dashButton
HeroBar.dashText = dashText
UI.DashButton = dashButton

function UI.SetDashKey(text)
    HeroBar.dash.key = text
end

UI.Hover(dashButton, function()
    local dash = HeroBar.dash
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:AddDoubleLine(dash.blink and L["hoa.addon.blink"] or L["hoa.addon.dash"], dash.key ~= "" and dash.key or NOT_BOUND, 1, 1, 1, 0.6, 0.6, 0.6)
    GameTooltip:AddDoubleLine(L("hoa.addon.1_2_charges", dash.charges, dash.max),
        L("hoa.addon.1_sec_recharge", floor(dash.cooldown / 100 + 0.5) / 10), 1, 1, 1, 1, 1, 1)
    if dash.blink then
        GameTooltip:AddLine(L["hoa.addon.teleports_you_a_short_distance_in_the_direction_you_re_movin"], 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(L["hoa.addon.dashes_a_short_distance_in_the_direction_you_re_moving_or_fo"], 1, 0.82, 0, 1)
    end
    GameTooltip:Show()
end)

function HeroBar:SetDashArc(done)
    if not done then
        self.dashButton.arc:Hide()
        return
    end
    local frame = max(0, min(DASH_ARC_FRAMES - 1, floor(DASH_ARC_FRAMES * done)))
    local column, row = mod(frame, DASH_ARC_COLUMNS), floor(frame / DASH_ARC_COLUMNS)
    self.dashButton.arc:SetTexCoord(column / DASH_ARC_COLUMNS, (column + 1) / DASH_ARC_COLUMNS, row / DASH_ARC_ROWS, (row + 1) / DASH_ARC_ROWS)
    self.dashButton.arc:Show()
end

local DASH_TIMER_DRIFT = 0.05

function HeroBar:SetDashTimer(duration)
    local dash = self.dash
    if not duration then
        self.dashButton.cooldown:Hide()
        dash.timerStart = nil
        return
    end
    local start = GetTime() - (duration - dash.left)
    if not dash.timerStart or abs(start - dash.timerStart) > DASH_TIMER_DRIFT then
        dash.timerStart = start
        CooldownFrame_SetTimer(self.dashButton.cooldown, start, duration, 1)
    end
end

function HeroBar:RefreshDash()
    local dash = self.dash
    local dashButton = self.dashButton
    if dash.max <= 0 then
        dashButton:Hide()
        return
    end
    local icon = dash.blink and dashButton.blinkIcon or dashButton.dashIcon
    if icon ~= dashButton.icon then
        dashButton.icon:Hide()
        icon:Show()
        dashButton.icon = icon
    end
    if dash.charges > 0 then
        dashButton.icon:SetVertexColor(1, 1, 1)
    else
        dashButton.icon:SetVertexColor(0.45, 0.45, 0.45)
    end
    if dash.left and dash.cooldown > 0 then
        local duration = dash.cooldown / 1000
        self:SetDashTimer(duration)
        self:SetDashArc(1 - dash.left / duration)
    else
        self:SetDashTimer(nil)
        self:SetDashArc(nil)
    end
    dashButton.count:SetText(dash.max > 1 and dash.charges or "")
    dashButton:Show()
end

dashButton:SetScript("OnUpdate", function()
    local dash = HeroBar.dash
    if not dash.left then
        return
    end
    if HeroBar:RunHeld() then
        HeroBar:RefreshDash()
        return
    end
    dash.left = dash.left - arg1
    if dash.left <= 0 then
        dash.charges = min(dash.max, dash.charges + 1)
        dash.left = dash.charges < dash.max and dash.cooldown / 1000 or nil
    end
    HeroBar:RefreshDash()
end)

function HeroBar:PlaceDash(running)
    local dashButton = self.dashButton
    dashButton:ClearAllPoints()
    dashButton:SetPoint("CENTER", running and self.runDashDock or self.campDashDock, "CENTER", 0, 0)
    dashButton:SetFrameLevel((running and self.runPlate or self.campPlate):GetFrameLevel() + 5)
    dashButton.cooldown:SetFrameLevel(dashButton:GetFrameLevel() + 1)
    self.dashText:SetFrameLevel(dashButton:GetFrameLevel() + 3)
end

if UIPARENT_MANAGED_FRAME_POSITIONS and UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"] then
    UIPARENT_MANAGED_FRAME_POSITIONS["CastingBarFrame"].baseY = 140
end

function HeroBar:RunXp(level)
    local xp = self.run.xp
    if xp then
        return xp.level, xp.xp, xp.next
    end
    return level or UnitLevel("player"), UnitXP("player"), UnitXPMax("player")
end

function HeroBar:RefreshXp(level)
    local current, maximum
    level, current, maximum = self:RunXp(level)
    if maximum and maximum > 0 then
        self.xpBar:SetMinMaxValues(0, maximum)
        self.xpBar:SetValue(min(current, maximum))
        self.xpText:SetText(current .. " / " .. maximum)
    else
        self.xpBar:SetMinMaxValues(0, 1)
        self.xpBar:SetValue(1)
        self.xpText:SetText("")
    end
    self.levelRing.text:SetText(level)
end

function HeroBar:ShowXpTooltip(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    local level, current, maximum = self:RunXp()
    GameTooltip:AddLine(L("hoa.addon.level_1", level), 1, 1, 1)
    GameTooltip:AddLine(L("hoa.addon.1_2_experience", current, maximum), 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.every_level_brings_a_choice_of_3_upgrades"], 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["hoa.addon.each_run_starts_again_at_level_1"], 0.6, 0.6, 0.6)
    GameTooltip:Show()
end
UI.Hover({ xpHover, levelRing }, function()
    HeroBar:ShowXpTooltip(this)
end)

function HeroBar:SetMode(running)
    self.inRun = running
    self:PlaceDash(running)
    if running then
        self.campFrame:Hide()
        self.runFrame:Show()
        self:RefreshXp()
    else
        self.runFrame:Hide()
        self.campFrame:Show()
        self:RefreshMastery()
        self:RefreshWallet()
    end
end

local XP_STREAK_SOUND = "Interface\\AddOns\\HordesOfAzeroth\\Sounds\\XpStreak%d_%d.wav"
local XP_SOUND_GAP = 0.08
local XP_SOUND_MAX_QUEUED = 5
local xpSounds = CreateFrame("Frame")
xpSounds.queued = 0
xpSounds.wait = 0
xpSounds.step = 0
xpSounds.steps = 8
xpSounds.streakAt = 0
xpSounds.streakReset = 1.0
xpSounds.coin = 2
HeroBar.xpSounds = xpSounds

function HeroBar:PlayXpPickupSound()
    local sounds = self.xpSounds
    local now = GetTime()
    if now - sounds.streakAt > sounds.streakReset then
        sounds.step = 0
    end
    sounds.streakAt = now
    sounds.step = min(sounds.step + 1, sounds.steps)
    sounds.coin = sounds.coin == 2 and 4 or 2
    PlaySoundFile(format(XP_STREAK_SOUND, sounds.coin, sounds.step))
end

xpSounds:SetScript("OnUpdate", function()
    if this.queued <= 0 then
        return
    end
    this.wait = this.wait - arg1
    if this.wait > 0 then
        return
    end
    this.queued = this.queued - 1
    this.wait = XP_SOUND_GAP
    HeroBar:PlayXpPickupSound()
end)

function HeroBar:QueueXpPickupSounds(orbs)
    if orbs <= 0 or not UI.Option("xpSounds", true) then
        return
    end
    self.xpSounds.queued = min(self.xpSounds.queued + orbs, XP_SOUND_MAX_QUEUED)
end

UI.ListenHoa({
    HOA_LOADOUT = function(loadout)
        HeroBar:ApplyLoadout({ false, loadout.entries, loadout.spell_slots, loadout.passive_slots })
    end,
    HOA_WEAPON_INFO = function(weapon)
        local f = {
            false, weapon.index, weapon.name, weapon.ranks, weapon.interval, weapon.next_cast, weapon.line, weapon.description,
            weapon.damage, weapon.header, weapon.faster and "1" or "0",
        }
        for _, part in ipairs(UI.Split(weapon.tags or "", "~")) do
            tinsert(f, part)
        end
        for _, part in ipairs(UI.Split(weapon.radius or "", "~")) do
            tinsert(f, part)
        end
        HeroBar:ApplyWeapon(f)
    end,
    HOA_WEAPON_EVOLUTION = function(evolution)
        HeroBar:ApplyWeaponEvolution({
            false, evolution.index, evolution.evolution, evolution.evolution_text, evolution.evolved_from,
            evolution.chance_text, evolution.chance,
        })
    end,
    HOA_WEAPON_EVOLUTION_OPTION = function(option)
        HeroBar:ApplyWeaponEvolutionOption({ false, option.index, option.name, option.text })
    end,
    HOA_COOLDOWN_PIE = function(pie)
        HeroBar:ApplyCooldownPie({ false, pie.index, pie.pie_ms, pie.timer, pie.held and "1" or "0" })
    end,
    HOA_REACH_RING = function(ring)
        HeroBar:ApplyReachRing({ false, ring.spell_id, ring.slot })
    end,
    HOA_MASTERY_STATE = function(mastery)
        HeroBar:ApplyMastery({
            false, mastery.class_name, mastery.level, mastery.xp, mastery.next, mastery.max_level, mastery.unspent,
            mastery.trees and "1" or "0",
        })
    end,
    HOA_WALLET = function(wallet)
        HeroBar:ApplyWallet({ false, wallet.shards })
    end,
    HOA_SHARD = function(shard)
        HeroBar:ApplyShard({ false, shard.count, shard.total })
    end,
    HOA_RUN_XP = function(xp)
        HeroBar:ApplyRunXp(xp)
    end,
    HOA_RUN_STATE = function(state)
        HeroBar:ApplyRunState(state)
    end,
})

HeroBar:OnRunStart(function()
    HeroBar:StartRun()
end):OnRunEnd(function()
    HeroBar:EndRun()
end)

UI.ListenHoa({
    HOA_DASH = function(maxCharges, rechargeMs, cooldownMs, blink, available)
        HeroBar:ApplyDash(maxCharges, rechargeMs, cooldownMs, blink, available)
    end,
})

function HeroBar:ApplyLoadout(f)
    self.run.spells, self.run.passives = {}, {}
    self.run.spellSlots = tonumber(f[3] or "")
    self.run.passiveSlots = tonumber(f[4] or "")
    local index = 0
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        if item ~= "" then
            local parts = UI.Split(item, ":")
            index = index + 1
            local entry = { index = index, kind = parts[1], icon = parts[2] ~= "" and parts[2] or "INV_Misc_QuestionMark",
                rank = tonumber(parts[3]) or 1, max = tonumber(parts[4]) or 0 }
            if entry.kind == "p" then
                tinsert(self.run.passives, entry)
            else
                tinsert(self.run.spells, entry)
            end
        end
    end
    self:RefreshSlots()
end

function HeroBar:ApplyWeapon(f)
    local index = tonumber(f[2])
    if not index then
        return
    end
    local info = self.run.info[index] or {}
    info.name = f[3]
    info.ranks = f[4] or ""
    info.interval = tonumber(f[5]) or 0
    info.nextCast = tonumber(f[6]) or 0
    info.held = nil
    info.line = f[7] or ""
    info.description = gsub(f[8] or "", "|n", "\n")
    info.damage = f[9] or ""
    info.header = f[10] or ""
    info.faster = f[11] == "1"
    info.school = f[12] or ""
    info.spec = f[13] or ""
    info.aoe = f[14] == "1"
    info.radius = tonumber(f[15]) or 0
    info.range = tonumber(f[16]) or 0
    info.currentRadius = tonumber(f[17]) or 0
    info.currentRange = tonumber(f[18]) or 0
    self.run.info[index] = info
    self:RefreshSlots()
    local slot = self.spellSlots[index]
    if slot and VanillaBonkSpellTip:IsOwned(slot) then
        self:ShowSlotTooltip(slot)
    end
end

function HeroBar:ApplyCooldownPie(f)
    local index = tonumber(f[2])
    local info = index and self.run.info[index]
    if not info then
        return
    end
    info.interval = tonumber(f[3]) or info.interval
    info.nextCast = tonumber(f[4]) or 0
    info.held = f[5] == "1" or nil
    for _, slot in ipairs(self.spellSlots) do
        if slot.entry and slot.entry.index == index then
            slot.cycleStart = nil
            self:RestartCooldown(slot)
        end
    end
end

function HeroBar:ApplyWeaponEvolution(f)
    local index = tonumber(f[2])
    if not index then
        return
    end
    local info = self.run.info[index] or {}
    info.evolution = f[3] or ""
    info.evolutionText = f[4] or ""
    info.evolutions = nil
    info.evolvedFrom = f[5] or ""
    info.chance = f[6] or ""
    info.chanceValue = f[7] or "0"
    self.run.info[index] = info
    self:RefreshSlots()
end

function HeroBar:ApplyWeaponEvolutionOption(f)
    local index = tonumber(f[2])
    if not index then
        return
    end
    local info = self.run.info[index] or {}
    info.evolutions = info.evolutions or {}
    tinsert(info.evolutions, { name = f[3] or "", text = f[4] or "" })
    self.run.info[index] = info
end

function HeroBar:ApplyMastery(f)
    self.mastery = {
        class = f[2] or L["hoa.addon.class"],
        level = tonumber(f[3]) or 0,
        xp = tonumber(f[4]) or 0,
        next = tonumber(f[5]) or 0,
        maxLevel = tonumber(f[6]) or 0,
        unspent = tonumber(f[7]) or 0,
        trees = f[8] == "1",
    }
    self:RefreshMastery()
end

function HeroBar:ApplyWallet(f)
    self.run.shards = tonumber(f[2])
    self:RefreshWallet()
end

function HeroBar:ApplyShop(f)
    if f[5] == "shards" then
        self.run.shards = tonumber(f[6]) or self.run.shards
        self:RefreshWallet()
    end
end

function HeroBar:ApplyShard(f)
    self.run.shards = tonumber(f[3]) or self.run.shards
end

function HeroBar:RefreshReachMarks()
    for _, slot in ipairs(self.spellSlots) do
        self:RefreshReachMark(slot)
    end
end

function UI.RefreshReachMarks()
    HeroBar:RefreshReachMarks()
end

function HeroBar:ApplyReachRing(f)
    UI.SetReachRingSpell(tonumber(f[2]) or 0)
    self.run.reachSlot = tonumber(f[3]) or 0
    UI.RefreshReachMarks()
end

function HeroBar:ApplyRunXp(xp)
    self.run.xp = { level = tonumber(xp.level) or 1, xp = tonumber(xp.xp) or 0, next = tonumber(xp.next) or 0 }
    if self.inRun then
        self:QueueXpPickupSounds(tonumber(xp.orbs) or 0)
        self:RefreshXp()
    end
end

function HeroBar:ApplyRunState(state)
    if not self.inRun then
        self:SetMode(true)
    end
    local stats = state.weapon_stats
    if stats and stats ~= "" then
        self.run.stats = {}
        for index, item in ipairs(UI.Split(stats, ",")) do
            local parts = UI.Split(item, ":")
            self.run.stats[index] = { damage = tonumber(parts[1]) or 0, kills = tonumber(parts[2]) or 0 }
        end
    end
end

function HeroBar:ApplyDash(maxCharges, rechargeMs, cooldownMs, blink, available)
    local dash = self.dash
    dash.max = tonumber(maxCharges) or 0
    dash.untilNext = tonumber(rechargeMs) or 0
    dash.cooldown = tonumber(cooldownMs) or 0
    dash.blink = blink and true or false
    dash.charges = tonumber(available) or 0
    dash.left = (dash.charges < dash.max and dash.untilNext > 0) and dash.untilNext / 1000 or nil
    self:RefreshDash()
end

function HeroBar:StartRun()
    self.run.info = {}
    self.run.stats = {}
    self.run.xp = nil
    self:SetMode(true)
end

function HeroBar:EndRun()
    self.run.xp = nil
    self.dash.max = 0
    self:RefreshDash()
    self:SetMode(false)
end

function HeroBar:EnterWorld()
    self:SetMode(self.inRun)
    if UIParent_ManageFramePositions then
        UIParent_ManageFramePositions()
    end
    self:RefreshXp()
end

HeroBar:OnEnterWorld(function()
    HeroBar:EnterWorld()
end)
HeroBar:Listen({
    PLAYER_XP_UPDATE = function()
        HeroBar:RefreshXp()
    end,
    PLAYER_LEVEL_UP = function(level)
        HeroBar:RefreshXp(level)
    end,
})
HeroBar:OnMoney(function()
    HeroBar:RefreshWallet()
end)

HeroBar:SetMode(false)

function HeroBar:SpellSlot(name)
    for index, slot in ipairs(self.spellSlots) do
        local info = self.run.info[index]
        if info and info.name == name and self.run.spells[index] then
            return slot
        end
    end
end

function UI.HeroSpellSlot(name)
    return HeroBar:SpellSlot(name)
end

function UI.HeroSpellSlotAt(index)
    return HeroBar.run.spells[index] and HeroBar.spellSlots[index]
end
