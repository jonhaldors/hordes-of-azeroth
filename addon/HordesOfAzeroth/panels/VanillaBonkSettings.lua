local L = VanillaBonkL
local UI = VanillaBonkUI

local DEFAULT_KEY_DELAY = 1
local MODIFIER_KEYS = { SHIFT = true, CTRL = true, ALT = true }

UI.INTERACT_TYPES = {
    { key = "interactPeople", label = L["hoa.addon.people"], hint = L["hoa.addon.talk_shop_and_bank"], units = true },
    { key = "interactChests", label = L["hoa.addon.chests"], hint = L["hoa.addon.open_chests_vaults_and_hidden_finds"], objects = { 900001, 900002, 900041, 900060 }, types = { 3 } },
    { key = "interactShrines", label = L["hoa.addon.shrines"], hint = L["hoa.addon.touch_shrines_totems_and_altars"], objects = { 900031, 900032, 900033, 900034 } },
    { key = "interactPortals", label = L["hoa.addon.portals"], hint = L["hoa.addon.step_through_portals"], objects = { 900003 } },
    { key = "interactMail", label = L["hoa.addon.mailbox"], hint = L["hoa.addon.read_your_mail"], types = { 19 } },
}

UI.AUTO_CHEST_ENTRIES = { 900001, 900002 }

UI.DISPLAY_SETTINGS = {
    { key = "enemyPlates", label = L["hoa.addon.enemy_nameplates"], default = true,
        tooltip = L["hoa.addon.shows_health_bars_over_enemies_near_you"], apply = function() UI.ApplyEnemyPlates() end },
    { key = "damageMeter", label = L["hoa.addon.damage_meter"], default = true,
        tooltip = L["hoa.addon.shows_how_much_damage_each_of_your_spells_has_done_this_run"], apply = function() UI.ApplyDamageMeter() end },
    { key = "incomingNumbers", label = L["hoa.addon.damage_taken_numbers"], default = true,
        tooltip = L["hoa.addon.shows_the_damage_you_take_as_numbers_beside_your_character"] },
    { key = "healthNumbers", label = L["hoa.addon.health_bar_numbers"], default = true,
        tooltip = L["hoa.addon.shows_your_health_as_numbers_on_your_health_bars"], apply = function() UI.ApplyHealthNumbers() end },
    { key = "cooldownNumbers", label = L["hoa.addon.cooldown_numbers"], default = true,
        tooltip = L["hoa.addon.shows_the_seconds_left_on_spells_with_a_cooldown_of_2_second"] },
    { key = "partyPlates", label = L["hoa.addon.party_health_bars"], default = true,
        tooltip = L["hoa.addon.shows_health_bars_over_your_party_members_during_a_run_they_"],
        apply = function() UI.ApplyPartyPlates() end },
}

UI.OTHER_EFFECTS_SETTING = { key = "otherEffects", label = L["hoa.addon.party_spell_effects"], default = 100,
    tooltip = L["hoa.addon.lower_this_to_see_fewer_of_your_party_s_spell_effects_your_o"],
    apply = function() UI.SendOtherEffects() end }

UI.SIDE_CARD_SCALE_SETTING = { key = "sideCardScale", label = L["hoa.addon.reward_card_scale"], default = 50, min = 50, max = 100, step = 10,
    tooltip = L["hoa.addon.size_of_reward_cards_when_pause_on_rewards_is_disabled"], low = "50%", high = "100%",
    valueText = function(value) return format("%d%%", value) end }

function UI.SideScale(smallest)
    local value = UI.SettingValue(UI.SIDE_CARD_SCALE_SETTING)
    return smallest + (1 - smallest) * (value - UI.SIDE_CARD_SCALE_SETTING.min) / (UI.SIDE_CARD_SCALE_SETTING.max - UI.SIDE_CARD_SCALE_SETTING.min)
end

function UI.OtherEffectsText(value)
    if value <= 0 then
        return L["hoa.addon.off_2"]
    end
    return format("%d%%", value)
end

function UI.SendOtherEffects()
    SendChatMessage(".bonk effects " .. UI.SettingValue(UI.OTHER_EFFECTS_SETTING), "SAY")
end

UI.REACH_RING_COLORS = {
    { style = 3, label = L["hoa.addon.blue"], r = 0.65, g = 0.90, b = 1.0 },
    { style = 1, label = L["hoa.addon.purple"], r = 0.75, g = 0.55, b = 1.0 },
    { style = 2, label = L["hoa.addon.green"], r = 0.55, g = 1.0, b = 0.45 },
    { style = 0, label = L["hoa.addon.red"], r = 1.0, g = 0.30, b = 0.18 },
    { style = 4, label = L["hoa.addon.dark_red"], r = 0.85, g = 0.10, b = 0.10 },
}
UI.REACH_RING_PREVIEW_SECONDS = 5

UI.REACH_RING_COLOR_SETTING = { key = "reachRingColor", default = 3, apply = function() UI.SendReachRing() end }
UI.REACH_RING_FILL_SETTING = { key = "reachRingFill", label = L["hoa.addon.fill_range_ring"], default = false,
    tooltip = L["hoa.addon.shades_the_whole_area_inside_the_range_ring_not_just_its_edg"], apply = function() UI.SendReachRing() end }
UI.REACH_RING_OPACITY_SETTING = { key = "reachRingOpacity", label = L["hoa.addon.range_ring_opacity"], default = 60, min = 10,
    tooltip = L["hoa.addon.how_strongly_the_range_ring_shows_on_the_ground"], low = "10%", high = "100%",
    valueText = function(value) return format("%d%%", value) end, apply = function() UI.SendReachRing() end }

function UI.ReachRingColor()
    local style = UI.SettingValue(UI.REACH_RING_COLOR_SETTING)
    for _, color in ipairs(UI.REACH_RING_COLORS) do
        if color.style == style then
            return color
        end
    end
    return UI.REACH_RING_COLORS[1]
end

local function ReachRingSpellKey()
    local _, classToken = UnitClass("player")
    return "reachRingSpell" .. (classToken or "")
end

function UI.ReachRingSpell()
    return UI.Option(ReachRingSpellKey(), 0)
end

function UI.SetReachRingSpell(spellId)
    UI.SetOption(ReachRingSpellKey(), spellId)
end

function UI.SendReachRing()
    SendChatMessage(format(".bonk ring set %d %d %d %d", UI.ReachRingSpell(), UI.ReachRingColor().style,
        UI.SettingValue(UI.REACH_RING_FILL_SETTING) and 1 or 0, UI.SettingValue(UI.REACH_RING_OPACITY_SETTING)), "SAY")
end

function UI.ChooseReachRingSlot(index)
    SendChatMessage(".bonk ring slot " .. index, "SAY")
end

local reachPreview = CreateFrame("Frame")
reachPreview:Hide()
reachPreview:SetScript("OnUpdate", function()
    if GetTime() >= this.endsAt then
        this:Hide()
        SendChatMessage(".bonk ring preview 0", "SAY")
    end
end)

function UI.PreviewReachRing()
    UI.SendReachRing()
    SendChatMessage(".bonk ring preview 1", "SAY")
    reachPreview.endsAt = GetTime() + UI.REACH_RING_PREVIEW_SECONDS
    reachPreview:Show()
end

UI.INTERACT_SETTINGS = {}
for _, kind in ipairs(UI.INTERACT_TYPES) do
    tinsert(UI.INTERACT_SETTINGS, { key = kind.key, label = kind.label, default = true,
        tooltip = L("hoa.addon.the_interact_key_interacts_with_1_2", string.lower(kind.label), kind.hint),
        apply = function() UI.ApplyInteract() end })
end
UI.AUTO_CHEST_SETTING = { key = "autoChests", label = L["hoa.addon.auto_open_chests"], default = false,
    tooltip = L["hoa.addon.when_enabled_chests_open_as_you_walk_up_to_them_everything_e"],
    apply = function() UI.ApplyInteract() end }

UI.KEYS = {
    { command = "VANILLABONK_INTERACT", label = L["hoa.addon.interact"], default = "F" },
    { command = "VANILLABONK_HEARTH", label = L["hoa.addon.use_hearthstone"], default = "T" },
    { command = "VANILLABONK_DASH", label = L["hoa.addon.dash"], modifierAllowed = true },
    { command = "VANILLABONK_SHAPESHIFT", label = L["hoa.addon.shapeshift_druid"], default = "R", class = "Druid", replaces = { REPLY = true } },
    { command = "VANILLABONK_INSPECT", label = L["hoa.addon.inspect_talents"], default = "N", replaces = { TOGGLETALENTS = true } },
}

local settingsWatchers = {}

function UI.WatchSettings(watcher)
    tinsert(settingsWatchers, watcher)
end

local function SettingsChanged()
    for _, watcher in ipairs(settingsWatchers) do
        watcher()
    end
end

UI.WatchSettings(function()
    if UI.RefreshReachMarks then
        UI.RefreshReachMarks()
    end
end)

function UI.SettingValue(setting)
    return UI.Option(setting.key, setting.default)
end

function UI.ChangeSetting(setting, value)
    UI.SetOption(setting.key, value)
    if setting.apply then
        setting.apply()
    end
    SettingsChanged()
end

UI.LANGUAGES = {
    { value = "enUS", label = L["hoa.addon.language_english"] },
    { value = "zhCN", label = L["hoa.addon.language_simplified_chinese"] },
}

UI.LANGUAGE_CVAR = "hoaLanguage"
RegisterCVar(UI.LANGUAGE_CVAR, "enUS")

function UI.Language()
    return GetCVar(UI.LANGUAGE_CVAR) or "enUS"
end

function UI.LanguageLabel(value)
    for _, language in ipairs(UI.LANGUAGES) do
        if language.value == value then
            return language.label
        end
    end
    return value
end

function UI.ChangeLanguage(value)
    if value == UI.Language() then
        return
    end
    SetCVar(UI.LANGUAGE_CVAR, value)
    SendChatMessage(".bonk lang " .. value, "SAY")
    VanillaBonkLocale.Changed(value)
    SettingsChanged()
end

function UI.ChangeHealthBar(mode)
    UI.SetOption("healthBar", mode)
    UI.ApplyHealthBarMode(mode)
    SettingsChanged()
end

local function SetKeyBinding(binding, key)
    local old = { GetBindingKey(binding.command) }
    for _, oldKey in ipairs(old) do
        SetBinding(oldKey)
    end
    SetBinding(key, binding.command)
    SaveBindings(GetCurrentBindingSet())
    SettingsChanged()
end

local function DefaultKeyFree(binding)
    local action = GetBindingAction(binding.default) or ""
    return not binding.replaces or action == "" or binding.replaces[action]
end

local function KeysGivenThisClient()
    VanillaBonkKeysGiven = VanillaBonkKeysGiven or {}
    if BenillaOptionsFrame and not VanillaBonkKeysGiven.benilla then
        VanillaBonkKeysGiven = { benilla = true }
    end
    return VanillaBonkKeysGiven
end

local function GiveDefaultKeys()
    if VanillaBonkChoiceKeys then
        return
    end
    local given = KeysGivenThisClient()
    local changed = false
    for _, binding in ipairs(UI.KEYS) do
        local forClass = not binding.class or UnitClass("player") == binding.class
        if binding.default and forClass and not given[binding.command] then
            given[binding.command] = true
            if not GetBindingKey(binding.command) and DefaultKeyFree(binding) then
                SetBinding(binding.default, binding.command)
                changed = true
            end
        end
    end
    if changed then
        SaveBindings(GetCurrentBindingSet())
    end
end

local capture = CreateFrame("Frame", "VanillaBonkKeyCapture", UIParent)
capture:SetFrameStrata("FULLSCREEN_DIALOG")
capture:SetWidth(320)
capture:SetHeight(110)
capture:SetPoint("CENTER", UIParent, "CENTER", 0, 120)
capture:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
capture:EnableMouse(true)
capture:EnableKeyboard(true)
capture.title = UI.Text(capture, 14)
capture.title:SetTextColor(1, 0.82, 0)
capture.title:SetPoint("TOP", capture, "TOP", 0, -24)
capture.body = UI.Text(capture, 12)
capture.body:SetWidth(280)
capture.body:SetPoint("TOP", capture.title, "BOTTOM", 0, -10)
capture:Hide()

local function FinishCapture(key)
    local binding = capture.binding
    capture:Hide()
    if key and binding then
        SetKeyBinding(binding, key)
        PlaySound("igMainMenuOptionCheckBoxOn")
    end
end

capture:SetScript("OnKeyDown", function()
    local key = arg1
    if key == "ESCAPE" then
        FinishCapture(nil)
        return
    end
    if MODIFIER_KEYS[key] then
        capture.modifier = key
        return
    end
    capture.modifier = nil
    if key == "UNKNOWN" or key == "LeftButton" or key == "RightButton" then
        return
    end
    if IsAltKeyDown() then
        key = "ALT-" .. key
    end
    if IsControlKeyDown() then
        key = "CTRL-" .. key
    end
    if IsShiftKeyDown() then
        key = "SHIFT-" .. key
    end
    FinishCapture(key)
end)

capture:SetScript("OnKeyUp", function()
    if capture.modifier and arg1 == capture.modifier and capture.binding.modifierAllowed then
        FinishCapture(arg1)
    end
    capture.modifier = nil
end)

function UI.CaptureKey(binding)
    capture.binding = binding
    capture.modifier = nil
    capture.title:SetText(binding.label)
    capture.body:SetText(L("hoa.addon.press_the_key_you_want_for_1_escape_keeps_the_current_key", binding.label))
    capture:Show()
end

function UI.KeyText(binding)
    local text = UI.BindingText(binding.command)
    if text == "" then
        return L["hoa.addon.none"]
    end
    return text
end

VANILLABONK_OTHER_EFFECTS_TIP = UI.OTHER_EFFECTS_SETTING.tooltip

local function AddOtherEffectsVideoRow()
    local page = BenillaOptionsFrameContainerBodyGraphics
    local before = BenillaOptionsFrameContainerBodyGraphicsRowSpellDetail
    local after = BenillaOptionsFrameContainerBodyGraphicsRowBrightness
    if not (page and before and after and BenillaOptionsNumFuncRow_OnLoad and BENILLA_OPTIONS_PAGE_ROWS) then
        return
    end
    local setting = UI.OTHER_EFFECTS_SETTING
    local row = CreateFrame("Frame", page:GetName() .. "RowOtherEffects", page, "BenillaOptionsSliderRowTemplate")
    row:SetPoint("TOPLEFT", before, "BOTTOMLEFT", 0, -9)
    row:SetPoint("TOPRIGHT", before, "BOTTOMRIGHT", 0, -9)
    after:ClearAllPoints()
    after:SetPoint("TOPLEFT", row, "BOTTOMLEFT", 0, -9)
    after:SetPoint("TOPRIGHT", row, "BOTTOMRIGHT", 0, -9)
    BenillaOptionsNumFuncRow_OnLoad(row, function()
        return UI.SettingValue(setting) / 100
    end, function(value)
        UI.ChangeSetting(setting, math.floor(value * 100 + 0.5))
    end, "1", setting.label, "VANILLABONK_OTHER_EFFECTS_TIP")
    BenillaOptionsSliderRow_Setup(row, 0, 1, 0.1)
    local rows = BENILLA_OPTIONS_PAGE_ROWS.Graphics
    for index, key in ipairs(rows) do
        if key == "RowSpellDetail" then
            tinsert(rows, index + 1, "RowOtherEffects")
            break
        end
    end
end

AddOtherEffectsVideoRow()

local events = CreateFrame("Frame")
UI.Module("settings"):OnEnterWorld(function()
    events.giveAt = GetTime() + DEFAULT_KEY_DELAY
end)
events:SetScript("OnUpdate", function()
    if this.giveAt and GetTime() >= this.giveAt then
        this.giveAt = nil
        GiveDefaultKeys()
        if UI.SettingValue(UI.OTHER_EFFECTS_SETTING) < 100 then
            UI.SendOtherEffects()
        end
        UI.SendReachRing()
    end
end)
