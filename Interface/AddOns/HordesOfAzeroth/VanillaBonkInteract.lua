local L = VanillaBonkL
local UI = VanillaBonkUI
local Controller = VanillaBonkController

BINDING_NAME_VANILLABONK_INTERACT = L["Interact With Nearby"]

function VanillaBonk_Interact()
    if HoAController_Interact then
        HoAController_Interact()
    end
end

local function PushInteractType(kind, skip)
    if kind.units then
        HoAController_SetInteractSkip("unit", 0, skip)
    end
    for _, entry in ipairs(kind.objects or {}) do
        HoAController_SetInteractSkip("object", entry, skip)
    end
    for _, objectType in ipairs(kind.types or {}) do
        HoAController_SetInteractSkip("type", objectType, skip)
    end
end

function UI.ApplyInteract()
    if not HoAController_SetInteractSkip or not HoAController_SetAutoUse then
        return
    end
    for _, kind in ipairs(UI.INTERACT_TYPES) do
        PushInteractType(kind, not UI.Option(kind.key, true))
    end
    local autoChests = UI.SettingValue(UI.AUTO_CHEST_SETTING)
    for _, entry in ipairs(UI.AUTO_CHEST_ENTRIES) do
        HoAController_SetAutoUse(entry, autoChests)
    end
end

local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if not this.pushed and HoAController_SetInteractSkip then
        this.pushed = true
        UI.ApplyInteract()
    end
    if HoAController_AutoUse and not Controller.captured and not UnitIsDeadOrGhost("player") then
        HoAController_AutoUse()
    end
end)
