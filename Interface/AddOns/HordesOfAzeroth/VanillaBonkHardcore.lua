local L = VanillaBonkL
local UI = VanillaBonkUI

local WIDTH = 440
local ROW_HEIGHT = 18
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"

local function Played(seconds)
    seconds = tonumber(seconds) or 0
    local hours = floor(seconds / 3600)
    local minutes = floor(mod(seconds, 3600) / 60)
    if hours > 0 then
        return L("hours and minutes::{1}h {2}m", hours, minutes)
    end
    return L("minutes::{1}m", minutes)
end

local shade = CreateFrame("Frame", "VanillaBonkHardcoreFallen", UIParent)
shade:SetAllPoints(UIParent)
shade:SetFrameStrata("FULLSCREEN_DIALOG")
shade:EnableMouse(true)
shade:Hide()

local dim = shade:CreateTexture(nil, "BACKGROUND")
dim:SetAllPoints(shade)
dim:SetTexture(0, 0, 0, 0.75)

local card = UI.Panel(shade, UI.PANEL_EDGE)
card:SetWidth(WIDTH)
card:SetPoint("CENTER", shade, "CENTER", 0, 40)
card:SetBackdropColor(UI.WINDOW_BG[1], UI.WINDOW_BG[2], UI.WINDOW_BG[3], UI.WINDOW_BG[4])

local skull = card:CreateTexture(nil, "ARTWORK")
skull:SetTexture(SKULL)
skull:SetWidth(40)
skull:SetHeight(40)
skull:SetPoint("TOP", card, "TOP", 0, -18)

local title = UI.Text(card, 26, nil, "OUTLINE")
title:SetPoint("TOP", skull, "BOTTOM", 0, -8)
title:SetTextColor(0.85, 0.12, 0.1)
title:SetText(L["You Have Fallen"])

local subtitle = UI.Text(card, 13)
subtitle:SetPoint("TOP", title, "BOTTOM", 0, -8)
subtitle:SetWidth(WIDTH - 48)
subtitle:SetTextColor(1, 0.82, 0)

local killedBy = UI.Text(card, 12)
killedBy:SetPoint("TOP", subtitle, "BOTTOM", 0, -6)
killedBy:SetWidth(WIDTH - 48)
killedBy:SetTextColor(0.85, 0.85, 0.85)

local rows = {}
for index = 1, 6 do
    local label = UI.Text(card, 12)
    label:SetJustifyH("LEFT")
    label:SetTextColor(1, 0.82, 0)
    local value = UI.Text(card, 12)
    value:SetJustifyH("RIGHT")
    value:SetTextColor(1, 1, 1)
    label:SetPoint("TOPLEFT", killedBy, "BOTTOM", -150, -18 - (index - 1) * ROW_HEIGHT)
    value:SetPoint("TOPRIGHT", killedBy, "BOTTOM", 150, -18 - (index - 1) * ROW_HEIGHT)
    rows[index] = { label = label, value = value }
end

local note = UI.Text(card, 12)
note:SetPoint("TOP", killedBy, "BOTTOM", 0, -30 - 6 * ROW_HEIGHT)
note:SetWidth(WIDTH - 60)
note:SetTextColor(0.8, 0.8, 0.8)

local fallen = { name = "", ironman = false, confirming = false }

local rest = UI.Button(card, 170)
local keep = UI.Button(card, 170)
rest:SetPoint("TOPRIGHT", note, "BOTTOM", -6, -18)
keep:SetPoint("TOPLEFT", note, "BOTTOM", 6, -18)

local function ShowChoice()
    fallen.confirming = false
    rest:SetText(L["Lay to Rest"])
    if fallen.ironman then
        keep:SetText(L["Keep Playing"])
        note:SetText(L("Lay {1} to rest in the graveyard, or keep playing as a regular Ironman character with their gear, gold and mastery.", fallen.name))
    else
        keep:SetText(L["Keep Playing"])
        note:SetText(L("Lay {1} to rest in the graveyard, or keep playing as a regular character with their gear and mastery. Hardcore gold and bank stay with your other Hardcore characters.", fallen.name))
    end
end

local function ShowConfirm()
    fallen.confirming = true
    rest:SetText(L["Lay to Rest"])
    keep:SetText(L["Back"])
    note:SetText(L("{1} leaves your character list for good and is remembered in the graveyard.", fallen.name))
end

rest:SetScript("OnClick", function()
    if not fallen.confirming then
        PlaySound("igMainMenuOption")
        ShowConfirm()
        return
    end
    rest:Disable()
    keep:Disable()
    SendChatMessage(".bonk rest", "WHISPER", nil, UnitName("player"))
end)

keep:SetScript("OnClick", function()
    if fallen.confirming then
        PlaySound("igMainMenuOption")
        ShowChoice()
        return
    end
    PlaySound("igMainMenuLogout")
    Logout()
end)

local function SetRow(index, label, value)
    rows[index].label:SetText(label)
    rows[index].value:SetText(value)
end

local function Show(f)
    local name = f[2] or ""
    local ironman = f[12] == "1"
    subtitle:SetText(L("{1} fell in Hardcore at level {2}.", name, tonumber(f[4]) or 0))
    local place = L[f[11] ~= "" and f[11] or "unknown"]
    if f[10] == "" then
        killedBy:SetText(L("Fled the fight in {1}.", place))
    else
        killedBy:SetText(L("Slain by {1} in {2}.", L[f[10]], place))
    end
    SetRow(1, L["Best level"], UI.LevelName(f[5]))
    SetRow(2, L["Mastery"], tonumber(f[6]) or 0)
    SetRow(3, L["Runs"], tonumber(f[8]) or 0)
    SetRow(4, L["Enemies slain"], UI.Thousands(tonumber(f[9]) or 0))
    SetRow(5, L["Time played"], Played(f[7]))
    SetRow(6, L["Mode"], ironman and L["Hardcore Ironman"] or L["Hardcore"])
    fallen.name = name
    fallen.ironman = ironman
    rest:Enable()
    keep:Enable()
    ShowChoice()
    card:SetHeight(18 + 40 + 8 + title:GetHeight() + 8 + subtitle:GetHeight() + 6 + killedBy:GetHeight() + 30 + 6 * ROW_HEIGHT + note:GetHeight() + 18 + 22 + 22)
    PlaySound("igQuestFailed")
    shade:Show()
end

local function Rested()
    PlaySound("igMainMenuLogout")
    Logout()
end

UI.Listen({
    ["hardcorefell"] = Show,
    ["hardcorerested"] = Rested,
})
