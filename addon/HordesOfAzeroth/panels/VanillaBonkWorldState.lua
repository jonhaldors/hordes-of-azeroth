local UI = VanillaBonkUI
local MAX_CAPTURE_BARS = 5

local function HideWorldStateUI()
    if WorldStateAlwaysUpFrame then
        WorldStateAlwaysUpFrame:Hide()
    end
    for index = 1, MAX_CAPTURE_BARS do
        local bar = getglobal("WorldStateCaptureBar" .. index)
        if bar then
            bar:Hide()
        end
    end
end

if WorldStateAlwaysUpFrame then
    WorldStateAlwaysUpFrame:SetScript("OnShow", function()
        this:Hide()
    end)
end

WorldStateAlwaysUpFrame_Update = HideWorldStateUI

local watcher = CreateFrame("Frame")
UI.Module("worldState"):OnEnterWorld(HideWorldStateUI)
UI.Module("worldState"):Listen({
    UPDATE_WORLD_STATES = HideWorldStateUI,
    ZONE_CHANGED_NEW_AREA = HideWorldStateUI,
})
HideWorldStateUI()
