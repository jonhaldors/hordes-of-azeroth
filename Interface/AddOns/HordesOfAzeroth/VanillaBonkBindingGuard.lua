local L = VanillaBonkL
local CHECK_DELAY = 0.5
local CAPTURE_DELAY = 1
local MODIFIERS = { "", "SHIFT-", "CTRL-", "ALT-", "CTRL-SHIFT-", "ALT-SHIFT-", "ALT-CTRL-", "ALT-CTRL-SHIFT-" }
local BASE_KEYS = {
    "A", "B", "C", "D", "E", "F", "G", "H", "I", "J", "K", "L", "M", "N", "O", "P", "Q", "R", "S", "T", "U", "V", "W", "X", "Y", "Z",
    "0", "1", "2", "3", "4", "5", "6", "7", "8", "9",
    "F1", "F2", "F3", "F4", "F5", "F6", "F7", "F8", "F9", "F10", "F11", "F12",
    "NUMPAD0", "NUMPAD1", "NUMPAD2", "NUMPAD3", "NUMPAD4", "NUMPAD5", "NUMPAD6", "NUMPAD7", "NUMPAD8", "NUMPAD9",
    "NUMPADDIVIDE", "NUMPADMULTIPLY", "NUMPADMINUS", "NUMPADPLUS", "NUMPADDECIMAL", "NUMLOCK",
    "UP", "DOWN", "LEFT", "RIGHT", "SPACE", "TAB", "ENTER", "ESCAPE", "BACKSPACE", "INSERT", "DELETE", "HOME", "END", "PAGEUP", "PAGEDOWN",
    "PRINTSCREEN", "CAPSLOCK", "`", "-", "=", "[", "]", "\\", ";", "'", ",", ".", "/",
    "BUTTON1", "BUTTON2", "BUTTON3", "BUTTON4", "BUTTON5", "MOUSEWHEELUP", "MOUSEWHEELDOWN",
    "SHIFT", "CTRL", "ALT",
}

local checked = false
local checkAt, captureAt

local function SnapshotKey()
    if GetCurrentBindingSet() == 2 then
        return "keys-" .. GetRealmName() .. "-" .. UnitName("player")
    end
    return "keys-account"
end

local function AllKeys(extra)
    local keys = {}
    for _, modifier in ipairs(MODIFIERS) do
        for _, key in ipairs(BASE_KEYS) do
            keys[modifier .. key] = true
        end
    end
    for index = 1, GetNumBindings() do
        local _, key1, key2 = GetBinding(index)
        if key1 then
            keys[key1] = true
        end
        if key2 then
            keys[key2] = true
        end
    end
    if extra then
        for key in pairs(extra) do
            keys[key] = true
        end
    end
    return keys
end

local function Capture()
    local snapshot = {}
    for key in pairs(AllKeys()) do
        local action = GetBindingAction(key)
        if action and action ~= "" then
            snapshot[key] = action
        end
    end
    return snapshot
end

local function Differs(saved, current)
    for key, action in pairs(saved) do
        if current[key] ~= action then
            return true
        end
    end
    for key in pairs(current) do
        if not saved[key] then
            return true
        end
    end
    return false
end

local function Restore(saved)
    for key in pairs(AllKeys(saved)) do
        local want = saved[key]
        local have = GetBindingAction(key)
        if have == "" then
            have = nil
        end
        if want ~= have then
            if want then
                SetBinding(key, want)
            else
                SetBinding(key)
            end
        end
    end
    SaveBindings(GetCurrentBindingSet())
end

local function KeepGameMenuKey()
    if GetBindingAction("ESCAPE") ~= "TOGGLEGAMEMENU" then
        SetBinding("ESCAPE", "TOGGLEGAMEMENU")
        SaveBindings(GetCurrentBindingSet())
    end
end

local function Store()
    if not checked or VanillaBonkChoiceKeys then
        return
    end
    VanillaBonkBindings = VanillaBonkBindings or {}
    VanillaBonkBindings[SnapshotKey()] = Capture()
end

local function Check()
    checked = true
    local saved = VanillaBonkBindings and VanillaBonkBindings[SnapshotKey()]
    if saved and not VanillaBonkChoiceKeys and Differs(saved, Capture()) then
        Restore(saved)
    end
    KeepGameMenuKey()
    Store()
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("UPDATE_BINDINGS")
events:RegisterEvent("PLAYER_LOGOUT")
events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        if not checked then
            checkAt = GetTime() + CHECK_DELAY
        end
    elseif event == "UPDATE_BINDINGS" then
        captureAt = GetTime() + CAPTURE_DELAY
    elseif event == "PLAYER_LOGOUT" then
        Store()
    end
end)
events:SetScript("OnUpdate", function()
    local now = GetTime()
    if checkAt and now >= checkAt then
        checkAt = nil
        Check()
    end
    if captureAt and now >= captureAt then
        captureAt = nil
        if checked then
            KeepGameMenuKey()
        end
        Store()
    end
end)
