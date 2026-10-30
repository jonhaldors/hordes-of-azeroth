local L = VanillaBonkL
local UI = VanillaBonkUI
local Controller = VanillaBonkController

local PANEL_WIDTH = 820
local PANEL_HEIGHT = 646
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
local ART = {
    xbox = { file = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ControllerXbox", height = 329 },
    ps = { file = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ControllerPlayStation", height = 331 },
}
ART.deck = ART.xbox
local KIND_NAMES = { xbox = L["Xbox controller connected"], ps = L["PlayStation controller connected"], deck = L["Steam Deck controls connected"] }
local LEFT_LABELS = {
    { "lt", L["Zoom"], L["Hold with right stick or d-pad"] },
    { "lb", L["Shapeshift"], L["Druid forms"], "shapeshift" },
    { "ls", L["Move"], L["Full 360 degrees"] },
    { "view", L["Run map"], nil, "map" },
    { "dpad", L["Menus and cards"], L["Move the focus"] },
}
local RIGHT_LABELS = {
    { "rt", L["Dash"], L["Dash where you are moving"], "dash" },
    { "rb", L["Hearthstone"], nil, "hearth" },
    { "y", L["Character and bags"], nil, "character" },
    { "x", L["Interact"], L["Talk, open, use"], "interact" },
    { "b", L["Close or cancel"] },
    { "a", L["Jump"] },
    { "rs", L["Camera"], L["Press to recenter"] },
    { "menu", L["Pause menu"] },
}
local PROMPT_CHOICES = { { "auto", L["Automatic"] }, { "xbox", "Xbox" }, { "ps", "PlayStation" }, { "deck", "Steam Deck" } }

local panel = UI.Window("VanillaBonkControllerPanel", PANEL_WIDTH, PANEL_HEIGHT)
panel:SetPoint("CENTER", UIParent, "CENTER", 0, 10)
panel.title:SetText(L["Controller"])
panel.ART = ART
panel.controls = {}
panel.labels = {}

panel.status = UI.Text(panel, 12)
panel.status:SetPoint("TOP", panel, "TOP", 0, -44)
panel.status:SetTextColor(0.78, 0.75, 0.66)
panel.hint = UI.Text(panel, 10)
panel.hint:SetPoint("TOP", panel.status, "BOTTOM", 0, -4)
panel.hint:SetTextColor(0.66, 0.63, 0.56)
panel.hint:SetText("Select a highlighted action, then press the button you want for it")

panel.art = panel:CreateTexture(nil, "ARTWORK")
panel.art:SetPoint("TOP", panel, "TOP", 0, ART_TOP)
panel.art:SetWidth(ART_WIDTH)

local function ArtHeight(style)
    return ART_WIDTH * ART[style].height / 512
end

local LISTEN_TEXT = "Press a button"
local LISTEN_HELP = "B cancels"

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
            panel:Listen(this)
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
panel.section:SetText(L["Settings"])
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
    return name
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
        if not panel.loading then
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
            panel:Refresh()
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
leftY = leftY - SliderRow(COLUMN_LEFT, leftY, "yawSpeed", L["Camera turn speed"], L["How fast the right stick turns the camera"], 0.5, 2, 0.05, L["Slow"], L["Fast"], Percent)
leftY = leftY - SliderRow(COLUMN_LEFT, leftY, "pitchSpeed", L["Camera up and down speed"], L["Right stick up and down"], 0.5, 2, 0.05, L["Slow"], L["Fast"], Percent)
leftY = leftY - CheckRow(COLUMN_LEFT, leftY, "invertPitch", L["Invert camera up and down"], L["Push up to look down"])
SliderRow(COLUMN_LEFT, leftY, "deadzone", L["Stick deadzone"], L["Raise it if your hero drifts on its own"], 0.1, 0.4, 0.01, L["Small"], L["Large"], Percent)

local rightY = SETTINGS_TOP - 24
rightY = rightY - SliderRow(COLUMN_RIGHT, rightY, "cursorSpeed", L["Cursor speed"], L["Right stick cursor in Blizzard windows"], 0.5, 2, 0.05, L["Slow"], L["Fast"], Percent)
rightY = rightY - ChoiceRow(COLUMN_RIGHT, rightY, "prompts", L["Button prompts"], L["Automatic follows the controller you pick up"], PROMPT_CHOICES)
CheckRow(COLUMN_RIGHT, rightY, "interactPrompts", L["Show interact prompts"], L["\"X Talk\" above NPCs, chests and portals"])

panel.reset = UI.Button(panel, 150, L["Reset to defaults"], function()
    panel:StopListening()
    Controller.ResetSettings()
    panel:Refresh()
end)
panel.reset:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", COLUMN_LEFT, 22)
panel.done = UI.Button(panel, 120, L["Done"], function()
    panel:Hide()
end)
panel.done:SetPoint("BOTTOMRIGHT", panel, "BOTTOMRIGHT", -COLUMN_LEFT, 22)

local function StatusText()
    local connected = HoAController_GetConnected and HoAController_GetConnected()
    local text = connected and ("|cff40d040" .. KIND_NAMES[connected] .. "|r") or L["No controller connected"]
    if Controller.Setting("prompts") == "auto" then
        text = text .. L["  |cff9d9d9d·|r  prompts follow your last input"]
    end
    return text
end

function panel:Refresh()
    local style = Controller.Style()
    self.loading = true
    for _, control in ipairs(self.controls) do
        control:Load()
    end
    self.loading = nil
    self.art:SetTexture(ART[style].file)
    self.art:SetTexCoord(0, 1, 0, ART[style].height / 512)
    self.art:SetHeight(ArtHeight(style))
    PlaceLabels(style)
    for _, label in pairs(self.labels) do
        FillLabel(label, label.entry)
        Controller.SetGlyph(label.glyph, label.action and Controller.ButtonFor(label.action) or label.button)
    end
    self.status:SetText(StatusText())
    self.style = style
    self:ShowListening()
end

function panel:StopListening()
    Controller.listening = nil
    self.listeningTo = nil
end

function panel:ShowListening()
    local label = self.listeningTo
    if not label then
        return
    end
    local entry = label.entry
    FillLabel(label, { entry[1], LISTEN_TEXT, LISTEN_HELP, entry[4] })
    label.entry = entry
end

function panel:Listen(label)
    self:StopListening()
    self:Refresh()
    self.listeningTo = label
    self:ShowListening()
    Controller.listening = function(name)
        if name ~= "b" and not Controller.REBINDABLE[name] then
            return
        end
        if name ~= "b" then
            Controller.BindButton(label.action, name)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        panel:StopListening()
        panel:Refresh()
    end
end

panel:SetScript("OnShow", function()
    SetPortraitTexture(this.portrait, "player")
    this:Refresh()
    this.statusAt = 0
end)
panel:SetScript("OnUpdate", function()
    this.statusAt = (this.statusAt or 0) + arg1
    if this.statusAt < STATUS_INTERVAL then
        return
    end
    this.statusAt = 0
    if Controller.Style() ~= this.style then
        this:Refresh()
    else
        this.status:SetText(StatusText())
    end
end)

local BasePanelHide = panel:GetScript("OnHide")
panel:SetScript("OnHide", function()
    this:StopListening()
    this.asBindings = nil
    if BasePanelHide then
        BasePanelHide()
    end
end)
