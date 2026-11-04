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
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR1", "显示左下方动作条。")
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR2", "显示右下方动作条。")
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR3", "显示右侧动作条。")
    setglobal("OPTION_TOOLTIP_SHOW_MULTIBAR4", "显示第二条右侧动作条。")
    setglobal("OPTION_TOOLTIP_ALWAYS_SHOW_MULTIBARS", "始终显示动作条。")
    setglobal("OPTION_TOOLTIP_LOCK_ACTIONBAR", "锁定动作条，防止拖动。")
    setglobal("OPTION_TOOLTIP_UI_SCALE", "调整界面元素的大小。")
    setglobal("OPTION_TOOLTIP_FARCLIP", "调整地形可见距离。")
    setglobal("OPTION_TOOLTIP_ENVIRONMENT_DETAIL", "调整环境细节。")
    setglobal("OPTION_TOOLTIP_SPELL_DETAIL", "调整法术效果的细节程度。")
    setglobal("OPTION_TOOLTIP_WEATHER_DETAIL", "调整天气效果强度。")
    setglobal("OPTION_TOOLTIP_VERTICAL_SYNC", "将帧率与显示器刷新率同步。")

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

local BENILLA_OPTIONS_ZHCN = {
    ["Action Bars"] = "动作条",
    ["AddOns"] = "插件",
    ["Always"] = "始终",
    ["Always Show ActionBars"] = "始终显示动作条",
    ["Ambience Volume"] = "环境音音量",
    ["Apply"] = "应用",
    ["Arc"] = "弧形",
    ["Attack on assist"] = "协助攻击",
    ["Audio"] = "声音",
    ["Auto Clear AFK"] = "自动取消暂离",
    ["Auto Loot"] = "自动拾取",
    ["Auto Self Cast"] = "自动自我施法",
    ["Auto-Follow Speed"] = "自动跟随速度",
    ["Automatic"] = "自动",
    ["Automatic Quest Tracking"] = "自动追踪任务",
    ["Automatic fills your screen at its own resolution.\n\nPick a size to run the game in a window of that size instead. On Steam Deck and other handhelds the window is stretched to fill the screen. To keep fullscreen and only draw the 3D world at a lower or higher resolution, use Render Scale."] = "“自动”会以屏幕自身的分辨率铺满屏幕。\n\n选择某个尺寸后，游戏会改为在相应大小的窗口中运行。在 Steam Deck 和掌机上，窗口会被拉伸以铺满屏幕。如果想保持全屏、只以更低或更高的分辨率绘制 3D 世界，请使用渲染缩放。",
    ["Block Trades"] = "拒绝交易",
    ["Buff Durations"] = "增益持续时间",
    ["Camera Following Style"] = "镜头跟随方式",
    ["Character Specific Key Bindings"] = "角色专用按键绑定",
    ["Chat"] = "聊天",
    ["Click-to-Move"] = "点击移动",
    ["Close"] = "关闭",
    ["Combat"] = "战斗",
    ["Combat Text Float Mode"] = "战斗文字浮动方式",
    ["Controls"] = "控制",
    ["Defaults"] = "默认",
    ["Detailed Loot Information"] = "详细拾取信息",
    ["Disable Spam Filter"] = "禁用广告过滤",
    ["Display Mode"] = "显示模式",
    ["Draws the 3D world at a fraction of the window's resolution, or larger than it. The interface is unaffected at any setting.\n\nBelow 100% trades sharpness for frame rate; above 100% is supersampling, which smooths edges at the cost of frame rate. Applies when you click Apply."] = "以窗口分辨率的一部分（或更高）绘制 3D 世界，界面在任何设置下都不受影响。\n\n低于100%会用清晰度换取帧率；高于100%则是超级采样，以帧率为代价让边缘更平滑。点击“应用”后生效。",
    ["Enable All Sound"] = "启用所有声音",
    ["Enable Ambience"] = "启用环境音",
    ["Enable Error Speech"] = "启用错误语音",
    ["Enable Floating Combat Text"] = "启用浮动战斗文字",
    ["Enable Music"] = "启用音乐",
    ["Enable Sound in Background"] = "后台播放声音",
    ["Enhanced Tooltips"] = "增强提示信息",
    ["Environment Detail"] = "环境细节",
    ["Follow Terrain"] = "跟随地形",
    ["Game"] = "游戏",
    ["Gameplay"] = "游戏性",
    ["Graphics"] = "图像",
    ["Guild Member Alert"] = "公会成员提示",
    ["Head Bob"] = "头部晃动",
    ["Instant Quest Text"] = "任务文本即时显示",
    ["Interface"] = "界面",
    ["Invert Mouse"] = "反转鼠标",
    ["Keeps the game's sound playing while you are working in another window.\n\nWith this off, switching away silences the game and switching back restores it. Sounds keep running while they are silenced, so a long one may have finished by the time you return."] = "当你在其他窗口中工作时，让游戏继续播放声音。\n\n关闭时，切换到其他窗口会让游戏静音，切回来再恢复。静音期间声音仍在继续播放，所以你回来时较长的音效可能已经放完了。",
    ["Keybindings"] = "按键设置",
    ["Lightens or darkens the whole picture — nights, caves and interiors are what it is for.\n\nThis is the same correction 1.12 applied through the display's own gamma ramp, which it could only do in exclusive fullscreen. benilla applies it to the finished image instead, so it works in both display modes."] = "提亮或压暗整个画面——夜晚、洞穴和室内场景最需要它。\n\n它与 1.12 通过显示器自身的伽马曲线所做的校正相同，只是当年只能在独占全屏下生效。benilla 改为对最终画面进行校正，因此在两种显示模式下都能使用。",
    ["Lock ActionBars"] = "锁定动作条",
    ["Master Volume"] = "主音量",
    ["Max Camera Distance"] = "最大镜头距离",
    ["Mouse Look Speed"] = "鼠标视角速度",
    ["Mouse Sensitivity"] = "鼠标灵敏度",
    ["Music Volume"] = "音乐音量",
    ["NPC Names"] = "NPC姓名",
    ["Nameplates"] = "姓名板",
    ["Never"] = "从不",
    ["No results found."] = "未找到结果。",
    ["Options"] = "选项",
    ["Party"] = "小队",
    ["Party or Raid"] = "小队或团队",
    ["Periodic Damage"] = "持续伤害",
    ["Pet Damage"] = "宠物伤害",
    ["Player Guild Names"] = "玩家公会名称",
    ["Player Names"] = "玩家姓名",
    ["Player Titles"] = "玩家头衔",
    ["Profanity Filter"] = "语言过滤器",
    ["Raid"] = "团队",
    ["Remove Chat Hover Delay"] = "移除聊天悬停延迟",
    ["Render Scale"] = "渲染缩放",
    ["Resolution"] = "分辨率",
    ["Scroll Down"] = "向下滚动",
    ["Scroll Up"] = "向上滚动",
    ["Search"] = "搜索",
    ["Search Results"] = "搜索结果",
    ["Show Auras"] = "显示光环",
    ["Show Chat Bubbles"] = "显示聊天气泡",
    ["Show Combat State"] = "显示战斗状态",
    ["Show Combo Points"] = "显示连击点",
    ["Show Damage Reduction"] = "显示伤害减免",
    ["Show Detailed Tooltips"] = "显示详细提示",
    ["Show Dodge/Parries/Misses"] = "显示闪躲/招架/未命中",
    ["Show Energy Gains"] = "显示能量获得",
    ["Show Fading Auras"] = "显示渐隐光环",
    ["Show Friendly Healer Names"] = "显示友方治疗者姓名",
    ["Show Honor Gained"] = "显示荣誉获得",
    ["Show Loading Screen Tips"] = "显示载入界面提示",
    ["Show Low Mana and Health"] = "显示低法力与低生命",
    ["Show Own Name"] = "显示自己的姓名",
    ["Show Party Chat Bubbles"] = "显示小队聊天气泡",
    ["Show Reactive Spells and Abilities"] = "显示可触发法术和技能",
    ["Show Reputation"] = "显示声望",
    ["Show Target Damage"] = "显示目标伤害",
    ["Show Target of Target"] = "显示目标的目标",
    ["Show When"] = "显示时机",
    ["Smart"] = "智能",
    ["Smart Pivot"] = "智能转向",
    ["Solo"] = "单人",
    ["Sound Volume"] = "音效音量",
    ["Status Bar Text"] = "状态栏文字",
    ["Sticky Targeting"] = "粘性目标",
    ["System"] = "系统",
    ["Terrain Distance"] = "地形距离",
    ["UI Scale"] = "界面缩放",
    ["Vertical Sync"] = "垂直同步",
    ["Water Collision"] = "水面碰撞",
    ["Weather Intensity"] = "天气强度",
    ["Windowed"] = "窗口",
    ["Windowed (Fullscreen)"] = "窗口（全屏）",
    ["Windowed (Fullscreen) fills the screen with a borderless window; Windowed runs in an ordinary one.\n\nThere is no exclusive fullscreen mode. WoW itself removed one in 8.0.1, and modern Classic offers these same two."] = "“窗口（全屏）”用无边窗口铺满屏幕；“窗口”则在普通窗口中运行。\n\n没有独占全屏模式。WoW 本身在 8.0.1 中移除了它，现代魔兽经典版也只提供这两种方式。",
    ["Show Bottom Left ActionBar"] = "显示左下方动作条",
    ["Show Bottom Right ActionBar"] = "显示右下方动作条",
    ["Show Right ActionBar"] = "显示右侧动作条",
    ["Show Right ActionBar 2"] = "显示右侧动作条 2",
    ["Show Cloak"] = "显示披风",
    ["Show Helm"] = "显示头盔",
    ["Enemy Name Plates"] = "敌方姓名板",
    ["Friendly Name Plates"] = "友方姓名板",
    ["Brightness"] = "亮度",
    ["Low"] = "低",
    ["Medium"] = "中",
    ["High"] = "高",
    ["Minimal"] = "最低",
    ["Full"] = "最高",
    ["Show Tutorials"] = "显示教程",
    ["Tip of the Day"] = "每日提示",
    ["Newbie Tips"] = "新手提示",
    ["Unbind Key"] = "取消绑定按键",
    ["Spell Detail"] = "法术细节",
    ["Click this to toggle between general key bindings and key bindings specific to this character."] = "点击此处在通用按键绑定和此角色的专用按键绑定之间切换。",
    ["yards"] = "码",
}

local function TranslateOptions(frame)
    if frame.GetText and frame.SetText then
        local text = frame:GetText()
        local translated = text and BENILLA_OPTIONS_ZHCN[text]
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
                local translated = text and BENILLA_OPTIONS_ZHCN[text]
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

if VanillaBonkLocale.language == "zhCN" then
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
            text = BENILLA_OPTIONS_ZHCN[text] or text
        end
        return originalSetText(tooltip, text, red, green, blue, wrap)
    end

    if UIDropDownMenu_AddButton then
    local originalAddButton = UIDropDownMenu_AddButton
    UIDropDownMenu_AddButton = function(info, level)
        if type(info) == "table" and type(info.text) == "string" then
            info.text = BENILLA_OPTIONS_ZHCN[info.text] or info.text
        end
        return originalAddButton(info, level)
    end
    end
end
