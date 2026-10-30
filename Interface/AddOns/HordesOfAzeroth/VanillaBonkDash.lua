local L = VanillaBonkL
local UI = VanillaBonkUI

local DASH = "VANILLABONK_DASH"
local SHIFT = "SHIFT"
local HEADER = "HEADER_VANILLABONK"
BINDING_NAME_VANILLABONK_DASH = L["Dash"]
KEY_SHIFT = KEY_SHIFT or L["Shift"]

local DASH_KEYS = { "SHIFT", "CTRL-SHIFT", "ALT-SHIFT", "ALT-CTRL-SHIFT" }
local PLAIN_KEYS = { "SPACE", "UP", "DOWN", "MOUSEWHEELUP", "MOUSEWHEELDOWN" }
local CHOICE_KEYS = {
    ["1"] = "VANILLABONK_CHOICE1", ["2"] = "VANILLABONK_CHOICE2", ["3"] = "VANILLABONK_CHOICE3",
    ["4"] = "VANILLABONK_CHOICE4", ["5"] = "VANILLABONK_CHOICE5", ["6"] = "VANILLABONK_CHOICE6",
    ["R"] = "VANILLABONK_REROLL", ["X"] = "VANILLABONK_SKIP",
}
local MODIFIER_NAMES = { { "ALT-", L["Alt-"] }, { "CTRL-", L["Ctrl-"] }, { "SHIFT-", L["Shift-"] } }
local KEY_NAMES = { SHIFT = L["Shift"], CTRL = L["Ctrl"], ALT = L["Alt"] }
local SEND_INTERVAL = 0.25
local NPC_WINDOWS = {
    "MailFrame", "OpenMailFrame", "MerchantFrame", "GossipFrame", "QuestFrame", "TradeFrame", "BankFrame",
    "AuctionFrame", "TaxiFrame", "ClassTrainerFrame", "LootFrame", "TabardFrame", "PetitionFrame",
    "GuildRegistrarFrame", "ItemTextFrame",
}

local BlizzardSetBinding = SetBinding
local BlizzardGetBinding = GetBinding
local BlizzardGetBindingKey = GetBindingKey
local BlizzardGetBindingAction = GetBindingAction
local BlizzardSaveBindings = SaveBindings
local BlizzardLoadBindings = LoadBindings

local owner = CreateFrame("Frame")
local active = false
local warned = false
local onShift = true
local charges = 0
local lastSent = 0

local function SavedOnShift()
    return VanillaBonkDashShift ~= false
end

local function KeyText(key)
    if not key then
        return ""
    end
    local prefix = ""
    local stripped = true
    while stripped do
        stripped = false
        for _, modifier in ipairs(MODIFIER_NAMES) do
            local length = strlen(modifier[1])
            if strlen(key) > length and strsub(key, 1, length) == modifier[1] then
                prefix = prefix .. modifier[2]
                key = strsub(key, length + 1)
                stripped = true
            end
        end
    end
    return prefix .. (KEY_NAMES[key] or getglobal("KEY_" .. key) or key)
end

function UI.DashKeyText()
    return KeyText((GetBindingKey(DASH)))
end

function UI.BindingText(command)
    return KeyText((GetBindingKey(command)))
end

local function OverrideShiftKeys()
    for _, key in ipairs(DASH_KEYS) do
        SetOverrideBinding(owner, true, key, DASH)
    end
    for _, key in ipairs(PLAIN_KEYS) do
        local action = BlizzardGetBindingAction(key)
        if action and action ~= "" then
            SetOverrideBinding(owner, true, "SHIFT-" .. key, action)
        end
    end
    for key, action in pairs(CHOICE_KEYS) do
        SetOverrideBinding(owner, true, "SHIFT-" .. key, action)
    end
end

local shiftWatch = CreateFrame("Frame")
shiftWatch:Hide()
shiftWatch:SetScript("OnUpdate", function()
    local down = IsShiftKeyDown()
    if down and not this.wasDown and not HoAKeys_IsTyping() then
        local before = keystate
        keystate = "down"
        VanillaBonk_Dash()
        keystate = before
    end
    this.wasDown = down
end)

local function WatchShift(on)
    shiftWatch.wasDown = IsShiftKeyDown()
    if on then
        shiftWatch:Show()
    else
        shiftWatch:Hide()
    end
end

local function SyncKeys()
    if UI.SetDashKey then
        UI.SetDashKey(UI.DashKeyText())
    end
    if not active then
        return
    end
    if HoAKeys_IsTyping then
        WatchShift(onShift)
        return
    end
    if not SetOverrideBinding or not ClearOverrideBindings then
        if onShift and not warned then
            warned = true
            DEFAULT_CHAT_FRAME:AddMessage(L["Hordes of Azeroth: Shift can't dash in this client. Bind Dash to another key under Key Bindings instead."])
        end
        return
    end
    ClearOverrideBindings(owner)
    if onShift then
        OverrideShiftKeys()
    end
end

function UI.DashOnShift()
    return onShift
end

function UI.SetDashOnShift(on)
    if on then
        SetBinding(SHIFT, DASH)
    else
        SetBinding(SHIFT)
    end
    VanillaBonkDashShift = onShift
end

function SetBinding(key, command)
    if key ~= SHIFT then
        return BlizzardSetBinding(key, command)
    end
    if command == DASH then
        onShift = true
    elseif not command or command == "" then
        onShift = false
    else
        return BlizzardSetBinding(key, command)
    end
    SyncKeys()
    return 1
end

function GetBindingKey(command)
    local key1, key2 = BlizzardGetBindingKey(command)
    if command == DASH and onShift then
        return SHIFT, key1
    end
    return key1, key2
end

function GetBindingAction(key)
    if key == SHIFT and onShift then
        return DASH
    end
    return BlizzardGetBindingAction(key)
end

local bindingOrder = {}

local function OwnBlock()
    local count = GetNumBindings()
    if bindingOrder.count == count then
        return bindingOrder
    end
    bindingOrder = { count = count }
    for index = 1, count do
        local command = BlizzardGetBinding(index)
        if command == HEADER then
            bindingOrder.first = index
        elseif bindingOrder.first and not bindingOrder.last and strsub(command, 1, 7) == "HEADER_" then
            bindingOrder.last = index - 1
        end
    end
    if bindingOrder.first then
        bindingOrder.last = bindingOrder.last or count
        bindingOrder.size = bindingOrder.last - bindingOrder.first + 1
    end
    return bindingOrder
end

function GetBinding(index)
    local block = OwnBlock()
    if block.first and index <= block.last then
        if index <= block.size then
            index = block.first + index - 1
        else
            index = index - block.size
        end
    end
    local command, key1, key2 = BlizzardGetBinding(index)
    if command == DASH and onShift then
        return command, SHIFT, key1
    end
    return command, key1, key2
end

function SaveBindings(which)
    BlizzardSaveBindings(which)
    VanillaBonkDashShift = onShift
end

function LoadBindings(which)
    BlizzardLoadBindings(which)
    onShift = which == DEFAULT_BINDINGS or SavedOnShift()
    SyncKeys()
end

local DASH_THROUGH_WINDOWS = {
    VanillaBonkMap = true, VanillaBonkBags = true, VanillaBonkHearthTip = true, VanillaBonkControllerTip = true,
}

local function IsShown(name)
    local frame = getglobal(name)
    return frame and frame:IsVisible()
end

local function IsWindowOpen()
    for _, name in ipairs(NPC_WINDOWS) do
        if IsShown(name) then
            return true
        end
    end
    for _, name in ipairs(UISpecialFrames) do
        if string.find(name, "^VanillaBonk") and not DASH_THROUGH_WINDOWS[name] and IsShown(name) then
            return true
        end
    end
    return false
end

function VanillaBonk_Dash()
    if keystate == "up" or charges < 1 or IsWindowOpen() then
        return
    end
    local now = GetTime()
    if now - lastSent < SEND_INTERVAL then
        return
    end
    lastSent = now
    SendChatMessage(".bonk dash", "SAY")
end

local shiftAlone = false

local function BindDashToShift()
    local key1, key2 = GetBindingKey(DASH)
    if key1 then
        SetBinding(key1)
    end
    if key2 then
        SetBinding(key2)
    end
    if KeyBindingFrame.keyID == 1 then
        SetBinding(SHIFT, DASH)
        if key2 and key2 ~= SHIFT then
            SetBinding(key2, DASH)
        end
    else
        if key1 and key1 ~= SHIFT then
            SetBinding(key1, DASH)
        end
        SetBinding(SHIFT, DASH)
    end
    KeyBindingFrameOutputText:SetText(KEY_BOUND)
    KeyBindingFrame.selected = nil
    KeyBindingFrame.buttonPressed:UnlockHighlight()
    KeyBindingFrame.bindingsChanged = 1
    KeyBindingFrame_Update()
    KeyBindingFrame_UpdateUnbindKey()
end

local function HookBindingWindow()
    local BlizzardOnKeyDown = KeyBindingFrame_OnKeyDown
    function KeyBindingFrame_OnKeyDown(button)
        shiftAlone = not button and arg1 == SHIFT and KeyBindingFrame.selected == DASH
        BlizzardOnKeyDown(button)
    end
    KeyBindingFrame:SetScript("OnKeyUp", function()
        if arg1 == SHIFT and shiftAlone and KeyBindingFrame.selected == DASH then
            BindDashToShift()
        end
        shiftAlone = false
    end)
end

if IsAddOnLoaded("Blizzard_BindingUI") then
    HookBindingWindow()
end

owner:RegisterEvent("ADDON_LOADED")
owner:RegisterEvent("UPDATE_BINDINGS")
owner:SetScript("OnEvent", function()
    if event == "UPDATE_BINDINGS" then
        SyncKeys()
    elseif arg1 == "HordesOfAzeroth" then
        onShift = SavedOnShift()
        SyncKeys()
    elseif arg1 == "Blizzard_BindingUI" then
        HookBindingWindow()
    end
end)

UI.Listen({
    dash = function(f)
        charges = tonumber(f[2]) or 0
        if not active then
            active = true
            SyncKeys()
        end
    end,
})
