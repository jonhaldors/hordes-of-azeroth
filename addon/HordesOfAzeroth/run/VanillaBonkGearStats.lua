local L = VanillaBonkL
local UI = VanillaBonkUI
local VB = VanillaBonkRun
local handlers = VB.handlers
local Split = VB.Split
local Gear = UI.Module("gear")

local STATS = {
    [0]  = { name = L["hoa.addon.power"], pct = true, text = L["hoa.addon.increases_all_damage_you_and_your_minions_deal_by_s"] },
    [1]  = { name = L["hoa.addon.haste"], pct = true, curve = 75, gearCap = 20, text = L["hoa.addon.increases_the_speed_of_your_attacks_periodic_effects_and_min"] },
    [2]  = { name = L["hoa.addon.count"], cap = 5, text = L["hoa.addon.your_spells_fire_s_extra_bolts_shots_or_swings"] },
    [3]  = { name = L["hoa.addon.movement_speed_2"], short = L["hoa.addon.speed"], pct = true, cap = 50, text = L["hoa.addon.increases_movement_speed_by_s"] },
    [4]  = { name = L["hoa.addon.max_health_2"], pct = true, text = L["hoa.addon.increases_maximum_health_by_s"] },
    [5]  = { name = L["hoa.addon.regen"], pct = true, text = L["hoa.addon.restores_s_of_maximum_health_per_second"] },
    [6]  = { name = L["hoa.addon.gold"], pct = true, text = L["hoa.addon.increases_gold_found_by_s"] },
    [7]  = { name = L["hoa.addon.experience_2"], pct = true, text = L["hoa.addon.increases_experience_gained_by_s"] },
    [8]  = { name = L["hoa.addon.pickup_range"], pct = true, cap = 400, text = L["hoa.addon.increases_pickup_range_by_s"] },
    [9]  = { name = L["hoa.addon.leech"], pct = true, text = L["hoa.addon.your_hits_have_a_s_chance_to_heal_you_for_1_of_maximum_healt"] },
    [10] = { name = L["hoa.addon.area"], pct = true, curve = 60, text = L["hoa.addon.increases_the_size_of_your_aoe_spells_by_s"] },
    [11] = { name = L["hoa.addon.duration"], pct = true, text = L["hoa.addon.increases_the_duration_of_your_spells_by_s"] },
    [12] = { name = L["hoa.addon.armor"], text = L["hoa.addon.reduces_damage_taken_by_s"] },
    [14] = { name = L["hoa.addon.dodge_chance"], short = L["hoa.addon.dodge"], pct = true, cap = 60, text = L["hoa.addon.increases_your_chance_to_dodge_attacks_by_s"] },
    [15] = { name = L["hoa.addon.critical_strike_chance"], short = L["hoa.addon.crit_chance"], pct = true, text = L["hoa.addon.increases_your_critical_strike_chance_by_s"] },
    [16] = { name = L["hoa.addon.critical_strike_damage_2"], short = L["hoa.addon.crit_damage"], pct = true, text = L["hoa.addon.increases_critical_strike_damage_by_s"] },
    [17] = { name = L["hoa.addon.shield"], pct = true, text = L["hoa.addon.absorbs_damage_equal_to_s_of_maximum_health"], note = L["hoa.addon.shield_is_restored_after_4_sec_without_taking_damage"] },
    [18] = { name = L["hoa.addon.luck"], text = L["hoa.addon.improves_the_rarity_of_chest_and_level_up_choices"] },
    [19] = { name = L["hoa.addon.poison_damage"], pct = true, text = L["hoa.addon.increases_poison_damage_by_s"] },
    [20] = { name = L["hoa.addon.burning_damage"], pct = true, text = L["hoa.addon.increases_burning_damage_by_s"] },
    [21] = { name = L["hoa.addon.bleed_damage"], pct = true, text = L["hoa.addon.increases_bleed_damage_by_s"] },
}
local STAT_ORDER = { 0, 12, 14, 15, 16, 17, 1, 10, 8, 18, 4, 3, 5, 9, 11, 19, 20, 21, 6, 7, 2 }

VB.statTips = {
    s0 = { name = L["hoa.addon.power"], text = L["hoa.addon.increases_all_damage_you_and_your_minions_deal"] },
    s1 = { name = L["hoa.addon.haste"], text = L["hoa.addon.increases_the_speed_of_your_attacks_periodic_effects_and_min_2"] },
    s2 = { name = L["hoa.addon.count"], text = L["hoa.addon.your_spells_fire_extra_bolts_shots_or_swings_does_not_affect"] },
    s3 = { name = L["hoa.addon.movement_speed_2"], text = L["hoa.addon.increases_movement_speed"] },
    s4 = { name = L["hoa.addon.maximum_health"], text = L["hoa.addon.increases_maximum_health"] },
    s5 = { name = L["hoa.addon.health_regeneration"], text = L["hoa.addon.restores_a_portion_of_maximum_health_per_second"] },
    s7 = { name = L["hoa.addon.experience_2"], text = L["hoa.addon.increases_experience_gained"] },
    s8 = { name = L["hoa.addon.pickup_range"], text = L["hoa.addon.increases_the_range_at_which_you_pick_up_experience_food_and"] },
    s10 = { name = L["hoa.addon.area"], text = L["hoa.addon.increases_the_size_of_your_aoe_spells"] },
    s12 = { name = L["hoa.addon.armor"], text = L["hoa.addon.reduces_damage_taken"] },
    s14 = { name = L["hoa.addon.dodge_chance"], text = L["hoa.addon.increases_your_chance_to_dodge_attacks"] },
    s15 = { name = L["hoa.addon.critical_strike_chance"], text = L["hoa.addon.increases_your_critical_strike_chance"] },
    s16 = { name = L["hoa.addon.critical_strike_damage_2"], text = L["hoa.addon.increases_critical_strike_damage"] },
    s18 = { name = L["hoa.addon.luck"], text = L["hoa.addon.improves_the_rarity_of_chest_and_level_up_choices"] },
}
function VB.BuildStatTerms(names)
    VB.statTerms = {}
    for text, id in pairs(names) do
        tinsert(VB.statTerms, { text = text, id = id, stat = true })
    end
    VB.keywordTerms = nil
end

VB.BuildStatTerms({
    [L["hoa.addon.power"]] = "s0", [L["hoa.addon.haste"]] = "s1", [L["hoa.addon.count"]] = "s2",
    [L["hoa.addon.movement_speed_2"]] = "s3", [L["hoa.addon.movement_speed_3"]] = "s3", [L["hoa.addon.movement_speed"]] = "s3",
    [L["hoa.addon.maximum_health"]] = "s4", [L["hoa.addon.maximum_health_2"]] = "s4", [L["hoa.addon.max_health_2"]] = "s4", [L["hoa.addon.max_health"]] = "s4",
    [L["hoa.addon.health_regained_each_second"]] = "s5",
    [L["hoa.addon.experience_2"]] = "s7", [L["hoa.addon.experience_3"]] = "s7",
    [L["hoa.addon.pickup_range"]] = "s8", [L["hoa.addon.pickup_range_2"]] = "s8",
    [L["hoa.addon.area"]] = "s10", [L["hoa.addon.armor"]] = "s12",
    [L["hoa.addon.dodge_chance"]] = "s14", [L["hoa.addon.chance_to_dodge"]] = "s14",
    [L["hoa.addon.critical_strike_chance"]] = "s15", [L["hoa.addon.critical_strike_chance_2"]] = "s15", [L["hoa.addon.crit_chance"]] = "s15", [L["hoa.addon.critical_strike"]] = "s15",
    [L["hoa.addon.critical_strike_damage_2"]] = "s16", [L["hoa.addon.critical_strike_damage_3"]] = "s16", [L["hoa.addon.critical_strike_damage"]] = "s16",
    [L["hoa.addon.luck"]] = "s18",
})

VB.gear = {}
VB.stats = {}
VB.statsAfterCaps = {}
VB.statsInRun = false

local EQUIPPED_SLOTS = 19

local function Percent(value)
    return format("%g", value) .. "%"
end

function Gear:FormatStat(id, value)
    if STATS[id] and STATS[id].pct then
        return Percent(value)
    end
    return format("%g", value)
end

function Gear:ParseStats(text)
    local stats = {}
    for _, pair in ipairs(Split(text or "", ",")) do
        local colon = strfind(pair, ":", 1, true)
        if colon then
            local id = tonumber(strsub(pair, 1, colon - 1))
            if id then
                stats[id] = tonumber(strsub(pair, colon + 1)) or 0
            end
        end
    end
    return stats
end

function Gear:ItemIdFromLink(link)
    if not link then
        return nil
    end
    local _, _, id = strfind(link, "item:(%d+)")
    return tonumber(id)
end

function Gear:GearTotals()
    local totals = {}
    for slot = 1, EQUIPPED_SLOTS do
        local id = Gear:ItemIdFromLink(GetInventoryItemLink("player", slot))
        local stat = id and VB.gear[id]
        if stat then
            for statId, value in pairs(stat.stats) do
                totals[statId] = (totals[statId] or 0) + value
            end
        end
        local enchant = VanillaBonkUI.enchants and VanillaBonkUI.enchants[slot]
        if enchant then
            totals[enchant.stat] = (totals[enchant.stat] or 0) + enchant.value
        end
        local found = VanillaBonkUI.FoundAt and VanillaBonkUI.FoundAt("inv", slot)
        if found then
            for statId, value in pairs(found.extra) do
                totals[statId] = (totals[statId] or 0) + value
            end
            for _, line in ipairs(found.lines) do
                totals[line.stat] = (totals[line.stat] or 0) + line.value
            end
        end
    end

    return totals
end

local PRIMARY_STATS = { 12, 0, 4 }

function PRIMARY_STATS.Has(statId)
    for _, primary in ipairs(PRIMARY_STATS) do
        if primary == statId then
            return true
        end
    end
    return false
end

function PRIMARY_STATS.AddLine(tooltip, statId, value, r, g, b)
    if not value or value == 0 then
        return
    end
    local sign = value > 0 and "+" or ""
    tooltip:AddLine(sign .. Gear:FormatStat(statId, value) .. " " .. STATS[statId].name, r, g, b)
end

function VanillaBonkUI.StatText(statId, value)
    local stat = STATS[statId]
    if not stat or not value then
        return ""
    end
    return (value > 0 and "+" or "") .. Gear:FormatStat(statId, value) .. " " .. stat.name
end

function VanillaBonkUI.StatRangeText(statId, low, high)
    if not STATS[statId] or not low or not high then
        return ""
    end
    return "(" .. Gear:FormatStat(statId, low) .. "-" .. Gear:FormatStat(statId, high) .. ")"
end

function Gear:AddGearLines(tooltip, link, found, enchantLine)
    local id = Gear:ItemIdFromLink(link)
    local stat = id and VB.gear[id]
    if not stat then
        return
    end

    local extra = found and found.extra or {}
    for _, statId in ipairs(PRIMARY_STATS) do
        PRIMARY_STATS.AddLine(tooltip, statId, (stat.stats[statId] or 0) + (extra[statId] or 0), 1, 1, 1)
    end
    for _, statId in ipairs(STAT_ORDER) do
        if not PRIMARY_STATS.Has(statId) then
            PRIMARY_STATS.AddLine(tooltip, statId, (stat.stats[statId] or 0) + (extra[statId] or 0), 0.12, 1, 0.12)
        end
    end
    if found then
        local color = VanillaBonkUI.FOUND_LINE_COLOR
        for _, line in ipairs(found.lines) do
            PRIMARY_STATS.AddLine(tooltip, line.stat, line.value, color[1], color[2], color[3])
        end
    end
    if enchantLine then
        tooltip:AddLine(enchantLine, 0.12, 1, 0.12)
    end
    local tier = found and found.tier or VanillaBonkUI.GearTier(id)
    local tierText = tier > 0 and tooltip:GetName() and getglobal(tooltip:GetName() .. "TextRight1")
    if tierText then
        local _, _, itemQuality = GetItemInfo(id)
        tierText:SetText(VanillaBonkUI.ItemLevelText(tier, itemQuality))
        tierText:SetTextColor(1, 0.82, 0)
        tierText:Show()
    end
    local proc = VanillaBonkUI.trinketTips and VanillaBonkUI.trinketTips[id]
    if proc then
        local bindLine = tooltip:GetName() and getglobal(tooltip:GetName() .. "TextLeft2")
        local bindText = bindLine and bindLine:GetText()
        if bindText == ITEM_BIND_ON_PICKUP then
            bindLine:SetText(bindText .. "\n" .. L["hoa.addon.unique_equipped_1"])
        elseif not (bindText and strfind(bindText, L["hoa.addon.unique_equipped"], 1, true)) then
            tooltip:AddLine(L["hoa.addon.unique_equipped_1"], 1, 1, 1)
        end
        tooltip:AddLine(L("hoa.addon.equip_1", proc), 0.12, 1, 0.12, 1)
    end
    if found and found.legacy then
        tooltip:AddLine(L["hoa.addon.legacy_item_doesn_t_count_toward_this_season_s_leaderboard"], 0.6, 0.6, 0.6, 1)
    end
    tooltip:Show()
end

function Gear:HookTooltip(tooltip, method, linkOf)
    local original = tooltip and tooltip[method]
    if not original then
        return
    end
    tooltip[method] = function(self, a1, a2, a3)
        local r1, r2, r3 = original(self, a1, a2, a3)
        Gear:AddGearLines(self, linkOf(a1, a2, a3))
        return r1, r2, r3
    end
end

do
    local SOLID_TOOLTIP = {
        bgFile = "Interface\\Buttons\\WHITE8X8",
        edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
        tile = false,
        edgeSize = 16,
        insets = { left = 5, right = 5, top = 5, bottom = 5 },
    }

    local function MakeTooltipSolid(tooltip)
        if not tooltip then
            return
        end
        local background = TOOLTIP_DEFAULT_BACKGROUND_COLOR or { r = 0.09, g = 0.09, b = 0.19 }
        local border = TOOLTIP_DEFAULT_COLOR or { r = 1, g = 1, b = 1 }
        tooltip:SetBackdrop(SOLID_TOOLTIP)
        tooltip:SetBackdropColor(background.r, background.g, background.b)
        tooltip:SetBackdropBorderColor(border.r, border.g, border.b)
    end

    MakeTooltipSolid(GameTooltip)
    MakeTooltipSolid(ItemRefTooltip)
end

Gear:HookTooltip(GameTooltip, "SetBagItem", function(bag, slot) return GetContainerItemLink(bag, slot), VanillaBonkUI.FoundAt(bag, slot) end)
Gear:HookTooltip(GameTooltip, "SetInventoryItem", function(unit, slot)
    if unit ~= "player" then
        return GetInventoryItemLink(unit, slot)
    end
    return GetInventoryItemLink(unit, slot), VanillaBonkUI.FoundAt("inv", slot), VanillaBonkUI.EnchantLine and VanillaBonkUI.EnchantLine(slot)
end)
Gear:HookTooltip(GameTooltip, "SetMerchantItem", function(index) return GetMerchantItemLink(index) end)
Gear:HookTooltip(GameTooltip, "SetLootItem", function(slot) return GetLootSlotLink(slot) end)
Gear:HookTooltip(GameTooltip, "SetHyperlink", function(link) return link, VanillaBonkUI.TakeHyperlinkFound() end)
Gear:HookTooltip(ItemRefTooltip, "SetHyperlink", function(link) return link end)

function Gear:GearLinkNamed(name)
    if not name then
        return nil
    end
    for id in pairs(VB.gear) do
        if GetItemInfo(id) == name then
            return "item:" .. id .. ":0:0:0"
        end
    end
end

function Gear:InboxItemLink(index)
    return Gear:GearLinkNamed(GetInboxItem(index))
end

Gear:HookTooltip(GameTooltip, "SetInboxItem", function(index) return Gear:InboxItemLink(index) end)

local SLOTS_BY_EQUIP_LOC = {
    INVTYPE_HEAD = { 1 }, INVTYPE_NECK = { 2 }, INVTYPE_SHOULDER = { 3 }, INVTYPE_BODY = { 4 },
    INVTYPE_CHEST = { 5 }, INVTYPE_ROBE = { 5 }, INVTYPE_WAIST = { 6 }, INVTYPE_LEGS = { 7 },
    INVTYPE_FEET = { 8 }, INVTYPE_WRIST = { 9 }, INVTYPE_HAND = { 10 }, INVTYPE_FINGER = { 11, 12 },
    INVTYPE_TRINKET = { 13, 14 }, INVTYPE_CLOAK = { 15 }, INVTYPE_WEAPON = { 16, 17 },
    INVTYPE_SHIELD = { 17 }, INVTYPE_2HWEAPON = { 16 }, INVTYPE_WEAPONMAINHAND = { 16 },
    INVTYPE_WEAPONOFFHAND = { 17 }, INVTYPE_HOLDABLE = { 17 }, INVTYPE_RANGED = { 18 },
    INVTYPE_THROWN = { 18 }, INVTYPE_RANGEDRIGHT = { 18 }, INVTYPE_RELIC = { 18 }, INVTYPE_TABARD = { 19 },
}

function Gear:HideCompare()
    for index = 1, 2 do
        local tooltip = getglobal("ShoppingTooltip" .. index)
        if tooltip then
            tooltip:Hide()
        end
    end
end

function Gear:EquippedSlotsFor(link)
    local id = Gear:ItemIdFromLink(link)
    if not id then
        return nil
    end
    local _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    return equipLoc and SLOTS_BY_EQUIP_LOC[equipLoc]
end

function Gear:CursorOnRightHalf()
    local x = GetCursorPosition()
    return x / UIParent:GetEffectiveScale() > GetScreenWidth() / 2
end

function Gear:ShowCompare(link)
    Gear:HideCompare()
    local slots = Gear:EquippedSlotsFor(link)
    if not slots or not ShoppingTooltip1 then
        return
    end

    local onLeft = Gear:CursorOnRightHalf()
    local previous = GameTooltip
    local shown = 0
    for _, slot in ipairs(slots) do
        if shown < 2 and GetInventoryItemLink("player", slot) then
            shown = shown + 1
            local tooltip = getglobal("ShoppingTooltip" .. shown)
            tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
            tooltip:ClearAllPoints()
            local gap = previous == GameTooltip and -10 or 0
            if onLeft then
                tooltip:SetPoint("TOPRIGHT", previous, "TOPLEFT", 0, gap)
            else
                tooltip:SetPoint("TOPLEFT", previous, "TOPRIGHT", 0, gap)
            end
            tooltip:SetInventoryItem("player", slot)
            previous = tooltip
        end
    end
end

function Gear:CompareOn(method, linkOf)
    local original = GameTooltip[method]
    if not original then
        return
    end
    GameTooltip[method] = function(self, a1, a2, a3)
        local r1, r2, r3 = original(self, a1, a2, a3)
        Gear:ShowCompare(linkOf(a1, a2, a3))
        return r1, r2, r3
    end
end

Gear:CompareOn("SetBagItem", function(bag, slot) return GetContainerItemLink(bag, slot) end)
Gear:CompareOn("SetLootItem", function(slot) return GetLootSlotLink(slot) end)
Gear:CompareOn("SetMerchantItem", function(index) return GetMerchantItemLink(index) end)
Gear:CompareOn("SetInboxItem", function(index) return Gear:InboxItemLink(index) end)

local compareOnHide = GameTooltip:GetScript("OnHide")
GameTooltip:SetScript("OnHide", function()
    if compareOnHide then
        compareOnHide()
    end
    Gear:HideCompare()
end)
function Gear:WornLinkNamed(tooltip)
    for line = 1, 3 do
        local text = getglobal(tooltip:GetName() .. "TextLeft" .. line)
        local name = text and text:GetText()
        if name and name ~= "" then
            for slot = 1, EQUIPPED_SLOTS do
                local link = GetInventoryItemLink("player", slot)
                if link and strfind(link, "[" .. name .. "]", 1, true) then
                    return link, name, slot
                end
            end
        end
    end
end

for _, name in ipairs({ "ShoppingTooltip1", "ShoppingTooltip2" }) do
    local tooltip = getglobal(name)
    if tooltip then
        local onUpdate = tooltip:GetScript("OnUpdate")
        tooltip:SetScript("OnUpdate", function()
            if onUpdate then
                onUpdate()
            end
            local link, itemName, slot = Gear:WornLinkNamed(this)
            if link and (itemName ~= this.bonkItem or this:NumLines() < (this.bonkLines or 0)) then
                this.bonkItem = itemName
                Gear:AddGearLines(this, link, VanillaBonkUI.FoundAt("inv", slot))
                this.bonkLines = this:NumLines()
            end
        end)
        local onHide = tooltip:GetScript("OnHide")
        tooltip:SetScript("OnHide", function()
            if onHide then
                onHide()
            end
            this.bonkItem = nil
            this.bonkLines = nil
        end)
    end
end

function VanillaBonk_HookItemTooltip(tooltip)
    Gear:HookTooltip(tooltip, "SetHyperlink", function(link) return link, VanillaBonkUI.TakeHyperlinkFound() end)
end

function VanillaBonk_AddGearLines(tooltip, link, found)
    Gear:AddGearLines(tooltip, link, found)
    local name = getglobal(tooltip:GetName() .. "TextLeft1")
    tooltip.bonkItem = name and name:GetText()
    tooltip.bonkLines = tooltip:NumLines()
end
if GetBuybackItemLink then
    Gear:HookTooltip(GameTooltip, "SetBuybackItem", function(index) return GetBuybackItemLink(index) end)
end

local heroStats = CreateFrame("Frame", "VanillaBonkHeroStats", PaperDollFrame)
Gear.frame = heroStats
if CharacterAttributesFrame then
    heroStats:SetAllPoints(CharacterAttributesFrame)
else
    heroStats:SetPoint("TOPLEFT", PaperDollFrame, "TOPLEFT", 67, -291)
    heroStats:SetWidth(230)
    heroStats:SetHeight(78)
end

local STAT_ROW_HEIGHT = 11

function Gear:CreateStatLine(column, row)
    local line = CreateFrame("Frame", nil, heroStats)
    line:SetWidth(104)
    line:SetHeight(STAT_ROW_HEIGHT)
    line:SetPoint("TOPLEFT", heroStats, "TOPLEFT", column == 1 and 6 or 122, -1 - (row - 1) * STAT_ROW_HEIGHT)
    line:EnableMouse(true)

    line.label = line:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    line.label:SetPoint("LEFT", line, "LEFT", 0, 0)
    line.value = line:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    line.value:SetPoint("RIGHT", line, "RIGHT", 0, 0)

    UI.Hover(line, function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.title or "", 1, 1, 1)
        for _, text in ipairs(this.lines or {}) do
            GameTooltip:AddLine(text, 1, 0.82, 0, 1)
        end
        GameTooltip:Show()
    end)
    return line
end

local STAT_LAYOUT = {
    { 0, 1, 15, 16, 10, 18 },
    { 12, 14, 17, 4, 3, 8 },
}
Gear.statLines = {}
for column, ids in ipairs(STAT_LAYOUT) do
    for row, statId in ipairs(ids) do
        local line = Gear:CreateStatLine(column, row)
        line.label:SetText((STATS[statId].short or STATS[statId].name) .. ":")
        Gear.statLines[statId] = line
    end
end

function Gear:Refresh()
    if CharacterAttributesFrame then
        CharacterAttributesFrame:Hide()
    end

    local gear = Gear:GearTotals()

    for statId, line in pairs(Gear.statLines) do
        local stat = STATS[statId]
        local gearTotal = gear[statId] or 0
        local fromGear = stat.gearCap and min(gearTotal, stat.gearCap) or gearTotal
        local fromRest = VB.stats[statId] or 0
        local total = fromGear + fromRest
        if statId == 0 then
            total = ((1 + fromRest / 100) * (1 + fromGear / 200) - 1) * 100
        end
        local shown = stat.cap and min(total, stat.cap) or total
        if stat.curve and total > 0 then
            shown = floor(10 * stat.curve * (1 - math.exp(-total / stat.curve)) + 0.5) / 10
        end
        shown = shown + (VB.statsAfterCaps[statId] or 0)

        local compact = math.abs(shown) >= 100 and floor(shown + 0.5) or floor(10 * shown + 0.5) / 10
        line.value:SetText(Gear:FormatStat(statId, compact))
        line.title = stat.name
        local explained = Gear:FormatStat(statId, shown)
        if statId == 12 then
            explained = Percent(floor(1000 * min(0.6, max(0, shown) / (max(0, shown) * 4 / 3 + 100)) + 0.5) / 10)
        end
        line.lines = { format(stat.text, explained) }
        if statId == 9 and shown > 0 then
            tinsert(line.lines, L("hoa.addon.heals_up_to_1_of_maximum_health_per_second", Percent(floor(3 * shown + 0.5) / 100)))
        end
        if statId == 12 and shown > 300 then
            tinsert(line.lines, L("hoa.addon.armor_past_300_gives_1_maximum_health", Percent(floor(5 * (shown - 300) + 0.5) / 10)))
        end
        if stat.cap then
            tinsert(line.lines, L("hoa.addon.maximum_1", Gear:FormatStat(statId, stat.cap)))
        end
        if stat.note then
            tinsert(line.lines, " ")
            tinsert(line.lines, stat.note)
        end
    end
end

local paperDollOnShow = PaperDollFrame:GetScript("OnShow")
PaperDollFrame:SetScript("OnShow", function()
    if paperDollOnShow then
        paperDollOnShow()
    end
    Gear:Refresh()
    SendChatMessage(".bonk stats on", "SAY")
end)

do
    local paperDollOnHide = PaperDollFrame:GetScript("OnHide")
    PaperDollFrame:SetScript("OnHide", function()
        if paperDollOnHide then
            paperDollOnHide()
        end
        SendChatMessage(".bonk stats off", "SAY")
    end)
end

Gear:OnInventory(function(unit)
    if unit == "player" and PaperDollFrame:IsVisible() then
        Gear:Refresh()
    end
end)

function Gear:ApplyGear(f)
    VB.gear[tonumber(f[2])] = { stats = self:ParseStats(f[3]) }
end
handlers["gear"] = function(f) Gear:ApplyGear(f) end

function Gear:EndGear()
    if PaperDollFrame:IsVisible() then
        self:Refresh()
    end
end
handlers["gearend"] = function() Gear:EndGear() end

function VanillaBonkUI.FoundRefreshed()
    if PaperDollFrame:IsVisible() then
        Gear:Refresh()
    end
end

function Gear:ApplyStats(f)
    VB.statsInRun = f[2] == "1"
    VB.stats = {}
    local values = Split(f[3] or "", ",")
    for i = 1, getn(values) do
        VB.stats[i - 1] = tonumber(values[i]) or 0
    end
    VB.statsAfterCaps = {}
    local afterCaps = Split(f[4] or "", ",")
    for i = 1, getn(afterCaps) do
        VB.statsAfterCaps[i - 1] = tonumber(afterCaps[i]) or 0
    end
    if PaperDollFrame:IsVisible() then
        self:Refresh()
    end
end
handlers["stats"] = function(f) Gear:ApplyStats(f) end

