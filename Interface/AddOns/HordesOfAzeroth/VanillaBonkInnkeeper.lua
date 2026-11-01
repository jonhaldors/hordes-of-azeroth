local L = VanillaBonkL
local UI = VanillaBonkUI

local WIDTH = 420
local LEFT = 26
local RIGHT = 36
local CONTENT_WIDTH = WIDTH - LEFT - RIGHT
local COLUMN = CONTENT_WIDTH / 2
local ROW = 24
local SECTION_GAP = 14
local KEY_BUTTON_WIDTH = 74
local PAD_GLYPH_SIZE = 24
local PAD_ACTIONS = {
    VANILLABONK_INTERACT = "interact",
    VANILLABONK_HEARTH = "hearth",
    VANILLABONK_DASH = "dash",
    VANILLABONK_SHAPESHIFT = "shapeshift",
}
local GREETING = L["Make yourself at home, friend. Tell old Tarn how you like things, and the Inn will keep it that way."]

local window = UI.Window("VanillaBonkInnkeeper", WIDTH, 600)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
window.title:SetText(UI.INNKEEPER_NAME)
window.checks = {}
window.sliders = {}
window.radios = {}
window.keys = {}

local LISTEN_TEXT = L["Press a button"]

local function PadAction(row)
    local controller = VanillaBonkController
    if not (controller and controller.kind) then
        return nil
    end
    return PAD_ACTIONS[row.binding.command]
end

local function StopPadListen()
    if not window.listeningRow then
        return
    end
    window.listeningRow = nil
    VanillaBonkController.listening = nil
    window.Refresh()
end

local function ListenForPadButton(row, action)
    local controller = VanillaBonkController
    window.listeningRow = row
    controller.listening = function(name)
        if name ~= "b" and not controller.REBINDABLE[name] then
            return
        end
        if name ~= "b" then
            controller.BindButton(action, name)
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        StopPadListen()
    end
    window.Refresh()
end

local function ChangeKey(row)
    local action = PadAction(row)
    if action then
        ListenForPadButton(row, action)
    else
        UI.CaptureKey(row.binding)
    end
end

window.greeting = UI.Text(window, 12)
window.greeting:SetWidth(CONTENT_WIDTH)
window.greeting:SetJustifyH("LEFT")
window.greeting:SetTextColor(0.91, 0.86, 0.75)
window.greeting:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -84)
window.greeting:SetText(GREETING)

local cursor = 0

local function Section(title)
    local header = UI.Text(window, 13)
    header:SetTextColor(1, 0.82, 0)
    header:SetPoint("TOPLEFT", window.greeting, "BOTTOMLEFT", 0, -cursor - SECTION_GAP)
    header:SetText(title)
    local line = window:CreateTexture(nil, "ARTWORK")
    line:SetTexture(1, 0.82, 0, 0.35)
    line:SetHeight(1)
    line:SetWidth(CONTENT_WIDTH)
    line:SetPoint("TOPLEFT", header, "BOTTOMLEFT", 0, -3)
    cursor = cursor + SECTION_GAP + 20
end

local function Place(widget, column, height)
    widget:SetPoint("TOPLEFT", window.greeting, "BOTTOMLEFT", (column - 1) * COLUMN, -cursor)
    if height then
        cursor = cursor + height
    end
end

local function Check(setting, column, advance)
    local check = CreateFrame("CheckButton", "VanillaBonkInnkeeperCheck" .. setting.key, window, "UICheckButtonTemplate")
    check:SetWidth(24)
    check:SetHeight(24)
    check.setting = setting
    local label = getglobal(check:GetName() .. "Text")
    label:SetFontObject(GameFontHighlightSmall)
    label:SetText(setting.label)
    check:SetScript("OnClick", function()
        PlaySound(this:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
        UI.ChangeSetting(this.setting, this:GetChecked() and true or false)
    end)
    check:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.setting.tooltip, 1, 1, 1, 1, 1)
    end)
    check:SetScript("OnLeave", function() GameTooltip:Hide() end)
    Place(check, column, advance and ROW)
    tinsert(window.checks, check)
    return check
end

local function SettingSlider(setting)
    local slider = CreateFrame("Slider", "VanillaBonkInnkeeperSlider" .. setting.key, window, "OptionsSliderTemplate")
    slider:SetWidth(CONTENT_WIDTH - 70)
    slider:SetMinMaxValues(0, 100)
    slider:SetValueStep(10)
    slider.setting = setting
    getglobal(slider:GetName() .. "Text"):SetText(setting.label)
    getglobal(slider:GetName() .. "Low"):SetText(L["Off"])
    getglobal(slider:GetName() .. "High"):SetText(L["All"])
    slider.value = UI.Text(slider, 11)
    slider.value:SetPoint("LEFT", slider, "RIGHT", 10, 0)
    slider:SetScript("OnValueChanged", function()
        this.value:SetText(UI.OtherEffectsText(this:GetValue()))
    end)
    slider:SetScript("OnMouseUp", function()
        local value = math.floor(this:GetValue() + 0.5)
        if value ~= UI.SettingValue(this.setting) then
            PlaySound("igMainMenuOptionCheckBoxOn")
            UI.ChangeSetting(this.setting, value)
        end
    end)
    slider:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        GameTooltip:SetText(this.setting.tooltip, 1, 1, 1, 1, 1)
    end)
    slider:SetScript("OnLeave", function() GameTooltip:Hide() end)
    cursor = cursor + 18
    slider:SetPoint("TOPLEFT", window.greeting, "BOTTOMLEFT", 8, -cursor)
    cursor = cursor + 34
    tinsert(window.sliders, slider)
    return slider
end

local function KeyRow(binding, label)
    local row = CreateFrame("Frame", nil, window)
    row:SetWidth(CONTENT_WIDTH)
    row:SetHeight(26)
    row.binding = binding
    row.label = UI.Text(row, 12)
    row.label:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.label:SetText(label or binding.label)
    row.change = UI.Button(row, KEY_BUTTON_WIDTH, L["Change"], function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        ChangeKey(this:GetParent())
    end)
    row.change:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.cap = UI.KeyCap(row)
    row.cap:SetPoint("RIGHT", row.change, "LEFT", -8, 0)
    row.glyph = row:CreateTexture(nil, "ARTWORK")
    row.glyph:SetWidth(PAD_GLYPH_SIZE)
    row.glyph:SetHeight(PAD_GLYPH_SIZE)
    row.glyph:SetPoint("RIGHT", row.change, "LEFT", -8, 0)
    row.glyph:Hide()
    row.listen = UI.Text(row, 11)
    row.listen:SetTextColor(1, 0.82, 0)
    row.listen:SetPoint("RIGHT", row.change, "LEFT", -8, 0)
    row.listen:SetText(LISTEN_TEXT)
    row.listen:Hide()
    Place(row, 1, 30)
    tinsert(window.keys, row)
    return row
end

local function Note(text)
    local note = UI.Text(window, 11)
    note:SetTextColor(0.72, 0.69, 0.63)
    note:SetText(text)
    Place(note, 1, 16)
    return note
end

local function HealthBarChoice(mode, column)
    local radio = CreateFrame("CheckButton", "VanillaBonkInnkeeperHealth" .. mode.value, window, "UIRadioButtonTemplate")
    radio.mode = mode.value
    radio.label = UI.Text(radio, 11)
    radio.label:SetPoint("LEFT", radio, "RIGHT", 2, 0)
    radio.label:SetText(mode.label)
    radio:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        UI.ChangeHealthBar(this.mode)
    end)
    radio:SetPoint("TOPLEFT", window.greeting, "BOTTOMLEFT", 4 + (column - 1) * (CONTENT_WIDTH / 3), -cursor - 4)
    tinsert(window.radios, radio)
end

Section(L["Interact key"])
KeyRow(UI.KEYS[1], L["Interact with what's nearby"])
Note(L["The key interacts with:"])
for index, setting in ipairs(UI.INTERACT_SETTINGS) do
    Check(setting, math.mod(index - 1, 2) + 1, math.mod(index, 2) == 0 or index == table.getn(UI.INTERACT_SETTINGS))
end
cursor = cursor + 4
Check(UI.AUTO_CHEST_SETTING, 1, true)

Section(L["Your character"])
Note(L["Your health bar:"])
for index, mode in ipairs(UI.HEALTH_BAR_MODES) do
    HealthBarChoice(mode, index)
end
cursor = cursor + ROW + 6
for index, setting in ipairs(UI.DISPLAY_SETTINGS) do
    Check(setting, math.mod(index - 1, 2) + 1, math.mod(index, 2) == 0 or index == table.getn(UI.DISPLAY_SETTINGS))
end
SettingSlider(UI.OTHER_EFFECTS_SETTING)

Section(L["Keys"])
KeyRow(UI.KEYS[2])
KeyRow(UI.KEYS[3])
KeyRow(UI.KEYS[4])

window.settings = UI.Button(window, 150, L["All Game Settings"], function()
    PlaySound("igMainMenuOption")
    window:Hide()
    ShowUIPanel(UIOptionsFrame)
end)
window.goodbye = UI.Button(window, 100, L["Goodbye"], function() window:Hide() end)

local footerTop = 84 + window.greeting:GetHeight() + cursor + 18
window.settings:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -footerTop)
window.goodbye:SetPoint("TOPRIGHT", window, "TOPRIGHT", -RIGHT, -footerTop)
UI.SetWindowSize(window, WIDTH, footerTop + 22 + 24)

local function ShowPadButton(row)
    local controller = VanillaBonkController
    local action = PadAction(row)
    if not action then
        return false
    end
    return controller.SetGlyph(row.glyph, controller.ButtonFor(action))
end

local function RefreshKeyRow(row)
    row.change:Show()
    if window.listeningRow == row then
        row.glyph:Hide()
        row.cap:Hide()
        row.listen:Show()
        return
    end
    row.listen:Hide()
    if ShowPadButton(row) then
        row.cap:Hide()
        return
    end
    row.glyph:Hide()
    row.cap:Show()
    UI.SetKeyCap(row.cap, UI.KeyText(row.binding))
end

local function Refresh()
    if not window:IsShown() then
        return
    end
    for _, check in ipairs(window.checks) do
        check:SetChecked(UI.SettingValue(check.setting))
    end
    for _, slider in ipairs(window.sliders) do
        slider:SetValue(UI.SettingValue(slider.setting))
    end
    local mode = UI.HealthBarMode()
    for _, radio in ipairs(window.radios) do
        radio:SetChecked(radio.mode == mode)
    end
    for _, row in ipairs(window.keys) do
        RefreshKeyRow(row)
    end
end

window.Refresh = Refresh
UI.WatchSettings(Refresh)
window:RegisterEvent("UPDATE_BINDINGS")
window:SetScript("OnEvent", Refresh)

window:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    UI.SetPortrait(this)
    Refresh()
end)

window:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    StopPadListen()
    if this.fromGossip then
        this.fromGossip = nil
        if not this.gossipClosed then
            CloseGossip()
        end
    end
    this.gossipClosed = nil
end)

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and UI.TalkingTo(UI.INNKEEPER_NAME) then
        window.fromGossip = true
        window:Show()
        Refresh()
        return
    elseif event == "GOSSIP_CLOSED" and window.fromGossip and window:IsShown() then
        window.gossipClosed = true
        window:Hide()
    end
    PreviousGossipOnEvent()
end
