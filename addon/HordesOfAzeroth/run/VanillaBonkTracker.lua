local L = VanillaBonkL
local UI = VanillaBonkUI

local DIFFICULTY_COLORS = {
    [L["hoa.addon.normal"]] = { 0.25, 1, 0.25 },
    [L["hoa.addon.heroic"]] = { 1, 0.82, 0 },
    [L["hoa.addon.mythic"]] = { 1, 0.3, 0.3 },
}

local run = { duration = 600, stage = 1, difficulty = "" }

local tracker = CreateFrame("Frame", "VanillaBonkTracker", UIParent)
tracker:SetWidth(240)
tracker:SetHeight(60)
tracker:SetPoint("TOP", UIParent, "TOP", 0, 0)
tracker:Hide()

tracker.timer = UI.Text(tracker, 28, UI.FONT, "OUTLINE")
tracker.timer:SetPoint("TOP", tracker, "TOP", 0, -4)

tracker.stage = UI.Text(tracker, 11)
tracker.stage:SetPoint("TOP", tracker.timer, "BOTTOM", 0, -3)

local BEAT_WALL, BEAT_MINIBOSS = 2, 3
local BEAT_ICONS = { [BEAT_WALL] = "Ability_Warrior_Challange", [BEAT_MINIBOSS] = "Ability_Rogue_Eviscerate" }

local list = CreateFrame("Frame", "VanillaBonkRewards", UIParent)
list:SetWidth(200)
list:SetHeight(80)
list:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -10, -196)
list:Hide()

local rewards = UI.List(list, {})
local trackerPanel = UI.PanelObject("tracker", { tracker, list })
trackerPanel.rewards = rewards

local kills = rewards:Add("kills", { label = L["hoa.addon.kills_2"], icon = UI.ICON_PATH .. "INV_Misc_Bone_HumanSkull_01", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.kills_2"], run.kills or 0, 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.enemies_killed_this_run"], 1, 0.82, 0)
end })
local valor = rewards:Add("valor", { label = L["hoa.addon.valor"], icon = UI.ICON_PATH .. "INV_Misc_Coin_04", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.valor"], run.valor or 0, 1, 1, 1, 1, 0.9, 0.45)
    GameTooltip:AddLine(L["hoa.addon.spent_on_chests_and_shops_during_the_run"], 1, 0.82, 0, 1)
    GameTooltip:AddLine(L("hoa.addon.next_chest_1_valor", run.chest or "?"), 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.lost_when_the_run_ends"], 0.6, 0.6, 0.6)
end })
local shards = rewards:Add("shards", { label = L["hoa.addon.tickets_2"], icon = UI.ICON_PATH .. "INV_Misc_Ticket_Darkmoon_01", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.darkmoon_tickets_2"], "+" .. (run.shards or 0), 1, 1, 1, 0.75, 0.5, 1)
    GameTooltip:AddLine(L["hoa.addon.spend_them_with_sayge_at_the_inn"], 1, 0.82, 0)
end })
local gold = rewards:Add("gold", { label = L["hoa.addon.gold"], icon = UI.ICON_PATH .. "INV_Misc_Coin_02", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.gold_earned"], UI.FormatGold(run.gold or 0), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.yours_to_keep_even_if_you_die"], 1, 0.82, 0)
end })
local greed = rewards:Add("greed", { label = L["hoa.addon.greed"], icon = UI.ICON_PATH .. "Spell_Nature_EarthBindTotem", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.greed"], L(run.greed == 1 and "hoa.addon.1_stack" or "hoa.addon.1_stacks", run.greed or 0), 1, 1, 1, 1, 0.82, 0)
    GameTooltip:AddLine(L("hoa.addon.1_gold_and_darkmoon_tickets", run.greedReward or 0), 0.25, 1, 0.25)
    GameTooltip:AddLine(L("hoa.addon.1_more_enemies", run.greedMobs or 0), 1, 0.4, 0.4)
    GameTooltip:AddLine(L["hoa.addon.every_greed_totem_taken_this_run_adds_a_stack"], 1, 0.82, 0, 1)
end })
greed:Hide()
local revives = rewards:Add("revives", { label = L["hoa.addon.revives"], icon = UI.ICON_PATH .. "Spell_Holy_Resurrection", tooltip = function()
    GameTooltip:AddDoubleLine(L["hoa.addon.party_revives"], (run.revives or 0) .. " / " .. (run.revivesCap or 0), 1, 1, 1, 0.4, 1, 0.4)
    GameTooltip:AddLine(L["hoa.addon.shared_by_your_party_stand_near_a_fallen_ally_to_revive_them"], 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["hoa.addon.clearing_a_stage_gives_one_back"], 0.6, 0.6, 0.6, 1)
end })
revives:Hide()
rewards:Layout()

local function Refresh()
    local elapsed = run.elapsed or 0
    if run.portal then
        tracker.timer:SetText(L["hoa.addon.cff40c0ffportal_open_r"])
    elseif run.boss then
        tracker.timer:SetText("|cffff5a4a" .. UI.FormatTime(elapsed) .. "|r")
    else
        tracker.timer:SetText(UI.FormatTime(elapsed))
    end
    local stage = "|cffffd100" .. (run.finale and L["hoa.addon.finale"] or L("hoa.addon.stage_1_2", run.stage, run.stages)) .. "|r"
    local color = DIFFICULTY_COLORS[run.difficulty]
    if run.difficulty ~= "" and color then
        stage = stage .. format("  |cff9d9d9d·|r  |cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, run.levelName)
    elseif run.difficulty ~= "" then
        stage = stage .. "  |cff9d9d9d·|r  " .. run.levelName
    end
    tracker.stage:SetText(stage)

    kills:SetValue(run.kills or 0)
    valor:SetValue("|cffffe873" .. (run.valor or 0) .. "|r |cff9d9d9d/ " .. (run.chest or "?") .. "|r")
    shards:SetValue("|cffd6b0ff" .. (run.shards or 0) .. "|r")
    gold:SetValue(UI.FormatGold(run.gold or 0))
    if (run.greed or 0) > 0 then
        greed:SetValue("|cffffd100x" .. run.greed .. "|r |cff9d9d9d+" .. (run.greedReward or 0) .. "%|r")
        greed:Show()
    else
        greed:Hide()
    end
    if (run.revivesCap or 0) > 0 then
        local color = run.revives == 0 and "ff5a4a" or "66ff66"
        revives:SetValue("|cff" .. color .. run.revives .. "|r |cff9d9d9d/ " .. run.revivesCap .. "|r")
        revives:Show()
    else
        revives:Hide()
    end
    rewards:Layout()
end
trackerPanel.OnRefresh = Refresh

tracker:SetScript("OnUpdate", function()
    this.elapsed = (this.elapsed or 0) + arg1
    if this.elapsed < 0.1 then
        return
    end
    this.elapsed = 0
    if VanillaBonkBossBar and VanillaBonkBossBar:IsShown() then
        tracker.stage:Hide()
    else
        tracker.stage:Show()
    end
end)

local CALLOUT_FADE_IN = 0.2
local CALLOUT_FADE_OUT = 0.4

local callout = CreateFrame("Frame", nil, UIParent)
callout:SetWidth(440)
callout:SetHeight(30)
callout:SetPoint("TOP", tracker, "BOTTOM", 0, -4)
callout:Hide()
for side = 1, 2 do
    local half = callout:CreateTexture(nil, "BACKGROUND")
    half:SetTexture(UI.FLAT)
    half:SetWidth(220)
    half:SetHeight(30)
    if side == 1 then
        half:SetPoint("LEFT", callout, "LEFT", 0, 0)
        if half.SetGradientAlpha then
            half:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0, 0, 0, 0, 0.65)
        end
    else
        half:SetPoint("RIGHT", callout, "RIGHT", 0, 0)
        if half.SetGradientAlpha then
            half:SetGradientAlpha("HORIZONTAL", 0, 0, 0, 0.65, 0, 0, 0, 0)
        end
    end
end
callout.text = UI.Text(callout, 18, UI.FONT, "OUTLINE")
callout.text:SetPoint("CENTER", callout, "CENTER", 12, 0)
callout.text:SetTextColor(1, 0.25, 0.2)
callout.icon = callout:CreateTexture(nil, "ARTWORK")
callout.icon:SetWidth(22)
callout.icon:SetHeight(22)
callout.icon:SetPoint("RIGHT", callout.text, "LEFT", -6, 0)
callout.alpha, callout.want = 0, 0

local function CalloutText()
    local left = max(1, (callout.at or 0) - (run.elapsed or 0))
    callout.text:SetText(L("hoa.addon.1_cffffffffin_2_s_r", callout.name, left))
end

callout:SetScript("OnUpdate", function()
    local low = -4
    local bossBar = VanillaBonkBossBar
    if bossBar and bossBar:IsVisible() then
        low = -32 - (bossBar.below or 0)
    end
    if low ~= this.low then
        this.low = low
        this:ClearAllPoints()
        this:SetPoint("TOP", tracker, "BOTTOM", 0, low)
    end
    if this.alpha ~= this.want then
        local fade = this.want > this.alpha and CALLOUT_FADE_IN or CALLOUT_FADE_OUT
        local step = arg1 / fade
        this.alpha = this.want > this.alpha and min(this.want, this.alpha + step) or max(this.want, this.alpha - step)
        if this.alpha <= 0 then
            this:Hide()
            return
        end
    end
    this:SetAlpha(this.alpha * (0.8 + 0.2 * sin(GetTime() * 360)))
end)

local function HideCallout()
    callout.want, callout.alpha = 0, 0
    callout.at = nil
    callout:Hide()
end

local handlers = {}

UI.ListenHoa({
    HOA_GREED = function(greed)
        handlers["greed"]({ false, greed.stacks, greed.reward_percent, greed.mob_percent })
    end,
    HOA_COOP_DOWN = function(down)
        handlers["coopdown"]({ false, down.pool, down.cap, down.list })
    end,
    HOA_WAVE_BEAT = function(beat)
        local seconds = tonumber(beat.seconds) or 0
        if seconds <= 0 then
            callout.at = nil
            callout.want = 0
            return
        end
        callout.name = beat.name ~= "" and beat.name or L["hoa.addon.mini_boss"]
        callout.at = (run.elapsed or 0) + seconds
        callout.icon:SetTexture(UI.ICON_PATH .. (BEAT_ICONS[tonumber(beat.beat)] or BEAT_ICONS[BEAT_WALL]))
        CalloutText()
        callout.want = 1
        callout:Show()
        PlaySound("RaidWarning")
    end,
    HOA_RUN_STATE = function(state)
        run.elapsed = tonumber(state.elapsed_s) or 0
        run.duration = tonumber(state.duration_s) or run.duration
        run.kills = tonumber(state.kills) or 0
        run.gold = tonumber(state.gold_earned) or 0
        run.boss = state.boss_spawned and true or false
        run.valor = tonumber(state.coins) or 0
        run.chest = tostring(state.chest_price or "?")
        run.stage = tonumber(state.stage) or run.stage
        run.portal = state.portal and true or false
        run.shards = tonumber(state.shards_earned) or 0
        if callout.at then
            CalloutText()
        end
        Refresh()
        if not tracker:IsShown() then
            trackerPanel:Show()
        end
    end,
})
UI.Module("tracker"):OnRunStart(function(start)
    run.map = start.map_name or ""
    run.difficulty = start.difficulty or ""
    run.levelName = (start.level_name and start.level_name ~= "") and start.level_name or run.difficulty
    run.duration = tonumber(start.duration_s) or 600
    run.stage = tonumber(start.stage) or 1
    run.stages = tonumber(start.stages) or 3
    run.finale = start.finale and true or false
    run.elapsed = 0
    HideCallout()
    run.boss, run.portal = false, false
    Refresh()
    trackerPanel:Show()
end):OnRunEnd(function()
    run.greed, run.greedReward, run.greedMobs = 0, 0, 0
    run.revives, run.revivesCap = 0, 0
    HideCallout()
    trackerPanel:Hide()
end)

handlers["greed"] = function(f)
    run.greed = tonumber(f[2] or "") or 0
    run.greedReward = tonumber(f[3] or "") or 0
    run.greedMobs = tonumber(f[4] or "") or 0
    Refresh()
end

handlers["coopdown"] = function(f)
    run.revives = tonumber(f[2] or "") or 0
    run.revivesCap = tonumber(f[3] or "") or 0
    Refresh()
end

