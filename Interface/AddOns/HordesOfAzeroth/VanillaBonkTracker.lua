local L = VanillaBonkL
local UI = VanillaBonkUI

local DIFFICULTY_COLORS = {
    Normal = { 0.25, 1, 0.25 },
    Heroic = { 1, 0.82, 0 },
    Mythic = { 1, 0.3, 0.3 },
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

local rows = {}
local function Row(index, label, icon, tooltip)
    local row = CreateFrame("Frame", nil, list)
    row:SetWidth(200)
    row:SetHeight(19)
    row:SetPoint("TOPRIGHT", list, "TOPRIGHT", 0, -(index - 1) * 19)
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetTexture(UI.ICON_PATH .. icon)
    row.icon:SetWidth(15)
    row.icon:SetHeight(15)
    row.icon:SetPoint("RIGHT", row, "RIGHT", 0, 0)
    row.value = UI.Text(row, 12)
    row.value:SetPoint("RIGHT", row.icon, "LEFT", -6, 0)
    row.label = UI.Text(row, 12)
    row.label:SetPoint("RIGHT", row.value, "LEFT", -5, 0)
    row.label:SetTextColor(1, 0.82, 0)
    row.label:SetText(label)
    row:EnableMouse(true)
    row.tooltip = tooltip
    row:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_LEFT")
        this.tooltip()
        GameTooltip:Show()
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    rows[index] = row
    return row
end

local kills = Row(1, L["Kills"], "INV_Misc_Bone_HumanSkull_01", function()
    GameTooltip:AddDoubleLine(L["Kills"], run.kills or 0, 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(L["Enemies killed this run."], 1, 0.82, 0)
end)
local valor = Row(2, L["Valor"], "INV_Misc_Coin_04", function()
    GameTooltip:AddDoubleLine(L["Valor"], run.valor or 0, 1, 1, 1, 1, 0.9, 0.45)
    GameTooltip:AddLine(L["Collected during the run and spent to open chests and buy from shops."], 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["Next chest: "] .. (run.chest or "?") .. L[" Valor"], 1, 1, 1)
    GameTooltip:AddLine(L["Resets every run, it's not kept."], 0.6, 0.6, 0.6)
end)
local shards = Row(3, L["Tickets"], "INV_Misc_Ticket_Darkmoon_01", function()
    GameTooltip:AddDoubleLine(L["Darkmoon Tickets"], "+" .. (run.shards or 0), 1, 1, 1, 0.75, 0.5, 1)
    GameTooltip:AddLine(L["Spend them with Sayge at the Inn."], 1, 0.82, 0)
end)
local gold = Row(4, L["Gold"], "INV_Misc_Coin_02", function()
    GameTooltip:AddDoubleLine(L["Gold earned"], UI.FormatGold(run.gold or 0), 1, 1, 1, 1, 1, 1)
    GameTooltip:AddLine(L["Yours to keep, even if you die."], 1, 0.82, 0)
end)
local greed = Row(5, L["Greed"], "Spell_Nature_EarthBindTotem", function()
    GameTooltip:AddDoubleLine(L["Greed"], (run.greed or 0) .. (run.greed == 1 and L[" stack"] or L[" stacks"]), 1, 1, 1, 1, 0.82, 0)
    GameTooltip:AddLine("+" .. (run.greedReward or 0) .. L["% gold and Darkmoon Tickets"], 0.25, 1, 0.25)
    GameTooltip:AddLine((run.greedMobs or 0) .. L["% more enemies"], 1, 0.4, 0.4)
    GameTooltip:AddLine(L["Every Greed Totem taken this run adds a stack."], 1, 0.82, 0, 1)
end)
greed:Hide()

local function Refresh()
    local elapsed = run.elapsed or 0
    if run.portal then
        tracker.timer:SetText(L["|cff40c0ffPORTAL OPEN|r"])
    elseif run.boss then
        tracker.timer:SetText("|cffff5a4a" .. UI.FormatTime(elapsed) .. "|r")
    else
        tracker.timer:SetText(UI.FormatTime(elapsed))
    end
    local stage = "|cffffd100" .. L["Floor "] .. run.stage .. "|r"
    local color = DIFFICULTY_COLORS[run.difficulty]
    if run.difficulty ~= "" and color then
        stage = stage .. format("  |cff9d9d9d·|r  |cff%02x%02x%02x%s|r", color[1] * 255, color[2] * 255, color[3] * 255, run.difficulty)
    elseif run.difficulty ~= "" then
        stage = stage .. "  |cff9d9d9d·|r  " .. run.difficulty
    end
    tracker.stage:SetText(stage)

    kills.value:SetText(run.kills or 0)
    valor.value:SetText("|cffffe873" .. (run.valor or 0) .. "|r |cff9d9d9d/ " .. (run.chest or "?") .. "|r")
    shards.value:SetText("|cffd6b0ff" .. (run.shards or 0) .. "|r")
    gold.value:SetText(UI.FormatGold(run.gold or 0))
    if (run.greed or 0) > 0 then
        greed.value:SetText("|cffffd100x" .. run.greed .. "|r |cff9d9d9d+" .. (run.greedReward or 0) .. "%|r")
        greed:Show()
    else
        greed:Hide()
    end
    for _, row in ipairs(rows) do
        row:SetWidth(row.label:GetStringWidth() + row.value:GetStringWidth() + 15 + 11 + 4)
    end
end

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
    callout.text:SetText(callout.name .. L[" |cffffffffin "] .. left .. "s|r")
end

callout:SetScript("OnUpdate", function()
    local low = -4
    local bossBar = VanillaBonkBossBar
    if bossBar and bossBar:IsVisible() then
        low = -32
        if bossBar.debuffs:IsVisible() then
            low = low - bossBar.debuffs.height - 4
        end
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

handlers["beat"] = function(f)
    local seconds = tonumber(f[4] or "") or 0
    if seconds <= 0 then
        callout.at = nil
        callout.want = 0
        return
    end
    callout.name = f[2] ~= "" and f[2] or L["Mini-boss"]
    callout.at = (run.elapsed or 0) + seconds
    callout.icon:SetTexture(UI.ICON_PATH .. (BEAT_ICONS[tonumber(f[3] or "")] or BEAT_ICONS[BEAT_WALL]))
    CalloutText()
    callout.want = 1
    callout:Show()
    PlaySound("RaidWarning")
end

handlers["start"] = function(f)
    run.map = f[2] or ""
    run.difficulty = f[3] or ""
    run.duration = tonumber(f[4]) or 600
    run.stage = tonumber(f[5]) or 1
    run.floors = f[8] == "1"
    run.elapsed = 0
    HideCallout()
    run.boss, run.portal = false, false
    Refresh()
    tracker:Show()
    list:Show()
end

handlers["state"] = function(f)
    run.elapsed = tonumber(f[2]) or 0
    run.duration = tonumber(f[3]) or run.duration
    run.kills = tonumber(f[4]) or 0
    run.gold = tonumber(f[5]) or 0
    run.boss = f[7] == "1"
    run.valor = tonumber(f[8]) or 0
    run.chest = f[9] or "?"
    run.stage = tonumber(f[10]) or run.stage
    run.portal = f[11] == "1"
    run.shards = tonumber(f[12]) or 0
    if callout.at then
        CalloutText()
    end
    Refresh()
    if not tracker:IsShown() then
        tracker:Show()
        list:Show()
    end
end

handlers["greed"] = function(f)
    run.greed = tonumber(f[2] or "") or 0
    run.greedReward = tonumber(f[3] or "") or 0
    run.greedMobs = tonumber(f[4] or "") or 0
    Refresh()
end

handlers["end"] = function()
    run.greed, run.greedReward, run.greedMobs = 0, 0, 0
    HideCallout()
    tracker:Hide()
    list:Hide()
end

UI.Listen(handlers)
