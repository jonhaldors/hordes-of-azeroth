local L = VanillaBonkL

local INTERFACE_TITLE = L["hoa.addon.interface_options"]
local SOUND_TITLE = L["hoa.addon.sound_options"]
local OKAY_TEXT = L["hoa.addon.options_window_okay"]
local CANCEL_TEXT = L["hoa.addon.cancel"]
local DEFAULTS_TEXT = L["hoa.addon.defaults"]
local LOW_TEXT = L["hoa.addon.slider_low"]
local HIGH_TEXT = L["hoa.addon.slider_high"]

local STRINGS = {
    INVERT_MOUSE = L["hoa.addon.invert_mouse"],
    CLICK_TO_MOVE = L["hoa.addon.click_to_move"],
    USE_UBERTOOLTIPS = L["hoa.addon.enhanced_tooltips"],
    SHOW_BUFF_DURATION_TEXT = L["hoa.addon.buff_durations"],
    SHOW_PLAYER_NAMES = L["hoa.addon.player_names"],
    SHOW_GUILD_NAMES = L["hoa.addon.player_guild_names"],
    SHOW_PLAYER_TITLES = L["hoa.addon.player_titles"],
    SHOW_NPC_NAMES = L["hoa.addon.npc_names"],
    SHOW_OWN_NAME = L["hoa.addon.show_own_name"],
    SHOW_CLOAK = L["hoa.addon.show_cloak"],
    SHOW_HELM = L["hoa.addon.show_helm"],
    FOLLOW_TERRAIN = L["hoa.addon.follow_terrain"],
    HEAD_BOB = L["hoa.addon.head_bob"],
    WATER_COLLISION = L["hoa.addon.water_collision"],
    SMART_PIVOT = L["hoa.addon.smart_pivot"],
    SHOW_COMBAT_TEXT_TEXT = L["hoa.addon.enable_floating_combat_text"],
    COMBAT_TEXT_SHOW_LOW_HEALTH_MANA_TEXT = L["hoa.addon.show_low_mana_and_health"],
    COMBAT_TEXT_SHOW_AURAS_TEXT = L["hoa.addon.show_auras"],
    COMBAT_TEXT_SHOW_AURA_FADE_TEXT = L["hoa.addon.show_fading_auras"],
    COMBAT_TEXT_SHOW_COMBAT_STATE_TEXT = L["hoa.addon.show_combat_state"],
    COMBAT_TEXT_SHOW_DODGE_PARRY_MISS_TEXT = L["hoa.addon.show_dodge_parries_misses"],
    COMBAT_TEXT_SHOW_RESISTANCES_TEXT = L["hoa.addon.show_damage_reduction"],
    SHOW_DAMAGE_TEXT = L["hoa.addon.show_target_damage"],
    LOG_PERIODIC_EFFECTS = L["hoa.addon.periodic_damage"],
    SHOW_PET_MELEE_DAMAGE = L["hoa.addon.pet_damage"],
    OPTION_TOOLTIP_INVERT_MOUSE = L["hoa.addon.invert_the_way_that_the_mouse_affects_camera_pitch"],
    OPTION_TOOLTIP_CLICK_TO_MOVE = L["hoa.addon.use_mouse_clicks_to_move_your_character_to_destinations"],
    OPTION_TOOLTIP_USE_UBERTOOLTIPS = L["hoa.addon.enable_detailed_tooltips_in_the_lower_right_hand_corner_of_t"],
    OPTION_TOOLTIP_SHOW_BUFF_DURATION = L["hoa.addon.toggle_text_counters_for_buff_durations_on_and_off"],
    OPTION_TOOLTIP_SHOW_PLAYER_NAMES = L["hoa.addon.always_display_player_names_in_the_game_world"],
    OPTION_TOOLTIP_SHOW_GUILD_NAMES = L["hoa.addon.always_display_player_guild_names_in_the_game_world"],
    OPTION_TOOLTIP_SHOW_PLAYER_TITLES = L["hoa.addon.always_display_player_titles_in_the_game_world"],
    OPTION_TOOLTIP_SHOW_NPC_NAMES = L["hoa.addon.always_display_npc_names_in_the_game_world"],
    OPTION_TOOLTIP_SHOW_OWN_NAME = L["hoa.addon.shows_your_character_s_name"],
    OPTION_TOOLTIP_SHOW_CLOAK = L["hoa.addon.uncheck_this_box_to_hide_your_character_s_cloak"],
    OPTION_TOOLTIP_SHOW_HELM = L["hoa.addon.uncheck_this_box_to_hide_your_character_s_helm"],
    OPTION_TOOLTIP_FOLLOW_TERRAIN = L["hoa.addon.automatically_change_the_camera_angle_based_on_the_terrain_i"],
    OPTION_TOOLTIP_HEAD_BOB = L["hoa.addon.simulate_head_bobbing_when_in_first_person_perspective"],
    OPTION_TOOLTIP_WATER_COLLISION = L["hoa.addon.set_the_camera_to_be_above_water_when_your_character_is_abov"],
    OPTION_TOOLTIP_SMART_PIVOT = L["hoa.addon.lets_you_free_look_when_the_camera_is_on_the_ground"],
    OPTION_TOOLTIP_SHOW_COMBAT_TEXT = L["hoa.addon.checking_this_will_enable_additional_combat_messages_to_appe"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_LOW_HEALTH_MANA = L["hoa.addon.shows_a_message_when_you_fall_below_20_mana_or_health"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURAS = L["hoa.addon.shows_a_message_when_the_player_gains_an_aura"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_AURA_FADE = L["hoa.addon.shows_a_message_when_an_aura_fades_from_the_player"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_COMBAT_STATE = L["hoa.addon.shows_a_message_when_you_enter_or_leave_combat"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_DODGE_PARRY_MISS = L["hoa.addon.shows_attacks_against_you_that_dodge_parry_or_miss"],
    OPTION_TOOLTIP_COMBAT_TEXT_SHOW_RESISTANCES = L["hoa.addon.shows_when_you_resist_taking_damage_from_attacks_or_spells"],
    OPTION_TOOLTIP_SHOW_DAMAGE = L["hoa.addon.display_damage_numbers_over_hostile_creatures_when_damaged"],
    OPTION_TOOLTIP_LOG_PERIODIC_EFFECTS = L["hoa.addon.display_damage_caused_by_periodic_effects_such_as_rend_and_s"],
    OPTION_TOOLTIP_SHOW_PET_MELEE_DAMAGE = L["hoa.addon.show_damage_caused_by_your_pet"],
    MOUSE_SENSITIVITY = L["hoa.addon.mouse_sensitivity"],
    AUTO_FOLLOW_SPEED = L["hoa.addon.auto_follow_speed"],
    MOUSE_LOOK_SPEED = L["hoa.addon.mouse_look_speed"],
    MAX_FOLLOW_DIST = L["hoa.addon.max_camera_distance"],
    OPTION_TOOLTIP_MOUSE_SENSITIVITY = L["hoa.addon.adjust_the_speed_at_which_the_mouse_cursor_moves"],
    OPTION_TOOLTIP_AUTO_FOLLOW_SPEED = L["hoa.addon.adjust_the_camera_movement_speed_in_always_and_smart_followi"],
    OPTION_TOOLTIP_MOUSE_LOOK_SPEED = L["hoa.addon.adjust_the_speed_at_which_you_turn_the_camera_when_using_mou"],
    OPTION_TOOLTIP_MAX_FOLLOW_DIST = L["hoa.addon.adjust_the_maximum_distance_the_camera_will_follow_behind_yo"],
    CLICK_CAMERA_STYLE = L["hoa.addon.click_to_move_camera_style"],
    CAMERA_FOLLOWING_STYLE = L["hoa.addon.camera_following_style"],
    COMBAT_TEXT_FLOAT_MODE_LABEL = L["hoa.addon.combat_text_float_mode"],
    CAMERA_SMART = L["hoa.addon.camera_style_smart"],
    CAMERA_LOCKED = L["hoa.addon.camera_style_locked"],
    CAMERA_NEVER = L["hoa.addon.camera_style_never"],
    CAMERA_ALWAYS = L["hoa.addon.camera_style_always"],
    COMBAT_TEXT_SCROLL_UP = L["hoa.addon.scroll_up"],
    COMBAT_TEXT_SCROLL_DOWN = L["hoa.addon.scroll_down"],
    COMBAT_TEXT_SCROLL_ARC = L["hoa.addon.scroll_direction_arc"],
    OPTION_TOOLTIP_CLICKCAMERA_SMART = L["hoa.addon.sets_the_camera_to_follow_your_character_after_a_brief_delay_2"],
    OPTION_TOOLTIP_CLICKCAMERA_LOCKED = L["hoa.addon.sets_the_camera_to_always_be_aligned_with_your_character_whe"],
    OPTION_TOOLTIP_CLICKCAMERA_NEVER = L["hoa.addon.sets_the_camera_to_not_move_when_changing_direction_with_cli"],
    OPTION_TOOLTIP_CLICK_CAMERA1 = L["hoa.addon.sets_the_camera_to_follow_your_character_after_a_brief_delay"],
    OPTION_TOOLTIP_CLICK_CAMERA2 = L["hoa.addon.sets_the_camera_to_always_be_aligned_with_your_character_whe"],
    OPTION_TOOLTIP_CLICK_CAMERA3 = L["hoa.addon.sets_the_camera_to_not_move_when_changing_direction_with_cli"],
    OPTION_TOOLTIP_CAMERA_SMART = L["hoa.addon.set_the_camera_to_stay_where_placed_except_when_your_charact_2"],
    OPTION_TOOLTIP_CAMERA_ALWAYS = L["hoa.addon.set_the_camera_to_always_prefer_being_behind_your_character"],
    OPTION_TOOLTIP_CAMERA_NEVER = L["hoa.addon.set_the_camera_to_stay_where_set_and_never_auto_adjust"],
    OPTION_TOOLTIP_CAMERA1 = L["hoa.addon.set_the_camera_to_stay_where_placed_except_when_your_charact"],
    OPTION_TOOLTIP_CAMERA2 = L["hoa.addon.set_the_camera_to_always_prefer_being_behind_your_character"],
    OPTION_TOOLTIP_CAMERA3 = L["hoa.addon.set_the_camera_to_stay_where_set_and_never_auto_adjust"],
    OPTION_TOOLTIP_COMBAT_TEXT_MODE = L["hoa.addon.sets_the_direction_that_combat_text_scrolls"],
    OPTION_TOOLTIP_SCROLL_UP = L["hoa.addon.scrolls_combat_text_towards_the_top_of_the_screen"],
    OPTION_TOOLTIP_SCROLL_DOWN = L["hoa.addon.scrolls_combat_text_towards_the_bottom_of_the_screen"],
    OPTION_TOOLTIP_SCROLL_ARC = L["hoa.addon.scrolls_the_text_in_arcs_away_from_the_player"],
    ENABLE_ERROR_SPEECH = L["hoa.addon.enable_error_speech"],
    ENABLE_MUSIC = L["hoa.addon.enable_music"],
    ENABLE_AMBIENCE = L["hoa.addon.enable_ambience"],
    ENABLE_ALL_SOUND = L["hoa.addon.enable_all_sound"],
    ENABLE_SOUND_AT_CHARACTER = L["hoa.addon.enable_sound_at_character"],
    ENABLE_EMOTE_SOUNDS = L["hoa.addon.enable_emote_sounds"],
    ENABLE_MUSIC_LOOPING = L["hoa.addon.loop_music"],
    OPTION_TOOLTIP_ENABLE_ERROR_SPEECH = L["hoa.addon.enables_speech_from_errors_e_g_target_out_of_range"],
    OPTION_TOOLTIP_ENABLE_MUSIC = L["hoa.addon.enable_background_music"],
    OPTION_TOOLTIP_ENABLE_AMBIENCE = L["hoa.addon.enable_ambient_sounds"],
    OPTION_TOOLTIP_ENABLE_ALL_SOUND = L["hoa.addon.enables_or_disables_all_game_sound"],
    OPTION_TOOLTIP_ENABLE_SOUND_AT_CHARACTER = L["hoa.addon.listen_to_sound_from_the_character_s_point_of_view_rather_th"],
    OPTION_TOOLTIP_ENABLE_EMOTE_SOUNDS = L["hoa.addon.toggles_emote_sounds_on_and_off"],
    OPTION_TOOLTIP_ENABLE_MUSIC_LOOPING = L["hoa.addon.enable_to_continuously_play_background_music"],
    SOUND_VOLUME = L["hoa.addon.sound_volume"],
    MUSIC_VOLUME = L["hoa.addon.music_volume"],
    AMBIENCE_VOLUME = L["hoa.addon.ambience_volume"],
    MASTER_VOLUME = L["hoa.addon.master_volume"],
    OPTION_TOOLTIP_SOUND_VOLUME = L["hoa.addon.adjusts_the_sound_effect_volume"],
    OPTION_TOOLTIP_MUSIC_VOLUME = L["hoa.addon.adjusts_the_background_music_volume"],
    OPTION_TOOLTIP_AMBIENCE_VOLUME = L["hoa.addon.adjusts_the_ambient_sound_volume"],
    OPTION_TOOLTIP_MASTER_VOLUME = L["hoa.addon.adjusts_the_master_sound_volume"],
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

do
    local soundTitle = SOUNDOPTIONS_MENU
    for name, text in pairs(STRINGS) do
        setglobal(name, text)
    end
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR1", L["hoa.addon.show_the_bottom_left_action_bar"])
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR2", L["hoa.addon.show_the_bottom_right_action_bar"])
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR3", L["hoa.addon.show_the_right_action_bar"])
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR4", L["hoa.addon.show_the_second_right_action_bar"])
    setglobal("OPTION_TOOLTIP_ALWAYS_SHOW_MULTIBARS", L["hoa.addon.always_show_action_bars"])
    setglobal("OPTION_TOOLTIP_LOCK_ACTIONBAR", L["hoa.addon.lock_the_action_bars_in_place"])
    setglobal("OPTION_TOOLTIP_UI_SCALE", L["hoa.addon.adjust_the_size_of_the_interface_elements"])
    setglobal("OPTION_TOOLTIP_FARCLIP", L["hoa.addon.adjust_how_far_terrain_is_visible"])
    setglobal("OPTION_TOOLTIP_ENVIRONMENT_DETAIL", L["hoa.addon.adjust_the_level_of_environmental_detail"])
    setglobal("OPTION_TOOLTIP_SPELL_DETAIL", L["hoa.addon.adjust_the_level_of_spell_effect_detail"])
    setglobal("OPTION_TOOLTIP_WEATHER_DETAIL", L["hoa.addon.adjust_the_intensity_of_weather_effects"])
    setglobal("OPTION_TOOLTIP_VERTICAL_SYNC", L["hoa.addon.synchronize_the_frame_rate_with_the_monitor_s_refresh_rate"])

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


local function TranslateOptions(frame)
    if frame.GetText and frame.SetText then
        local text = frame:GetText()
        local translated = text and L[text]
        if translated then
            frame:SetText(translated)
        end
    end
    if frame.GetRegions then
        local regions = { frame:GetRegions() }
        for index = 1, table.getn(regions) do
            local region = regions[index]
            if region.GetText and region.SetText then
                local text = region:GetText()
                local translated = text and L[text]
                if translated then
                    region:SetText(translated)
                end
            end
        end
    end
    if frame.GetChildren then
        local children = { frame:GetChildren() }
        for index = 1, table.getn(children) do
            TranslateOptions(children[index])
        end
    end
end

do
    local ticker = CreateFrame("Frame")
    local nextCheck = GetTime() + 0.5
    ticker:SetScript("OnUpdate", function()
        if GetTime() < nextCheck then
            return
        end
        nextCheck = GetTime() + 0.5
        if BenillaOptionsFrame and BenillaOptionsFrame:IsShown() then
            TranslateOptions(BenillaOptionsFrame)
        end
    end)

    local originalSetText = GameTooltip.SetText
    GameTooltip.SetText = function(tooltip, text, red, green, blue, wrap)
        if BenillaOptionsFrame and BenillaOptionsFrame:IsShown() and type(text) == "string" then
            text = L[text] or text
        end
        return originalSetText(tooltip, text, red, green, blue, wrap)
    end

    if UIDropDownMenu_AddButton then
    local originalAddButton = UIDropDownMenu_AddButton
    UIDropDownMenu_AddButton = function(info, level)
        if type(info) == "table" and type(info.text) == "string" then
            info.text = L[info.text] or info.text
        end
        return originalAddButton(info, level)
    end
    end
end
