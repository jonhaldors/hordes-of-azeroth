local L = VanillaBonkL
local UI = VanillaBonkUI

local FADE = 0.2
local WAIT = 1.5
local RETRY = 0.25
local RETRIES = 12
local QUALITY_EPIC = 4
local CARD_TOP = 150
local CARD_MIN_WIDTH = 230
local CARD_HEAD = 84
local CARD_FOOT = 16
local EMPTY_HEIGHT = 170
local CARD_GAP = 24
local SLOT_NAMES = { [10] = L["Ring 1"], [11] = L["Ring 2"], [12] = L["Trinket 1"], [13] = L["Trinket 2"], [15] = L["Main Hand"], [16] = L["Off Hand"] }

local offer = nil

local frame = CreateFrame("Frame", "VanillaBonkGear", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(false)
frame:Hide()

frame.dim = frame:CreateTexture(nil, "BACKGROUND")
frame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
frame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
frame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)

frame.title = frame:CreateFontString(nil, "OVERLAY")
frame.title:SetFont(UI.TITLE_FONT, 40, "OUTLINE")
frame.title:SetPoint("CENTER", frame, "CENTER", 0, 210)
frame.title:SetTextColor(1, 0.82, 0)
frame.title:SetText(L["Loot"])

frame.subtitle = UI.Text(frame, 13)
frame.subtitle:SetPoint("CENTER", frame, "CENTER", 0, 172)
frame.subtitle:SetTextColor(0.9, 0.83, 0.64)
frame.subtitle:SetText(L["Wear it, carry it, or salvage it for Valor"])
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

local function Card(name, label)
    local card = CreateFrame("Frame", nil, frame)
    card:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 })
    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetTexture("Interface\\TalentFrame\\" .. UI.CardArt("") .. "-TopLeft")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    UI.Shade(card.shade, 0.95, 0.45)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    card.slot = UI.Slot(card, 48, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -24)
    card.glow = card.slot:CreateTexture(nil, "OVERLAY")
    card.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    card.glow:SetBlendMode("ADD")
    card.glow:SetWidth(84)
    card.glow:SetHeight(84)
    card.glow:SetPoint("CENTER", card.slot, "CENTER", 0, 0)

    card.label = UI.Text(frame, 12)
    card.label:SetPoint("BOTTOM", card, "TOP", 0, 4)
    card.label:SetTextColor(0.75, 0.75, 0.75)
    card.label:SetText(label)

    card.tip = CreateFrame("GameTooltip", name, card, "GameTooltipTemplate")
    if VanillaBonk_HookItemTooltip then
        VanillaBonk_HookItemTooltip(card.tip)
    end
    card.empty = UI.Text(card, 13)
    card.empty:SetPoint("CENTER", card, "CENTER", 0, -10)
    card.empty:SetTextColor(0.6, 0.6, 0.6)
    card.empty:SetText(L["Nothing equipped in this slot"])
    card:Hide()
    return card
end
local newCard = Card("VanillaBonkGearNewTip", L["New"])
local wornCard = Card("VanillaBonkGearWornTip", L["Equipped"])
local otherCard = Card("VanillaBonkGearOtherTip", L["Equipped"])
local newTip, wornTip, otherTip = newCard.tip, wornCard.tip, otherCard.tip

frame.rule = UI.Text(frame, 12)
frame.rule:SetPoint("CENTER", frame, "CENTER", 0, -150)
frame.rule:SetWidth(520)

local function Send(text)
    if frame.waitUntil and GetTime() < frame.waitUntil then
        return
    end
    frame.waitUntil = GetTime() + WAIT
    SendChatMessage(".bonk gear " .. text, "SAY")
end

local function EquipIn(slot)
    if slot then
        Send("equip " .. slot)
    else
        Send("equip")
    end
end

frame.equip = UI.Button(frame, 140, L["Equip"], function()
    EquipIn(offer and offer.slot)
end)
frame.equip:SetHeight(26)
frame.equip:SetPoint("CENTER", frame, "CENTER", -80, -186)
frame.equipOther = UI.Button(frame, 140, L["Replace"], function()
    EquipIn(offer and offer.otherSlot)
end)
frame.equipOther:SetHeight(26)
frame.equipOther:Hide()
frame.salvage = UI.Button(frame, 160, L["Salvage"], function()
    Send("salvage")
end)
frame.salvage:SetHeight(26)
frame.salvage:SetPoint("CENTER", frame, "CENTER", 80, -186)
frame.loot = UI.Button(frame, 90, L["Loot"], function()
    Send("loot")
end)
frame.loot:SetHeight(26)
frame.loot:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:SetText(L["Loot"])
    GameTooltip:AddLine(L["Carry it in your bags and equip it whenever you like."], 1, 1, 1, 1)
    GameTooltip:AddLine(L["Found gear is only kept if you put it in the Extraction Vault and extract."], 1, 0.82, 0, 1)
    GameTooltip:Show()
end)
frame.loot:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local function WornFound(slot, entry)
    return slot and UI.FoundAt("inv", slot + 1) or UI.FoundWorn(entry)
end

local function Fill(card, entry, found)
    local tip = card.tip
    local r, g, b = 0.85, 0.75, 0.5
    if entry and entry > 0 then
        tip:SetOwner(card, "ANCHOR_NONE")
        UI.nextFound = found
        tip:SetHyperlink("item:" .. entry .. ":0:0:0")
        tip:SetBackdropColor(0, 0, 0, 0)
        tip:SetBackdropBorderColor(0, 0, 0, 0)
        tip:ClearAllPoints()
        tip:SetPoint("TOP", card, "TOP", 0, -CARD_HEAD + 8)
        tip:Show()
        local _, _, quality, _, _, _, _, _, texture = GetItemInfo(entry)
        if quality then
            r, g, b = GetItemQualityColor(quality)
        end
        card.slot.icon:SetTexture(texture or (UI.ICON_PATH .. "INV_Misc_QuestionMark"))
        card.slot:Show()
        card.empty:Hide()
        card:SetWidth(max(CARD_MIN_WIDTH, tip:GetWidth() + 24))
        card:SetHeight(CARD_HEAD + tip:GetHeight() + CARD_FOOT)
    else
        tip:Hide()
        card.slot:Hide()
        card.empty:Show()
        card:SetWidth(CARD_MIN_WIDTH)
        card:SetHeight(EMPTY_HEIGHT)
    end
    card:SetBackdropBorderColor(r, g, b)
    card.line:SetBackdropBorderColor(r, g, b, 0.9)
    card.glow:SetVertexColor(r, g, b)
    UI.TalentArtCoords(card.art, card:GetWidth() - 18, card:GetHeight() - 18)
    card:Show()
    card.label:Show()
    return card:GetHeight()
end

local function PlaceButtonUnder(button, card, below, offset)
    button:ClearAllPoints()
    button:SetPoint("TOP", card, "TOP", offset or 0, -(CARD_TOP - below) - 14)
end

local function PlaceNewCardButtons(below)
    local gap = 8
    local width = frame.loot:GetWidth() + gap + frame.salvage:GetWidth()
    PlaceButtonUnder(frame.loot, newCard, below, (frame.loot:GetWidth() - width) / 2)
    PlaceButtonUnder(frame.salvage, newCard, below, (width - frame.salvage:GetWidth()) / 2)
end

local OFFHAND_LOCS = { INVTYPE_SHIELD = true, INVTYPE_WEAPONOFFHAND = true, INVTYPE_HOLDABLE = true }

local function EquipLoc(entry)
    if not entry or entry <= 0 then
        return nil
    end
    local _, _, _, _, _, _, _, equipLoc = GetItemInfo(entry)
    return equipLoc
end

local function ReplacesTwoHander()
    return offer and OFFHAND_LOCS[EquipLoc(offer.entry) or ""] and EquipLoc(offer.replaced) == "INVTYPE_2HWEAPON"
end

local function LayoutRow(cards)
    local width = (getn(cards) - 1) * CARD_GAP
    for _, card in ipairs(cards) do
        width = width + card:GetWidth()
    end
    local half = frame:GetWidth() / 2
    local left = -width / 2
    local sheetRight = CharacterFrame:IsShown() and CharacterFrame:GetRight()
    if sheetRight then
        left = max(left, sheetRight * CharacterFrame:GetEffectiveScale() / frame:GetEffectiveScale() - half + 16)
    end
    left = min(left, half - 8 - width)
    local previous
    for _, card in ipairs(cards) do
        card:ClearAllPoints()
        if previous then
            card:SetPoint("TOPLEFT", previous, "TOPRIGHT", CARD_GAP, 0)
        else
            card:SetPoint("TOPLEFT", frame, "CENTER", left, CARD_TOP)
        end
        previous = card
    end
    return left + width / 2
end

local function RefreshOneSlot()
    otherCard:Hide()
    otherCard.label:Hide()
    frame.equipOther:Hide()
    wornCard.label:SetText(ReplacesTwoHander() and L["Main Hand"] or L["Equipped"])
    frame.equip:SetText(offer.replaced > 0 and L["Replace"] or L["Equip"])
    local tallest = max(Fill(newCard, offer.entry, offer.found), Fill(wornCard, offer.replaced, WornFound(offer.slot, offer.replaced)))
    local center = LayoutRow({ wornCard, newCard })
    local below = CARD_TOP - tallest
    PlaceButtonUnder(frame.equip, wornCard, below)
    PlaceNewCardButtons(below)
    return below - 6, center
end

local function RefreshTwoSlots()
    wornCard.label:SetText(SLOT_NAMES[offer.slot] or L["Equipped"])
    otherCard.label:SetText(SLOT_NAMES[offer.otherSlot] or L["Equipped"])
    frame.equip:SetText(offer.replaced > 0 and L["Replace"] or L["Equip"])
    frame.equipOther:SetText(offer.otherReplaced > 0 and L["Replace"] or L["Equip"])
    local tallest = max(Fill(newCard, offer.entry, offer.found), Fill(wornCard, offer.replaced, WornFound(offer.slot, offer.replaced)),
        Fill(otherCard, offer.otherReplaced, WornFound(offer.otherSlot, offer.otherReplaced)))
    local center = LayoutRow({ wornCard, otherCard, newCard })
    local below = CARD_TOP - tallest
    PlaceButtonUnder(frame.equip, wornCard, below)
    PlaceButtonUnder(frame.equipOther, otherCard, below)
    PlaceNewCardButtons(below)
    frame.equipOther:Show()
    return below - 6, center
end

local function Refresh()
    if not offer then
        return
    end
    local below, center
    if offer.otherSlot then
        below, center = RefreshTwoSlots()
    else
        below, center = RefreshOneSlot()
    end
    frame.rule:SetText(frame.ruleText .. (ReplacesTwoHander() and frame.twoHanderText or ""))
    frame.rule:ClearAllPoints()
    frame.rule:SetPoint("TOP", frame, "CENTER", center, below - 46)
end

local function ShowSheet()
    if not CharacterFrame:IsShown() then
        ToggleCharacter("PaperDollFrame")
        frame.openedSheet = CharacterFrame:IsShown()
    end
    if CharacterFrame:IsShown() and not frame.sheetStrata then
        frame.sheetStrata = CharacterFrame:GetFrameStrata()
        CharacterFrame:SetFrameStrata("FULLSCREEN")
    end
end

local function HideSheet()
    if frame.sheetStrata then
        CharacterFrame:SetFrameStrata(frame.sheetStrata)
        frame.sheetStrata = nil
    end
    if frame.openedSheet then
        frame.openedSheet = nil
        if CharacterFrame:IsShown() then
            HideUIPanel(CharacterFrame)
        end
    end
end

local function Open()
    frame.salvage:SetText(L["Salvage  |cffffe873+"] .. offer.valor .. L[" Valor|r"])
    local keep = L["Worn or looted, found gear is only kept if you put it in the Extraction Vault and leave through a floor portal or the Hearthstone."]
    if offer.quality >= QUALITY_EPIC then
        frame.ruleText = "|cffffd100" .. keep .. L[" A permanent copy then arrives by mail. If you die, it is lost.|r"]
    else
        frame.ruleText = "|cffbbbbbb" .. keep .. L[" Otherwise it sells for gold when the run ends.|r"]
    end
    frame.twoHanderText = L["\n|cffff8040Replacing puts your two-handed weapon in your bags. You can equip it again from there.|r"]
    frame.waitUntil = nil
    frame.retries = RETRIES
    frame.retryIn = RETRY
    ShowSheet()
    Refresh()
    if not frame.open then
        frame.open = true
        frame.alpha = 0
        frame:SetAlpha(0)
        PlaySound("igMainMenuOpen")
    end
    frame:Show()
end

local function Close()
    offer = nil
    frame.open = false
    HideSheet()
end

frame:SetScript("OnUpdate", function()
    local want = this.open and 1 or 0
    if this.alpha ~= want then
        local step = arg1 / FADE
        this.alpha = want > this.alpha and min(want, this.alpha + step) or max(want, this.alpha - step)
        this:SetAlpha(this.alpha)
        if this.alpha <= 0 then
            this:Hide()
            return
        end
    end
    if this.open and this.retries and this.retries > 0 then
        this.retryIn = this.retryIn - arg1
        if this.retryIn <= 0 then
            this.retryIn = RETRY
            this.retries = this.retries - 1
            if newTip:NumLines() == 0 or (offer and offer.replaced > 0 and wornTip:NumLines() == 0) or
                (offer and offer.otherReplaced > 0 and otherTip:NumLines() == 0) then
                Refresh()
            else
                this.retries = 0
            end
        end
    end
end)

local handlers = {}

handlers["gearoffer"] = function(f)
    local entry = tonumber(f[2] or "")
    if not entry then
        return
    end
    offer = {
        entry = entry,
        replaced = tonumber(f[3] or "") or 0,
        valor = tonumber(f[4] or "") or 0,
        quality = tonumber(f[5] or "") or 2,
        found = UI.ParseFound(f[6], f[7]),
        slot = tonumber(f[8] or ""),
        otherSlot = tonumber(f[9] or ""),
        otherReplaced = tonumber(f[10] or "") or 0,
    }
    Open()
end

handlers["gearclose"] = Close

local function HideNow()
    Close()
    frame.alpha = 0
    frame:Hide()
end
handlers["start"] = HideNow
handlers["end"] = HideNow

UI.Listen(handlers)
