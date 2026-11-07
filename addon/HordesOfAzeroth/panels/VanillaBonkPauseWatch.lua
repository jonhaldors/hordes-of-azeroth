local UI = VanillaBonkUI

local STUCK_SECONDS = 2
local RETRY_SECONDS = 5
local CHOICE_FRAMES = {
    "VanillaBonkOffer", "VanillaBonkGlyphs", "VanillaBonkGear", "VanillaBonkVendor", "VanillaBonkVault",
    "VanillaBonkMenu", "VanillaBonkHearthTip", "VanillaBonkControllerTip", "VanillaBonkCurrencyTip", "VanillaBonkPlateGuide",
    "GameMenuFrame", "OptionsFrame", "SoundOptionsFrame", "UIOptionsFrame", "KeyBindingFrame", "BenillaOptionsFrame",
}

local inRun, paused = false, false
local stuckFor, retryIn = 0, 0

function UI.RunPaused()
    return inRun and paused
end

local function AnyChoiceShown()
    for _, name in ipairs(CHOICE_FRAMES) do
        local frame = getglobal(name)
        if frame and frame:IsShown() then
            return true
        end
    end
    return false
end

local watch = CreateFrame("Frame")
watch:SetScript("OnUpdate", function()
    retryIn = retryIn - arg1
    if not (inRun and paused) or AnyChoiceShown() then
        stuckFor = 0
        return
    end
    stuckFor = stuckFor + arg1
    if stuckFor >= STUCK_SECONDS and retryIn <= 0 then
        retryIn = RETRY_SECONDS
        SendChatMessage(".bonk resync", "SAY")
    end
end)

UI.ListenHoa({
    HOA_RUN_PAUSED = function(state)
        paused = state.paused and true or false
        stuckFor = 0
    end,
    HOA_RUN_STATE = function()
        inRun = true
    end,
})
UI.Module("pauseWatch"):OnRunStart(function()
    inRun = true
end):OnRunEnd(function()
    inRun = false
    paused = false
end)
