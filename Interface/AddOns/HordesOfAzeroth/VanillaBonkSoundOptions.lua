local L = VanillaBonkL
local UI = VanillaBonkUI

local XP_SOUNDS_KEY = "xpSounds"
local ROW = 26

local check = CreateFrame("CheckButton", "VanillaBonkXpSoundsCheck", SoundOptionsFrame, "OptionsCheckButtonTemplate")
check:SetPoint("TOP", SoundOptionsFrameCheckButton8, "BOTTOM", 0, 6)
getglobal(check:GetName() .. "Text"):SetText(L["Experience Pickup Sounds"])
getglobal(check:GetName() .. "Text"):SetTextColor(HIGHLIGHT_FONT_COLOR.r, HIGHLIGHT_FONT_COLOR.g, HIGHLIGHT_FONT_COLOR.b)
check.tooltipText = L["Plays a coin sound when you collect experience."]
SoundOptionsFrame:SetHeight(SoundOptionsFrame:GetHeight() + ROW)

check:SetScript("OnClick", function()
    local on = this:GetChecked() and true or false
    UI.SetOption(XP_SOUNDS_KEY, on)
    PlaySound(on and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
end)

local BaseOnShow = SoundOptionsFrame:GetScript("OnShow")
SoundOptionsFrame:SetScript("OnShow", function()
    if BaseOnShow then
        BaseOnShow()
    end
    check.initial = UI.Option(XP_SOUNDS_KEY, true)
    check:SetChecked(check.initial)
end)

local BaseCancel = SoundOptionsFrame_Cancel
function SoundOptionsFrame_Cancel()
    BaseCancel()
    if check.initial ~= nil then
        UI.SetOption(XP_SOUNDS_KEY, check.initial)
    end
end

local BaseDefaults = SoundOptionsFrame_SetDefaults
function SoundOptionsFrame_SetDefaults()
    BaseDefaults()
    UI.SetOption(XP_SOUNDS_KEY, true)
    check:SetChecked(true)
end
