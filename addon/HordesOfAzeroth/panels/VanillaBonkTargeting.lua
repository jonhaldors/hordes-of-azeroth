local UI = VanillaBonkUI

local inRun = false

local function IsEnemyTarget()
    return UnitExists("target") and not UnitIsUnit("target", "player") and UnitCanAttack("player", "target")
end

local function DropEnemyTarget()
    if inRun and IsEnemyTarget() then
        ClearTarget()
    end
end

local BaseErrorsOnEvent = UIErrorsFrame:GetScript("OnEvent")
UIErrorsFrame:SetScript("OnEvent", function()
    if inRun and event == "UI_ERROR_MESSAGE" and arg1 == ERR_NO_ATTACK_TARGET then
        return
    end
    if BaseErrorsOnEvent then
        BaseErrorsOnEvent()
    end
end)

UI.Module("targeting"):Listen({ PLAYER_TARGET_CHANGED = DropEnemyTarget })

local function EnterRun()
    inRun = true
    DropEnemyTarget()
end

UI.ListenHoa({
    HOA_RUN_STATE = EnterRun,
})
UI.Module("targeting"):OnRunStart(EnterRun):OnRunEnd(function()
    inRun = false
end)
