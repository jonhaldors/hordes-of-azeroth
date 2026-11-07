local L = VanillaBonkL
local UI = VanillaBonkUI

UI.TRANSMOGRIFIER_NAME = L["hoa.addon.esmeralda_glimmerstitch"]

local WIDTH = 660
local HEIGHT = 640
local LEFT = 26
local TOP = 84
local SLOT_SIZE = 36
local SLOT_GAP = 6
local MODEL_WIDTH = 200
local MODEL_HEIGHT = 330
local LOOK_SIZE = 40
local LOOK_GAP = 10
local LOOK_COLUMNS = 5
local LOOK_ROWS = 5
local PER_PAGE = LOOK_COLUMNS * LOOK_ROWS
local PAGE_TABS = 6
local PAGE_TAB_WIDTH = 28
local PAGE_TAB_GAP = 4
local PAGE_ARROW_WIDTH = 24
local ICON_RETRY = 0.5
local ICON_RETRIES = 10
local SLOT_ART = "Interface\\PaperDoll\\UI-PaperDoll-Slot-"
local GREETING = L["hoa.addon.every_piece_you_find_adds_its_look_to_your_collection_choose"]

local LEFT_SLOTS = {
    { slot = 0, name = L["hoa.addon.head"], art = "Head" },
    { slot = 2, name = L["hoa.addon.shoulders"], art = "Shoulder" },
    { slot = 14, name = L["hoa.addon.back"], art = "Chest" },
    { slot = 4, name = L["hoa.addon.armor_slot_chest"], art = "Chest" },
    { slot = 3, name = L["hoa.addon.shirt"], art = "Shirt" },
    { slot = 18, name = L["hoa.addon.tabard"], art = "Tabard" },
    { slot = 8, name = L["hoa.addon.wrists"], art = "Wrists" },
}
local RIGHT_SLOTS = {
    { slot = 9, name = L["hoa.addon.hands"], art = "Hands" },
    { slot = 5, name = L["hoa.addon.waist"], art = "Waist" },
    { slot = 6, name = L["hoa.addon.legs"], art = "Legs" },
    { slot = 7, name = L["hoa.addon.feet"], art = "Feet" },
}
local BOTTOM_SLOTS = {
    { slot = 15, name = L["hoa.addon.main_hand"], art = "MainHand" },
    { slot = 16, name = L["hoa.addon.off_hand"], art = "SecondaryHand" },
    { slot = 17, name = L["hoa.addon.ranged"], art = "Ranged" },
}

local HIDDEN_LOOK = 1
local TABARD_SLOT = 18
local HIDDEN_ICON = "Interface\\Buttons\\UI-GroupLoot-Pass-Up"
local OUTFITS = 5
local OUTFIT_ROW = 26
local OUTFIT_SAVE_WIDTH = 56
local OUTFIT_DELETE_WIDTH = 28

local Transmog = UI.Module("transmog")
Transmog.state = { slots = {}, looks = {}, outfits = {}, selected = 0, page = 1 }
Transmog.incoming = nil
Transmog.retries = 0
Transmog.slotButtons = {}
Transmog.lookButtons = {}

local window = UI.Window("VanillaBonkTransmog", WIDTH, HEIGHT)
Transmog.window = window
window:SetPoint("CENTER", UIParent, "CENTER", 0, 20)
window.title:SetText(UI.TRANSMOGRIFIER_NAME)

window.greeting = UI.Text(window, 12)
window.greeting:SetWidth(WIDTH - LEFT * 2 - 10)
window.greeting:SetJustifyH("LEFT")
window.greeting:SetTextColor(0.91, 0.86, 0.75)
window.greeting:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT, -TOP + 6)
window.greeting:SetText(GREETING)

local modelTop = TOP + 26
window.model = CreateFrame("PlayerModel", "VanillaBonkTransmogModel", window)
window.model:SetWidth(MODEL_WIDTH)
window.model:SetHeight(MODEL_HEIGHT)
window.model:SetPoint("TOPLEFT", window, "TOPLEFT", LEFT + SLOT_SIZE + SLOT_GAP * 2, -modelTop)

local function ItemString(entry)
    return "item:" .. entry .. ":0:0:0"
end

window.scan = CreateFrame("GameTooltip", "VanillaBonkTransmogScan", UIParent, "GameTooltipTemplate")
window.scan:Hide()

function Transmog:ResetModel()
    self.window.model:SetUnit("player")
end

function Transmog:SlotEntry(slot)
    return self.state.slots[slot] or {}
end

local function LookTexture(entry)
    local _, _, _, _, _, _, _, _, texture = GetItemInfo(entry)
    return texture
end

function Transmog:SlotButton(info, x, y)
    local button = UI.Slot(self.window, SLOT_SIZE)
    button.info = info
    button:SetPoint("TOPLEFT", self.window, "TOPLEFT", x, -y)
    button.glow = button:CreateTexture(nil, "OVERLAY")
    button.glow:SetTexture("Interface\\Buttons\\CheckButtonHilight")
    button.glow:SetBlendMode("ADD")
    button.glow:SetAllPoints(button)
    button.glow:Hide()
    button.changed = button:CreateTexture(nil, "OVERLAY")
    button.changed:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.changed:SetBlendMode("ADD")
    button.changed:SetVertexColor(1, 0.5, 1)
    button.changed:SetWidth(SLOT_SIZE * 1.8)
    button.changed:SetHeight(SLOT_SIZE * 1.8)
    button.changed:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.changed:Hide()
    button:SetScript("OnClick", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        Transmog.state.selected = this.info.slot
        Transmog.state.page = 1
        Transmog:Refresh()
    end)
    UI.Hover(button, function()
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        local current = Transmog:SlotEntry(this.info.slot)
        if current.worn and current.worn > 0 then
            GameTooltip:SetHyperlink(ItemString(current.look > 0 and current.look or current.worn))
        else
            GameTooltip:SetText(this.info.name, 1, 1, 1)
        end
        GameTooltip:Show()
    end)
    tinsert(self.slotButtons, button)
end

for index, info in ipairs(LEFT_SLOTS) do
    Transmog:SlotButton(info, LEFT, modelTop + (index - 1) * (SLOT_SIZE + SLOT_GAP))
end
for index, info in ipairs(RIGHT_SLOTS) do
    Transmog:SlotButton(info, LEFT + SLOT_SIZE + SLOT_GAP * 3 + MODEL_WIDTH, modelTop + (index - 1) * (SLOT_SIZE + SLOT_GAP))
end
for index, info in ipairs(BOTTOM_SLOTS) do
    local rowWidth = table.getn(BOTTOM_SLOTS) * SLOT_SIZE + (table.getn(BOTTOM_SLOTS) - 1) * SLOT_GAP
    local first = LEFT + SLOT_SIZE + SLOT_GAP * 2 + (MODEL_WIDTH - rowWidth) / 2
    Transmog:SlotButton(info, first + (index - 1) * (SLOT_SIZE + SLOT_GAP), modelTop + MODEL_HEIGHT + 4)
end

local gridLeft = LEFT + SLOT_SIZE * 2 + SLOT_GAP * 4 + MODEL_WIDTH + 24
local gridWidth = LOOK_COLUMNS * LOOK_SIZE + (LOOK_COLUMNS - 1) * LOOK_GAP

window.slotName = UI.Text(window, 14)
window.slotName:SetTextColor(1, 0.82, 0)
window.slotName:SetPoint("TOPLEFT", window, "TOPLEFT", gridLeft, -modelTop)

window.empty = UI.Text(window, 12)
window.empty:SetWidth(gridWidth)
window.empty:SetJustifyH("LEFT")
window.empty:SetTextColor(0.78, 0.75, 0.69)
window.empty:SetPoint("TOPLEFT", window.slotName, "BOTTOMLEFT", 0, -12)

local DUNGEON_NAMES = {
    moltencore = L["hoa.addon.molten_core"],
    zulgurub = L["hoa.addon.zul_gurub"],
    ruinsaq = L["hoa.addon.ruins_of_ahn_qiraj"],
}

local ZONE_NAMES = {
    westernplaguelands = L["hoa.addon.western_plaguelands"],
    easternplaguelands = L["hoa.addon.eastern_plaguelands"],
    arathi = L["hoa.addon.arathi_highlands"],
}

local function SourceLine(code)
    local kind, rest = strsub(code, 1, 1), strsub(code, 2)
    if kind == "N" then
        return L["hoa.addon.drops_in_normal_runs"]
    elseif kind == "H" then
        return L["hoa.addon.drops_in_heroic_runs"]
    elseif kind == "M" then
        return L["hoa.addon.drops_in_mythic_runs"]
    elseif kind == "E" then
        return L("hoa.addon.drops_in_mythic_1_and_higher", rest)
    elseif kind == "L" then
        return L["hoa.addon.drops_from_bosses_in_mythic_runs"]
    elseif kind == "D" then
        return L("hoa.addon.drops_in_the_1_dungeon_and_its_invasion", DUNGEON_NAMES[rest] or rest)
    elseif kind == "S" then
        return L["hoa.addon.sold_by_sayge_for_darkmoon_tickets"]
    elseif kind == "Q" then
        return L("hoa.addon.reward_from_the_quest_1", rest)
    elseif kind == "Z" then
        return L("hoa.addon.drops_from_bosses_in_1", ZONE_NAMES[rest] or rest)
    elseif kind == "R" then
        return L("hoa.addon.drops_from_bosses_everywhere_more_often_in_1", ZONE_NAMES[rest] or rest)
    end
end

local function SourceLines(source)
    local lines = {}
    if not source or source == "" then
        return lines
    end
    local sold = false
    for _, code in ipairs(UI.Split(source, ",")) do
        local line = SourceLine(code)
        if line then
            tinsert(lines, line)
        end
        local kind = strsub(code, 1, 1)
        sold = sold or kind == "N" or kind == "H" or kind == "M" or kind == "V"
    end
    if sold then
        tinsert(lines, L["hoa.addon.sold_by_durgan_ironbelly"])
    end
    return lines
end

local function ShowLookTip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.look.hidden then
        GameTooltip:SetText(L["hoa.addon.hidden"], 1, 1, 1)
        GameTooltip:AddLine(L["hoa.addon.hides_this_slot_while_you_keep_the_item_equipped"], 1, 0.82, 0, 1)
        GameTooltip:Show()
        return
    end
    GameTooltip:SetHyperlink(ItemString(button.look.entry))
    if button.look.collected then
        GameTooltip:AddLine(L["hoa.addon.appearance_collected"], 0.25, 0.75, 1)
    else
        GameTooltip:AddLine(L["hoa.addon.you_haven_t_collected_this_appearance"], 0.75, 0.55, 1)
        for _, line in ipairs(SourceLines(button.look.source)) do
            GameTooltip:AddLine(line, 1, 0.82, 0, 1)
        end
        GameTooltip:AddLine(L["hoa.addon.click_to_preview_it_in_the_dressing_room"], 0.6, 0.6, 0.6, 1)
    end
    GameTooltip:Show()
end

local function PreviewLook(entry)
    local _, link = GetItemInfo(entry)
    DressUpItemLink(link or ItemString(entry))
end

function Transmog:LookButton(index)
    local button = UI.Slot(self.window, LOOK_SIZE)
    local column = math.mod(index - 1, LOOK_COLUMNS)
    local row = floor((index - 1) / LOOK_COLUMNS)
    button:SetPoint("TOPLEFT", self.window, "TOPLEFT", gridLeft + column * (LOOK_SIZE + LOOK_GAP), -(modelTop + 26 + row * (LOOK_SIZE + LOOK_GAP)))
    button.border = button:CreateTexture(nil, "OVERLAY")
    button.border:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    button.border:SetBlendMode("ADD")
    button.border:SetWidth(LOOK_SIZE * 1.8)
    button.border:SetHeight(LOOK_SIZE * 1.8)
    button.border:SetPoint("CENTER", button, "CENTER", 0, 0)
    button.check = button:CreateTexture(nil, "OVERLAY")
    button.check:SetTexture("Interface\\Buttons\\UI-CheckBox-Check")
    button.check:SetWidth(22)
    button.check:SetHeight(22)
    button.check:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 4, -4)
    UI.Hover(button, function()
        if this.look then
            ShowLookTip(this)
        end
    end)
    button:SetScript("OnClick", function()
        if not this.look then
            return
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
        if this.look.collected then
            SendChatMessage(".bonk mog set " .. Transmog.state.selected .. " " .. this.look.entry, "SAY")
        else
            PreviewLook(this.look.entry)
        end
    end)
    self.lookButtons[index] = button
    return button
end

for index = 1, PER_PAGE do
    Transmog:LookButton(index)
end

function Transmog:ShowPage(page)
    self.state.page = page
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:Refresh()
end

local pagerTop = modelTop + 26 + LOOK_ROWS * (LOOK_SIZE + LOOK_GAP) + 4
window.pager = CreateFrame("Frame", nil, window)
window.pager:SetHeight(22)
window.pager:SetPoint("TOP", window, "TOPLEFT", gridLeft + gridWidth / 2, -pagerTop)
window.prev = UI.Button(window.pager, PAGE_ARROW_WIDTH, "<", function() Transmog:ShowPage(Transmog.state.page - 1) end)
window.next = UI.Button(window.pager, PAGE_ARROW_WIDTH, ">", function() Transmog:ShowPage(Transmog.state.page + 1) end)
window.pageTabs = {}
for index = 1, PAGE_TABS do
    local tab = UI.Button(window.pager, PAGE_TAB_WIDTH, "", function() Transmog:ShowPage(this.page) end)
    window.pageTabs[index] = tab
end

function Transmog:LayOutPager(pages)
    local window = self.window
    if pages <= 1 then
        window.pager:Hide()
        return
    end
    window.pager:Show()
    local shown = min(pages, PAGE_TABS)
    local arrows = pages > PAGE_TABS
    local first = max(1, min(self.state.page - floor(PAGE_TABS / 2), pages - shown + 1))
    local width = shown * PAGE_TAB_WIDTH + (shown - 1) * PAGE_TAB_GAP
    if arrows then
        width = width + 2 * (PAGE_ARROW_WIDTH + PAGE_TAB_GAP)
    end
    window.pager:SetWidth(width)
    local x = 0
    if arrows then
        window.prev:ClearAllPoints()
        window.prev:SetPoint("LEFT", window.pager, "LEFT", 0, 0)
        window.prev:Show()
        if self.state.page > 1 then window.prev:Enable() else window.prev:Disable() end
        x = PAGE_ARROW_WIDTH + PAGE_TAB_GAP
    else
        window.prev:Hide()
    end
    for index, tab in ipairs(window.pageTabs) do
        if index <= shown then
            tab.page = first + index - 1
            tab:SetText(tostring(tab.page))
            tab:ClearAllPoints()
            tab:SetPoint("LEFT", window.pager, "LEFT", x, 0)
            x = x + PAGE_TAB_WIDTH + PAGE_TAB_GAP
            if tab.page == self.state.page then
                tab:Disable()
            else
                tab:Enable()
            end
            tab:Show()
        else
            tab:Hide()
        end
    end
    if arrows then
        window.next:ClearAllPoints()
        window.next:SetPoint("LEFT", window.pager, "LEFT", x, 0)
        window.next:Show()
        if self.state.page < pages then window.next:Enable() else window.next:Disable() end
    else
        window.next:Hide()
    end
end

window.restore = UI.Button(window, gridWidth, L["hoa.addon.show_equipped_look"], function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(".bonk mog clear " .. Transmog.state.selected, "SAY")
end)
window.restore:SetPoint("TOPLEFT", window, "TOPLEFT", gridLeft, -(pagerTop + 34))

function Transmog:PadPage(step)
    local window = self.window
    local pages = window.padPages or 1
    local page = max(1, min(pages, self.state.page + step))
    if page ~= self.state.page then
        self:ShowPage(page)
    end
end

function window.PadPage(step)
    Transmog:PadPage(step)
end

window.outfitLabel = UI.Text(window, 13)
window.outfitLabel:SetTextColor(1, 0.82, 0)
window.outfitLabel:SetPoint("TOPLEFT", window, "TOPLEFT", gridLeft, -(pagerTop + 66))
window.outfitLabel:SetText(L["hoa.addon.outfits"])
window.outfitRows = {}

StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"] = {
    text = L["hoa.addon.name_this_outfit"],
    button1 = ACCEPT,
    button2 = CANCEL,
    hasEditBox = 1,
    maxLetters = 24,
    OnShow = function()
        local box = getglobal(this:GetName() .. "EditBox")
        box:SetText(Transmog.state.outfits[StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"].outfit] or L("hoa.addon.outfit_1", StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"].outfit))
        box:HighlightText()
        box:SetFocus()
    end,
    OnAccept = function()
        local name = getglobal(this:GetParent():GetName() .. "EditBox"):GetText()
        local outfit = StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"].outfit
        if name and name ~= "" then
            SendChatMessage(".bonk mog outfit save " .. outfit .. " " .. name, "SAY")
        end
    end,
    EditBoxOnEnterPressed = function()
        local name = this:GetText()
        local outfit = StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"].outfit
        if name and name ~= "" then
            SendChatMessage(".bonk mog outfit save " .. outfit .. " " .. name, "SAY")
        end
        this:GetParent():Hide()
    end,
    EditBoxOnEscapePressed = function() this:GetParent():Hide() end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function SaveOutfit(outfit)
    PlaySound("igMainMenuOptionCheckBoxOn")
    StaticPopupDialogs["VANILLABONK_OUTFIT_NAME"].outfit = outfit
    StaticPopup_Show("VANILLABONK_OUTFIT_NAME")
end

for outfit = 1, OUTFITS do
    local row = {}
    local nameWidth = gridWidth - OUTFIT_SAVE_WIDTH - OUTFIT_DELETE_WIDTH - 8
    row.apply = UI.Button(window, nameWidth, "", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        if Transmog.state.outfits[this.outfit] then
            SendChatMessage(".bonk mog outfit apply " .. this.outfit, "SAY")
        else
            SaveOutfit(this.outfit)
        end
    end)
    row.apply.outfit = outfit
    row.apply:SetPoint("TOPLEFT", window, "TOPLEFT", gridLeft, -(pagerTop + 84 + (outfit - 1) * OUTFIT_ROW))
    row.save = UI.Button(window, OUTFIT_SAVE_WIDTH, L["hoa.addon.save"], function() SaveOutfit(this.outfit) end)
    row.save.outfit = outfit
    row.save:SetPoint("LEFT", row.apply, "RIGHT", 4, 0)
    row.delete = UI.Button(window, OUTFIT_DELETE_WIDTH, "X", function()
        PlaySound("igMainMenuOptionCheckBoxOff")
        SendChatMessage(".bonk mog outfit delete " .. this.outfit, "SAY")
    end)
    row.delete.outfit = outfit
    row.delete:SetPoint("LEFT", row.save, "RIGHT", 4, 0)
    for _, button in ipairs({ row.apply, row.save, row.delete }) do
        UI.Hover(button, function()
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            if this == window.outfitRows[this.outfit].save then
                GameTooltip:SetText(L["hoa.addon.saves_your_current_looks_as_this_outfit"], 1, 1, 1, 1, 1)
            elseif this == window.outfitRows[this.outfit].delete then
                GameTooltip:SetText(L["hoa.addon.deletes_this_outfit"], 1, 1, 1, 1, 1)
            elseif Transmog.state.outfits[this.outfit] then
                GameTooltip:SetText(L["hoa.addon.click_to_wear_this_outfit"], 1, 1, 1, 1, 1)
            else
                GameTooltip:SetText(L["hoa.addon.click_to_save_your_current_looks_as_an_outfit"], 1, 1, 1, 1, 1)
            end
            GameTooltip:Show()
        end)
    end
    window.outfitRows[outfit] = row
end

function Transmog:RefreshOutfits()
    for outfit, row in ipairs(self.window.outfitRows) do
        local name = self.state.outfits[outfit]
        row.apply:SetText(name or L["hoa.addon.empty_2"])
        if name then
            row.delete:Enable()
        else
            row.delete:Disable()
        end
    end
end

function window.RefreshOutfits()
    Transmog:RefreshOutfits()
end

local function SlotInfo(slot)
    for _, list in ipairs({ LEFT_SLOTS, RIGHT_SLOTS, BOTTOM_SLOTS }) do
        for _, info in ipairs(list) do
            if info.slot == slot then
                return info
            end
        end
    end
end

function Transmog:LooksFor(group, canHide)
    local looks = {}
    if canHide then
        tinsert(looks, { entry = HIDDEN_LOOK, hidden = true, collected = true, quality = 1 })
    end
    for _, look in ipairs(self.state.looks) do
        if look.group == group then
            tinsert(looks, look)
        end
    end
    return looks
end

function Transmog:Refresh()
    local window = self.window
    if not window:IsShown() then
        return
    end
    local missingIcon = false
    for _, button in ipairs(self.slotButtons) do
        local current = self:SlotEntry(button.info.slot)
        local texture = current.worn and current.worn > 0 and (current.look > 0 and LookTexture(current.look) or GetInventoryItemTexture("player", button.info.slot + 1))
        button.icon:SetTexture(texture or (SLOT_ART .. button.info.art))
        if current.worn and current.worn > 0 and not texture then
            missingIcon = true
        end
        if button.info.slot == self.state.selected then
            button.glow:Show()
        else
            button.glow:Hide()
        end
        if current.look and current.look > 0 then
            button.changed:Show()
        else
            button.changed:Hide()
        end
    end

    local info = SlotInfo(self.state.selected) or LEFT_SLOTS[1]
    local current = self:SlotEntry(info.slot)
    window.slotName:SetText(info.name)
    local looks = current.group and current.group > 0 and self:LooksFor(current.group, current.canHide) or {}
    local pages = max(1, ceil(table.getn(looks) / PER_PAGE))
    self.state.page = max(1, min(self.state.page, pages))
    local first = (self.state.page - 1) * PER_PAGE

    if not current.worn or current.worn == 0 then
        if info.slot == TABARD_SLOT then
            window.empty:SetText(L["hoa.addon.equip_a_tabard_to_change_its_look_durgan_ironbelly_the_gear_"])
        else
            window.empty:SetText(L["hoa.addon.equip_an_item_in_this_slot_to_change_its_look"])
        end
        window.empty:Show()
    elseif table.getn(looks) == 0 then
        window.empty:SetText(L["hoa.addon.there_are_no_other_looks_for_this_slot_yet"])
        window.empty:Show()
    else
        window.empty:Hide()
    end

    local shown = current.shown
    for index, button in ipairs(self.lookButtons) do
        local look = looks[first + index]
        button.look = look
        if look then
            local texture = look.hidden and HIDDEN_ICON or LookTexture(look.entry)
            if not texture then
                missingIcon = true
                window.scan:SetOwner(UIParent, "ANCHOR_NONE")
                window.scan:SetHyperlink(ItemString(look.entry))
            end
            button.icon:SetTexture(texture or "Interface\\Icons\\INV_Misc_QuestionMark")
            if look.collected then
                button.icon:SetVertexColor(1, 1, 1)
                local r, g, b = GetItemQualityColor(look.quality)
                button.border:SetVertexColor(r, g, b)
                button.border:Show()
            else
                button.icon:SetVertexColor(0.3, 0.3, 0.3)
                button.border:Hide()
            end
            if look.entry == shown then
                button.check:Show()
            else
                button.check:Hide()
            end
            button:Show()
        else
            button:Hide()
        end
    end

    self:LayOutPager(pages)
    window.padPages = pages
    self:RefreshOutfits()
    if current.look and current.look > 0 then window.restore:Enable() else window.restore:Disable() end

    if missingIcon and self.retries < ICON_RETRIES then
        window.retryAt = GetTime() + ICON_RETRY
    else
        window.retryAt = nil
    end
end

function window.Refresh()
    Transmog:Refresh()
end

window:SetScript("OnUpdate", function()
    if this.retryAt and GetTime() >= this.retryAt then
        this.retryAt = nil
        Transmog.retries = Transmog.retries + 1
        Transmog:Refresh()
    end
end)

window:SetScript("OnShow", function()
    PlaySound("igCharacterInfoOpen")
    UI.SetPortrait(this)
    Transmog.retries = 0
    Transmog:ResetModel()
    Transmog:Refresh()
end)

window:SetScript("OnHide", function()
    PlaySound("igCharacterInfoClose")
    if this.fromGossip then
        this.fromGossip = nil
        if not this.gossipClosed then
            CloseGossip()
        end
    end
    this.gossipClosed = nil
end)

local PreviousGossipOnEvent = GossipFrame_OnEvent
function GossipFrame_OnEvent()
    if event == "GOSSIP_SHOW" and UI.TalkingTo(UI.TRANSMOGRIFIER_NAME) then
        window.fromGossip = true
        SendChatMessage(".bonk mog open", "SAY")
        return
    elseif event == "GOSSIP_CLOSED" and window.fromGossip and window:IsShown() then
        window.gossipClosed = true
        window:Hide()
    end
    PreviousGossipOnEvent()
end

function Transmog:HandleBegin()
    self.incoming = { slots = {}, looks = {}, outfits = {} }
end

function Transmog:HandleSlot(f)
    local slot = tonumber(f[2] or "")
    if self.incoming and slot then
        self.incoming.slots[slot] = { worn = tonumber(f[3] or "") or 0, look = tonumber(f[4] or "") or 0, group = tonumber(f[5] or "") or 0,
            shown = tonumber(f[6] or "") or 0, canHide = f[7] == "1" }
    end
end

function Transmog:HandleLook(f)
    local group = tonumber(f[2] or "")
    local entry = tonumber(f[3] or "")
    if self.incoming and group and entry then
        tinsert(self.incoming.looks, { group = group, entry = entry, quality = tonumber(f[4] or "") or 1, collected = f[5] == "1", source = f[6] })
    end
end

function Transmog:HandleOutfit(f)
    local outfit = tonumber(f[2] or "")
    if self.incoming and outfit then
        self.incoming.outfits[outfit] = f[3]
    end
end

function Transmog:HandleEnd()
    if not self.incoming then
        return
    end
    self.state.slots = self.incoming.slots
    self.state.looks = self.incoming.looks
    self.state.outfits = self.incoming.outfits
    self.incoming = nil
    self.retries = 0
    if self.window:IsShown() then
        self:ResetModel()
        self:Refresh()
    else
        self.window:Show()
    end
end

UI.ListenHoa({
    HOA_MOG_BEGIN = function() Transmog:HandleBegin() end,
    HOA_MOG_SLOT = function(slot)
        Transmog:HandleSlot({ false, slot.slot, slot.worn_entry, slot.look, slot.group, slot.catalog_entry, slot.can_hide and "1" or "0" })
    end,
    HOA_MOG_LOOK = function(look)
        Transmog:HandleLook({ false, look.group, look.entry, look.quality, look.owned and "1" or "0", look.source })
    end,
    HOA_MOG_OUTFIT = function(outfit) Transmog:HandleOutfit({ false, outfit.slot, outfit.name }) end,
    HOA_MOG_END = function() Transmog:HandleEnd() end,
})
