local L = VanillaBonkL
local UI = VanillaBonkUI

local WIDTH = 720
local HEIGHT = 560
local LEFT = 24
local PANEL_TOP = -104
local PANEL_BOTTOM = 76
local ROWS = 12
local ROW_HEIGHT = 22
local ROWS_TOP = -64
local ICON_SIZE = 16
local CLASS_ICON_SIZE = 24
local MEMBERS_WIDTH = 358
local GROUP_SIZES = { 2, 3, 4 }
local CLASSES = {
    { id = 1, token = "WARRIOR" }, { id = 2, token = "PALADIN" }, { id = 3, token = "HUNTER" },
    { id = 4, token = "ROGUE" }, { id = 5, token = "PRIEST" }, { id = 7, token = "SHAMAN" },
    { id = 8, token = "MAGE" }, { id = 9, token = "WARLOCK" }, { id = 11, token = "DRUID" },
}
local CLASS_TOKENS = {}
for _, class in ipairs(CLASSES) do
    CLASS_TOKENS[class.id] = class.token
end

local board = { season = 1, updated = nil, solo = {}, groups = {}, mine = { solo = {}, group = {} }, choice = -1, size = 1, class = nil }

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end

local window = UI.Window("VanillaBonkLeaderboard", WIDTH, HEIGHT)
window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
window.title:SetText(L["Leaderboard"])

local panel = UI.Panel(window)
panel:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, PANEL_TOP)
panel:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -LEFT - 10, PANEL_BOTTOM)
window.panel = panel

local function PaintClassIcon(texture, classId)
    UI.SetClassCrest(texture, CLASS_TOKENS[classId])
end

local function NameColor(classId)
    local color = RAID_CLASS_COLORS and RAID_CLASS_COLORS[CLASS_TOKENS[classId] or ""]
    if color then
        return color.r, color.g, color.b
    end
    return 1, 1, 1
end

local function CreateMember(parent)
    local member = {}
    member.icon = parent:CreateTexture(nil, "ARTWORK")
    member.icon:SetWidth(ICON_SIZE)
    member.icon:SetHeight(ICON_SIZE)
    member.name = UI.Text(parent, 12)
    member.name:SetJustifyH("LEFT")
    member.name:SetHeight(14)
    return member
end

local function PlaceMember(member, parent, x)
    member.icon:ClearAllPoints()
    member.icon:SetPoint("LEFT", parent, "LEFT", x, 0)
    member.name:ClearAllPoints()
    member.name:SetPoint("LEFT", member.icon, "RIGHT", 4, 0)
end

local function ShowMember(member, name, classId, width)
    PaintClassIcon(member.icon, classId)
    member.icon:Show()
    member.name:SetWidth(width)
    if name == "" then
        member.name:SetText(L["Hidden"])
        member.name:SetTextColor(0.6, 0.6, 0.6)
    else
        member.name:SetText(name)
        member.name:SetTextColor(NameColor(classId))
    end
    member.name:Show()
end

local function HideMember(member)
    member.icon:Hide()
    member.name:Hide()
end

local function CreateRow(parent)
    local row = CreateFrame("Frame", nil, parent)
    row:SetHeight(ROW_HEIGHT)
    row.shade = row:CreateTexture(nil, "BACKGROUND")
    row.shade:SetAllPoints(row)
    row.shade:SetTexture(UI.FLAT)
    row.rank = UI.Text(row, 12)
    row.rank:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.rank:SetWidth(30)
    row.rank:SetJustifyH("RIGHT")
    row.members = {}
    for index = 1, 4 do
        row.members[index] = CreateMember(row)
    end
    row.level = UI.Text(row, 12)
    row.level:SetPoint("LEFT", row, "LEFT", 410, 0)
    row.level:SetWidth(76)
    row.level:SetJustifyH("LEFT")
    row.level:SetTextColor(0.83, 0.55, 1)
    row.time = UI.Text(row, 12)
    row.time:SetPoint("RIGHT", row, "RIGHT", -84, 0)
    row.time:SetWidth(44)
    row.time:SetJustifyH("RIGHT")
    row.date = UI.Text(row, 12)
    row.date:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    row.date:SetWidth(76)
    row.date:SetJustifyH("RIGHT")
    row.date:SetTextColor(0.6, 0.6, 0.6)
    return row
end

local function ShowEntry(row, rank, entry)
    row.rank:SetText(rank and tostring(rank) or "-")
    local members = entry.members or { { name = entry.name, class = entry.class } }
    local count = getn(members)
    local slot = floor(MEMBERS_WIDTH / max(1, count))
    local width = slot - ICON_SIZE - 8
    for index, member in ipairs(row.members) do
        local info = members[index]
        if info then
            PlaceMember(member, row, 44 + (index - 1) * slot)
            ShowMember(member, info.name, info.class, width)
        else
            HideMember(member)
        end
    end
    row.level:SetText(UI.LevelName(entry.level))
    row.time:SetText(UI.FormatTime(floor(entry.ms / 1000)))
    row.date:SetText(entry.date or "")
end

local function ClearRow(row)
    row.rank:SetText("")
    for _, member in ipairs(row.members) do
        HideMember(member)
    end
    row.level:SetText("")
    row.time:SetText("")
    row.date:SetText("")
end

local function ScrollToTop()
    FauxScrollFrame_SetOffset(VanillaBonkLeaderboardScroll, 0)
    VanillaBonkLeaderboardScrollScrollBar:SetValue(0)
end

panel.tabs = UI.PanelTabs(panel, 10, function(index)
    board.size = index
    ScrollToTop()
    window.Refresh()
end)
panel.tabs:SetTabs({ L["Solo"], L["2 players"], L["3 players"], L["4 players"] })

window.allClasses = UI.Button(panel, 96, L["All classes"], function()
    board.class = nil
    ScrollToTop()
    window.Refresh()
end)
window.allClasses:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -10)

window.classIcons = {}
for index, class in ipairs(CLASSES) do
    local button = CreateFrame("Button", nil, panel)
    button:SetWidth(CLASS_ICON_SIZE)
    button:SetHeight(CLASS_ICON_SIZE)
    button:SetPoint("LEFT", window.allClasses, "RIGHT", 10 + (index - 1) * (CLASS_ICON_SIZE + 6), 0)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    UI.SetClassCrest(button.icon, class.token)
    button.ring = button:CreateTexture(nil, "OVERLAY")
    button.ring:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    button.ring:SetBlendMode("ADD")
    button.ring:SetAllPoints(button)
    button.classId = class.id
    button.label = UI.CLASS_NAMES[class.token]
    button:SetScript("OnClick", function()
        board.class = this.classId
        ScrollToTop()
        window.Refresh()
    end)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:SetText(this.label)
    end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    window.classIcons[class.id] = button
end

local function Heading(text, x, justify, width)
    local heading = UI.Text(panel, 11)
    heading:SetTextColor(1, 0.82, 0)
    heading:SetPoint("TOPLEFT", panel, "TOPLEFT", x, -44)
    heading:SetWidth(width)
    heading:SetJustifyH(justify)
    heading:SetText(text)
    return heading
end

Heading(L["Rank"], 10, "RIGHT", 34)
window.whoHeading = Heading(L["Character"], 54, "LEFT", 200)
Heading(L["Highest clear"], 420, "LEFT", 76)
Heading(L["Time"], 502, "RIGHT", 44)
Heading(L["Date"], 550, "RIGHT", 76)

window.rows = {}
for index = 1, ROWS do
    local row = CreateRow(panel)
    row:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, ROWS_TOP - (index - 1) * ROW_HEIGHT)
    row:SetPoint("RIGHT", panel, "RIGHT", -32, 0)
    row.shade:SetVertexColor(1, 1, 1, mod(index, 2) == 0 and 0.03 or 0)
    window.rows[index] = row
end

local scroll = CreateFrame("ScrollFrame", "VanillaBonkLeaderboardScroll", panel, "FauxScrollFrameTemplate")
scroll:SetPoint("TOPLEFT", window.rows[1], "TOPLEFT", 0, 0)
scroll:SetPoint("BOTTOMRIGHT", window.rows[ROWS], "BOTTOMRIGHT", 0, 0)
scroll:SetScript("OnVerticalScroll", function()
    FauxScrollFrame_OnVerticalScroll(ROW_HEIGHT, window.Refresh)
end)

window.empty = UI.Text(panel, 12)
window.empty:SetPoint("TOPLEFT", window.rows[1], "TOPLEFT", 44, -4)
window.empty:SetTextColor(0.6, 0.6, 0.6)

window.you = CreateRow(panel)
window.you:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 10, 10)
window.you:SetPoint("RIGHT", panel, "RIGHT", -32, 0)
window.you:SetHeight(ROW_HEIGHT + 6)
window.you.shade:SetVertexColor(1, 0.7, 0.15, 0.12)
window.you.rank:SetTextColor(1, 0.82, 0)
window.you.note = UI.Text(window.you, 12)
window.you.note:SetPoint("LEFT", window.you, "LEFT", 44, 0)
window.you.note:SetTextColor(0.6, 0.6, 0.6)
window.youTitle = UI.Text(panel, 11)
window.youTitle:SetPoint("BOTTOMLEFT", window.you, "TOPLEFT", 4, 3)
window.youTitle:SetTextColor(1, 0.82, 0)
window.youTitle:SetText(L["Your best"])

window.join = CreateFrame("CheckButton", "VanillaBonkLeaderboardJoin", window, "UICheckButtonTemplate")
window.join:SetWidth(24)
window.join:SetHeight(24)
window.join:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", LEFT, 44)
VanillaBonkLeaderboardJoinText:SetFontObject(GameFontHighlightSmall)
VanillaBonkLeaderboardJoinText:SetText(L["Show my characters on the leaderboard"])
window.join:SetScript("OnClick", function()
    PlaySound(this:GetChecked() and "igMainMenuOptionCheckBoxOn" or "igMainMenuOptionCheckBoxOff")
    Command("joinboard " .. (this:GetChecked() and "1" or "0"))
end)
window.join:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
    GameTooltip:SetText(L["Your Mythic clears are sent with the character's name and class. Group clears only show your name if this is on."], 1, 1, 1, 1, 1)
end)
window.join:SetScript("OnLeave", function() GameTooltip:Hide() end)

window.soon = UI.Text(window, 11)
window.soon:SetPoint("BOTTOMRIGHT", window, "BOTTOMRIGHT", -LEFT - 10, 50)
window.soon:SetJustifyH("RIGHT")
window.soon:SetTextColor(1, 0.82, 0)
window.soon:SetText(L["Builds will be shown here in a future update."])

window.note = UI.Text(window, 11)
window.note:SetPoint("BOTTOMLEFT", window, "BOTTOMLEFT", LEFT, 26)
window.note:SetWidth(WIDTH - LEFT * 2)
window.note:SetJustifyH("LEFT")
window.note:SetTextColor(0.6, 0.6, 0.6)

local function Better(a, b)
    return not b or a.level > b.level or (a.level == b.level and a.ms < b.ms)
end

local function SortEntries(list)
    sort(list, function(a, b)
        return a.level > b.level or (a.level == b.level and a.ms < b.ms)
    end)
end

local function HasClass(entry, classId)
    for _, member in ipairs(entry.members) do
        if member.class == classId then
            return true
        end
    end
    return false
end

local function VisibleEntries()
    if board.size == 1 then
        if board.class then
            return board.solo[board.class] or {}
        end
        local all = {}
        for _, list in pairs(board.solo) do
            for _, entry in ipairs(list) do
                tinsert(all, entry)
            end
        end
        SortEntries(all)
        return all
    end
    local list = board.groups[GROUP_SIZES[board.size - 1]] or {}
    if not board.class then
        return list
    end
    local filtered = {}
    for _, entry in ipairs(list) do
        if HasClass(entry, board.class) then
            tinsert(filtered, entry)
        end
    end
    return filtered
end

local function BestOfMine()
    local best, rank
    if board.size == 1 then
        for _, entry in ipairs(board.mine.solo) do
            if (not board.class or entry.class == board.class) and Better(entry, best) then
                best = entry
                rank = board.class and entry.classRank or entry.allRank
            end
        end
    else
        for _, entry in ipairs(board.mine.group) do
            if entry.size == GROUP_SIZES[board.size - 1] and (not board.class or HasClass(entry, board.class)) and Better(entry, best) then
                best = entry
                rank = entry.rank
            end
        end
    end
    return best, rank
end

function window.Refresh()
    panel.tabs:Select(board.size)
    if board.class then
        window.allClasses:UnlockHighlight()
    else
        window.allClasses:LockHighlight()
    end
    for id, button in pairs(window.classIcons) do
        local on = board.class == id
        local shade = (on or not board.class) and 1 or 0.4
        button.icon:SetVertexColor(shade, shade, shade)
        if on then
            button.ring:Show()
        else
            button.ring:Hide()
        end
    end
    window.whoHeading:SetText(board.size == 1 and L["Character"] or L["Group"])

    local entries = VisibleEntries()
    local total = getn(entries)
    FauxScrollFrame_Update(scroll, total, ROWS, ROW_HEIGHT)
    local offset = FauxScrollFrame_GetOffset(scroll)
    for index, row in ipairs(window.rows) do
        local entry = entries[index + offset]
        if entry then
            ShowEntry(row, index + offset, entry)
        else
            ClearRow(row)
        end
    end
    if total > 0 then
        window.empty:SetText("")
    elseif board.updated then
        window.empty:SetText(L["Nobody is on this list yet."])
    else
        window.empty:SetText(L["The launcher downloads the leaderboard when it starts."])
    end

    local best, rank = BestOfMine()
    if best then
        ShowEntry(window.you, rank, best)
        window.you.note:SetText("")
    else
        ClearRow(window.you)
        if board.choice ~= 1 then
            window.you.note:SetText(L["Turn on the box below to be listed."])
        elseif UI.WearsLegacyGear() then
            window.you.note:SetText(L["You're wearing legacy gear, so your runs don't count this season."])
        else
            window.you.note:SetText(L["Not ranked yet."])
        end
    end

    window.header:SetText(L("Season {1}", board.season))
    window.headerRight:SetText(board.updated and L("Updated {1}", board.updated) or "")
    window.join:SetChecked(board.choice == 1)
    window.note:SetText(L("Season {1}. Mythic clears with gear found this season. Ties go to the faster clear.", board.season))
end

local function ReadMembers(text)
    local members = {}
    for _, piece in ipairs(UI.Split(text or "", ",")) do
        local parts = UI.Split(piece, ":")
        if parts[2] then
            tinsert(members, { name = parts[1], class = tonumber(parts[2]) or 0 })
        end
    end
    return members
end

local ASK_WIDTH = 380

window.ask = UI.Panel(window)
window.ask:SetWidth(ASK_WIDTH)
window.ask:SetHeight(150)
window.ask:SetPoint("CENTER", window, "CENTER", 0, 0)
window.ask:SetFrameLevel(window:GetFrameLevel() + 20)
window.ask:SetBackdropColor(0.02, 0.02, 0.03, 0.97)
window.ask:EnableMouse(true)
window.ask.title = UI.Text(window.ask, 14)
window.ask.title:SetPoint("TOP", window.ask, "TOP", 0, -14)
window.ask.title:SetTextColor(1, 0.82, 0)
window.ask.title:SetText(L["Join the leaderboard?"])
window.ask.text = UI.Text(window.ask, 12)
window.ask.text:SetPoint("TOP", window.ask.title, "BOTTOM", 0, -8)
window.ask.text:SetWidth(ASK_WIDTH - 32)
window.ask.text:SetText(L["Show your characters on the public leaderboard? Your solo and group Mythic clears are sent with the character's name and class. You can change this any time at the bottom of this window."])
window.ask.join = UI.Button(window.ask, 120, L["Join"], function()
    window.ask:Hide()
    Command("joinboard 1")
end)
window.ask.join:SetPoint("BOTTOMRIGHT", window.ask, "BOTTOM", -6, 14)
window.ask.decline = UI.Button(window.ask, 120, L["No thanks"], function()
    window.ask:Hide()
    Command("joinboard 0")
end)
window.ask.decline:SetPoint("BOTTOMLEFT", window.ask, "BOTTOM", 6, 14)
window.ask:Hide()

local handlers = {}

handlers["boardopen"] = function()
    board.updated = nil
    board.solo = {}
    board.groups = {}
    board.mine = { solo = {}, group = {} }
end

handlers["board"] = function(f)
    local kind = f[2]
    if kind == "updated" then
        board.updated = f[3]
    elseif kind == "season" then
        board.season = tonumber(f[3]) or board.season
    elseif kind == "solo" then
        local class = tonumber(f[3]) or 0
        board.solo[class] = board.solo[class] or {}
        tinsert(board.solo[class], { class = class, name = f[5] or "", level = tonumber(f[6]) or 0, ms = tonumber(f[7]) or 0, date = f[8] or "" })
    elseif kind == "group" then
        local size = tonumber(f[3]) or 0
        board.groups[size] = board.groups[size] or {}
        tinsert(board.groups[size], { level = tonumber(f[5]) or 0, ms = tonumber(f[6]) or 0, date = f[7] or "", members = ReadMembers(f[8]) })
    elseif kind == "mine" and f[3] == "solo" then
        tinsert(board.mine.solo, { class = tonumber(f[4]) or 0, classRank = tonumber(f[5]), allRank = tonumber(f[6]), name = f[7] or "",
            level = tonumber(f[8]) or 0, ms = tonumber(f[9]) or 0, date = f[10] or "" })
    elseif kind == "mine" and f[3] == "group" then
        tinsert(board.mine.group, { size = tonumber(f[4]) or 0, rank = tonumber(f[5]), level = tonumber(f[6]) or 0, ms = tonumber(f[7]) or 0,
            date = f[8] or "", members = ReadMembers(f[9]) })
    end
end

handlers["boardchoice"] = function(f)
    board.choice = tonumber(f[2]) or -1
    if window:IsShown() then
        window.Refresh()
    end
end

handlers["boardend"] = function()
    UI.SetPortrait(window)
    window.Refresh()
    window:Show()
    if board.choice < 0 then
        window.ask:Show()
    else
        window.ask:Hide()
    end
end

UI.Listen(handlers)
