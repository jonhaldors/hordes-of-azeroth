local UI = VanillaBonkUI

local WIDTH, HEIGHT = 760, 480
local BAGS_ROOM = 370
local SIDE_X, SIDE_W = 18, 168
local CATEGORY_HEIGHT, SUB_HEIGHT = 32, 23
local LIST_X = SIDE_X + SIDE_W + 12
local LIST_TOP = 92
local CARD_HEIGHT, CARD_GAP, CARD_COLUMNS = 50, 6, 3
local SECTION_HEIGHT = 20
local CONTENT_TOP, CONTENT_BOTTOM, CONTENT_SIDE = 34, 26, 12
local MERGE_LIMIT = 3
local ICON_SIZE = 37
local PANE_ART = "Interface\\Glues\\LoadingScreens\\LoadScreenMoltenCore"
local PANE_DIM = 0.72
local PANE_FOCUS = 0.85
local INFO_RETRY_SECONDS, INFO_RETRIES = 0.5, 10

local SET_FIRST, MYTHIC_FIRST, MYTHIC_TIERS = 903000, 904500, 20
local SET_PIECES_PER_TIER = 8
local MYTHIC_KINDS = 20
local FIRST_ACCESSORY_KIND, FIRST_TRINKET_KIND = 9, 12
local LEGENDARY_FIRST, LEGENDARY_KINDS = 905000, 8
local LEGACY_LEGENDARY_FIRST = 901420
local UPGRADE_ARROW = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"

local ACCESSORY_GROUPS = {
    { key = "cloak", name = "Cloaks" },
    { key = "neck", name = "Necks" },
    { key = "ring", name = "Rings" },
    { key = "trinket", name = "Trinkets" },
}
local ARMOR_GROUPS = {
    { key = "head", name = "Head" },
    { key = "shoulder", name = "Shoulders" },
    { key = "chest", name = "Chest" },
    { key = "wrist", name = "Wrists" },
    { key = "hands", name = "Hands" },
    { key = "waist", name = "Waist" },
    { key = "legs", name = "Legs" },
    { key = "feet", name = "Feet" },
}
local CATEGORY_ART = {
    sets = { name = "Sets", icon = "Interface\\Icons\\INV_Helmet_74" },
    armor = { name = "Armor", icon = "Interface\\Icons\\INV_Chest_Plate16", groups = ARMOR_GROUPS },
    weapons = { name = "Weapons", icon = "Interface\\Icons\\INV_Sword_50" },
    accessories = { name = "Accessories", icon = "Interface\\Icons\\INV_Jewelry_Talisman_12", groups = ACCESSORY_GROUPS },
    legendaries = { name = "Legendaries", icon = "Interface\\Icons\\INV_Sword_39" },
    buyback = { name = "Buyback", icon = "Interface\\Icons\\INV_Misc_Coin_01" },
}
local MODES = {
    mythic = { title = "Mythic Quartermaster", categories = { "sets", "weapons", "accessories", "buyback" } },
    gear = { title = "Gear Vendor", categories = { "armor", "weapons", "accessories", "buyback" } },
}
local ACCESSORY_KIND_GROUP = { [9] = "cloak", [10] = "neck", [11] = "ring" }
local EQUIP_PLACES = {
    INVTYPE_HEAD = { "armor", "head" }, INVTYPE_SHOULDER = { "armor", "shoulder" }, INVTYPE_CHEST = { "armor", "chest" },
    INVTYPE_ROBE = { "armor", "chest" }, INVTYPE_WRIST = { "armor", "wrist" }, INVTYPE_HAND = { "armor", "hands" },
    INVTYPE_WAIST = { "armor", "waist" }, INVTYPE_LEGS = { "armor", "legs" }, INVTYPE_FEET = { "armor", "feet" },
    INVTYPE_CLOAK = { "accessories", "cloak" }, INVTYPE_NECK = { "accessories", "neck" },
    INVTYPE_FINGER = { "accessories", "ring" }, INVTYPE_TRINKET = { "accessories", "trinket" },
    INVTYPE_WEAPON = { "weapons" }, INVTYPE_2HWEAPON = { "weapons" }, INVTYPE_WEAPONMAINHAND = { "weapons" },
    INVTYPE_WEAPONOFFHAND = { "weapons" }, INVTYPE_SHIELD = { "weapons" }, INVTYPE_HOLDABLE = { "weapons" },
    INVTYPE_RANGED = { "weapons" }, INVTYPE_RANGEDRIGHT = { "weapons" }, INVTYPE_THROWN = { "weapons" },
    INVTYPE_RELIC = { "weapons" },
}
UI.trinketTips = UI.trinketTips or {}
UI.vendorTierTabs = {}

function UI.QualityColor(link)
    local _, _, hex = strfind(link or "", "|c%x%x(%x%x%x%x%x%x)")
    if not hex then
        return 1, 1, 1
    end
    return tonumber(strsub(hex, 1, 2), 16) / 255, tonumber(strsub(hex, 3, 4), 16) / 255, tonumber(strsub(hex, 5, 6), 16) / 255
end

function UI.GearTier(id)
    if not id then
        return nil
    end
    if id >= SET_FIRST and id < MYTHIC_FIRST then
        return floor(mod(id - SET_FIRST, MYTHIC_TIERS * SET_PIECES_PER_TIER) / SET_PIECES_PER_TIER) + 1
    end
    if id >= MYTHIC_FIRST and id < MYTHIC_FIRST + MYTHIC_KINDS * MYTHIC_TIERS then
        return mod(id - MYTHIC_FIRST, MYTHIC_TIERS) + 1
    end
    if id >= LEGENDARY_FIRST and id < LEGENDARY_FIRST + LEGENDARY_KINDS * MYTHIC_TIERS then
        return mod(id - LEGENDARY_FIRST, MYTHIC_TIERS) + 1
    end
    if id >= LEGACY_LEGENDARY_FIRST and id < LEGACY_LEGENDARY_FIRST + LEGENDARY_KINDS then
        return 1
    end
    return nil
end

local qm = { pending = nil, mode = "mythic", tier = 0, refitCount = 0, refitFee = 0, tabs = {}, currentTab = nil, category = "sets", group = nil, page = 1, items = {},
    scrap = 0, scrapNeeded = 100, upgrade = false, upgradeRoom = false, found = {} }

local frame = UI.GoldWindow("VanillaBonkQuartermasterFrame", WIDTH, HEIGHT)
frame:SetPoint("CENTER", UIParent, "CENTER", -BAGS_ROOM / 2, 20)
frame:SetFrameLevel(4)
frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
frame.base = CreateFrame("Frame", nil, frame)
frame.base:SetFrameLevel(3)
frame.base:SetAllPoints(frame)
frame.base:SetBackdrop({ bgFile = UI.FLAT, insets = { left = 11, right = 11, top = 11, bottom = 11 } })
frame.base:SetBackdropColor(UI.WINDOW_BG[1], UI.WINDOW_BG[2], UI.WINDOW_BG[3], 1)
frame.close:SetFrameLevel(frame:GetFrameLevel() + 3)
frame.headerArt:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Header")
frame.headerArt:SetWidth(320)
frame.headerArt:SetHeight(72)
frame.title:ClearAllPoints()
frame.title:SetPoint("TOP", frame.headerArt, "TOP", 0, -16)

frame.portrait = frame:CreateTexture(nil, "ARTWORK")
frame.portrait:SetWidth(52)
frame.portrait:SetHeight(52)
frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -18)
frame.npcName = UI.Text(frame, 20, "Fonts\\MORPHEUS.TTF")
frame.npcName:SetPoint("TOPLEFT", frame, "TOPLEFT", 80, -24)
frame.npcName:SetTextColor(1, 0.82, 0)
frame.stock = UI.Text(frame, 11)
frame.stock:SetPoint("TOPLEFT", frame.npcName, "BOTTOMLEFT", 1, -4)
frame.stock:SetTextColor(0.78, 0.75, 0.69)
frame.tierNote = UI.Text(frame, 10)
frame.tierNote:SetPoint("TOPLEFT", frame.stock, "BOTTOMLEFT", 0, -3)
frame.tierNote:SetTextColor(0.54, 0.52, 0.47)
frame.divider = UI.Divider(frame, WIDTH - 36)
frame.divider:SetPoint("TOPLEFT", frame, "TOPLEFT", 18, -80)

frame.upgrade = UI.Button(frame, 150, "Upgrade with Scrap", function()
    PlaySound(qm.upgrade and "igMainMenuOptionCheckBoxOff" or "igMainMenuOptionCheckBoxOn")
    SendChatMessage(".bonk gear upgrade " .. (qm.upgrade and "off" or "on"), "SAY")
end)
frame.upgrade:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -24, -34)
frame.upgrade:Hide()
frame.scrap = UI.Text(frame, 11, UI.NUMBER_FONT)
frame.scrap:SetPoint("BOTTOM", frame.upgrade, "TOP", 0, 3)
frame.scrap:SetTextColor(0.78, 0.75, 0.69)
frame.scrap:Hide()

frame.done = UI.Button(frame, 90, "Close", function() frame:Hide() end)
frame.done:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", SIDE_X, 18)

frame.refit = UI.Button(frame, SIDE_W, "Refit set pieces", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    SendChatMessage(".bonk gear refit", "SAY")
end)
frame.refit:SetPoint("BOTTOMLEFT", frame.done, "TOPLEFT", 0, 12)
frame.refit:Hide()
frame.refitNote = UI.Text(frame, 11)
frame.refitNote:SetPoint("BOTTOMLEFT", frame.refit, "TOPLEFT", 0, 4)
frame.refitNote:SetWidth(SIDE_W)
frame.refitNote:SetJustifyH("LEFT")
frame.refitNote:SetTextColor(0.78, 0.75, 0.69)
frame.refitNote:Hide()

local listWidth = WIDTH - LIST_X - 18
local listHeight = HEIGHT - LIST_TOP - 18
local cardWidth = floor((listWidth - CONTENT_SIDE * 2 - CARD_GAP * (CARD_COLUMNS - 1)) / CARD_COLUMNS)
local panel = UI.Pane(frame, LIST_X, LIST_TOP, listWidth, listHeight, PANE_ART, PANE_DIM)
UI.SetPaneArt(panel, PANE_ART, PANE_FOCUS)

panel.heading = UI.Text(panel, 12)
panel.heading:SetPoint("TOPLEFT", panel, "TOPLEFT", 14, -12)
panel.heading:SetTextColor(1, 0.82, 0)
panel.headingNote = UI.Text(panel, 10)
panel.headingNote:SetPoint("LEFT", panel.heading, "RIGHT", 8, 0)
panel.headingNote:SetTextColor(0.54, 0.52, 0.47)
panel.hint = UI.Text(panel, 10)
panel.hint:SetPoint("BOTTOMLEFT", panel, "BOTTOMLEFT", 14, 10)
panel.hint:SetTextColor(0.54, 0.52, 0.47)
panel.hint:SetText("Right-click an item to buy it, Ctrl-click to preview it. Right-click your own items to sell them.")

local Refresh

local function Command(text)
    SendChatMessage(".bonk gear " .. text, "SAY")
end

local function PageButton(direction)
    local button = CreateFrame("Button", nil, panel)
    button:SetWidth(24)
    button:SetHeight(24)
    local art = "Interface\\Buttons\\UI-SpellbookIcon-" .. direction .. "Page-"
    button:SetNormalTexture(art .. "Up")
    button:SetPushedTexture(art .. "Down")
    button:SetDisabledTexture(art .. "Disabled")
    button:SetHighlightTexture("Interface\\Buttons\\UI-Common-MouseHilight", "ADD")
    return button
end

panel.nextPage = PageButton("Next")
panel.nextPage:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -8, -6)
panel.nextPage:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    qm.page = qm.page + 1
    Refresh()
end)
panel.prevPage = PageButton("Prev")
panel.prevPage:SetPoint("RIGHT", panel.nextPage, "LEFT", -2, 0)
panel.prevPage:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    qm.page = qm.page - 1
    Refresh()
end)
panel.pageText = UI.Text(panel, 10)
panel.pageText:SetPoint("RIGHT", panel.prevPage, "LEFT", -4, 0)
panel.pageText:SetTextColor(0.54, 0.52, 0.47)

local tierTabs = UI.PanelTabs(panel, 0, function(index)
    local entry = qm.tabs[index]
    if not entry or entry.group == qm.currentTab then
        return
    end
    PlaySound("igCharacterInfoTab")
    qm.currentTab = entry.group
    qm.page = 1
    Command("tab " .. entry.group)
    Refresh()
end)

local function ItemId(link)
    local _, _, id = strfind(link or "", "item:(%d+)")
    return tonumber(id)
end

local function ClassifyMythic(id)
    if not id then
        return nil
    end
    if id >= SET_FIRST and id < MYTHIC_FIRST then
        return "sets"
    end
    if id >= LEGENDARY_FIRST and id < LEGENDARY_FIRST + LEGENDARY_KINDS * MYTHIC_TIERS then
        return "legendaries"
    end
    local kind = floor((id - MYTHIC_FIRST) / MYTHIC_TIERS)
    if id < MYTHIC_FIRST or kind >= MYTHIC_KINDS then
        return nil
    end
    if kind < FIRST_ACCESSORY_KIND then
        return "weapons"
    end
    return "accessories", kind >= FIRST_TRINKET_KIND and "trinket" or ACCESSORY_KIND_GROUP[kind]
end

local function ClassifyBySlot(id)
    if not id then
        return nil
    end
    local _, _, _, _, _, _, _, equipLoc = GetItemInfo(id)
    if not equipLoc then
        return nil, nil, true
    end
    local place = EQUIP_PLACES[equipLoc]
    if not place then
        return "armor"
    end
    return place[1], place[2]
end

local function CollectBuyback()
    if not GetNumBuybackItems then
        return
    end
    for index = 1, GetNumBuybackItems() do
        local name, texture, price = GetBuybackItemInfo(index)
        if name then
            tinsert(qm.items, { index = index, link = GetBuybackItemLink and GetBuybackItemLink(index), name = name, texture = texture,
                price = price, usable = true, category = "buyback", buyback = true })
        end
    end
end

local function CollectItems()
    qm.items = {}
    qm.missingInfo = nil
    for index = 1, GetMerchantNumItems() do
        local link = GetMerchantItemLink(index)
        local name, texture, price, _, _, usable = GetMerchantItemInfo(index)
        local category, group, missing
        if qm.mode == "gear" then
            category, group, missing = ClassifyBySlot(ItemId(link))
        else
            category, group = ClassifyMythic(ItemId(link))
        end
        if missing or not name then
            qm.missingInfo = true
        elseif category then
            tinsert(qm.items, { index = index, link = link, name = name, texture = texture, price = price, usable = usable,
                category = category, group = group })
        end
    end
    CollectBuyback()
end

local function Shown()
    local shown = {}
    for _, item in ipairs(qm.items) do
        if item.category == qm.category and (not qm.group or item.group == qm.group) then
            tinsert(shown, item)
        end
    end
    return shown
end

local function CountIn(category, group)
    local count = 0
    for _, item in ipairs(qm.items) do
        if item.category == category and (not group or item.group == group) then
            count = count + 1
        end
    end
    return count
end

local function SideButton(height, indent)
    local button = CreateFrame("Button", nil, frame)
    button:SetWidth(SIDE_W - indent)
    button:SetHeight(height)
    button.strip = UI.Strip(button)
    button.strip:SetAllPoints(button)
    button.label = UI.Text(button.strip, height > 24 and 12 or 11)
    button.label:SetJustifyH("LEFT")
    button.count = UI.Text(button.strip, 10)
    button.count:SetPoint("RIGHT", button, "RIGHT", -10, 0)
    button.count:SetTextColor(0.54, 0.52, 0.47)
    return button
end

local categoryButtons, groupButtons = {}, {}

local function CategoryButton(index)
    if categoryButtons[index] then
        return categoryButtons[index]
    end
    local button = SideButton(CATEGORY_HEIGHT, 0)
    button.icon = button.strip:CreateTexture(nil, "OVERLAY")
    button.icon:SetWidth(24)
    button.icon:SetHeight(24)
    button.icon:SetPoint("LEFT", button, "LEFT", 4, 0)
    UI.CropIcon(button.icon)
    button.label:SetPoint("LEFT", button.icon, "RIGHT", 8, 0)
    button:SetScript("OnClick", function()
        PlaySound("igCharacterInfoTab")
        qm.category = this.key
        qm.group = nil
        qm.page = 1
        Refresh()
    end)
    categoryButtons[index] = button
    return button
end

local function GroupButton(index)
    if groupButtons[index] then
        return groupButtons[index]
    end
    local button = SideButton(SUB_HEIGHT - 1, 10)
    button.label:SetPoint("LEFT", button, "LEFT", 12, 0)
    button:SetScript("OnClick", function()
        PlaySound("igCharacterInfoTab")
        qm.group = qm.group ~= this.key and this.key or nil
        qm.page = 1
        Refresh()
    end)
    groupButtons[index] = button
    return button
end

local cards, sections = {}, {}

local function PaintCard(card, hovered)
    if hovered then
        card:SetBackdropBorderColor(1, 0.82, 0, 0.9)
    else
        card:SetBackdropBorderColor(0, 0, 0, 1)
    end
end

local function Card(index)
    if cards[index] then
        return cards[index]
    end
    local card = CreateFrame("Button", nil, panel)
    card:SetWidth(cardWidth)
    card:SetHeight(CARD_HEIGHT)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    card:SetBackdropColor(0.03, 0.027, 0.04, 0.88)
    card.tint = card:CreateTexture(nil, "BORDER")
    card.tint:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card.tint:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 1, 1)
    card.tint:SetWidth(cardWidth * 0.45)
    card.bar = card:CreateTexture(nil, "ARTWORK")
    card.bar:SetTexture(UI.FLAT)
    card.bar:SetPoint("TOPLEFT", card, "TOPLEFT", 1, -1)
    card.bar:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 1, 1)
    card.bar:SetWidth(2)
    card.slot = UI.Slot(card, ICON_SIZE, "Frame")
    card.slot:SetPoint("LEFT", card, "LEFT", 7, 0)
    card.name = UI.Text(card, 11)
    card.name:SetPoint("TOPLEFT", card, "TOPLEFT", ICON_SIZE + 14, -5)
    card.name:SetWidth(cardWidth - ICON_SIZE - 18)
    card.name:SetHeight(26)
    card.name:SetJustifyH("LEFT")
    card.name:SetJustifyV("TOP")
    card.price = UI.Text(card, 11)
    card.price:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", ICON_SIZE + 14, 5)
    card.arrowFrame = CreateFrame("Frame", nil, card)
    card.arrowFrame:SetAllPoints(card)
    card.arrowFrame:SetFrameLevel(card.slot:GetFrameLevel() + 2)
    card.arrow = card.arrowFrame:CreateTexture(nil, "OVERLAY")
    card.arrow:SetTexture(UPGRADE_ARROW)
    card.arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    card.arrow:SetWidth(16)
    card.arrow:SetHeight(16)
    card.arrow:SetPoint("TOPRIGHT", card.slot, "TOPRIGHT", 5, 5)
    card.arrow:SetVertexColor(0.2, 1, 0.2)
    card.arrow:Hide()
    card.found = UI.Text(card, 10)
    card.found:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 5)
    card.found:SetTextColor(0.2, 1, 0.2)
    card.found:SetText("Found")
    card.found:Hide()
    card:SetScript("OnClick", function()
        local item = this.item
        if not item then
            return
        end
        if arg1 == "RightButton" then
            if item.buyback then
                BuybackItem(item.index)
            else
                BuyMerchantItem(item.index)
            end
        elseif IsControlKeyDown() and DressUpItemLink and item.link then
            DressUpItemLink(item.link)
        end
    end)
    card:SetScript("OnEnter", function()
        if this.item then
            SetCursor("BUY_CURSOR")
            PaintCard(this, true)
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            if this.item.buyback then
                GameTooltip:SetBuybackItem(this.item.index)
            else
                GameTooltip:SetMerchantItem(this.item.index)
                if qm.mode == "gear" and qm.found[ItemId(this.item.link) or 0] then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine("Found in a run: half price.", 0.2, 1, 0.2)
                    GameTooltip:Show()
                end
                if qm.mode == "mythic" and qm.upgrade then
                    GameTooltip:AddLine(" ")
                    GameTooltip:AddLine(this.item.category == "legendaries" and "Upgrade: replaces your legendary for " .. qm.scrapNeeded .. " Scrap."
                        or "Upgrade: one tier above stock. Buying it also spends " .. qm.scrapNeeded .. " Scrap.", 0.2, 1, 0.2)
                    GameTooltip:Show()
                end
            end
        end
    end)
    card:SetScript("OnLeave", function()
        ResetCursor()
        PaintCard(this, false)
        GameTooltip:Hide()
    end)
    cards[index] = card
    return card
end

local function Section(index)
    if sections[index] then
        return sections[index]
    end
    local section = CreateFrame("Frame", nil, panel)
    section:SetWidth(listWidth - CONTENT_SIDE * 2)
    section:SetHeight(SECTION_HEIGHT)
    section.label = UI.Text(section, 12)
    section.label:SetPoint("LEFT", section, "LEFT", 0, 0)
    section.label:SetTextColor(1, 0.82, 0)
    section.count = UI.Text(section, 10)
    section.count:SetPoint("LEFT", section.label, "RIGHT", 6, 0)
    section.count:SetTextColor(0.54, 0.52, 0.47)
    section.line = section:CreateTexture(nil, "ARTWORK")
    section.line:SetHeight(1)
    section.line:SetPoint("LEFT", section.count, "RIGHT", 8, 0)
    section.line:SetPoint("RIGHT", section, "RIGHT", 0, 0)
    UI.Gradient(section.line, "HORIZONTAL", 0.78, 0.63, 0.27, 0.8, 0)
    sections[index] = section
    return section
end

local function ModeCategories()
    local categories = MODES[qm.mode].categories
    if qm.mode ~= "mythic" or not qm.upgrade then
        return categories
    end
    for _, item in ipairs(qm.items) do
        if item.category == "legendaries" then
            local withLegendaries = {}
            for _, key in ipairs(categories) do
                if key == "buyback" then
                    tinsert(withLegendaries, "legendaries")
                end
                tinsert(withLegendaries, key)
            end
            return withLegendaries
        end
    end
    return categories
end

local function LayoutSide()
    local y = LIST_TOP
    local groupIndex = 0
    for index, key in ipairs(ModeCategories()) do
        local art = CATEGORY_ART[key]
        local button = CategoryButton(index)
        button.key = key
        button.icon:SetTexture(art.icon)
        button.label:SetText(art.name)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_X, -y)
        button.count:SetText(CountIn(key))
        UI.SetStripHighlight(button.strip, key == qm.category)
        if key == qm.category then
            button.label:SetTextColor(1, 1, 1)
        else
            button.label:SetTextColor(1, 0.82, 0)
        end
        button:Show()
        y = y + CATEGORY_HEIGHT + 4
        if art.groups and key == qm.category then
            for _, group in ipairs(art.groups) do
                local count = CountIn(key, group.key)
                if count > 0 then
                    groupIndex = groupIndex + 1
                    local sub = GroupButton(groupIndex)
                    sub.key = group.key
                    sub.label:SetText(group.name)
                    sub.count:SetText(count)
                    sub:ClearAllPoints()
                    sub:SetPoint("TOPLEFT", frame, "TOPLEFT", SIDE_X + 10, -y)
                    UI.SetStripHighlight(sub.strip, qm.group == group.key)
                    if qm.group == group.key then
                        sub.label:SetTextColor(1, 1, 1)
                    else
                        sub.label:SetTextColor(1, 0.82, 0)
                    end
                    sub:Show()
                    y = y + SUB_HEIGHT
                end
            end
        end
    end
    for index = table.getn(ModeCategories()) + 1, table.getn(categoryButtons) do
        categoryButtons[index]:Hide()
    end
    for index = groupIndex + 1, table.getn(groupButtons) do
        groupButtons[index]:Hide()
    end
end

local function HeadingText()
    local art = CATEGORY_ART[qm.category]
    if not art then
        return ""
    end
    for _, group in ipairs(art.groups or {}) do
        if group.key == qm.group then
            return group.name
        end
    end
    return art.name
end

local function LayoutTierTabs()
    UI.vendorTierTabs = {}
    if qm.mode ~= "gear" or table.getn(qm.tabs) < 2 then
        tierTabs:SetTabs({})
        frame.divider:Show()
        return
    end
    local labels, selected = {}, 1
    for index, entry in ipairs(qm.tabs) do
        labels[index] = entry.name
        if entry.group == qm.currentTab then
            selected = index
        end
    end
    tierTabs:SetTabs(labels)
    local width = 0
    for index = 1, table.getn(labels) do
        width = width + tierTabs.tabs[index]:GetWidth() + 5
    end
    local offset = listWidth - width - 9
    for index = 1, table.getn(labels) do
        local tab = tierTabs.tabs[index]
        tab.left = tab.left + offset
        tinsert(UI.vendorTierTabs, { tab = tab, name = labels[index] })
    end
    tierTabs:Select(selected)
    frame.divider:Hide()
end

local function JoinNames(names)
    local count = table.getn(names)
    if count == 1 then
        return names[1]
    end
    return table.concat(names, ", ", 1, count - 1) .. " and " .. names[count]
end

local function Sections(shown)
    local art = CATEGORY_ART[qm.category]
    if qm.group or not art or not art.groups then
        return { { items = shown } }
    end
    local list = {}
    for _, group in ipairs(art.groups) do
        local items = {}
        for _, item in ipairs(shown) do
            if item.group == group.key then
                tinsert(items, item)
            end
        end
        local count = table.getn(items)
        if count > 0 then
            local last = list[table.getn(list)]
            if last and last.mergeable and table.getn(last.items) + count <= MERGE_LIMIT then
                for _, item in ipairs(items) do
                    tinsert(last.items, item)
                end
                tinsert(last.names, group.name)
            else
                tinsert(list, { names = { group.name }, items = items, mergeable = count < MERGE_LIMIT })
            end
        end
    end
    for _, section in ipairs(list) do
        section.title = JoinNames(section.names)
    end
    return list
end

local function Paginate(sectionList)
    local pages, page, y = {}, {}, 0
    local room = listHeight - CONTENT_TOP - CONTENT_BOTTOM
    for _, section in ipairs(sectionList) do
        local header = section.title and SECTION_HEIGHT or 0
        local count = table.getn(section.items)
        local first = 1
        while first <= count do
            if y + header + CARD_HEIGHT > room and table.getn(page) > 0 then
                tinsert(pages, page)
                page, y = {}, 0
            end
            if header > 0 then
                tinsert(page, { section = section, y = y })
                y = y + header
            end
            local column = 0
            while first <= count do
                if column == CARD_COLUMNS then
                    if y + (CARD_HEIGHT + CARD_GAP) * 2 > room + CARD_GAP then
                        break
                    end
                    column = 0
                    y = y + CARD_HEIGHT + CARD_GAP
                end
                tinsert(page, { item = section.items[first], x = column, y = y })
                column = column + 1
                first = first + 1
            end
            y = y + CARD_HEIGHT + CARD_GAP + 4
            if first <= count then
                tinsert(pages, page)
                page, y = {}, 0
            end
        end
    end
    if table.getn(page) > 0 or table.getn(pages) == 0 then
        tinsert(pages, page)
    end
    return pages
end

local function ShowCard(card, item, x, y)
    card:ClearAllPoints()
    card:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_SIDE + x * (cardWidth + CARD_GAP), -(CONTENT_TOP + y))
    card.item = item
    local r, g, b = UI.QualityColor(item.link)
    card.slot.icon:SetTexture(item.texture)
    if item.usable == nil or item.usable then
        card.slot.icon:SetVertexColor(1, 1, 1)
    else
        card.slot.icon:SetVertexColor(0.9, 0.2, 0.2)
    end
    card.name:SetText(item.name)
    card.name:SetTextColor(r, g, b)
    card.price:SetText(UI.FormatGold(item.price))
    if qm.mode == "gear" and not item.buyback and qm.found[ItemId(item.link) or 0] then
        card.found:Show()
    else
        card.found:Hide()
    end
    if qm.mode == "mythic" and qm.upgrade and not item.buyback then
        card.arrow:Show()
    else
        card.arrow:Hide()
    end
    card.bar:SetVertexColor(r, g, b, 0.85)
    UI.Gradient(card.tint, "HORIZONTAL", r * 0.6, g * 0.6, b * 0.6, 0.35, 0)
    PaintCard(card, false)
    card:Show()
end

local function PlaceRows(shown)
    local pages = Paginate(Sections(shown))
    qm.page = math.max(1, math.min(qm.page, table.getn(pages)))
    local cardCount, sectionCount = 0, 0
    for _, entry in ipairs(pages[qm.page]) do
        if entry.item then
            cardCount = cardCount + 1
            ShowCard(Card(cardCount), entry.item, entry.x, entry.y)
        else
            sectionCount = sectionCount + 1
            local section = Section(sectionCount)
            section:ClearAllPoints()
            section:SetPoint("TOPLEFT", panel, "TOPLEFT", CONTENT_SIDE, -(CONTENT_TOP + entry.y))
            section.label:SetText(entry.section.title)
            section.count:SetText(table.getn(entry.section.items))
            section:Show()
        end
    end
    for index = cardCount + 1, table.getn(cards) do
        cards[index].item = nil
        cards[index]:Hide()
    end
    for index = sectionCount + 1, table.getn(sections) do
        sections[index]:Hide()
    end
    local count = table.getn(pages)
    if count > 1 then
        panel.pageText:SetText("Page " .. qm.page .. " of " .. count)
        panel.pageText:Show()
        panel.prevPage:Show()
        panel.nextPage:Show()
        if qm.page > 1 then panel.prevPage:Enable() else panel.prevPage:Disable() end
        if qm.page < count then panel.nextPage:Enable() else panel.nextPage:Disable() end
    else
        panel.pageText:Hide()
        panel.prevPage:Hide()
        panel.nextPage:Hide()
    end
end

local function TabName()
    for _, entry in ipairs(qm.tabs) do
        if entry.group == qm.currentTab then
            return entry.name
        end
    end
end

local function StockText()
    if qm.mode == "gear" then
        local tab = TabName()
        return tab and ("Gear Vendor  |cff8a8478·|r  Stock: |cffffd100" .. tab .. "|r") or "Gear Vendor"
    end
    if qm.upgrade then
        return "Mythic Quartermaster  |cff8a8478·|r  Upgrades: |cff33ff33Tier " .. (qm.tier + 1) .. "|r  |cff8a8478(one above stock, for Scrap)|r"
    end
    return "Mythic Quartermaster  |cff8a8478·|r  Stock: |cffffd100Tier " .. qm.tier .. "|r  |cff8a8478(2 below your best Mythic floor cleared)|r"
end

local function LayoutRefit()
    if qm.mode ~= "mythic" then
        frame.refit:Hide()
        frame.refitNote:Hide()
        return
    end
    local count = qm.refitCount
    if count > 0 then
        frame.refit:SetText(count == 1 and "Refit 1 set piece" or ("Refit " .. count .. " set pieces"))
        frame.refitNote:SetText("Set pieces from other classes in your bags become your class's. Costs " .. UI.FormatGold(qm.refitFee) .. ".")
        frame.refit:Enable()
    else
        frame.refit:SetText("Refit set pieces")
        frame.refitNote:SetText("Bring set pieces from your other characters to refit them for this class for a small fee.")
        frame.refit:Disable()
    end
    frame.refit:Show()
    frame.refitNote:Show()
end

local function LayoutUpgrade()
    if qm.mode ~= "mythic" then
        frame.upgrade:Hide()
        frame.scrap:Hide()
        return
    end
    frame.scrap:SetText("Scrap " .. qm.scrap .. "/" .. qm.scrapNeeded)
    if qm.upgrade then
        frame.upgrade:SetText("Stop upgrading")
        frame.upgrade:Enable()
    else
        frame.upgrade:SetText("Upgrade with Scrap")
        if qm.scrap >= qm.scrapNeeded and qm.upgradeRoom then
            frame.upgrade:Enable()
        else
            frame.upgrade:Disable()
        end
    end
    frame.upgrade:Show()
    frame.scrap:Show()
end

local retry = CreateFrame("Frame")
retry:Hide()
retry:SetScript("OnUpdate", function()
    this.wait = this.wait - arg1
    if this.wait > 0 then
        return
    end
    this.tries = this.tries - 1
    this:Hide()
    Refresh()
end)

local function RetryMissingInfo()
    if qm.missingInfo and retry.tries and retry.tries > 0 then
        retry.wait = INFO_RETRY_SECONDS
        retry:Show()
    end
end

Refresh = function()
    if not frame:IsShown() then
        return
    end
    CollectItems()
    LayoutSide()
    LayoutTierTabs()
    LayoutRefit()
    LayoutUpgrade()
    frame.title:SetText(MODES[qm.mode].title)
    frame.stock:SetText(StockText())
    frame.tierNote:SetText(qm.mode == "mythic"
        and ("New floors raise stock a tier. Unextracted Mythic items give Scrap. " .. qm.scrapNeeded .. " Scrap buys one item a tier higher.") or "")
    panel.heading:SetText(HeadingText())
    panel.headingNote:SetText(qm.mode == "mythic" and qm.category ~= "buyback" and qm.category ~= "legendaries"
        and ("Tier " .. (qm.upgrade and qm.tier + 1 or qm.tier)) or "")
    PlaceRows(Shown())
    RetryMissingInfo()
end

local function HideMerchantFrame()
    MerchantFrame:SetAlpha(0)
    MerchantFrame:ClearAllPoints()
    MerchantFrame:SetPoint("TOPRIGHT", UIParent, "TOPLEFT", -100, 0)
end

local function RestoreMerchantFrame()
    MerchantFrame:SetAlpha(1)
    MerchantFrame:ClearAllPoints()
    MerchantFrame:SetPoint("TOPLEFT", UIParent, "TOPLEFT", 0, -104)
    if UpdateUIPanelPositions then
        UpdateUIPanelPositions(MerchantFrame)
    end
end

local function ApplyPending()
    local pending = qm.pending
    qm.pending = nil
    if pending.mode ~= qm.mode then
        qm.mode = pending.mode
        qm.category = ModeCategories()[1]
        qm.group = nil
        qm.page = 1
    end
    if pending.mode == "gear" then
        if pending.currentTab ~= qm.currentTab then
            qm.page = 1
        end
        qm.tabs = pending.tabs
        qm.currentTab = pending.currentTab
    else
        qm.tier = pending.tier
        qm.scrap = pending.scrap
        qm.scrapNeeded = pending.scrapNeeded
        if qm.upgrade ~= pending.upgrade and qm.category == "legendaries" then
            qm.category = ModeCategories()[1]
            qm.page = 1
        end
        qm.upgrade = pending.upgrade
        qm.upgradeRoom = pending.upgradeRoom
    end
    retry.tries = INFO_RETRIES
end

local function OpenWindow()
    ApplyPending()
    qm.open = true
    HideMerchantFrame()
    if frame:IsShown() then
        Refresh()
    else
        frame:Show()
    end
end

frame:SetScript("OnShow", function()
    if UnitExists("npc") then
        SetPortraitTexture(frame.portrait, "npc")
        frame.npcName:SetText(UnitName("npc"))
    end
    Refresh()
end)

frame:SetScript("OnHide", function()
    GameTooltip:Hide()
    retry:Hide()
    UI.vendorTierTabs = {}
    if qm.open then
        qm.open = nil
        RestoreMerchantFrame()
        CloseMerchant()
    end
end)

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("MERCHANT_UPDATE")
events:RegisterEvent("MERCHANT_CLOSED")
events:RegisterEvent("PLAYER_MONEY")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:SetScript("OnEvent", function()
    if event == "MERCHANT_SHOW" then
        if qm.pending then
            OpenWindow()
        elseif qm.open then
            HideMerchantFrame()
            Refresh()
        end
    elseif event == "MERCHANT_CLOSED" then
        qm.pending = nil
        if qm.open then
            qm.open = nil
            RestoreMerchantFrame()
            frame:Hide()
        end
    elseif frame:IsShown() then
        Refresh()
    end
end)

local function Receive(pending)
    qm.pending = pending
    if MerchantFrame:IsShown() then
        OpenWindow()
    end
end

local handlers = {}

handlers["quartermaster"] = function(f)
    Receive({ mode = "mythic", tier = tonumber(f[2]) or 0, scrap = tonumber(f[3] or "") or 0, scrapNeeded = tonumber(f[4] or "") or 100,
        upgrade = f[5] == "1", upgradeRoom = f[6] == "1" })
end

handlers["gearfoundclear"] = function()
    qm.found = {}
end

handlers["gearfound"] = function(f)
    for _, text in ipairs(UI.Split(f[2] or "", ",")) do
        local id = tonumber(text)
        if id then
            qm.found[id] = true
        end
    end
end

handlers["qmrefit"] = function(f)
    qm.refitCount = tonumber(f[2]) or 0
    qm.refitFee = tonumber(f[3]) or 0
    Refresh()
end

handlers["geartabs"] = function(f)
    local tabs = {}
    local index = 3
    while f[index] and f[index + 1] do
        tinsert(tabs, { group = tonumber(f[index]), name = f[index + 1] })
        index = index + 2
    end
    Receive({ mode = "gear", currentTab = tonumber(f[2]), tabs = tabs })
end

handlers["trinkettip"] = function(f)
    local first, count, text = tonumber(f[2]), tonumber(f[3]), f[4]
    if not first or not count or not text then
        return
    end
    for id = first, first + count - 1 do
        UI.trinketTips[id] = text
    end
end

UI.Listen(handlers)
