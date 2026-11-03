local L = VanillaBonkL
local UI = VanillaBonkUI

BINDING_NAME_VANILLABONK_INSPECT = L["Inspect Talents"]

function VanillaBonk_Inspect()
    if keystate == "up" then
        return
    end
    if UI.InspectShown() then
        UI.HideInspect()
        return
    end
    if not UI.InRun() then
        UIErrorsFrame:AddMessage(L["You can only view your talents during a run."], 1, 0.1, 0.1, 1)
        return
    end
    SendChatMessage(".bonk inspect", "SAY")
end
