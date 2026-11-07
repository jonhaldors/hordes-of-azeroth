local L = VanillaBonkL
local UI = VanillaBonkUI
local VB = VanillaBonkRun
local Command = VB.Command
local GossipWindowHidden = VB.GossipWindowHidden
local ICON_PATH = VB.ICON_PATH
local Split = VB.Split
local arena = VB.arena
local content = VB.content
local ARENA_WIDTH, ARENA_HEIGHT = VB.ARENA_WIDTH, VB.ARENA_HEIGHT
local STARTER_SIZE, STARTER_STEP = 28, 34
local LOADOUT_X, LOADOUT_TOP, LOADOUT_WIDTH = 22, 252, 214
local Starters = UI.Module("starters")

local LOADOUT_GREY = { 0.51, 0.49, 0.44 }

arena.loadoutDivider = UI.Divider(content, LOADOUT_WIDTH)
arena.loadoutDivider:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP - 14))
arena.loadoutLabel = UI.Text(content, 11)
arena.loadoutLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -LOADOUT_TOP)
arena.loadoutLabel:SetTextColor(1, 0.82, 0)
arena.loadoutLabel:SetText(L["hoa.addon.loadout"])

arena.challengesLabel = UI.Text(content, 10)
arena.challengesLabel:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 84))
arena.challengesLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.challengesLabel:SetText(L["hoa.addon.dark_fortunes"])
arena.challenges = UI.Text(content, 10)
arena.challenges:SetPoint("TOPRIGHT", arena, "TOPLEFT", LOADOUT_X + LOADOUT_WIDTH, -(LOADOUT_TOP + 84))
arena.challenges:SetWidth(120)
arena.challenges:SetJustifyH("RIGHT")

arena.perksLabel = UI.Text(content, 10)
arena.perksLabel:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.perksLabel:SetText(L["hoa.addon.perks"])
arena.perks = UI.Text(content, 10)
arena.perks:SetPoint("TOPRIGHT", arena.challenges, "BOTTOMRIGHT", 0, -5)
arena.perks:SetWidth(140)
arena.perks:SetJustifyH("RIGHT")
arena.perksLabel:SetPoint("LEFT", arena, "LEFT", LOADOUT_X, 0)
arena.perksLabel:SetPoint("TOP", arena.perks, "TOP", 0, 0)

arena.pauseCheck = CreateFrame("CheckButton", "VanillaBonkArenaPause", content, "UICheckButtonTemplate")
arena.pauseCheck:SetWidth(22)
arena.pauseCheck:SetHeight(22)
arena.pauseCheck:SetPoint("LEFT", arena, "LEFT", LOADOUT_X - 4, 0)
arena.pauseCheck:SetPoint("TOP", arena.perks, "BOTTOM", 0, -6)
arena.pauseCheck.label = UI.Text(arena.pauseCheck, 10)
arena.pauseCheck.label:SetPoint("LEFT", arena.pauseCheck, "RIGHT", 2, 0)
arena.pauseCheck.label:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
arena.pauseCheck.label:SetText(L["hoa.addon.pause_on_rewards"])
arena.pauseCheck:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    UI.SetOption("pauseOnChoices", this:GetChecked() and true or false)
end)
UI.Hover(arena.pauseCheck, function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["hoa.addon.pause_on_rewards"], 1, 1, 1)
    GameTooltip:AddLine(L["hoa.addon.when_disabled_rewards_appear_at_the_bottom_of_the_screen_and"], 1, 0.82, 0, 1)
    GameTooltip:Show()
end)

VB.starters = {}
VB.pendingStarters = {}

function Starters:Chosen()
    for _, option in ipairs(VB.starters) do
        if option.chosen then
            return option
        end
    end
end

function Starters:ShowTooltip(owner, option)
    if not option then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    if option.unlocked then
        GameTooltip:AddLine(option.name, 1, 0.82, 0)
    else
        GameTooltip:AddLine(option.name, 0.6, 0.6, 0.6)
    end
    GameTooltip:AddLine(option.description, 1, 1, 1, 1)
    if option.chosen then
        GameTooltip:AddLine(L["hoa.addon.your_runs_start_with_this_spell"], 0.25, 1, 0.25, 1)
    elseif option.unlocked then
        GameTooltip:AddLine(L["hoa.addon.click_to_make_this_your_starter_spell"], 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(option.hint, 1, 0.3, 0.3, 1)
    end
    GameTooltip:Show()
end

function Starters:Choose(option)
    if not option or option.chosen or not option.unlocked or VB.inRun then
        return
    end
    PlaySound("igMainMenuOptionCheckBoxOn")
    Command("starter " .. option.id)
end

function Starters:SetIcon(texture, option)
    texture:SetTexture(ICON_PATH .. (option and option.icon ~= "" and option.icon or "INV_Misc_QuestionMark"))
    SetDesaturation(texture, option and not option.unlocked)
end

local starterBox = CreateFrame("Frame", nil, content)
starterBox:SetPoint("TOPLEFT", arena, "TOPLEFT", LOADOUT_X, -(LOADOUT_TOP + 26))
starterBox:SetWidth(LOADOUT_WIDTH)
starterBox:SetHeight(48)
starterBox.label = UI.Text(starterBox, 10)
starterBox.label:SetPoint("TOPLEFT", starterBox, "TOPLEFT", 0, 0)
starterBox.label:SetTextColor(LOADOUT_GREY[1], LOADOUT_GREY[2], LOADOUT_GREY[3])
starterBox.label:SetText(L["hoa.addon.starter_spell"])
starterBox.name = UI.Text(starterBox, 11)
starterBox.name:SetJustifyH("LEFT")
starterBox.slots = {}

function Starters:StarterSlot(index)
    local slot = starterBox.slots[index]
    if not slot then
        slot = CreateFrame("Button", nil, starterBox)
        slot:SetWidth(STARTER_SIZE)
        slot:SetHeight(STARTER_SIZE)
        slot:SetPoint("TOPLEFT", starterBox, "TOPLEFT", (index - 1) * STARTER_STEP, -16)
        slot:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
        slot.icon = slot:CreateTexture(nil, "ARTWORK")
        slot.icon:SetPoint("TOPLEFT", slot, "TOPLEFT", 1, -1)
        slot.icon:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 1)
        UI.CropIcon(slot.icon)
        slot:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
        slot:SetScript("OnClick", function() Starters:Choose(this.option) end)
        UI.Hover(slot, function() Starters:ShowTooltip(this, this.option) end)
        slot.glow = slot:CreateTexture(nil, "OVERLAY")
        slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        slot.glow:SetBlendMode("ADD")
        slot.glow:SetVertexColor(1, 0.82, 0)
        slot.glow:SetWidth(STARTER_SIZE * 1.8)
        slot.glow:SetHeight(STARTER_SIZE * 1.8)
        slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
        starterBox.slots[index] = slot
    end
    return slot
end

function Starters:Refresh()
    if getn(VB.starters) == 0 then
        starterBox:Hide()
        return
    end
    for _, slot in ipairs(starterBox.slots) do
        slot:Hide()
    end
    local chosen = Starters:Chosen()
    local last
    for index, option in ipairs(VB.starters) do
        local slot = Starters:StarterSlot(index)
        slot.option = option
        Starters:SetIcon(slot.icon, option)
        if option.chosen then
            slot.icon:SetVertexColor(1, 1, 1)
            slot:SetBackdropBorderColor(1, 0.82, 0, 1)
            slot.glow:Show()
        else
            slot.icon:SetVertexColor(0.6, 0.6, 0.6)
            slot:SetBackdropBorderColor(0, 0, 0, 1)
            slot.glow:Hide()
        end
        slot:Show()
        last = slot
    end
    starterBox.name:ClearAllPoints()
    starterBox.name:SetPoint("LEFT", last, "RIGHT", 10, 0)
    starterBox.name:SetText(chosen and chosen.name or "")
    starterBox:Show()
end

arena.button = UI.Button(content, 140, L["hoa.addon.start_run"], function()
    local tier = arena.tier
    if not tier or not tier.unlocked or VB.inRun or not VanillaBonkRunMaster.CanStart(tier) then
        return
    end
    Command("start " .. VanillaBonkRunMaster.StartArgs(tier))
    arena:Hide()
end)
arena.button:SetWidth(262)
arena.button:SetHeight(38)
arena.button:SetPoint("TOPLEFT", arena, "TOPLEFT", 560 + (ARENA_WIDTH - 22 - 560 - 262) / 2, -(ARENA_HEIGHT - 62))
arena.button:SetText("")
arena.button.label = UI.Text(arena.button, 15)
arena.button.label:SetPoint("CENTER", arena.button, "CENTER", 0, 0)
arena.button.label:SetTextColor(1, 0.82, 0)

arena:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    arena.title:SetText(UnitExists("npc") and UnitName("npc") or L["hoa.addon.run_master"])
    local _, classToken = UnitClass("player")
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[classToken]
    local name = UnitName("player") or ""
    if color then
        name = format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, name)
    end
    arena.hero:SetText(name .. "|cffffffff, " .. (UI.PlayerClassName() or "") .. "|r")
end)

arena:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    GossipWindowHidden(arena)
end)

local ShowArenaDetail

ShowArenaDetail = function(tier)
    arena.tier = tier
    Starters:Refresh()
    if GetNumPartyMembers() > 0 then
        arena.pauseCheck:Hide()
    else
        arena.pauseCheck:SetChecked(UI.Option("pauseOnChoices", true))
        arena.pauseCheck:Show()
    end
    VanillaBonkRunMaster.Show(tier)
    if not tier.unlocked then
        arena.button.label:SetText(L["hoa.addon.locked"])
        arena.button:Disable()
    elseif not VanillaBonkRunMaster.CanStart(tier) then
        arena.button.label:SetText(L["hoa.addon.start_run"])
        arena.button:Disable()
    else
        arena.button.label:SetText(L["hoa.addon.start_run"])
        arena.button:Enable()
    end
end

local RefreshArena

RefreshArena = function()
    local selected
    for _, tier in ipairs(VB.tiers) do
        if tier.id == VB.arenaSelected then
            selected = tier
        end
    end
    if not selected then
        for _, tier in ipairs(VB.tiers) do
            if tier.unlocked or not selected then
                selected = tier
            end
        end
        VB.arenaSelected = selected and selected.id
    end

    VanillaBonkRunMaster.SetTiers(VB.tiers, VB.arenaSelected, function(tier)
        VB.arenaSelected = tier.id
        RefreshArena()
    end)
    if selected then
        ShowArenaDetail(selected)
    end

    local info = VB.arenaInfo or {}
    if info.challenges and info.challenges ~= "" then
        local lines = ""
        for _, name in ipairs(UI.Split(info.challenges, ",")) do
            local trimmed = gsub(name, "^%s+", "")
            if trimmed ~= "" then
                lines = lines .. (lines ~= "" and ", " or "") .. trimmed
            end
        end
        arena.challenges:SetText("|cffffffff" .. lines .. "|r |cffffe873" .. L("hoa.addon.1_gold", info.goldBonus or 0) .. "|r")
    else
        arena.challenges:SetText(L["hoa.addon.cff9d9d9dnone_r"])
    end
    if info.perks and info.perks ~= "" then
        arena.perks:SetText("|cffffffff" .. gsub(info.perks, ", ", "\n") .. "|r")
    else
        arena.perks:SetText(L["hoa.addon.cff9d9d9dnone_yet_r"])
    end
end

VB.RefreshArena = RefreshArena

StaticPopupDialogs["VANILLABONK_LEAVE_RUN"] = {
    text = L["hoa.addon.end_this_run_it_counts_as_a_defeat_you_keep_the_gold_and_dar"],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        Command("stop")
    end,
    timeout = 0,
    whileDead = 1,
}

SLASH_VANILLABONK1 = "/bonk"
SlashCmdList["VANILLABONK"] = function(message)
    if message == "stop" then
        Command("stop")
    elseif VB.inRun then
        StaticPopup_Show("VANILLABONK_LEAVE_RUN")
    elseif arena:IsShown() then
        arena:Hide()
    else
        VB.arenaRequested = true
        Command("hello " .. UI.Language())
    end
end


VB.RefreshStarters = function() Starters:Refresh() end
