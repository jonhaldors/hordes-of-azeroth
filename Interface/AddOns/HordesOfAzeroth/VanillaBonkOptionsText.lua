local L = VanillaBonkL

local INTERFACE_TITLE = L["Interface Options"]
local SOUND_TITLE = L["Sound Options"]
local OKAY_TEXT = L["options window::Okay"]
local CANCEL_TEXT = L["Cancel"]
local DEFAULTS_TEXT = L["Defaults"]
local LOW_TEXT = L["slider::Low"]
local HIGH_TEXT = L["slider::High"]

local STRINGS = {
    INVERT_MOUSE = L["Invert Mouse"],
    CLICK_TO_MOVE = L["Click-to-Move"],
    USE_UBERTOOLTIPS = L["Enhanced Tooltips"],
    SHOW_BUFF_DURATION_TEXT = L["Buff Durations"],
    SHOW_PLAYER_NAMES = L["Player Names"],
    SHOW_GUILD_NAMES = L["Player Guild Names"],
    SHOW_PLAYER_TITLES = L["Player Titles"],
    SHOW_NPC_NAMES = L["NPC Names"],
    SHOW_OWN_NAME = L["Show Own Name"],
    SHOW_CLOAK = L["Show Cloak"],
    SHOW_HELM = L["Show Helm"],
    FOLLOW_TERRAIN = L["Follow Terrain"],
    HEAD_BOB = L["Head Bob"],
    WATER_COLLISION = L["Water Collision"],
    SMART_PIVOT = L["Smart Pivot"],
    SHOW_COMBAT_TEXT_TEXT = L["Enable Floating Combat Text"],
    COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT = L["Show Low Mana and Health"],
    COMBAT_TEXT_SHOW_AURAS_TEXT = L["Show Auras"],
    COMBAT_TEXT_SHOW_AURA_FADE_TEXT = L["Show Fading Auras"],
    COMBAT_TEXT_SHOW_COMBAT_STATE_TEXT = L["Show Combat State"],
    COMBAT_TEXT_SHOW_DODGE_PARRY_MISS_TEXT = L["Show Dodge/Parries/Misses"],
    COMBAT_TEXT_SHOW_RESISTANCES_TEXT = L["Show Damage Reduction"],
    SHOW_DAMAGE_TEXT = L["Show Target Damage"],
    LOG_PERIODIC_EFFECTS = L["Periodic Damage"],
    SHOW_PET_MELEE_DAMAGE = L["Pet Damage"],
    OPTION_TOOLTIP_INVERT_MOUSE = L["Invert the way that the mouse affects camera pitch."],
    OPTION_TOOLTIP_CLICK_TO_MOVE = L["Use mouse clicks to move your character to destinations."],
    OPTION_TOOLTIP_USE_UBERTOOLTIPS = L["Enable detailed tooltips in the lower right hand corner of the screen."],
    OPTION_TOOLTIP_SHOW_BUFF_DURATION = L["Toggle text counters for buff durations on and off."],
    OPTION_TOOLTIP_SHOW_PLAYER_NAMES = L["Always display player names in the game world."],
    OPTION_TOOLTIP_SHOW_GUILD_NAMES = L["Always display player guild names in the game world."],
    OPTION_TOOLTIP_SHOW_PLAYER_TITLES = L["Always display player titles in the game world."],
    OPTION_TOOLTIP_SHOW_NPC_NAMES = L["Always display NPC names in the game world."],
    OPTION_TOOLTIP_SHOW_OWN_NAME = L["Shows your character's name."],
    OPTION_TOOLTIP_SHOW_CLOAK = L["Uncheck this box to hide your character's cloak."],
    OPTION_TOOLTIP_SHOW_HELM = L["Uncheck this box to hide your character's helm."],
    OPTION_TOOLTIP_FOLLOW_TERRAIN = L["Automatically change the camera angle based on the terrain. If your character climbs a slope, the camera will rotate upwards; if you descend, it will rotate downwards."],
    OPTION_TOOLTIP_HEAD_BOB = L["Simulate head bobbing when in first-person perspective."],
    OPTION_TOOLTIP_WATER_COLLISION = L["Set the camera to be above water when your character is above water, and below water when your character is below water."],
    OPTION_TOOLTIP_SMART_PIVOT = L["Lets you free look when the camera is on the ground."],
    OPTION_TOOLTIP_SHOW_COMBAT_TEXT = L["Checking this will enable additional combat messages to appear in the playfield."],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_LOW_HEALTH_MANA = L["Shows a message when you fall below 20% mana or health."],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURAS = L["Shows a message when the player gains an aura."],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURA_FADE = L["Shows a message when an aura fades from the player."],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_COMBAT_STATE = L["Shows a message when you enter or leave combat. "],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_DODGE_PARRY_MISS = L["Shows attacks against you that dodge, parry, or miss."],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_RESISTANCES = L["Shows when you resist taking damage from attacks or spells."],
    OPTION_TOOLTIP_SHOW_DAMAGE = L["Display damage numbers over hostile creatures when damaged."],
    OPTION_TOOLTIP_LOG_PERIODIC_EFFECTS = L["Display damage caused by periodic effects such as Rend and Shadow Word: Pain."],
    OPTION_TOOLTIP_SHOW_PET_MELEE_DAMAGE = L["Show damage caused by your pet."],
    MOUSE_SENSITIVITY = L["Mouse Sensitivity"],
    AUTO_FOLLOW_SPEED = L["Auto-Follow Speed"],
    MOUSE_LOOK_SPEED = L["Mouse Look Speed"],
    MAX_FOLLOW_DIST = L["Max Camera Distance"],
    OPTION_TOOLTIP_MOUSE_SENSITIVITY = L["Adjust the speed at which the mouse cursor moves."],
    OPTION_TOOLTIP_AUTO_FOLLOW_SPEED = L["Adjust the camera movement speed in Always and Smart following styles."],
    OPTION_TOOLTIP_MOUSE_LOOK_SPEED = L["Adjust the speed at which you turn the camera when using mouse look."],
    OPTION_TOOLTIP_MAX_FOLLOW_DIST = L["Adjust the maximum distance the camera will follow behind you."],
    CLICK_CAMERA_STYLE = L["Click-to-Move Camera Style"],
    CAMERA_FOLLOWING_STYLE = L["Camera Following Style"],
    COMBAT_TEXT_FLOAT_MODE_LABEL = L["Combat Text Float Mode"],
    CAMERA_SMART = L["camera style::Smart"],
    CAMERA_LOCKED = L["camera style::Locked"],
    CAMERA_NEVER = L["camera style::Never"],
    CAMERA_ALWAYS = L["camera style::Always"],
    COMBAT_TEXT_SCROLL_UP = L["Scroll Up"],
    COMBAT_TEXT_SCROLL_DOWN = L["Scroll Down"],
    COMBAT_TEXT_SCROLL_ARC = L["scroll direction::Arc"],
    OPTION_TOOLTIP_CLICKCAMERA_SMART = L["Sets the camera to follow your character after a brief delay when changing direction with click-to-move. (Recommended Mode) "],
    OPTION_TOOLTIP_CLICKCAMERA_LOCKED = L["Sets the camera to always be aligned with your character when changing direction with click-to-move."],
    OPTION_TOOLTIP_CLICKCAMERA_NEVER = L["Sets the camera to not move when changing direction with click-to-move."],
    OPTION_TOOLTIP_CLICK_CAMERA1 = L["Sets the camera to follow your character after a brief delay when changing direction with click-to-move. (Recommended Mode)"],
    OPTION_TOOLTIP_CLICK_CAMERA2 = L["Sets the camera to always be aligned with your character when changing direction with click-to-move."],
    OPTION_TOOLTIP_CLICK_CAMERA3 = L["Sets the camera to not move when changing direction with click-to-move."],
    OPTION_TOOLTIP_CAMERA_SMART = L["Set the camera to stay where placed, except when your character is moving.  (Recommended Mode)"],
    OPTION_TOOLTIP_CAMERA_ALWAYS = L["Set the camera to always prefer being behind your character."],
    OPTION_TOOLTIP_CAMERA_NEVER = L["Set the camera to stay where set, and never auto-adjust."],
    OPTION_TOOLTIP_CAMERA1 = L["Set the camera to stay where placed, except when your character is moving."],
    OPTION_TOOLTIP_CAMERA2 = L["Set the camera to always prefer being behind your character."],
    OPTION_TOOLTIP_CAMERA3 = L["Set the camera to stay where set, and never auto-adjust."],
    OPTION_TOOLTIP_COMBAT_TEXT_MODE = L["Sets the direction that combat text scrolls."],
    OPTION_TOOLTIP_SCROLL_UP = L["Scrolls combat text towards the top of the screen."],
    OPTION_TOOLTIP_SCROLL_DOWN = L["Scrolls combat text towards the bottom of the screen."],
    OPTION_TOOLTIP_SCROLL_ARC = L["Scrolls the text in arcs away from the player."],
    ENABLE_ERROR_SPEECH = L["Enable Error Speech"],
    ENABLE_MUSIC = L["Enable Music"],
    ENABLE_AMBIENCE = L["Enable Ambience"],
    ENABLE_ALL_SOUND = L["Enable All Sound"],
    ENABLE_SOUND_AT_CHARACTER = L["Enable Sound at Character"],
    ENABLE_EMOTE_SOUNDS = L["Enable Emote Sounds"],
    ENABLE_MUSIC_LOOPING = L["Loop Music"],
    OPTION_TOOLTIP_ENABLE_ERROR_SPEECH = L["Enables speech from errors (e.g. \"Target out of range\")."],
    OPTION_TOOLTIP_ENABLE_MUSIC = L["Enable background music."],
    OPTION_TOOLTIP_ENABLE_AMBIENCE = L["Enable ambient sounds."],
    OPTION_TOOLTIP_ENABLE_ALL_SOUND = L["Enables or disables all game sound."],
    OPTION_TOOLTIP_ENABLE_SOUND_AT_CHARACTER = L["Listen to sound from the character's point of view rather than the camera."],
    OPTION_TOOLTIP_ENABLE_EMOTE_SOUNDS = L["Toggles emote sounds on and off."],
    OPTION_TOOLTIP_ENABLE_MUSIC_LOOPING = L["Enable to continuously play background music."],
    SOUND_VOLUME = L["Sound Volume"],
    MUSIC_VOLUME = L["Music Volume"],
    AMBIENCE_VOLUME = L["Ambience Volume"],
    MASTER_VOLUME = L["Master Volume"],
    OPTION_TOOLTIP_SOUND_VOLUME = L["Adjusts the sound effect volume."],
    OPTION_TOOLTIP_MUSIC_VOLUME = L["Adjusts the background music volume."],
    OPTION_TOOLTIP_AMBIENCE_VOLUME = L["Adjusts the ambient sound volume."],
    OPTION_TOOLTIP_MASTER_VOLUME = L["Adjusts the master sound volume."],
}

local SOUND_CHECKS = {
    "ENABLE_ERROR_SPEECH", "ENABLE_MUSIC", "ENABLE_AMBIENCE", "ENABLE_ALL_SOUND",
    "ENABLE_SOUND_AT_CHARACTER", "ENABLE_EMOTE_SOUNDS", "ENABLE_MUSIC_LOOPING",
}

local SOUND_SLIDERS = {
    SoundVolume = "SOUND_VOLUME", MusicVolume = "MUSIC_VOLUME",
    AmbienceVolume = "AMBIENCE_VOLUME", MasterVolume = "MASTER_VOLUME",
}

local function SetText(name, text)
    local widget = getglobal(name)
    if widget then
        widget:SetText(text)
    end
end

local function RefreshDropDown(dropdown, initialize, tooltip)
    if not dropdown or not initialize then
        return
    end
    local value = UIDropDownMenu_GetSelectedValue(dropdown)
    UIDropDownMenu_Initialize(dropdown, initialize)
    UIDropDownMenu_SetSelectedValue(dropdown, value)
    local id = UIDropDownMenu_GetSelectedID(dropdown)
    if id then
        dropdown.tooltip = getglobal(tooltip .. id)
    end
end

local function TranslateSoundTitle(english)
    local regions = { SoundOptionsFrame:GetRegions() }
    for _, region in ipairs(regions) do
        if region:GetObjectType() == "FontString" and region:GetText() == english then
            region:SetText(SOUND_TITLE)
        end
    end
end

if VanillaBonkLocale.language ~= "enUS" then
    local soundTitle = SOUNDOPTIONS_MENU
    for name, text in pairs(STRINGS) do
        setglobal(name, text)
    end

    SetText("UIOptionsFrameTitle", INTERFACE_TITLE)
    for _, prefix in ipairs({ "UIOptionsFrame", "SoundOptionsFrame" }) do
        SetText(prefix .. "Okay", OKAY_TEXT)
        SetText(prefix .. "Cancel", CANCEL_TEXT)
        SetText(prefix .. "Defaults", DEFAULTS_TEXT)
    end
    for _, slider in ipairs({
        "UIOptionsFrameSlider1", "UIOptionsFrameSlider2", "UIOptionsFrameSlider3", "UIOptionsFrameSlider4",
        "SoundOptionsFrameSlider1", "SoundOptionsFrameSlider2", "SoundOptionsFrameSlider3", "SoundOptionsFrameSlider4",
    }) do
        SetText(slider .. "Low", LOW_TEXT)
        SetText(slider .. "High", HIGH_TEXT)
    end

    SetText("UIOptionsFrameClickCameraDropDownLabel", STRINGS.CLICK_CAMERA_STYLE)
    SetText("UIOptionsFrameCameraDropDownLabel", STRINGS.CAMERA_FOLLOWING_STYLE)
    SetText("UIOptionsFrameCombatTextDropDownLabel", STRINGS.COMBAT_TEXT_FLOAT_MODE_LABEL)
    RefreshDropDown(UIOptionsFrameClickCameraDropDown, UIOptionsFrameClickCameraDropDown_Initialize, "OPTION_TOOLTIP_CLICK_CAMERA")
    RefreshDropDown(UIOptionsFrameCameraDropDown, UIOptionsFrameCameraDropDown_Initialize, "OPTION_TOOLTIP_CAMERA")

    for _, name in ipairs(SOUND_CHECKS) do
        local check = SoundOptionsFrameCheckButtons[name]
        if check then
            check.tooltipText = STRINGS["OPTION_TOOLTIP_" .. name]
        end
    end
    for _, slider in ipairs(SoundOptionsFrameSliders) do
        local name = SOUND_SLIDERS[slider.cvar]
        if name then
            slider.text = STRINGS[name]
            slider.tooltipText = STRINGS["OPTION_TOOLTIP_" .. name]
        end
    end
    TranslateSoundTitle(soundTitle)
end
