local L = VanillaBonkL
local UI = VanillaBonkUI

local CARD_WIDTH = 118
local CARD_HEIGHT = 168
local CARD_GAP = 10
local PER_ROW = 8
local PER_PAGE = PER_ROW * 2
local SLOT_SIZE = 52
local VAULT_SLOT_SPACING = 104
local VAULT_BOX_MARGIN = 92
local VAULT_BOX_MIN_WIDTH = 220
local WIDE_CAPTION, NARROW_CAPTION = 130, 100
local WORN_SLOTS = 19
local TOOLTIP_GAP = 4
local COMPARE_DROP = -10
local CARDS_TOP = 40
local CARDS_ROOM = 320
local WALK_AWAY = 3
local SAVED_LABEL = L["hoa.addon.your_saved_piece"]
local RETRY, RETRIES = 0.25, 12
local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }

local ARROW_UP = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
local ARROW_DOWN = "Interface\\Buttons\\UI-ScrollBar-ScrollDownButton-Up"

local Vault = UI.Module("vault")
Vault.state = { slots = 1, chosen = {}, order = {}, finds = {}, hearth = false, page = 1 }
Vault.incoming = nil
Vault.retries = 0
Vault.openedAt = nil

local function Command(text)
    SendChatMessage(".bonk vault " .. text, "SAY")
end

local function QualityColor(quality)
    local color = UI.RARITY[quality - 1] or UI.RARITY[1]
    return color.r, color.g, color.b
end

local frame = CreateFrame("Frame", "VanillaBonkVault", UIParent)
Vault.window = frame
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("DIALOG")
frame:Hide()
tinsert(UISpecialFrames, "VanillaBonkVault")

frame.dim = frame:CreateTexture(nil, "BACKGROUND")
frame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
frame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
frame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
frame.dim:SetVertexColor(0, 0, 0, 1)

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFont(UI.TITLE_FONT, 40, "OUTLINE")
frame.title:SetPoint("CENTER", frame, "CENTER", 0, 262)
frame.title:SetTextColor(1, 0.82, 0)
frame.title:SetText(L["hoa.addon.extraction_vault"])

frame.subtitle = UI.Text(frame, 13)
frame.subtitle:SetPoint("CENTER", frame, "CENTER", 0, 226)
frame.subtitle:SetTextColor(0.9, 0.83, 0.64)

for side = 1, 2 do
    local line = frame:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", frame.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", frame.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

frame.box = CreateFrame("Frame", nil, frame)
frame.box:SetHeight(128)
frame.box:SetPoint("CENTER", frame, "CENTER", 0, 132)
frame.box:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame.box.label = UI.Text(frame.box, 12)
frame.box.label:SetPoint("TOP", frame.box, "TOP", 0, -16)
frame.box.label:SetTextColor(1, 0.82, 0)
frame.box.label:SetText(L["hoa.addon.mailed_to_you_when_you_leave"])
frame.box.slots = {}

local function CursorOnRightHalf()
    local x = GetCursorPosition()
    return x / UIParent:GetEffectiveScale() > GetScreenWidth() / 2
end

local function SavedFound(saved)
    if not saved.place then
        return nil
    end
    local parts = UI.Split(saved.place, ":")
    local bag = parts[1] == "inv" and "inv" or tonumber(parts[1])
    local piece = UI.FoundAt(bag, tonumber(parts[2]))
    if piece and piece.entry == saved.entry then
        return piece
    end
    return nil
end

local function IsWorn(saved)
    local parts = saved.place and UI.Split(saved.place, ":")
    local slot = parts and parts[1] == "inv" and tonumber(parts[2])
    if not slot or slot > WORN_SLOTS then
        return false
    end
    local link = GetInventoryItemLink("player", slot)
    return link and strfind(link, "item:" .. saved.entry .. ":", 1, true) and true or false
end

local function BindText(text, replacement)
    if strsub(text, 1, strlen(ITEM_BIND_ON_PICKUP)) ~= ITEM_BIND_ON_PICKUP then
        return text
    end
    local rest = gsub(strsub(text, strlen(ITEM_BIND_ON_PICKUP) + 1), "^\n", "")
    if replacement then
        return rest ~= "" and replacement .. "\n" .. rest or replacement
    end
    return rest
end

local function RebuildItemTooltip(tooltip, entry, header, bindReplacement)
    local name = tooltip:GetName()
    local lines = {}
    for index = 1, tooltip:NumLines() do
        local left = getglobal(name .. "TextLeft" .. index)
        local right = getglobal(name .. "TextRight" .. index)
        local line = { text = BindText(left:GetText() or " ", bindReplacement) }
        line.r, line.g, line.b = left:GetTextColor()
        if right:IsShown() and right:GetText() then
            line.right = right:GetText()
            line.rr, line.rg, line.rb = right:GetTextColor()
        end
        if line.text ~= "" or line.right then
            tinsert(lines, line)
        end
    end
    local _, _, quality = GetItemInfo(entry)
    if lines[1] and quality then
        lines[1].r, lines[1].g, lines[1].b = GetItemQualityColor(quality)
    end
    tooltip:ClearLines()
    if header then
        tooltip:AddLine(header, 0.5, 0.5, 0.5)
    end
    for _, line in ipairs(lines) do
        if line.right then
            tooltip:AddDoubleLine(line.text, line.right, line.r, line.g, line.b, line.rr, line.rg, line.rb)
        else
            tooltip:AddLine(line.text, line.r, line.g, line.b, 1)
        end
    end
    tooltip.bonkHeader = header and true or nil
    tooltip.bonkItem = lines[1] and lines[1].text
    tooltip.bonkLines = tooltip:NumLines()
end

local function SetLineFont(tooltip, index, font)
    getglobal(tooltip:GetName() .. "TextLeft" .. index):SetFontObject(font)
    getglobal(tooltip:GetName() .. "TextRight" .. index):SetFontObject(font)
end

local function ResetItemFonts(tooltip)
    SetLineFont(tooltip, 1, GameTooltipHeaderText)
    SetLineFont(tooltip, 2, GameTooltipText)
end

local function ShowItemFonts(tooltip)
    local name = tooltip:GetName()
    if tooltip.bonkHeader then
        SetLineFont(tooltip, 1, GameTooltipTextSmall)
        SetLineFont(tooltip, 2, GameTooltipHeaderText)
    else
        ResetItemFonts(tooltip)
    end
    for index = 1, tooltip:NumLines() do
        getglobal(name .. "TextLeft" .. index):SetJustifyH("LEFT")
    end
    tooltip:Show()
end

for index = 1, 2 do
    local tooltip = getglobal("ShoppingTooltip" .. index)
    if tooltip then
        local onHide = tooltip:GetScript("OnHide")
        tooltip:SetScript("OnHide", function()
            if onHide then
                onHide()
            end
            if this.bonkHeader then
                this.bonkHeader = nil
                ResetItemFonts(this)
            end
        end)
    end
end

local function AnchorBeside(owner)
    GameTooltip:SetOwner(owner, "ANCHOR_NONE")
    GameTooltip:ClearAllPoints()
    if CursorOnRightHalf() then
        GameTooltip:SetPoint("TOPRIGHT", owner, "TOPLEFT", -TOOLTIP_GAP, 0)
    else
        GameTooltip:SetPoint("TOPLEFT", owner, "TOPRIGHT", TOOLTIP_GAP, 0)
    end
end

local function PlaceSaved(owner, tooltips)
    local width = 0
    for _, tooltip in ipairs(tooltips) do
        width = width + tooltip:GetWidth()
    end
    local screenWidth = GetScreenWidth() * UIParent:GetEffectiveScale() / GameTooltip:GetEffectiveScale()
    local mainOnLeft = GameTooltip:GetRight() <= owner:GetLeft() * owner:GetEffectiveScale() / GameTooltip:GetEffectiveScale() + 1
    local outward = mainOnLeft and GameTooltip:GetLeft() >= width or not mainOnLeft and screenWidth - GameTooltip:GetRight() >= width
    local leftward = (mainOnLeft and outward) or (not mainOnLeft and not outward)
    local previous = outward and GameTooltip or owner
    for index, tooltip in ipairs(tooltips) do
        tooltip:ClearAllPoints()
        local gap = index == 1 and (outward and COMPARE_DROP or 0) or 0
        local spacing = index == 1 and not outward and TOOLTIP_GAP or 0
        if leftward then
            tooltip:SetPoint("TOPRIGHT", previous, "TOPLEFT", -spacing, gap)
        else
            tooltip:SetPoint("TOPLEFT", previous, "TOPRIGHT", spacing, gap)
        end
        previous = tooltip
    end
end

local function ShowSaved(find, owner)
    local tooltips = {}
    for index = 1, min(2, getn(find.saved)) do
        local tooltip = getglobal("ShoppingTooltip" .. index)
        if not tooltip then
            break
        end
        tooltip:SetOwner(GameTooltip, "ANCHOR_NONE")
        tooltip:ClearAllPoints()
        tooltip:SetPoint("TOPLEFT", UIParent, "BOTTOMRIGHT", 0, 0)
        local saved = find.saved[index]
        local link = "item:" .. saved.entry .. ":0:0:0"
        tooltip:SetHyperlink(link)
        if VanillaBonk_AddGearLines then
            VanillaBonk_AddGearLines(tooltip, link, SavedFound(saved))
        end
        tooltip:AddLine(" ")
        tooltip:AddLine(SAVED_LABEL, 1, 0.82, 0)
        tooltip:AddLine(L["hoa.addon.you_brought_this_into_the_run"], 0.7, 0.7, 0.7)
        RebuildItemTooltip(tooltip, saved.entry, IsWorn(saved) and CURRENTLY_EQUIPPED or nil, ITEM_SOULBOUND)
        ShowItemFonts(tooltip)
        tinsert(tooltips, tooltip)
    end
    if getn(tooltips) > 0 then
        PlaceSaved(owner, tooltips)
    end
end

local function WorthText(find)
    local parts = {}
    if find.sell > 0 then
        tinsert(parts, UI.FormatGold(find.sell))
    end
    if find.scrap > 0 then
        tinsert(parts, L("hoa.addon.1_scrap", find.scrap))
    end
    return table.concat(parts, L["hoa.addon.and"])
end

local function LeftOutText(gold, scrap, rest)
    if gold > 0 and scrap > 0 then
        if rest then
            return L("hoa.addon.the_rest_sell_for_1_and_give_2_scrap", UI.FormatGold(gold), scrap)
        end
        return L("hoa.addon.sells_for_1_and_gives_2_scrap_if_you_leave_it_out_of_the_vau", UI.FormatGold(gold), scrap)
    elseif scrap > 0 then
        if rest then
            return L("hoa.addon.the_rest_give_1_scrap", scrap)
        end
        return L("hoa.addon.gives_1_scrap_if_you_leave_it_out_of_the_vault", scrap)
    end
    if rest then
        return L("hoa.addon.the_rest_sell_for_1", UI.FormatGold(gold))
    end
    return L("hoa.addon.sells_for_1_if_you_leave_it_out_of_the_vault", UI.FormatGold(gold))
end

function Vault:ShowItemTooltip(owner, find, line)
    AnchorBeside(owner)
    UI.nextFound = find.found
    GameTooltip:SetHyperlink("item:" .. find.entry .. ":0:0:0")
    GameTooltip:AddLine(" ")
    GameTooltip:AddLine(line, 1, 0.82, 0, 1)
    if find.owned then
        GameTooltip:AddLine(L["hoa.addon.you_already_own_this_piece_at_this_tier"], 1, 0.5, 0.25, 1)
    elseif find.tier > 0 and find.best > 0 then
        GameTooltip:AddLine(L("hoa.addon.your_best_in_this_slot_tier_1", find.best), 0.7, 0.7, 0.7, 1)
    end
    if not self.state.hearth then
        GameTooltip:AddLine(LeftOutText(find.sell, find.scrap), 0.7, 0.7, 0.7, 1)
    end
    if getn(find.saved) == 0 then
        GameTooltip:AddLine(L["hoa.addon.you_have_nothing_saved_in_this_slot"], 0.7, 0.7, 0.7, 1)
    end
    RebuildItemTooltip(GameTooltip, find.entry)
    ShowItemFonts(GameTooltip)
    ShowSaved(find, owner)
end

function Vault:VaultSlot(index)
    local slot = self.window.box.slots[index]
    if slot then
        return slot
    end
    slot = UI.Slot(self.window.box, SLOT_SIZE)
    slot.glow = slot:CreateTexture(nil, "OVERLAY")
    slot.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    slot.glow:SetBlendMode("ADD")
    slot.glow:SetWidth(SLOT_SIZE * 96 / 56)
    slot.glow:SetHeight(SLOT_SIZE * 96 / 56)
    slot.glow:SetPoint("CENTER", slot, "CENTER", 0, 0)
    slot.caption = UI.Text(self.window.box, 10)
    slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -6)
    slot.caption:SetWidth(130)
    slot:SetScript("OnClick", function()
        if this.find then
            PlaySound("igMainMenuOptionCheckBoxOff")
            Command("take " .. this.find.guid)
        end
    end)
    UI.Hover(slot, function()
        if this.find then
            Vault:ShowItemTooltip(this, this.find, L["hoa.addon.click_to_take_it_out_of_the_vault"])
        else
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            GameTooltip:AddLine(L["hoa.addon.empty_2"], 1, 1, 1)
            GameTooltip:AddLine(L["hoa.addon.click_an_item_below_to_put_it_in_the_vault"], 1, 0.82, 0, 1)
            GameTooltip:Show()
        end
    end)
    self.window.box.slots[index] = slot
    return slot
end

local SENT_SLOT_SIZE = 40
local SENT_SPACING = 70
local SENT_SHOWN = 8
local SENT_VIEW_HEIGHT = 64

frame.sent = CreateFrame("Frame", nil, frame)
frame.sent:SetHeight(128)
frame.sent:SetPoint("CENTER", frame, "CENTER", 0, 132)
frame.sent:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", tile = true, tileSize = 32,
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
frame.sent.label = UI.Text(frame.sent, 12)
frame.sent.label:SetPoint("TOP", frame.sent, "TOP", 0, -16)
frame.sent.label:SetTextColor(1, 0.82, 0)
frame.sent.label:SetText(L["hoa.addon.sent_home_this_run"])
frame.sent.empty = UI.Text(frame.sent, 11)
frame.sent.empty:SetPoint("CENTER", frame.sent, "CENTER", 0, -8)
frame.sent.empty:SetTextColor(0.62, 0.62, 0.62)
frame.sent.empty:SetText(L["hoa.addon.nothing_yet_each_hearthstone_sends_1_piece"])
frame.sent.slots = {}
frame.sent.offset = 0
frame.sent.maxOffset = 0
frame.sent:Hide()

frame.sent.view = CreateFrame("ScrollFrame", nil, frame.sent)
frame.sent.view:SetHeight(SENT_VIEW_HEIGHT)
frame.sent.view:SetPoint("TOP", frame.sent, "TOP", 0, -36)
frame.sent.strip = CreateFrame("Frame", nil, frame.sent.view)
frame.sent.strip:SetHeight(SENT_VIEW_HEIGHT)
frame.sent.view:SetScrollChild(frame.sent.strip)

frame.sent.slider = CreateFrame("Slider", "VanillaBonkHearthSentSlider", frame.sent, "OptionsSliderTemplate")
frame.sent.slider:SetPoint("BOTTOM", frame.sent, "BOTTOM", 0, 14)
frame.sent.slider:SetValueStep(1)
VanillaBonkHearthSentSliderText:SetText("")
VanillaBonkHearthSentSliderLow:SetText("")
VanillaBonkHearthSentSliderHigh:SetText("")
frame.sent.slider:Hide()

function Vault:ScrollSentTo(offset)
    local sent = self.window.sent
    offset = max(0, min(sent.maxOffset, offset))
    sent.offset = offset
    sent.view:SetHorizontalScroll(-offset)
    if abs(sent.slider:GetValue() - offset) >= 1 then
        sent.slider:SetValue(offset)
    end
end

frame.sent.slider:SetScript("OnValueChanged", function()
    if abs(this:GetValue() - frame.sent.offset) >= 1 then
        Vault:ScrollSentTo(this:GetValue())
    end
end)

local function CursorX()
    local x = GetCursorPosition()
    return x / frame.sent:GetEffectiveScale()
end

function Vault:StartSentDrag()
    if arg1 == "LeftButton" and self.window.sent.maxOffset > 0 then
        self.window.sent.dragX = CursorX()
        self.window.sent.dragOffset = self.window.sent.offset
    end
end

function Vault:StopSentDrag()
    self.window.sent.dragX = nil
end

function Vault:ScrollSentByWheel()
    self:ScrollSentTo(self.window.sent.offset - arg1 * SENT_SPACING)
end

frame.sent.view:EnableMouse(true)
frame.sent.view:EnableMouseWheel(true)
frame.sent.view:SetScript("OnMouseDown", function() Vault:StartSentDrag() end)
frame.sent.view:SetScript("OnMouseUp", function() Vault:StopSentDrag() end)
frame.sent.view:SetScript("OnMouseWheel", function() Vault:ScrollSentByWheel() end)
frame.sent.view:SetScript("OnHide", function() Vault:StopSentDrag() end)
frame.sent.view:SetScript("OnUpdate", function()
    local sent = frame.sent
    if sent.dragX then
        Vault:ScrollSentTo(sent.dragOffset - (CursorX() - sent.dragX))
    end
end)

function Vault:SentSlot(index)
    local slot = self.window.sent.slots[index]
    if slot then
        return slot
    end
    slot = UI.Slot(self.window.sent.strip, SENT_SLOT_SIZE)
    slot:SetPoint("TOPLEFT", self.window.sent.strip, "TOPLEFT", (index - 1) * SENT_SPACING + (SENT_SPACING - SENT_SLOT_SIZE) / 2, -4)
    slot.caption = UI.Text(self.window.sent.strip, 10)
    slot.caption:SetPoint("TOP", slot, "BOTTOM", 0, -5)
    slot.caption:SetTextColor(0.8, 0.8, 0.8)
    slot:EnableMouseWheel(true)
    slot:SetScript("OnMouseDown", function() Vault:StartSentDrag() end)
    slot:SetScript("OnMouseUp", function() Vault:StopSentDrag() end)
    slot:SetScript("OnMouseWheel", function() Vault:ScrollSentByWheel() end)
    UI.Hover(slot, function()
        if this.piece then
            GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
            UI.nextFound = this.piece.found
            GameTooltip:SetHyperlink("item:" .. this.piece.entry .. ":0:0:0")
            GameTooltip:AddLine(L("hoa.addon.sent_home_on_stage_1", this.piece.stage), 0.7, 0.7, 0.7)
            GameTooltip:Show()
        end
    end)
    self.window.sent.slots[index] = slot
    return slot
end

function Vault:ShowSent()
    local sent = self.window.sent
    local pieces = self.state.sent or {}
    local count = getn(pieces)
    local viewWidth = max(1, min(count, SENT_SHOWN)) * SENT_SPACING
    sent:SetWidth(max(300, 40 + viewWidth))
    sent.view:SetWidth(viewWidth)
    sent.strip:SetWidth(max(1, count) * SENT_SPACING)
    sent.maxOffset = max(0, count - SENT_SHOWN) * SENT_SPACING
    if count == 0 then
        sent.empty:Show()
    else
        sent.empty:Hide()
    end
    for index = 1, max(count, getn(sent.slots)) do
        local slot = self:SentSlot(index)
        local piece = pieces[index]
        slot.piece = piece
        if piece then
            local _, _, _, _, _, _, _, _, texture = GetItemInfo(piece.entry)
            slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
            slot.icon:Show()
            slot.caption:SetText(L("hoa.addon.stage_1", piece.stage))
            slot:Show()
            slot.caption:Show()
        else
            slot:Hide()
            slot.caption:Hide()
        end
    end
    if sent.maxOffset > 0 then
        sent.slider:SetWidth(viewWidth)
        sent.slider:SetMinMaxValues(0, sent.maxOffset)
        sent.slider:Show()
    else
        sent.slider:Hide()
    end
    sent.view:UpdateScrollChildRect()
    sent:Show()
    self:ScrollSentTo(sent.maxOffset)
end

frame.cards = CreateFrame("Frame", nil, frame)
frame.cards.list = {}

function Vault:Card(index)
    local card = self.window.cards.list[index]
    if card then
        return card
    end
    card = CreateFrame("Button", nil, self.window.cards)
    card:SetWidth(CARD_WIDTH)
    card:SetHeight(CARD_HEIGHT)
    card:SetBackdrop(STONE_BORDER)
    card.bg = card:CreateTexture(nil, "BACKGROUND")
    card.bg:SetTexture(UI.FLAT)
    card.bg:SetPoint("TOPLEFT", card, "TOPLEFT", 7, -7)
    card.bg:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -7, 7)
    card.bg:SetGradientAlpha("VERTICAL", 0.02, 0.02, 0.01, 0.95, 0.12, 0.09, 0.06, 0.9)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 6, -6)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -6, 6)
    card.line:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })

    card.slot = UI.Slot(card, 40, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -22)
    card.name = UI.Text(card, 11)
    card.name:SetPoint("TOP", card, "TOP", 0, -72)
    card.name:SetWidth(CARD_WIDTH - 20)
    card.where = UI.Text(card, 10)
    card.where:SetPoint("TOP", card, "TOP", 0, -104)
    card.where:SetTextColor(0.63, 0.63, 0.63)
    card.saved = UI.Text(card, 10)
    card.saved:SetPoint("TOP", card, "TOP", 0, -118)
    card.saved:SetWidth(CARD_WIDTH - 16)
    card.saved:SetHeight(24)
    card.saved:SetJustifyV("TOP")
    card.price = UI.Text(card, 12, UI.NUMBER_FONT)
    card.price:SetPoint("BOTTOM", card, "BOTTOM", 0, 12)

    card.tier = UI.Text(card, 10)
    card.tier:SetPoint("TOPLEFT", card, "TOPLEFT", 11, -10)
    card.tier:SetTextColor(1, 0.82, 0)
    card.arrow = card:CreateTexture(nil, "OVERLAY")
    card.arrow:SetWidth(14)
    card.arrow:SetHeight(14)
    card.arrow:SetTexCoord(0.25, 0.75, 0.25, 0.75)
    card.arrow:SetPoint("LEFT", card.tier, "RIGHT", 1, 0)
    card.owned = UI.Text(card, 10)
    card.owned:SetPoint("TOPRIGHT", card, "TOPRIGHT", -11, -10)
    card.owned:SetTextColor(1, 0.5, 0.25)
    card.owned:SetText(L["hoa.addon.owned"])

    card.ribbon = card:CreateTexture(nil, "OVERLAY")
    card.ribbon:SetTexture(UI.FLAT)
    card.ribbon:SetVertexColor(0, 0, 0, 0.8)
    card.ribbon:SetHeight(20)
    card.ribbon:SetPoint("LEFT", card, "LEFT", 6, 4)
    card.ribbon:SetPoint("RIGHT", card, "RIGHT", -6, 4)
    card.ribbonText = UI.Text(card, 11)
    card.ribbonText:SetPoint("CENTER", card.ribbon, "CENTER", 0, 0)
    card.ribbonText:SetTextColor(1, 0.82, 0)
    card.ribbonText:SetText(L["hoa.addon.in_the_vault"])

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.3)
    card.highlight:SetAllPoints(card.bg)

    card:SetScript("OnClick", function()
        local find = this.find
        if not find then
            return
        end
        if Vault.state.hearth then
            PlaySound("igMainMenuOptionCheckBoxOn")
            Command("send " .. find.guid)
        elseif Vault.state.chosen[find.guid] then
            PlaySound("igMainMenuOptionCheckBoxOff")
            Command("take " .. find.guid)
        else
            PlaySound("igMainMenuOptionCheckBoxOn")
            Command("put " .. find.guid)
        end
    end)
    UI.Hover(card, function()
        local find = this.find
        if find then
            local line = Vault.state.chosen[find.guid] and L["hoa.addon.click_to_take_it_out_of_the_vault"] or L["hoa.addon.click_to_put_it_in_the_vault"]
            Vault:ShowItemTooltip(this, find, Vault.state.hearth and L["hoa.addon.click_to_send_it_home_now"] or line)
        end
    end)
    self.window.cards.list[index] = card
    return card
end

frame.rest = UI.Text(frame, 12)
frame.hint = UI.Text(frame, 11)
frame.hint:SetTextColor(0.72, 0.72, 0.72)
frame.done = UI.Button(frame, 100, L["hoa.addon.done"], function()
    frame:Hide()
end)
frame.pageText = UI.Text(frame, 12)
frame.pageText:SetTextColor(1, 0.82, 0)

local function SavedText(find)
    if getn(find.saved) == 0 then
        return L["hoa.addon.cff9d9d9dyours_nothing_r"], true
    end
    local names = {}
    for _, saved in ipairs(find.saved) do
        local name, _, quality = GetItemInfo(saved.entry)
        if not name then
            return "", false
        end
        local r, g, b = QualityColor(quality or 2)
        tinsert(names, format("|cff%02x%02x%02x%s|r", r * 255, g * 255, b * 255, name))
    end
    return L("hoa.addon.cff9d9d9dyours_r_1", table.concat(names, ", ")), true
end

function Vault:FillCard(card, find)
    local name, _, _, _, _, _, _, _, texture = GetItemInfo(find.entry)
    local r, g, b = QualityColor(find.quality)
    card.find = find
    card.slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
    card.name:SetText(name or "")
    card.name:SetTextColor(r, g, b)
    card.where:SetText(find.worn and L["hoa.addon.equipped"] or L["hoa.addon.in_bags"])
    local saved, savedKnown = SavedText(find)
    card.saved:SetText(saved)
    card.price:SetText(self.state.hearth and "" or WorthText(find))
    if find.tier > 0 then
        local lines = find.found and table.getn(find.found.lines) or 0
        local _, _, itemQuality = GetItemInfo(find.entry)
        card.tier:SetText(UI.ItemLevelText(find.tier, itemQuality) .. (lines > 0 and ("  |cffff66cc+" .. lines .. "|r") or ""))
        card.tier:Show()
    else
        card.tier:Hide()
    end
    if find.tier > 0 and find.tier ~= find.best then
        local better = find.tier > find.best
        card.arrow:SetTexture(better and ARROW_UP or ARROW_DOWN)
        card.arrow:SetVertexColor(better and 0.2 or 1, better and 1 or 0.25, better and 0.2 or 0.25)
        card.arrow:Show()
    else
        card.arrow:Hide()
    end
    if find.owned then
        card.owned:Show()
    else
        card.owned:Hide()
    end
    card:SetBackdropBorderColor(r, g, b)
    card.line:SetBackdropBorderColor(r, g, b, 0.8)
    if self.state.chosen[find.guid] then
        card:SetAlpha(0.45)
        card.ribbon:Show()
        card.ribbonText:Show()
    else
        card:SetAlpha(1)
        card.ribbon:Hide()
        card.ribbonText:Hide()
    end
    return name ~= nil and savedKnown
end

function Vault:ShownOrder()
    local shown = {}
    for _, find in ipairs(self.state.finds) do
        tinsert(shown, find)
    end
    table.sort(shown, function(a, b)
        if a.tier ~= b.tier then
            return a.tier > b.tier
        end
        if a.quality ~= b.quality then
            return a.quality > b.quality
        end
        if a.sell ~= b.sell then
            return a.sell > b.sell
        end
        return a.scrap > b.scrap
    end)
    return shown
end

function Vault:TurnPage(step)
    self.state.page = self.state.page + step
    PlaySound("igMainMenuOptionCheckBoxOn")
    self:Refresh()
end

frame.prev = UI.Button(frame, 90, L["hoa.addon.previous"], function() Vault:TurnPage(-1) end)
frame.next = UI.Button(frame, 90, L["hoa.addon.page_next"], function() Vault:TurnPage(1) end)

function Vault:Refresh()
    local frame = self.window
    local slots = max(1, self.state.slots)
    frame.title:SetText(self.state.hearth and L["hoa.addon.hearthstone"] or L["hoa.addon.extraction_vault"])
    if self.state.hearth then
        frame.subtitle:SetText(L["hoa.addon.sends_1_piece_home_now_you_lose_it_for_the_rest_of_the_run"])
        frame.box:Hide()
        self:ShowSent()
    else
        frame.sent:Hide()
        frame.subtitle:SetText(slots == 1 and L["hoa.addon.1_piece_comes_home_with_you"] or L("hoa.addon.1_pieces_come_home_with_you", slots))
        frame.box:Show()
    end

    local byGuid = {}
    for _, find in ipairs(self.state.finds) do
        byGuid[find.guid] = find
    end
    local inVault = {}
    for _, guid in ipairs(self.state.order) do
        if byGuid[guid] then
            tinsert(inVault, byGuid[guid])
        end
    end
    frame.box:SetWidth(max(VAULT_BOX_MIN_WIDTH, slots * VAULT_SLOT_SPACING + VAULT_BOX_MARGIN))
    for index = 1, max(slots, getn(frame.box.slots)) do
        local slot = self:VaultSlot(index)
        if index > slots then
            slot:Hide()
            slot.caption:Hide()
        else
            local find = inVault[index]
            slot:ClearAllPoints()
            slot:SetPoint("TOP", frame.box, "TOP", (index - (slots + 1) / 2) * VAULT_SLOT_SPACING, -36)
            slot.caption:SetWidth(slots > 2 and NARROW_CAPTION or WIDE_CAPTION)
            slot.find = find
            if find then
                local name, _, _, _, _, _, _, _, texture = GetItemInfo(find.entry)
                local r, g, b = QualityColor(find.quality)
                slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
                slot.icon:Show()
                slot.glow:SetVertexColor(r, g, b)
                slot.glow:Show()
                slot.caption:SetText(name or "")
                slot.caption:SetTextColor(r, g, b)
            else
                slot.icon:Hide()
                slot.glow:Hide()
                slot.caption:SetText(index == 2 and L["hoa.addon.empty_pack_mule"] or L["hoa.addon.empty_2"])
                slot.caption:SetTextColor(0.62, 0.62, 0.62)
            end
            slot:Show()
            slot.caption:Show()
        end
    end

    local shown = self:ShownOrder()
    local total = getn(shown)
    local pages = max(1, ceil(total / PER_PAGE))
    self.state.page = max(1, min(self.state.page, pages))
    local first = (self.state.page - 1) * PER_PAGE
    local count = max(0, min(PER_PAGE, total - first))
    local perRow = max(1, min(count, PER_ROW))
    local rows = max(1, ceil(count / perRow))
    local width = perRow * CARD_WIDTH + (perRow - 1) * CARD_GAP
    local height = rows * CARD_HEIGHT + (rows - 1) * CARD_GAP
    local scale = min(1, CARDS_ROOM / height, (UIParent:GetWidth() - 60) / width)
    frame.cards:SetScale(scale)
    frame.cards:SetWidth(width)
    frame.cards:SetHeight(height)
    frame.cards:ClearAllPoints()
    frame.cards:SetPoint("TOP", frame, "CENTER", 0, CARDS_TOP / scale)
    local missing = false
    local rest, restScrap = 0, 0
    for _, find in ipairs(self.state.finds) do
        if not self.state.chosen[find.guid] then
            rest = rest + find.sell
            restScrap = restScrap + find.scrap
        end
    end
    restScrap = floor(restScrap * (1 + (self.state.scrapBonus or 0) / 100) + 0.5)
    for index = 1, count do
        local find = shown[first + index]
        local card = self:Card(index)
        local row = floor((index - 1) / perRow)
        local column = mod(index - 1, perRow)
        local inRow = min(perRow, count - row * perRow)
        local x = (column - (inRow - 1) / 2) * (CARD_WIDTH + CARD_GAP)
        card:ClearAllPoints()
        card:SetPoint("TOP", frame.cards, "TOP", x, -row * (CARD_HEIGHT + CARD_GAP))
        if not self:FillCard(card, find) then
            missing = true
        end
        card:Show()
    end
    for index = count + 1, getn(frame.cards.list) do
        frame.cards.list[index]:Hide()
    end

    local anchor = frame.cards
    if pages > 1 then
        frame.pageText:SetText(L("hoa.addon.page_1_of_2_3_items", self.state.page, pages, total))
        frame.pageText:ClearAllPoints()
        frame.pageText:SetPoint("TOP", frame.cards, "BOTTOM", 0, -12)
        frame.prev:ClearAllPoints()
        frame.prev:SetPoint("RIGHT", frame.pageText, "LEFT", -14, 0)
        frame.next:ClearAllPoints()
        frame.next:SetPoint("LEFT", frame.pageText, "RIGHT", 14, 0)
        if self.state.page > 1 then frame.prev:Enable() else frame.prev:Disable() end
        if self.state.page < pages then frame.next:Enable() else frame.next:Disable() end
        frame.pageText:Show()
        frame.prev:Show()
        frame.next:Show()
        anchor = frame.pageText
    else
        frame.pageText:Hide()
        frame.prev:Hide()
        frame.next:Hide()
    end

    frame.rest:ClearAllPoints()
    frame.rest:SetPoint("TOP", anchor, "BOTTOM", 0, -14)
    if count == 0 then
        frame.rest:SetText(L["hoa.addon.cff9d9d9dnothing_found_this_run_yet_r"])
    elseif self.state.hearth then
        frame.rest:SetText(L["hoa.addon.the_hearthstone_can_send_1_piece"])
    else
        frame.rest:SetText(LeftOutText(rest, restScrap, true))
    end

    frame.done:ClearAllPoints()
    frame.hint:ClearAllPoints()
    frame.hint:SetPoint("TOP", frame.rest, "BOTTOM", 0, -8)
    if self.state.hearth then
        frame.hint:SetText(L["hoa.addon.click_an_item_to_send_it_home_now_you_lose_it_for_the_rest_o"])
    else
        frame.hint:SetText(L["hoa.addon.gear_in_the_vault_goes_home_when_the_run_ends_even_if_you_di"])
    end
    frame.hint:Show()
    frame.done:SetPoint("TOP", frame.hint, "BOTTOM", 0, -12)

    if missing then
        self.retries = self.retries or RETRIES
        self.retryIn = RETRY
    else
        self.retries = nil
    end
end

function Refresh()
    Vault:Refresh()
end

local function HeroSpot()
    if not UnitPosition then
        return nil
    end
    local x, y = UnitPosition("player")
    return x, y
end

frame:SetScript("OnUpdate", function()
    if Vault.retries and Vault.retries > 0 then
        Vault.retryIn = Vault.retryIn - arg1
        if Vault.retryIn <= 0 then
            Vault.retries = Vault.retries - 1
            Vault:Refresh()
        end
    end
    if Vault.openedAt then
        local x, y = HeroSpot()
        if x then
            local dx, dy = x - Vault.openedAt[1], y - Vault.openedAt[2]
            if dx * dx + dy * dy > WALK_AWAY * WALK_AWAY then
                frame:Hide()
            end
        end
    end
end)

frame:SetScript("OnShow", function()
    PlaySound("igMainMenuOpen")
end)
frame:SetScript("OnHide", function()
    Command("close")
    Vault.openedAt = nil
    Vault.retries = nil
    GameTooltip:Hide()
    PlaySound("igMainMenuClose")
end)

local function SavedEntries(field)
    local entries = {}
    for _, text in ipairs(UI.Split(field or "", ",")) do
        local parts = UI.Split(text, "@")
        local entry = tonumber(parts[1])
        if entry then
            tinsert(entries, { entry = entry, place = parts[2] })
        end
    end
    return entries
end

function Vault:HandleClear()
    self.incoming = {}
end

function Vault:HandleSent()
    self.state.sent = {}
end

function Vault:HandleSentItem(f)
    local entry = tonumber(f[2] or "")
    if not entry then
        return
    end
    self.state.sent = self.state.sent or {}
    tinsert(self.state.sent, { entry = entry, stage = tonumber(f[3] or "") or 0, found = UI.ParseFound(f[4], f[5], f[6]) })
end

function Vault:HandleItem(f)
    local guid, entry = f[2], tonumber(f[3] or "")
    if not self.incoming or not guid or guid == "" or not entry then
        return
    end
    tinsert(self.incoming, {
        guid = guid,
        entry = entry,
        quality = tonumber(f[4] or "") or 2,
        worn = f[5] == "1",
        sell = tonumber(f[6] or "") or 0,
        saved = SavedEntries(f[7]),
        tier = tonumber(f[8] or "") or 0,
        best = tonumber(f[9] or "") or 0,
        owned = f[10] == "1",
        scrap = tonumber(f[11] or "") or 0,
        found = UI.ParseFound(f[8], f[12], f[13]),
    })
end

function Vault:HandleOpen(f)
    local frame = self.window
    self.state.slots = tonumber(f[2] or "") or 1
    self.state.hearth = f[4] == "hearth"
    self.state.scrapBonus = tonumber(f[5] or "") or 0
    self.state.chosen, self.state.order = {}, {}
    for _, guid in ipairs(UI.Split(f[3] or "", ",")) do
        if guid ~= "" then
            self.state.chosen[guid] = true
            tinsert(self.state.order, guid)
        end
    end
    if self.incoming then
        self.state.finds = self.incoming
        self.incoming = nil
    end
    self.retries = nil
    self:Refresh()
    if not frame:IsShown() then
        local x, y = HeroSpot()
        self.openedAt = x and { x, y } or nil
        self.state.page = 1
        frame:Show()
    end
end

function Vault:HandleClose()
    self.window:Hide()
end

function Vault:ClearRun()
    self.window:Hide()
    self.state.finds, self.state.chosen, self.state.order = {}, {}, {}
end

Vault:OnRunEnd(function()
    Vault:ClearRun()
end)

UI.ListenHoa({
    HOA_VAULT_CLEAR = function()
        Vault:HandleClear()
    end,
    HOA_VAULT_SENT = function()
        Vault:HandleSent()
    end,
    HOA_VAULT_SENT_ITEM = function(item)
        Vault:HandleSentItem({ false, item.entry, item.stage, item.tier, item.lines, item.extra })
    end,
    HOA_VAULT_ITEM = function(item)
        Vault:HandleItem({
            false, tostring(item.guid), item.entry, item.quality, item.worn and "1" or "0", item.sell_copper, item.saved,
            item.tier, item.best, item.owned and "1" or "0", item.scrap, item.lines, item.extra,
        })
    end,
    HOA_VAULT_OPEN = function(open)
        Vault:HandleOpen({ false, open.slots, open.chosen, open.mode, open.scrap_bonus })
    end,
    HOA_VAULT_CLOSE = function()
        Vault:HandleClose()
    end,
})

