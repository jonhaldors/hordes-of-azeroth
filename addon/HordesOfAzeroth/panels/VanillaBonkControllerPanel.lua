local L = VanillaBonkL
local UI = VanillaBonkUI
local Controller = VanillaBonkController

local PANEL_WIDTH = 820
local PANEL_HEIGHT = 696
local ART_WIDTH = 320
local ART_TOP = -92
local LABEL_ROW = 34
local LABEL_PAD = 0.03
local LABEL_WIDTH = 190
local GLYPH_SIZE = 24
local CHOICE_WIDTH = 84
local CHOICE_GAP = 4
local COLUMN_LEFT = 34
local COLUMN_RIGHT = 434
local SLIDER_WIDTH = 270
local STATUS_INTERVAL = 0.5
local CARD_BUTTON_WIDTH = 104
local CARD_ACTIONS = { { "reroll", L["hoa.addon.reroll"] }, { "banish", L["hoa.addon.banish"] }, { "skip", L["hoa.addon.skip"] } }
local CARD_HINT_TEXT = L["hoa.addon.level_up_and_chest_cards"]
local CARD_CANCEL_TEXT = L["hoa.addon.press_menu_to_cancel"]
local ART = {
    xbox = { file = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ControllerXbox", height = 329 },
    ps = { file = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ControllerPlayStation", height = 331 },
}
ART.deck = ART.xbox
local KIND_NAMES = { xbox = L["hoa.addon.xbox_controller_connected"], ps = L["hoa.addon.playstation_controller_connected"], deck = L["hoa.addon.steam_deck_controls_connected"] }
local LEFT_LABELS = {
    { "lt", L["hoa.addon.zoom"], L["hoa.addon.hold_then_use_right_stick_or_d_pad"] },
    { "lb", L["hoa.addon.shapeshift"], L["hoa.addon.druid_forms"], "shapeshift" },
    { "ls", L["hoa.addon.move"], L["hoa.addon.move_in_any_direction"] },
    { "view", L["hoa.addon.run_map"], nil, "map" },
    { "dpad", L["hoa.addon.menus_and_cards"], L["hoa.addon.move_selection"] },
}
local RIGHT_LABELS = {
    { "rt", L["hoa.addon.dash"], L["hoa.addon.dash_in_your_movement_direction"], "dash" },
    { "rb", L["hoa.addon.hearthstone"], nil, "hearth" },
    { "y", L["hoa.addon.character_and_bags"], nil, "character" },
    { "x", L["hoa.addon.interact"], L["hoa.addon.talk_open_use"], "interact" },
    { "b", L["hoa.addon.close_or_cancel"] },
    { "a", L["hoa.addon.jump"] },
    { "rs", L["hoa.addon.camera"], L["hoa.addon.press_to_recenter"] },
    { "menu", L["hoa.addon.pause_menu"] },
}
local PROMPT_CHOICES = { { "auto", L["hoa.addon.automatic"] }, { "xbox", "Xbox" }, { "ps", "PlayStation" }, { "deck", "Steam Deck" } }

local panel = UI.Window("VanillaBonkControllerPanel", PANEL_WIDTH, PANEL_HEIGHT)
Controller.panel = panel
panel.controller = Controller
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
panel.title:SetText(L["hoa.addon.controller"])
panel.ART = ART
Controller.panelControls = {}
Controller.panelLabels = {}
panel.controls = Controller.panelControls
panel.labels = Controller.panelLabels

panel.status = UI.Text(panel, 12)
panel.status:SetPoint("TOP", panel, "TOP", 0, -44)
panel.status:SetTextColor(0.78, 0.75, 0.66)
panel.hint = UI.Text(panel, 10)
panel.hint:SetPoint("TOP", panel.status, "BOTTOM", 0, -4)
panel.hint:SetTextColor(0.66, 0.63, 0.56)
panel.hint:SetText(L["hoa.addon.select_an_action_then_press_a_button_to_bind_it"])

panel.art = panel:CreateTexture(nil, "ARTWORK")
panel.art:SetPoint("TOP", panel, "TOP", 0, ART_TOP)
panel.art:SetWidth(ART_WIDTH)

local function ArtHeight(style)
    return ART_WIDTH * ART[style].height / 512
end

local LISTEN_TEXT = L["hoa.addon.press_a_button"]
local LISTEN_HELP = L["hoa.addon.b_cancels"]

local function MakeLabel(rightSide, rebindable)
    local label = CreateFrame(rebindable and "Button" or "Frame", nil, panel)
    label.rightSide = rightSide
    label:SetWidth(LABEL_WIDTH)
    label:SetHeight(GLYPH_SIZE)
    label.glyph = label:CreateTexture(nil, "ARTWORK")
    label.glyph:SetWidth(GLYPH_SIZE)
    label.glyph:SetHeight(GLYPH_SIZE)
    label.title = UI.Text(label, 13)
    label.title:SetTextColor(1, 0.82, 0)
    label.help = UI.Text(label, 10)
    label.help:SetTextColor(0.72, 0.69, 0.63)
    if rightSide then
        label.glyph:SetPoint("RIGHT", label, "RIGHT", 0, 0)
        label.title:SetJustifyH("RIGHT")
        label.help:SetPoint("TOPRIGHT", label.title, "BOTTOMRIGHT", 0, -1)
        label.help:SetJustifyH("RIGHT")
    else
        label.glyph:SetPoint("LEFT", label, "LEFT", 0, 0)
        label.help:SetPoint("TOPLEFT", label.title, "BOTTOMLEFT", 0, -1)
    end
    if rebindable then
        label:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
        label:GetHighlightTexture():SetBlendMode("ADD")
        label:SetScript("OnClick", function()
            Controller:ListenPanel(this)
        end)
    end
    return label
end

local function FillLabel(label, entry)
    label.entry = entry
    label.button = entry[1]
    label.action = entry[4]
    label.title:SetText(entry[2])
    label.help:SetText(entry[3] or "")
    label.title:ClearAllPoints()
    local rightSide = label.rightSide
    if entry[3] then
        label.title:SetPoint(rightSide and "BOTTOMRIGHT" or "BOTTOMLEFT", label.glyph, rightSide and "LEFT" or "RIGHT", rightSide and -6 or 6, -1)
    else
        label.title:SetPoint(rightSide and "RIGHT" or "LEFT", label.glyph, rightSide and "LEFT" or "RIGHT", rightSide and -6 or 6, 0)
    end
end

local function LabelTop(index, count, height)
    local span = height * (1 - 2 * LABEL_PAD) - LABEL_ROW
    return ART_TOP - height * LABEL_PAD - (index - 1) * span / math.max(1, count - 1)
end

local function PlaceLabels(style)
    local height = ArtHeight(style)
    local artLeft = -ART_WIDTH / 2
    for index, entry in ipairs(LEFT_LABELS) do
        local label = panel.labels["left" .. index]
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", panel, "TOP", artLeft + ART_WIDTH * 0.13 - LABEL_WIDTH, LabelTop(index, table.getn(LEFT_LABELS), height))
    end
    for index, entry in ipairs(RIGHT_LABELS) do
        local label = panel.labels["right" .. index]
        label:ClearAllPoints()
        label:SetPoint("TOPLEFT", panel, "TOP", artLeft + ART_WIDTH * 0.87, LabelTop(index, table.getn(RIGHT_LABELS), height))
    end
end

for index, entry in ipairs(LEFT_LABELS) do
    local label = MakeLabel(false, entry[4] ~= nil)
    FillLabel(label, entry)
    panel.labels["left" .. index] = label
end
for index, entry in ipairs(RIGHT_LABELS) do
    local label = MakeLabel(true, entry[4] ~= nil)
    FillLabel(label, entry)
    panel.labels["right" .. index] = label
end

local SETTINGS_TOP = ART_TOP - ArtHeight("xbox") - 18

panel.section = UI.Text(panel, 13)
panel.section:SetPoint("TOPLEFT", panel, "TOPLEFT", COLUMN_LEFT, SETTINGS_TOP)
panel.section:SetTextColor(1, 0.82, 0)
panel.section:SetText(L["hoa.addon.settings"])
panel.rule = panel:CreateTexture(nil, "ARTWORK")
panel.rule:SetTexture(UI.FLAT)
panel.rule:SetVertexColor(1, 0.82, 0, 0.35)
panel.rule:SetHeight(1)
panel.rule:SetPoint("TOPLEFT", panel.section, "BOTTOMLEFT", 0, -3)
panel.rule:SetPoint("RIGHT", panel, "RIGHT", -COLUMN_LEFT, 0)

local function Heading(x, y, title, help)
    local name = UI.Text(panel, 12)
    name:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    name:SetText(title)
    local hint = UI.Text(panel, 10)
    hint:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -2)
    hint:SetTextColor(0.66, 0.63, 0.56)
    hint:SetText(help)
    return name, hint
end

local function Percent(value)
    return format("%d%%", math.floor(value * 100 + 0.5))
end

local function SliderRow(x, y, key, title, help, low, high, step, lowText, highText, shown)
    Heading(x, y, title, help)
    local name = "VanillaBonkControllerPanel" .. key
    local slider = CreateFrame("Slider", name, panel, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y - 34)
    slider:SetWidth(SLIDER_WIDTH)
    slider:SetMinMaxValues(low, high)
    slider:SetValueStep(step)
    getglobal(name .. "Text"):SetText("")
    getglobal(name .. "Low"):SetText(lowText)
    getglobal(name .. "High"):SetText(highText)
    slider.value = UI.Text(panel, 12)
    slider.value:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    slider.value:SetTextColor(1, 0.82, 0)
    slider.key = key
    slider.shown = shown
    slider:SetScript("OnValueChanged", function()
        this.value:SetText(this.shown(this:GetValue()))
        if not Controller.panelLoading then
            Controller.SetSetting(this.key, this:GetValue())
        end
    end)
    slider.Load = function(self)
        self:SetValue(Controller.Setting(self.key))
        self.value:SetText(self.shown(self:GetValue()))
    end
    table.insert(panel.controls, slider)
    return 64
end

local function CheckRow(x, y, key, title, help)
    local name = "VanillaBonkControllerPanel" .. key
    local check = CreateFrame("CheckButton", name, panel, "OptionsCheckButtonTemplate")
    check:SetWidth(26)
    check:SetHeight(26)
    check:SetPoint("TOPLEFT", panel, "TOPLEFT", x - 4, y + 4)
    getglobal(name .. "Text"):SetText("")
    Heading(x + 26, y, title, help)
    check.key = key
    check:SetScript("OnClick", function()
        Controller.SetSetting(this.key, this:GetChecked() == 1)
    end)
    check.Load = function(self)
        self:SetChecked(Controller.Setting(self.key) and 1 or nil)
    end
    table.insert(panel.controls, check)
    return 44
end

local function ChoiceRow(x, y, key, title, help, choices)
    Heading(x, y, title, help)
    local row = { key = key, buttons = {} }
    local left = x
    for _, choice in ipairs(choices) do
        local button = UI.Button(panel, CHOICE_WIDTH, choice[2])
        button:SetPoint("TOPLEFT", panel, "TOPLEFT", left, y - 30)
        button.value = choice[1]
        button:SetScript("OnClick", function()
            Controller.SetSetting(key, this.value)
            Controller:RefreshPanel()
        end)
        table.insert(row.buttons, button)
        left = left + CHOICE_WIDTH + CHOICE_GAP
    end
    row.Load = function(self)
        local current = Controller.Setting(self.key)
        for _, button in ipairs(self.buttons) do
            if button.value == current then
                button:LockHighlight()
                button:SetTextColor(1, 1, 1)
            else
                button:UnlockHighlight()
                button:SetTextColor(1, 0.82, 0)
            end
        end
    end
    table.insert(panel.controls, row)
    return 64
end

local leftY = SETTINGS_TOP - 24
leftY = leftY - SliderRow(COLUMN_LEFT, leftY, "yawSpeed", L["hoa.addon.camera_turn_speed"], L["hoa.addon.how_fast_the_right_stick_turns_the_camera"], 0.5, 2, 0.05, L["hoa.addon.slow"], L["hoa.addon.fast"], Percent)
leftY = leftY - SliderRow(COLUMN_LEFT, leftY, "pitchSpeed", L["hoa.addon.camera_pitch_speed"], L["hoa.addon.right_stick_up_and_down"], 0.5, 2, 0.05, L["hoa.addon.slow"], L["hoa.addon.fast"], Percent)
leftY = leftY - CheckRow(COLUMN_LEFT, leftY, "invertPitch", L["hoa.addon.invert_camera_pitch"], L["hoa.addon.push_up_to_look_down"])
SliderRow(COLUMN_LEFT, leftY, "deadzone", L["hoa.addon.stick_deadzone"], L["hoa.addon.raise_this_if_your_character_moves_on_its_own"], 0.1, 0.4, 0.01, L["hoa.addon.small"], L["hoa.addon.large"], Percent)

local function CardButton(x, y, action, title)
    local button = CreateFrame("Button", nil, panel)
    button:SetPoint("TOPLEFT", panel, "TOPLEFT", x, y)
    button:SetWidth(CARD_BUTTON_WIDTH)
    button:SetHeight(GLYPH_SIZE)
    button.action = action
    button.text = title
    button.glyph = button:CreateTexture(nil, "ARTWORK")
    button.glyph:SetWidth(GLYPH_SIZE)
    button.glyph:SetHeight(GLYPH_SIZE)
    button.glyph:SetPoint("LEFT", button, "LEFT", 0, 0)
    button.title = UI.Text(button, 12)
    button.title:SetTextColor(1, 0.82, 0)
    button.title:SetPoint("LEFT", button.glyph, "RIGHT", 5, 0)
    button:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight")
    button:GetHighlightTexture():SetBlendMode("ADD")
    button:SetScript("OnClick", function()
        Controller:ListenPanelCard(this)
    end)
    button.Load = function(self)
        Controller.SetGlyph(self.glyph, Controller.CardButtonFor(self.action))
        self.title:SetText(self.text)
        if Controller.panelListeningTo == self then
            self.title:SetTextColor(1, 1, 1)
            self:LockHighlight()
            panel.cardHint:SetText(L("hoa.addon.press_a_button_for_1", self.text) .. " " .. CARD_CANCEL_TEXT)
        else
            self.title:SetTextColor(1, 0.82, 0)
            self:UnlockHighlight()
        end
    end
    table.insert(panel.controls, button)
end

local function CardRow(x, y)
    local _, hint = Heading(x, y, L["hoa.addon.card_buttons"], CARD_HINT_TEXT)
    panel.cardHint = hint
    hint.Load = function(self)
        self:SetText(CARD_HINT_TEXT)
    end
    table.insert(panel.controls, 1, hint)
    for index, entry in ipairs(CARD_ACTIONS) do
        CardButton(x + (index - 1) * (CARD_BUTTON_WIDTH + CHOICE_GAP), y - 32, entry[1], entry[2])
    end
    return 64
end

local rightY = SETTINGS_TOP - 24
rightY = rightY - SliderRow(COLUMN_RIGHT, rightY, "cursorSpeed", L["hoa.addon.cursor_speed"], L["hoa.addon.how_fast_the_right_stick_moves_the_cursor_in_menus"], 0.5, 2, 0.05, L["hoa.addon.slow"], L["hoa.addon.fast"], Percent)
rightY = rightY - ChoiceRow(COLUMN_RIGHT, rightY, "prompts", L["hoa.addon.button_prompts"], L["hoa.addon.automatic_matches_the_controller_you_re_using"], PROMPT_CHOICES)
rightY = rightY - CheckRow(COLUMN_RIGHT, rightY, "interactPrompts", L["hoa.addon.interact_prompts"], L["hoa.addon.x_talk_above_npcs_chests_and_portals"])
CardRow(COLUMN_RIGHT, rightY)

panel.reset = UI.Button(panel, 150, L["hoa.addon.defaults"], function()
    Controller:StopPanelListening()
    Controller.ResetSettings()
    Controller:RefreshPanel()
end)
panel.reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", COLUMN_LEFT, 22)
panel.done = UI.Button(panel, 120, L["hoa.addon.done"], function()
    panel:Hide()
end)
panel.done:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -COLUMN_LEFT, 22)

local function StatusText()
    local connected = HoAController_GetConnected and HoAController_GetConnected()
    local text = connected and ("|cff40d040" .. KIND_NAMES[connected] .. "|r") or L["hoa.addon.no_controller_connected"]
    if Controller.Setting("prompts") == "auto" then
        text = L("hoa.addon.1_cff9d9d9d_r_prompts_follow_your_last_input", text)
    end
    return text
end

function Controller:RefreshPanel()
    local panel = self.panel
    local style = Controller.Style()
    self.panelLoading = true
    for _, control in ipairs(self.panelControls) do
        control:Load()
    end
    self.panelLoading = nil
    panel.art:SetTexture(ART[style].file)
    panel.art:SetTexCoord(0, 1, 0, ART[style].height / 512)
    panel.art:SetHeight(ArtHeight(style))
    PlaceLabels(style)
    for _, label in pairs(self.panelLabels) do
        FillLabel(label, label.entry)
        Controller.SetGlyph(label.glyph, label.action and Controller.ButtonFor(label.action) or label.button)
    end
    panel.status:SetText(StatusText())
    self.panelStyle = style
    self:ShowPanelListening()
end

function Controller:StopPanelListening()
    Controller.listening = nil
    self.panelListeningTo = nil
end

function Controller:ShowPanelListening()
    local label = self.panelListeningTo
    if not label or not label.entry then
        return
    end
    local entry = label.entry
    FillLabel(label, { entry[1], LISTEN_TEXT, LISTEN_HELP, entry[4] })
    label.entry = entry
end

function Controller:ListenPanel(label)
    self:StopPanelListening()
    self:RefreshPanel()
    self.panelListeningTo = label
    self:ShowPanelListening()
    Controller.listening = function(name)
        if name ~= "b" and not Controller.REBINDABLE[name] then
            return
        end
        if name ~= "b" then
            Controller.BindButton(label.action, name)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        Controller:StopPanelListening()
        Controller:RefreshPanel()
    end
end

function Controller:ListenPanelCard(button)
    self:StopPanelListening()
    self.panelListeningTo = button
    self:RefreshPanel()
    Controller.listening = function(name)
        if name ~= "menu" and not Controller.CARD_REBINDABLE[name] then
            return
        end
        if name ~= "menu" then
            Controller.BindCardButton(button.action, name)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        Controller:StopPanelListening()
        Controller:RefreshPanel()
    end
end

function panel:Refresh()
    return Controller:RefreshPanel()
end

function panel:StopListening()
    return Controller:StopPanelListening()
end

function panel:ShowListening()
    return Controller:ShowPanelListening()
end

function panel:Listen(label)
    return Controller:ListenPanel(label)
end

function panel:ListenCard(button)
    return Controller:ListenPanelCard(button)
end

panel:SetScript("OnShow", function()
    SetPortraitTexture(this.portrait, "player")
    Controller:RefreshPanel()
    Controller.panelStatusAt = 0
end)
panel:SetScript("OnUpdate", function()
    Controller.panelStatusAt = (Controller.panelStatusAt or 0) + arg1
    if Controller.panelStatusAt < STATUS_INTERVAL then
        return
    end
    Controller.panelStatusAt = 0
    if Controller.Style() ~= Controller.panelStyle then
        Controller:RefreshPanel()
    else
        panel.status:SetText(StatusText())
    end
end)

local BasePanelHide = panel:GetScript("OnHide")
panel:SetScript("OnHide", function()
    Controller:StopPanelListening()
    Controller.panelAsBindings = nil
    if BasePanelHide then
        BasePanelHide()
    end
end)
