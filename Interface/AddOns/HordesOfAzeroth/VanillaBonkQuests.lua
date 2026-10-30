local L = VanillaBonkL
local PREFIX = "BONK~"
local FLAT = "Interface\\Buttons\\WHITE8X8"
local FONT = "Fonts\\FRIZQT__.TTF"
local NUMBER_FONT = "Fonts\\ARIALN.TTF"
local ICON_PATH = "Interface\\Icons\\"

local WIDTH = 600
local HEIGHT = 437
local LIST_HEIGHT = 336
local ROW_HEIGHT = 56

local quests = {}
local incoming
local pendingNpc
local openRequested

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

local function SetFont(fontString, font, size, flags)
    fontString:SetFont(font, size, flags or "")
end

local UI = VanillaBonkUI

local board = UI.Window("VanillaBonkQuestBoard", WIDTH, HEIGHT)
board:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
board.title:SetText(L["Quest Board"])

board.pane = UI.Pane(board, UI.CONTENT_LEFT, UI.CONTENT_TOP, WIDTH - UI.CONTENT_LEFT - UI.CONTENT_RIGHT,
    HEIGHT - UI.CONTENT_TOP - UI.CONTENT_BOTTOM, "Interface\\Glues\\LoadingScreens\\LoadScreenStormwindStockade", 0.65)
board.pane:SetFrameLevel(board:GetFrameLevel() + 1)

local CATEGORIES = {
    { key = "slayer", label = L["Slayer"] },
    { key = "victory", label = L["Victory"] },
    { key = "mastery", label = L["Mastery"] },
    { key = "challenge", label = L["Challenge"] },
    { key = "discovery", label = L["Discovery"] },
    { key = "collection", label = L["Collection"] },
}
board.tab = "all"
board.tabKeys = {}
local RefreshBoard

board.scroll = CreateFrame("ScrollFrame", "VanillaBonkQuestScroll", board, "UIPanelScrollFrameTemplate")
board.scroll:SetPoint("TOPLEFT", board, "TOPLEFT", 26, -80)
board.scroll:SetWidth(WIDTH - 78)
board.scroll:SetHeight(LIST_HEIGHT)
board.scroll:SetFrameLevel(board.pane:GetFrameLevel() + 2)

board.list = CreateFrame("Frame", nil, board.scroll)
board.list:SetWidth(WIDTH - 78)
board.list:SetHeight(LIST_HEIGHT)
board.scroll:SetScrollChild(board.list)

board.rows = {}

local function RewardTooltip()
    if not this.reward or this.reward == "" then
        return
    end
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:AddLine(L["Reward"], 1, 0.82, 0)
    GameTooltip:AddLine(this.reward, 1, 1, 1, 1)
    GameTooltip:Show()
end

local BAR_WIDTH = 220

local function CreateRow(index)
    local row = UI.Strip(board.list)
    row:SetWidth(WIDTH - 82)
    row:SetHeight(ROW_HEIGHT - 6)

    row.slot = UI.Slot(row, 34, "Frame")
    row.slot:SetPoint("LEFT", row, "LEFT", 10, 0)
    row.icon = row.slot.icon

    row.name = UI.Text(row, 13)
    row.name:SetPoint("TOPLEFT", row.slot, "TOPRIGHT", 12, 3)

    row.description = UI.Text(row, 11)
    row.description:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -2)
    row.description:SetWidth(WIDTH - 330)
    row.description:SetJustifyH("LEFT")

    row.barBack = row:CreateTexture(nil, "ARTWORK")
    row.barBack:SetTexture(FLAT)
    row.barBack:SetVertexColor(0, 0, 0, 0.7)
    row.barBack:SetWidth(BAR_WIDTH)
    row.barBack:SetHeight(9)
    row.barBack:SetPoint("BOTTOMLEFT", row.slot, "BOTTOMRIGHT", 14, 0)

    row.bar = row:CreateTexture(nil, "ARTWORK")
    row.bar:SetTexture("Interface\\TargetingFrame\\UI-StatusBar")
    row.bar:SetHeight(9)
    row.bar:SetPoint("LEFT", row.barBack, "LEFT", 0, 0)

    row.barBorder = row:CreateTexture(nil, "OVERLAY")
    row.barBorder:SetTexture("Interface\\PaperDollInfoFrame\\UI-Character-Skills-BarBorder")
    row.barBorder:SetPoint("TOPLEFT", row.barBack, "TOPLEFT", -5, 7)
    row.barBorder:SetPoint("BOTTOMRIGHT", row.barBack, "BOTTOMRIGHT", 5, -7)

    row.progress = UI.Text(row, 10, NUMBER_FONT, "OUTLINE")
    row.progress:SetPoint("CENTER", row.barBack, "CENTER", 0, 0)

    row.rewardButton = CreateFrame("Button", nil, row)
    row.rewardButton:SetWidth(30)
    row.rewardButton:SetHeight(30)
    row.rewardButton:SetPoint("RIGHT", row, "RIGHT", -130, 0)
    row.rewardButton:SetScript("OnEnter", RewardTooltip)
    row.rewardButton:SetScript("OnLeave", function() GameTooltip:Hide() end)
    row.rewardIcon = row.rewardButton:CreateTexture(nil, "ARTWORK")
    row.rewardIcon:SetAllPoints(row.rewardButton)

    row.rewardText = UI.Text(row, 10)
    row.rewardText:SetPoint("LEFT", row.rewardButton, "RIGHT", 7, 0)
    row.rewardText:SetWidth(118)
    row.rewardText:SetHeight(30)
    row.rewardText:SetJustifyH("LEFT")

    row.check = row.rewardButton:CreateTexture(nil, "OVERLAY")
    row.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    row.check:SetWidth(26)
    row.check:SetHeight(26)
    row.check:SetPoint("CENTER", row.rewardButton, "CENTER", 0, 0)

    board.rows[index] = row
    return row
end

local function QuestTab(quest)
    if quest.class then
        return "class"
    end
    return quest.category ~= "" and quest.category or "all"
end

local function SortedQuests()
    local list = {}
    for _, quest in ipairs(quests) do
        if QuestTab(quest) == board.tab then
            tinsert(list, quest)
        end
    end
    table.sort(list, function(a, b)
        if a.done ~= b.done then
            return not a.done
        end
        local fa, fb = a.progress / max(1, a.amount), b.progress / max(1, b.amount)
        if fa ~= fb then
            return fa > fb
        end
        return a.id < b.id
    end)
    return list
end

function RefreshBoard()
    local present = {}
    for _, quest in ipairs(quests) do
        present[QuestTab(quest)] = true
    end
    local keys, labels = {}, {}
    if present["all"] then
        tinsert(keys, "all")
        tinsert(labels, L["General"])
    end
    for _, category in ipairs(CATEGORIES) do
        if present[category.key] then
            tinsert(keys, category.key)
            tinsert(labels, category.label)
        end
    end
    if present["class"] then
        tinsert(keys, "class")
        tinsert(labels, L("{1} quests", UI.PlayerClassName() or L["Class"]))
    end
    if table.getn(keys) == 0 then
        tinsert(keys, "all")
        tinsert(labels, L["General"])
    end

    local selected = 1
    for index, key in ipairs(keys) do
        if key == board.tab then
            selected = index
        end
    end
    board.tab = keys[selected]
    board.tabKeys = keys
    UI.Tabs(board, labels, function(id)
        board.tab = board.tabKeys[id] or "all"
        RefreshBoard()
    end)
    UI.SelectTab(board, selected)

    local list = SortedQuests()
    local done = 0
    for index, quest in ipairs(list) do
        local row = board.rows[index] or CreateRow(index)
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", board.list, "TOPLEFT", 0, -(index - 1) * ROW_HEIGHT)
        row.icon:SetTexture(ICON_PATH .. (quest.icon ~= "" and quest.icon or "INV_Misc_Note_01"))
        row.name:SetText(quest.name)
        row.description:SetText(quest.description)
        row.rewardIcon:SetTexture(ICON_PATH .. (quest.rewardIcon ~= "" and quest.rewardIcon or "INV_Misc_QuestionMark"))
        row.rewardButton.reward = quest.reward
        row.rewardText:SetText(quest.reward)

        local fraction = min(1, quest.progress / max(1, quest.amount))
        row.bar:SetWidth(max(1, BAR_WIDTH * fraction))
        if quest.done then
            done = done + 1
            UI.SetStripHighlight(row, false)
            row:SetBackdropColor(0.03, 0.12, 0.03, 0.7)
            row.name:SetTextColor(0.4, 1, 0.4)
            row.bar:SetVertexColor(0.25, 0.8, 0.25)
            row.progress:SetText(L["Complete"])
            row.rewardText:SetTextColor(0.6, 0.6, 0.6)
            row.check:Show()
            SetDesaturation(row.rewardIcon, 1)
        else
            UI.SetStripHighlight(row, false)
            row.name:SetTextColor(1, 0.82, 0)
            row.bar:SetVertexColor(0.95, 0.72, 0.2)
            row.progress:SetText(quest.progress .. " / " .. quest.amount)
            row.rewardText:SetTextColor(1, 1, 1)
            row.check:Hide()
            SetDesaturation(row.rewardIcon, nil)
        end
        row:Show()
    end
    for index = table.getn(list) + 1, table.getn(board.rows) do
        board.rows[index]:Hide()
    end

    board.list:SetHeight(max(LIST_HEIGHT, table.getn(list) * ROW_HEIGHT))
    board.scroll:UpdateScrollChildRect()
    board.headerRight:SetText("|cffffffff" .. done .. " / " .. table.getn(list) .. L[" done|r"])
    board.scroll:SetVerticalScroll(0)
end

board:SetScript("OnShow", function()
    PlaySound("igQuestLogOpen")
    UI.SetPortrait(board)
    board.header:SetText(UnitExists("npc") and UnitName("npc") or L["Quest Board"])
end)

board:SetScript("OnHide", function()
    PlaySound("igQuestLogClose")
    if board.fromGossip then
        board.fromGossip = nil
        if not board.gossipClosed then
            CloseGossip()
        end
    end
    board.gossipClosed = nil
end)

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and pendingNpc then
        local npc = pendingNpc
        pendingNpc = nil
        if UI.TalkingTo(npc) then
            RefreshBoard()
            board.fromGossip = true
            board:Show()
            return
        end
    elseif event == "GOSSIP_CLOSED" and board.fromGossip and board:IsShown() then
        board.gossipClosed = true
        board:Hide()
    end
    PreviousGossipOnEvent()
end

SLASH_VANILLABONKQUESTS1 = "/quests"
SlashCmdList["VANILLABONKQUESTS"] = function()
    if board:IsShown() then
        board:Hide()
        return
    end
    if table.getn(quests) > 0 then
        RefreshBoard()
        board:Show()
    else
        openRequested = true
    end
    SendChatMessage(".bonk quests", "SAY")
end

local TOAST_WIDTH = 340
local TOAST_TEXT = TOAST_WIDTH - 10 - 44 - 10 - 12
local TOAST_NAME_SIZE = 15
local toast = CreateFrame("Frame", "VanillaBonkQuestToast", UIParent)
toast:SetWidth(TOAST_WIDTH)
toast:SetHeight(64)
toast:SetPoint("TOP", UIParent, "TOP", 0, -170)
toast:SetFrameStrata("HIGH")
toast:SetBackdrop({
    bgFile = FLAT, edgeFile = FLAT, edgeSize = 1,
    insets = { left = 1, right = 1, top = 1, bottom = 1 },
})
toast:SetBackdropColor(0.04, 0.04, 0.04, 0.9)
toast:SetBackdropBorderColor(1, 0.82, 0, 1)
toast:Hide()

toast.icon = toast:CreateTexture(nil, "ARTWORK")
toast.icon:SetWidth(44)
toast.icon:SetHeight(44)
toast.icon:SetPoint("LEFT", toast, "LEFT", 10, 0)

toast.header = toast:CreateFontString(nil, "OVERLAY")
SetFont(toast.header, FONT, 11)
toast.header:SetPoint("TOPLEFT", toast, "TOPLEFT", 64, -9)
toast.header:SetTextColor(1, 0.82, 0)
toast.header:SetText(L["QUEST COMPLETE"])

toast.name = toast:CreateFontString(nil, "OVERLAY")
SetFont(toast.name, FONT, TOAST_NAME_SIZE, "OUTLINE")
toast.name:SetPoint("TOPLEFT", toast.header, "BOTTOMLEFT", 0, -3)
toast.name:SetWidth(TOAST_TEXT)
toast.name:SetJustifyH("LEFT")

toast.reward = toast:CreateFontString(nil, "OVERLAY")
SetFont(toast.reward, FONT, 11)
toast.reward:SetPoint("TOPLEFT", toast.name, "BOTTOMLEFT", 0, -3)
toast.reward:SetWidth(TOAST_TEXT)
toast.reward:SetJustifyH("LEFT")
toast.reward:SetTextColor(0.6, 1, 0.6)

toast.queue = {}
toast.time = 0

local TOAST_SECONDS = 5
local TOAST_FADE = 0.6

local function NextToast()
    local entry = tremove(toast.queue, 1)
    if not entry then
        toast:Hide()
        return
    end
    toast.icon:SetTexture(ICON_PATH .. (entry.icon ~= "" and entry.icon or "INV_Misc_QuestionMark"))
    local size = TOAST_NAME_SIZE
    SetFont(toast.name, FONT, size, "OUTLINE")
    toast.name:SetText(entry.name)
    while size > 11 and toast.name:GetHeight() > (size + 2) * 2 do
        size = size - 1
        SetFont(toast.name, FONT, size, "OUTLINE")
    end
    toast.reward:SetText(entry.reward)
    toast:SetHeight(max(64, 9 + toast.header:GetHeight() + 3 + toast.name:GetHeight() + 3 + toast.reward:GetHeight() + 10))
    toast.time = 0
    toast:SetAlpha(0)
    toast:Show()
    PlaySound("QUESTCOMPLETED")
end

toast:SetScript("OnUpdate", function()
    this.time = this.time + arg1
    if this.time < TOAST_FADE then
        this:SetAlpha(this.time / TOAST_FADE)
    elseif this.time > TOAST_SECONDS - TOAST_FADE then
        this:SetAlpha(max(0, (TOAST_SECONDS - this.time) / TOAST_FADE))
    else
        this:SetAlpha(1)
    end
    if this.time >= TOAST_SECONDS then
        NextToast()
    end
end)

local handlers = {}

handlers["qlog"] = function(f)
    incoming = { npc = f[2] or "", quests = {} }
end

handlers["q"] = function(f)
    if not incoming then
        return
    end
    tinsert(incoming.quests, {
        id = tonumber(f[2]) or 0,
        name = f[3] or "",
        description = f[4] or "",
        icon = f[5] or "",
        progress = tonumber(f[6]) or 0,
        amount = tonumber(f[7]) or 1,
        done = f[8] == "1",
        reward = f[9] or "",
        rewardIcon = f[10] or "",
        class = f[11] == "1",
        category = strlower(f[12] or ""),
    })
end

handlers["qlogend"] = function()
    if not incoming then
        return
    end
    quests = incoming.quests
    local npc = incoming.npc
    incoming = nil

    if npc ~= "" then
        pendingNpc = npc
    elseif board:IsShown() then
        RefreshBoard()
    elseif openRequested then
        openRequested = nil
        RefreshBoard()
        board:Show()
    end
end

handlers["questdone"] = function(f)
    tinsert(toast.queue, { name = f[3] or "", reward = f[4] or "", icon = f[5] or "" })
    if not toast:IsShown() then
        NextToast()
    end

    local id = tonumber(f[2])
    for _, quest in ipairs(quests) do
        if quest.id == id then
            quest.done = true
            quest.progress = quest.amount
        end
    end
    if board:IsShown() then
        RefreshBoard()
    end
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent", function()
    if not arg1 or strsub(arg1, 1, strlen(PREFIX)) ~= PREFIX then
        return
    end
    local f = Split(strsub(arg1, strlen(PREFIX) + 1), "~")
    local handler = handlers[f[1]]
    if handler then
        handler(f)
    end
end)
