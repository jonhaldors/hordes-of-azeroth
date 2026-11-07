local L = VanillaBonkL
local UI = VanillaBonkUI

BINDING_NAME_VANILLABONK_INSPECT = L["hoa.addon.inspect_talents"]

function VanillaBonk_Inspect()
    if keystate == "up" then
        return
    end
    if UI.InspectShown() then
        UI.HideInspect()
        return
    end
    if not UI.InRun() then
        UIErrorsFrame:AddMessage(L["hoa.addon.you_can_only_view_your_talents_during_a_run"], 1, 0.1, 0.1, 1)
        return
    end
    SendChatMessage(".bonk inspect", "SAY")
end
