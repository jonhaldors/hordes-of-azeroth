local UI = VanillaBonkUI

local DEFAULT_KEY_DELAY = 1
local MODIFIER_KEYS = { SHIFT = true, CTRL = true, ALT = true }

UI.INTERACT_TYPES = {
    { key = "interactPeople", label = "People", hint = "Talk, shop and bank", units = true },
    { key = "interactChests", label = "Chests", hint = "Open chests, vaults and hidden finds", objects = { 900001, 900002, 900041, 900060 }, types = { 3 } },
    { key = "interactShrines", label = "Shrines", hint = "Touch shrines, totems and altars", objects = { 900031, 900032, 900033, 900034 } },
    { key = "interactPortals", label = "Portals", hint = "Step through portals", objects = { 900003 } },
    { key = "interactMail", label = "Mailbox", hint = "Read your mail", types = { 19 } },
}

UI.AUTO_CHEST_ENTRIES = { 900001, 900002 }

UI.DISPLAY_SETTINGS = {
    { key = "enemyPlates", label = "Enemy Nameplates", default = true,
        tooltip = "Shows health bars over enemies near you.", apply = function() UI.ApplyEnemyPlates() end },
    { key = "damageMeter", label = "Damage Meter", default = true,
        tooltip = "Shows how much damage each of your spells has done this run.", apply = function() UI.ApplyDamageMeter() end },
    { key = "incomingNumbers", label = "Damage Taken Numbers", default = true,
        tooltip = "Shows the damage you take as numbers beside your character." },
    { key = "healthNumbers", label = "Health Bar Numbers", default = true,
        tooltip = "Shows your health as numbers on your health bars.", apply = function() UI.ApplyHealthNumbers() end },
    { key = "cooldownNumbers", label = "Cooldown Numbers", default = true,
        tooltip = "Shows the seconds left on spells with a cooldown of 2 seconds or more." },
}

UI.INTERACT_SETTINGS = {}
for _, kind in ipairs(UI.INTERACT_TYPES) do
    tinsert(UI.INTERACT_SETTINGS, { key = kind.key, label = kind.label, default = true,
        tooltip = "The interact key interacts with " .. string.lower(kind.label) .. ". " .. kind.hint .. ".",
        apply = function() UI.ApplyInteract() end })
end
UI.AUTO_CHEST_SETTING = { key = "autoChests", label = "Automatically open chests when you walk up to them", default = false,
    tooltip = "Chests open by themselves when you get close. People, shrines and portals still wait for the interact key.",
    apply = function() UI.ApplyInteract() end }

UI.KEYS = {
    { command = "VANILLABONK_INTERACT", label = "Interact", default = "F" },
    { command = "VANILLABONK_HEARTH", label = "Use Hearthstone", default = "T" },
    { command = "VANILLABONK_DASH", label = "Dash", modifierAllowed = true },
    { command = "VANILLABONK_SHAPESHIFT", label = "Shapeshift (Druid)", default = "R", class = "Druid", replaces = { REPLY = true } },
    { command = "VANILLABONK_INSPECT", label = "Inspect talents (in a run)", default = "N", replaces = { TOGGLETALENTS = true } },
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
    { value = "enUS", label = "English" },
    { value = "zhCN", label = "简体中文" },
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
    capture.body:SetText("Press the key you want for " .. binding.label .. ". Escape keeps the current key.")
    capture:Show()
end

function UI.KeyText(binding)
    local text = UI.BindingText(binding.command)
    if text == "" then
        return "None"
    end
    return text
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    this.giveAt = GetTime() + DEFAULT_KEY_DELAY
end)
events:SetScript("OnUpdate", function()
    if this.giveAt and GetTime() >= this.giveAt then
        this.giveAt = nil
        GiveDefaultKeys()
    end
end)
