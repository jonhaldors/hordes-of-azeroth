local L = VanillaBonkL
local BAG_OFFSET_Y = 88
local MICRO_STEP = 26

local hidden = CreateFrame("Frame")
hidden:Hide()

local corner = CreateFrame("Frame", "VanillaBonkMenuBar", UIParent)
corner:SetWidth(260)
corner:SetHeight(44)
corner:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -4, 2)

local MICRO_BUTTONS = { "CharacterMicroButton", "SpellbookMicroButton", "TalentMicroButton", "QuestLogMicroButton",
    "SocialsMicroButton", "WorldMapMicroButton", "MainMenuMicroButton", "HelpMicroButton" }
local HIDDEN_BAGS = { "CharacterBag0Slot", "CharacterBag1Slot", "CharacterBag2Slot", "CharacterBag3Slot", "KeyRingButton" }

for _, name in ipairs(MICRO_BUTTONS) do
    local button = getglobal(name)
    if button then
        button:SetParent(corner)
    end
end
MainMenuBarBackpackButton:SetParent(corner)
for _, name in ipairs(HIDDEN_BAGS) do
    local button = getglobal(name)
    if button then
        button:SetParent(hidden)
    end
end

MainMenuBarBackpackButton:ClearAllPoints()
MainMenuBarBackpackButton:SetPoint("BOTTOMRIGHT", corner, "BOTTOMRIGHT", -4, 2)

function UpdateTalentButton()
    TalentMicroButton:Hide()
    QuestLogMicroButton:SetPoint("BOTTOMLEFT", "TalentMicroButton", "BOTTOMLEFT", 0, 0)
end
UpdateTalentButton()

function ToggleTalentFrame()
end

local function LayoutMicroButtons()
    local shown = 0
    for _, name in ipairs(MICRO_BUTTONS) do
        local button = getglobal(name)
        if button and button:IsShown() then
            shown = shown + 1
        end
    end
    CharacterMicroButton:ClearAllPoints()
    CharacterMicroButton:SetPoint("BOTTOMRIGHT", MainMenuBarBackpackButton, "BOTTOMLEFT", -4 - max(0, shown - 1) * MICRO_STEP, 0)
end

LayoutMicroButtons()

MainMenuBar:SetParent(hidden)

local function RaiseBags()
    if CONTAINER_OFFSET_Y and CONTAINER_OFFSET_Y < BAG_OFFSET_Y then
        CONTAINER_OFFSET_Y = BAG_OFFSET_Y
        if updateContainerFrameAnchors then
            updateContainerFrameAnchors()
        end
    end
end

local PreviousManageFramePositions = UIParent_ManageFramePositions
UIParent_ManageFramePositions = function()
    if PreviousManageFramePositions then
        PreviousManageFramePositions()
    end
    RaiseBags()
end
RaiseBags()

local NO_POWER_FRAME = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\PlayerFrameNoPower"
local BACKGROUND_HEIGHT = 41
local NO_POWER_BACKGROUND_HEIGHT = 31

local function HidePlayerPower()
    PlayerFrameManaBar:SetParent(hidden)
    PlayerFrameManaBarText:Hide()
    PlayerFrameManaBarText.Show = PlayerFrameManaBarText.Hide
    PlayerFrameTexture:SetTexture(NO_POWER_FRAME)
    PlayerFrameBackground:SetHeight(NO_POWER_BACKGROUND_HEIGHT)
end

local function ShowPower(bar, text, parent, show)
    if bar.powerShown == show then
        return
    end
    bar.powerShown = show
    bar:SetParent(show and parent or hidden)
    if text then
        text:SetTextColor(1, 1, 1, show and 1 or 0)
    end
end

local targetPowerParent = TargetFrameManaBar:GetParent()
local PreviousCheckClassification = TargetFrame_CheckClassification
function TargetFrame_CheckClassification()
    PreviousCheckClassification()
    local hero = UnitIsUnit("target", "player")
    ShowPower(TargetFrameManaBar, TargetFrameManaBarText, targetPowerParent, not hero)
    TargetFrameBackground:SetHeight(hero and NO_POWER_BACKGROUND_HEIGHT or BACKGROUND_HEIGHT)
    if hero then
        TargetFrameTexture:SetTexture(NO_POWER_FRAME)
    end
end

if TargetofTargetManaBar and TargetofTarget_Update then
    local targetTargetPowerParent = TargetofTargetManaBar:GetParent()
    local PreviousTargetofTargetUpdate = TargetofTarget_Update
    function TargetofTarget_Update()
        PreviousTargetofTargetUpdate()
        ShowPower(TargetofTargetManaBar, TargetofTargetFrameManaBarText, targetTargetPowerParent, not UnitIsUnit("targettarget", "player"))
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:SetScript("OnEvent", function()
    RaiseBags()
    UpdateTalentButton()
    HidePlayerPower()
end)

VanillaBonkUI.Listen({
    ["start"] = function() corner:Hide() end,
    ["end"] = function() corner:Show() end,
})
