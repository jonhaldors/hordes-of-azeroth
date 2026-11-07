local L = VanillaBonkL
local UI = VanillaBonkUI
local ICON_PATH = "Interface\\Icons\\"
local FONT = VanillaBonkUI.FONT

local VB = {
    tiers = {},
    pendingTiers = {},
    offer = {},
    inRun = false,
}
VanillaBonkRun = VB
VB.ICON_PATH = ICON_PATH
VB.FONT = FONT

local function Split(text, separator)
    local fields = {}
    local start = 1
    while true do
        local found = strfind(text, separator, start, true)
        if not found then
            tinsert(fields, strsub(text, start))
            return fields
        end
        tinsert(fields, strsub(text, start, found - 1))
        start = found + 1
    end
end

VB.Split = Split

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end
VB.Command = Command

local function FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    return format("%d:%02d", floor(seconds / 60), mod(seconds, 60))
end
VB.FormatTime = FormatTime

local function FormatGold(copper)
    copper = tonumber(copper) or 0
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local text = format(L["hoa.addon.cffeda55f_dc_r"], mod(copper, 100))
    if silver > 0 or gold > 0 then
        text = format(L["hoa.addon.cffc7c7cf_ds_r"], silver) .. text
    end
    if gold > 0 then
        text = format(L["hoa.addon.cffffd700_dg_r"], gold) .. text
    end
    return text
end
VB.FormatGold = FormatGold

local function Notice(text)
    UIErrorsFrame:AddMessage(text, 1.0, 0.82, 0.0, 1.0, 5)
end
VB.Notice = Notice

local function SetFont(fontString, size, flags)
    fontString:SetFont(FONT, size, flags or "OUTLINE")
end
VB.SetFont = SetFont

local function DialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end
VB.DialogBackdrop = DialogBackdrop

UI.Module("buffTimers"):Listen({
    VARIABLES_LOADED = function()
        SHOW_BUFF_DURATIONS = "1"
    end,
})

local hiddenBars = CreateFrame("Frame")
hiddenBars:Hide()

for index = 1, 12 do
    getglobal("ActionButton" .. index):SetParent(hiddenBars)
end
for _, name in ipairs({ "BonusActionBarFrame", "ShapeshiftBarFrame", "MultiBarBottomLeft", "MultiBarBottomRight",
        "MultiBarRight", "MultiBarLeft", "ActionBarUpButton", "ActionBarDownButton" }) do
    local frame = getglobal(name)
    if frame then
        frame:SetParent(hiddenBars)
    end
end
for _, name in ipairs({ "MainMenuBarTexture0", "MainMenuBarTexture1", "MainMenuBarTexture2", "MainMenuBarTexture3",
        "MainMenuBarLeftEndCap", "MainMenuBarRightEndCap", "MainMenuBarPageNumber" }) do
    local region = getglobal(name)
    if region then
        region:Hide()
    end
end

UseAction = function() end

local Gossip = UI.Module("gossip")
Gossip.frame = nil
Gossip.pending = nil

function Gossip.TakeOver(pending)
    if not pending then
        return
    end
    if Gossip.frame and Gossip.frame ~= pending.frame then
        Gossip.frame.gossipClosed = true
        Gossip.frame:Hide()
    end
    Gossip.frame = pending.frame
    VB.gossipFrame = Gossip.frame
    if pending.refresh then
        pending.refresh()
    end
    pending.frame:Show()
end

function Gossip.HideBlizzardKeepingOpen()
    local onHide = GossipFrame:GetScript("OnHide")
    GossipFrame:SetScript("OnHide", nil)
    HideUIPanel(GossipFrame)
    GossipFrame:SetScript("OnHide", onHide)
end

function Gossip.ReplaceNext(frame, npc, refresh)
    local pending = { frame = frame, npc = npc, refresh = refresh }
    if GossipFrame:IsShown() and VanillaBonkUI.TalkingTo(npc) then
        Gossip.pending = nil
        VB.gossipPending = nil
        Gossip.HideBlizzardKeepingOpen()
        Gossip.TakeOver(pending)
        return
    end
    Gossip.pending = pending
    VB.gossipPending = pending
end

function Gossip.WindowHidden(frame)
    if Gossip.frame == frame then
        Gossip.frame = nil
        VB.gossipFrame = nil
        if not frame.gossipClosed then
            CloseGossip()
        end
    end
    frame.gossipClosed = nil
end

VB.TakeOverGossip = function(pending)
    Gossip.TakeOver(pending)
end
VB.HideBlizzardGossipKeepingItOpen = function()
    Gossip.HideBlizzardKeepingOpen()
end
VB.ReplaceNextGossip = function(frame, npc, refresh)
    Gossip.ReplaceNext(frame, npc, refresh)
end
VB.GossipWindowHidden = function(frame)
    Gossip.WindowHidden(frame)
end

local BlizzardGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" then
        local pending = Gossip.pending
        Gossip.pending = nil
        VB.gossipPending = nil
        if pending and VanillaBonkUI.TalkingTo(pending.npc) then
            Gossip.TakeOver(pending)
            return
        end
    elseif event == "GOSSIP_CLOSED" and Gossip.frame then
        Gossip.frame.gossipClosed = true
        Gossip.frame:Hide()
    end
    BlizzardGossipOnEvent()
end

local UI = VanillaBonkUI

local ARENA_WIDTH, ARENA_HEIGHT = 920, 660
VB.ARENA_WIDTH, VB.ARENA_HEIGHT = ARENA_WIDTH, ARENA_HEIGHT

local arena = UI.GoldWindow("VanillaBonkArena", ARENA_WIDTH, ARENA_HEIGHT)
arena:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
arena.title:SetText(L["hoa.addon.run_master"])
VB.arena = arena

local content = CreateFrame("Frame", nil, arena)
content:SetAllPoints(arena)
VB.content = content
content:SetFrameLevel(arena:GetFrameLevel() + 2)
arena.content = content

arena.hero = UI.Text(content, 12)
arena.hero:SetPoint("TOPRIGHT", arena, "TOPRIGHT", -36, -20)
arena.hero:SetJustifyH("RIGHT")

local handlers = {}
VB.handlers = handlers

handlers["kwd"] = function(f)
    local id = tonumber(f[2])
    if not id then
        return
    end
    VB.keywords[id] = { name = f[3] or "", icon = f[4] or "", description = f[5] or "" }
    VB.keywordTerms = nil
end

handlers["npcname"] = function(f)
    UI.npcNames[f[2]] = f[3]
    UI.npcNames[f[3]] = f[2]
end

handlers["arena"] = function(f)
    VB.arenaInfo = { goldBonus = tonumber(f[4]) or 0, challenges = f[5] or "", perks = f[6] or "" }
    VB.arenaNpc = f[2] == "1" and f[3] or nil
end

handlers["tier"] = function(f)
    local maps = {}
    for _, item in ipairs(Split(f[10] or "", ",")) do
        if item ~= "" then
            local parts = Split(item, ":")
            tinsert(maps, { icon = parts[1] or "", name = parts[2] or parts[1], type = parts[3], reward = tonumber(parts[4] or ""), key = parts[5] or "" })
        end
    end
    local dungeons = {}
    for _, item in ipairs(Split(f[13] or "", ",")) do
        local parts = Split(item, ":")
        if parts[1] and parts[1] ~= "" then
            tinsert(dungeons, { key = parts[1], icon = parts[2] or "", name = parts[3] or parts[1], open = parts[4] == "1" })
        end
    end
    tinsert(VB.pendingTiers, { id = f[2], key = f[3], name = f[4], unlocked = f[5] == "1", hint = f[6] or "", best = tonumber(f[7]) or 0,
        description = f[8] or "", art = f[9] or "", maps = maps, levels = tonumber(f[11] or "") or 0, open = tonumber(f[12] or "") or 0,
        dungeons = dungeons, details = f[14] or "", firstLevel = tonumber(f[15] or "") })
end

handlers["tiermap"] = function(f)
    local tier = VB.pendingTiers[table.getn(VB.pendingTiers)]
    if not tier or tier.id ~= f[2] or not f[3] or f[3] == "" then
        return
    end
    local parts = Split(f[3], ":")
    tinsert(tier.maps, { icon = parts[1] or "", name = parts[2] or parts[1], type = parts[3], reward = tonumber(parts[4] or ""), key = parts[5] or "" })
end

handlers["starter"] = function(f)
    tinsert(VB.pendingStarters, { id = f[2], icon = f[3] or "", name = f[4] or "", unlocked = f[5] == "1", chosen = f[6] == "1",
        hint = f[7] or "", description = f[8] or "" })
end

handlers["starterend"] = function()
    VB.starters = VB.pendingStarters
    VB.pendingStarters = {}
    if arena:IsShown() then
        VB.RefreshStarters()
    end
end

handlers["tierend"] = function()
    VB.tiers = VB.pendingTiers
    VB.pendingTiers = {}
    if VB.arenaNpc then
        Gossip.ReplaceNext(arena, VB.arenaNpc, VB.RefreshArena)
        VB.arenaNpc = nil
    elseif arena:IsShown() then
        VB.RefreshArena()
    elseif VB.arenaRequested then
        VB.arenaRequested = nil
        VB.RefreshArena()
        arena:Show()
    end
end

local CombatLog = UI.Module("combatLog")
CombatLog.quiet = false

function CombatLog:IsGroup(group)
    return strsub(group, 1, 7) == "COMBAT_" or strsub(group, 1, 6) == "SPELL_"
end

function CombatLog:SetQuiet(quiet)
    if quiet == self.quiet or not ChatTypeGroup then
        return
    end
    self.quiet = quiet
    for index = 1, NUM_CHAT_WINDOWS do
        local chat = getglobal("ChatFrame" .. index)
        if chat then
            if quiet then
                for group, chatEvents in pairs(ChatTypeGroup) do
                    if self:IsGroup(group) then
                        for _, chatEvent in ipairs(chatEvents) do
                            chat:UnregisterEvent(chatEvent)
                        end
                    end
                end
            elseif chat.messageTypeList then
                for _, group in ipairs(chat.messageTypeList) do
                    if self:IsGroup(group) and ChatTypeGroup[group] then
                        for _, chatEvent in ipairs(ChatTypeGroup[group]) do
                            chat:RegisterEvent(chatEvent)
                        end
                    end
                end
            end
        end
    end
end

UI.ListenHoa({
    HOA_RUN_START = function(start)
        VB.inRun = true
        CombatLog:SetQuiet(true)
        VB.duration = tonumber(start.duration_s) or 0
        VB.results:Hide()
        arena:Hide()
        if VB.shopFrame then
            VB.shopFrame:Hide()
        end
    end,
    HOA_RUN_STATE = function()
        VB.inRun = true
        CombatLog:SetQuiet(true)
    end,
})

UI.ListenHoa({
    HOA_CODEX = function(entry)
        if entry.kind ~= "kwd" then
            return
        end
        local f = { false, entry.kind }
        for _, part in ipairs(Split(entry.line or "", "~")) do
            tinsert(f, part)
        end
        handlers[entry.kind](f)
    end,
    HOA_STATS = function(stats)
        handlers["stats"]({ false, stats.in_run and "1" or "0", stats.caps, stats.after_caps })
    end,
    HOA_GEAR = function(gear)
        handlers["gear"]({ false, tostring(gear.id), gear.stats })
    end,
    HOA_GEAR_END = function()
        handlers["gearend"]()
    end,
    HOA_ARENA = function(arena)
        handlers["arena"]({
            false, arena.npc_present and "1" or "0", arena.npc, arena.gold_bonus, arena.challenges, arena.perks,
        })
    end,
    HOA_TIER = function(tier)
        handlers["tier"]({
            false, tostring(tier.id), tier.key, tier.name, tier.unlocked and "1" or "0", tier.hint, tier.best,
            tier.description, tier.art, tier.maps, tier.levels, tier.open_level, tier.dungeons, tier.details,
            tier.first_level,
        })
    end,
    HOA_TIER_END = function()
        handlers["tierend"]()
    end,
    HOA_SHOP_OPEN = function(shop)
        local kind = tostring(shop.kind)
        if kind == VB.FORTUNE_SHOP then
            handlers["shop"]({
                false, kind, shop.open and "1" or "0", shop.npc, shop.currency, shop.balance, shop.gates,
                shop.coop_guest and "1" or "0",
            })
        else
            handlers["shop"]({
                false, kind, shop.open and "1" or "0", shop.npc, shop.currency, shop.balance, shop.level, shop.xp,
                shop.xp_next, shop.max_level, shop.earned, shop.from_quests, shop.class_name, shop.points_per_row,
                shop.inspect and "1" or "0",
            })
        end
    end,
    HOA_SHOP_TREE = function(tree)
        handlers["tree"]({ false, tostring(tree.id), tree.name, tree.background, tree.spent })
    end,
    HOA_MASTERY_TREE = function(tree)
        handlers["tree"]({ false, tostring(tree.id), tree.name, tree.background, tree.layout, tree.gates, tree.spent })
    end,
    HOA_SHOP_NODE = function(node)
        handlers["node"]({
            false, tostring(node.tree), tostring(node.id), node.row, node.column, node.icon, node.rank, node.max_rank,
            node.cost, tostring(node.required_id), node.required_rank, node.toggle and "1" or "0",
            node.enabled and "1" or "0", node.name, node.description, node.locked and "1" or "0", node.quest,
            node.value_per_rank, node.refund, node.quest_description, node.rank_lock,
        })
    end,
    HOA_MASTERY_NODE = function(node)
        handlers["node"]({
            false, tostring(node.tree), tostring(node.id), node.row, node.column, node.icon, node.rank, node.max_rank,
            node.cost, tostring(node.required_id), node.required_rank, "0", "0", node.name, node.description, "0", "",
            node.value_per_rank, node.refund, node.shape, node.position, node.parents, node.excludes,
        })
    end,
    HOA_MASTERY_PRESETS = function(presets)
        handlers["presets"]({ false, presets.active, presets.points_1, presets.points_2, presets.points_3 })
    end,
    HOA_MASTERY_PRESET_RANKS = function(ranks)
        handlers["presetranks"]({ false, ranks.preset, ranks.ranks })
    end,
    HOA_SHOP_END = function()
        handlers["shopend"]()
    end,
    HOA_SHOP_CLOSE = function()
        handlers["shopclose"]()
    end,
    HOA_STARTER = function(starter)
        handlers["starter"]({
            false, tostring(starter.id), starter.icon, starter.name, starter.unlocked and "1" or "0",
            starter.chosen and "1" or "0", starter.hint, starter.description,
        })
    end,
    HOA_STARTER_END = function()
        handlers["starterend"]()
    end,
    HOA_NPC_NAME = function(name)
        handlers["npcname"]({ false, name.name, name.npc_name })
    end,
    HOA_MESSAGE = function(message)
        handlers["msg"]({ false, message.text })
    end,
    HOA_FIND = function(find)
        handlers["find"]({ false, find.text })
    end,
    HOA_SHARD = function()
        handlers["shard"]()
    end,
    HOA_VALOR = function()
        handlers["valor"]()
    end,
    HOA_OFFER_OPEN = function(offer)
        handlers["offer"]({ false, offer.level, offer.count, offer.source, offer.rerolls, offer.banishes, offer.skips })
    end,
    HOA_OFFER_OPTION = function(option)
        handlers["opt"]({
            false, tostring(option.index), option.kind, option.new_level, option.max_level, option.name, option.icon,
            option.description, option.rarity, option.locked and "1" or "0", option.damage_before, option.damage_after,
            option.damage_label, option.banishable and "1" or "0",
        })
    end,
    HOA_OFFER_STAT = function(stat)
        handlers["ostat"]({ false, tostring(stat.index), stat.label, stat.before, stat.after })
    end,
    HOA_OFFER_END = function()
        handlers["offerend"]()
    end,
    HOA_OFFER_CLOSED = function()
        handlers["picked"]()
    end,
    HOA_LEY_OPEN = function()
        handlers["leyoffer"]()
    end,
    HOA_LEY_OPTION = function(option)
        handlers["leyopt"]({
            false, tostring(option.index), option.name, option.icon, option.description, option.rarity, option.kind,
            option.new_level, option.max_level,
        })
    end,
    HOA_LEY_END = function()
        handlers["leyofferend"]()
    end,
    HOA_LEY_CLOSED = function()
        handlers["leyofferclose"]()
    end,
})

UI.ListenHoa({
    HOA_COOP_NO_PAUSE = function(state)
        VB.sideOffers = state.no_pause and true or false
    end,
    HOA_RUN_END = function(ending)
        VB.inRun = false
        VB.sideOffers = false
        if VanillaBonkUI.InspectShown() and VB.shopFrame then
            VB.shopFrame:Hide()
        end
        CombatLog:SetQuiet(false)
        VB.offer = {}
        VB.offerFrame:Hide()
        if ending.victory then
            VB.results.title:SetText(L["hoa.addon.cffffd100victory_r"])
            PlaySound("QUESTCOMPLETED")
        elseif ending.went_home then
            VB.results.title:SetText(L["hoa.addon.cff20ff20run_complete_r"])
            PlaySound("QUESTCOMPLETED")
        else
            VB.results.title:SetText(L["hoa.addon.cffff3030defeated_r"])
        end
        VB.results.body:SetText(L("hoa.addon.reached_stage_1_in_2", ending.stage or "1", FormatTime(ending.seconds)) .. "\n" ..
            L("hoa.addon.kills_1_level_2", ending.kills, ending.player_level) .. "\n" ..
            L("hoa.addon.gold_earned_1", FormatGold(ending.gold)) .. "\n" ..
            L("hoa.addon.darkmoon_tickets_cffc080ff_1_r", ending.shards or "0") .. "\n\n" ..
            L["hoa.addon.cffaaaaaareturning_to_the_inn_r"])
        VB.results:Show()
    end,
})

handlers["msg"] = function(f)
    Notice(f[2])
end

handlers["find"] = function(f)
    UIErrorsFrame:AddMessage(f[2], 0.3, 0.8, 1.0, 1.0, 10)
    PlaySound("igQuestListComplete")
end

handlers["shard"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

handlers["valor"] = function()
    PlaySound("LOOTWINDOWCOINSOUND")
end

local Shield = UI.Module("shield")
Shield.value = 0
Shield.bar = CreateFrame("StatusBar", "VanillaBonkShieldBar", PlayerFrame)
Shield.bar:SetAllPoints(PlayerFrameHealthBar)
Shield.bar:SetFrameLevel(PlayerFrameHealthBar:GetFrameLevel() + 1)
VanillaBonkUI.DressShield(Shield.bar)
Shield.bar:Hide()
VB.shield = 0

function Shield:Refresh()
    local maxHealth = UnitHealthMax("player")
    if self.value <= 0 or not maxHealth or maxHealth <= 0 then
        self.bar:Hide()
        return
    end
    self.bar:SetValue(min(1, self.value / maxHealth))
    self.bar:Show()
end

function Shield:Set(value)
    self.value = value
    VB.shield = value
    self:Refresh()
end

UI.ListenHoa({
    HOA_AURA_VALUE = function(spellId, value)
        if tonumber(spellId) == HOA_AURA_IDS.shield then
            Shield:Set(tonumber(value) or 0)
        end
    end,
})

UI.Module("shieldEvents"):Listen({
    UNIT_MAXHEALTH = function(unit)
        if unit == "player" then
            Shield:Refresh()
        end
    end,
})

UI.Module("enterWorld"):OnEnterWorld(function()
    VB.lastMoney = GetMoney()
    if not VB.helloSent then
        VB.helloSent = true
        Command("hello " .. UI.Language())
    end
end)
UI.Module("enterWorld"):OnMoney(function()
    VB.PlayPurchaseSound()
    if VB.shopFrame and VB.shopFrame:IsShown() then
        VB.RefreshShop()
    end
end)

function UI.NavPrompt(box, primary, second)
    box.navButtons = { primary, second }
    UI.navPrompts = UI.navPrompts or {}
    tinsert(UI.navPrompts, box)
end
