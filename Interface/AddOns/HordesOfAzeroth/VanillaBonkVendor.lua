local L = VanillaBonkL
local UI = VanillaBonkUI

local SLOTS = 4
local CARD_HEIGHT = 330
local CARD_Y = 4
local DESCRIPTION_BOTTOM = 70
local VALOR_ICON = "INV_Misc_Coin_04"
local DARKMOON_CLOTH = "World\\ENVIRONMENT\\DOODAD\\Carnival\\bm_Carnie_tarp01"
local DARKMOON_BANNER = "World\\ENVIRONMENT\\DOODAD\\Carnival\\Darkmoon_Banner01"
local VALOR_COLOR = "|cffffe873"
local POP = 0.24
local STAGGER = 0.05
local CLOSE = 0.18
local WAIT = 1.5

local shop = { slots = {}, valor = 0, rerollCost = 0, restocks = 0, seconds = 0, name = L["Zixil"], waitUntil = 0 }

local function Command(text)
    SendChatMessage(".bonk vendor " .. text, "SAY")
end

local function Busy()
    return GetTime() < shop.waitUntil
end

local function Send(text)
    if Busy() then
        return
    end
    shop.waitUntil = GetTime() + WAIT
    Command(text)
end

local frame = CreateFrame("Frame", "VanillaBonkVendor", UIParent)
frame:SetAllPoints(UIParent)
frame:SetFrameStrata("DIALOG")
frame:EnableMouse(false)
frame:Hide()

frame.dim = frame:CreateTexture(nil, "BACKGROUND")
frame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
frame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
frame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
frame.dim:SetVertexColor(0, 0, 0, 0)

frame.chrome = CreateFrame("Frame", nil, frame)
frame.chrome:SetAllPoints(frame)

frame.title = frame.chrome:CreateFontString(nil, "OVERLAY")
frame.title:SetFont(UI.TITLE_FONT, 46, "OUTLINE")
frame.title:SetPoint("CENTER", frame, "CENTER", 0, 230)
frame.title:SetTextColor(1, 0.82, 0)

frame.subtitle = UI.Text(frame.chrome, 13)
frame.subtitle:SetPoint("CENTER", frame, "CENTER", 0, 186)
frame.subtitle:SetTextColor(0.9, 0.83, 0.64)

for side = 1, 2 do
    local line = frame.chrome:CreateTexture(nil, "ARTWORK")
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

frame.hint = UI.Text(frame.chrome, 11)
frame.hint:SetPoint("CENTER", frame, "CENTER", 0, -218)
frame.hint:SetTextColor(0.78, 0.78, 0.78)

local function ButtonTooltip(button, title, text)
    button:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 1, 0.82, 0, 1)
        GameTooltip:Show()
    end)
    button:SetScript("OnLeave", function()
        GameTooltip:Hide()
    end)
end

local Leave

frame.reroll = UI.Button(frame.chrome, 160, L["Restock"], function()
    if shop.restocks > 0 and shop.valor >= shop.rerollCost then
        Send("reroll")
    end
end)
frame.reroll:SetHeight(24)
ButtonTooltip(frame.reroll, L["Restock"], L["Replaces every card you haven't locked or bought; bought cards stay sold. Sayge's Restock upgrade sets how many restocks each visit allows. Each restock this visit costs 50% more."])

frame.close = UI.Button(frame.chrome, 120, L["Close"], function()
    Leave()
end)
frame.close:SetHeight(24)

frame.cards = {}

for index = 1, SLOTS do
    local card = CreateFrame("Frame", nil, frame)
    card:SetHeight(CARD_HEIGHT)
    card.index = index

    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    UI.Shade(card.shade, 0.95, 0.1)

    card:SetBackdrop({ edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 })
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    card.slot = UI.Slot(card, 56, "Frame")
    card.slot:SetPoint("TOP", card, "TOP", 0, -34)
    card.glow = card.slot:CreateTexture(nil, "OVERLAY")
    card.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    card.glow:SetBlendMode("ADD")
    card.glow:SetWidth(96)
    card.glow:SetHeight(96)
    card.glow:SetPoint("CENTER", card.slot, "CENTER", 0, 0)

    card.crest = card:CreateTexture(nil, "ARTWORK")
    card.crest:SetTexture(DARKMOON_BANNER)
    card.crest:SetTexCoord(8 / 256, 182 / 256, 16 / 256, 190 / 256)
    card.crest:SetWidth(116)
    card.crest:SetHeight(116)
    card.crest:SetPoint("TOP", card, "TOP", 0, -32)
    card.crest:Hide()
    card.eye = UI.Ring(card, 52, true)
    card.eye:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.eye.icon = UI.RingArt(card.eye, "")
    card.eye:Hide()

    card.name = UI.Text(card, 17)
    card.name:SetPoint("TOP", card, "TOP", 0, -104)
    card.name:SetJustifyH("CENTER")

    card.level = UI.Text(card, 11)
    card.level:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
    card.level:SetTextColor(0.85, 0.85, 0.85)

    card.divider = card:CreateTexture(nil, "ARTWORK")
    card.divider:SetTexture(UI.FLAT)
    card.divider:SetHeight(1)
    card.divider:SetPoint("TOPRIGHT", card.level, "BOTTOM", 0, -11)
    card.divider:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
    card.dividerRight = card:CreateTexture(nil, "ARTWORK")
    card.dividerRight:SetTexture(UI.FLAT)
    card.dividerRight:SetHeight(1)
    card.dividerRight:SetPoint("TOPLEFT", card.level, "BOTTOM", 0, -11)
    card.dividerRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)

    card.count = UI.Text(card, 11)
    card.count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -17)
    card.count:SetTextColor(0.85, 0.85, 0.85)

    card.description = UI.Text(card, 13)
    card.description:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -10)
    card.description:SetJustifyH("CENTER")
    card.description:SetJustifyV("TOP")
    card.description:SetHeight(84)
    card.measure = UI.Text(card, 13)
    card.measure:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card.measure:SetTextColor(0, 0, 0, 0)
    card.measure:SetShadowColor(0, 0, 0, 0)

    card.price = UI.Text(card, 15)
    card.price:SetPoint("BOTTOM", card, "BOTTOM", 9, 50)
    card.coin = card:CreateTexture(nil, "ARTWORK")
    card.coin:SetTexture(UI.ICON_PATH .. VALOR_ICON)
    card.coin:SetWidth(16)
    card.coin:SetHeight(16)
    card.coin:SetPoint("RIGHT", card.price, "LEFT", -4, 0)

    card.lock = UI.Button(card, 70, L["Lock"], function()
        Send("lock " .. this:GetParent().index)
    end)
    card.lock:SetPoint("BOTTOMLEFT", card, "BOTTOMLEFT", 16, 18)
    ButtonTooltip(card.lock, L["Lock"], L["Restocks skip a locked card, and it comes back at the same price on the next visit."])

    card.buy = UI.Button(card, 100, L["Buy"], function()
        local slot = shop.slots[this:GetParent().index]
        if slot and slot.state == 0 and shop.valor >= slot.price then
            Send("buy " .. this:GetParent().index)
        end
    end)
    card.buy:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -16, 18)

    card.status = UI.Text(card, 13)
    card.status:SetPoint("BOTTOM", card, "BOTTOM", 0, 34)

    frame.cards[index] = card
end

frame.special = UI.Text(frame.chrome, 18, UI.TITLE_FONT, "OUTLINE")
frame.special:SetPoint("BOTTOM", frame.cards[SLOTS], "TOP", 0, 2)
frame.special:SetTextColor(1, 0.82, 0)
frame.special:SetText(L["Special"])

local function EaseOut(t)
    t = 1 - t
    return 1 - t * t * t
end

local function EaseBack(t)
    t = t - 1
    return 1 + 2.70158 * t * t * t + 1.70158 * t * t
end

local function Progress(t, start, length)
    return min(1, max(0, (t - start) / length))
end

local function PlaceCard(card, scale, alpha, rise)
    card:SetScale(scale)
    card:SetAlpha(alpha)
    card.alphaNow = alpha
    card:ClearAllPoints()
    card:SetPoint("CENTER", frame, "CENTER", card.x / scale, (CARD_Y + rise) / scale)
end

local function Animate(elapsed)
    local anim = frame.anim
    anim.t = anim.t + elapsed
    local t = anim.t

    if anim.mode == "close" then
        local e = Progress(t, 0, CLOSE)
        frame.dimAlpha = anim.dimFrom * (1 - e)
        frame.dim:SetVertexColor(0, 0, 0, frame.dimAlpha)
        frame.chrome:SetAlpha(anim.chromeFrom * (1 - e))
        for _, card in ipairs(frame.cards) do
            if card:IsShown() then
                PlaceCard(card, 1 - 0.06 * e, card.closeFrom * max(0, 1 - e * 1.5), -12 * e)
            end
        end
        if e >= 1 then
            frame.anim = nil
            frame:Hide()
        end
        return
    end

    local busy = false
    if anim.mode == "open" then
        frame.dimAlpha = anim.dimFrom + (1 - anim.dimFrom) * EaseOut(Progress(t, 0, 0.2))
        frame.dim:SetVertexColor(0, 0, 0, frame.dimAlpha)
        local header = EaseOut(Progress(t, 0.04, 0.26))
        frame.chrome:SetAlpha(header)
        frame.title:SetPoint("CENTER", frame, "CENTER", 0, 230 + 16 * (1 - header))
        busy = header < 1
    end
    for _, card in ipairs(frame.cards) do
        if card.pop then
            local p = Progress(t, card.pop, POP)
            PlaceCard(card, 0.8 + 0.2 * EaseBack(p), min(1, p * 2), -24 * (1 - EaseOut(p)))
            if p >= 1 then
                card.pop = nil
            else
                busy = true
            end
        end
    end
    if not busy then
        frame.anim = nil
    end
end

frame:SetScript("OnUpdate", function()
    if this.anim then
        Animate(arg1)
    end
end)

local escape = CreateFrame("Frame", "VanillaBonkVendorEscape", UIParent)
escape:SetWidth(1)
escape:SetHeight(1)
escape:Hide()
tinsert(UISpecialFrames, "VanillaBonkVendorEscape")
escape:SetScript("OnHide", function()
    if not this:IsShown() and frame.open then
        Leave()
    end
end)

local function Close()
    if not frame.open then
        return
    end
    frame.open = false
    escape:Hide()
    frame:EnableMouse(false)
    frame.anim = { mode = "close", t = 0, dimFrom = frame.dimAlpha or 1, chromeFrom = frame.chrome:GetAlpha() }
    for _, card in ipairs(frame.cards) do
        card.pop = nil
        card.closeFrom = card.alphaNow or 1
    end
    PlaySound("igCharacterInfoClose")
end

function Leave()
    if frame.open then
        Command("close")
        Close()
    end
end

local function HideNow()
    frame.open = false
    escape:Hide()
    frame.anim = nil
    frame.dimAlpha = 0
    frame:Hide()
    shop.slots = {}
end

local function LevelText(slot)
    local rarity = slot.rarity and UI.RARITY[slot.rarity]
    local rarityName = rarity and UI.RarityText(slot.rarity, rarity.name) .. " " or ""
    if slot.kind == "c" then
        return L["For level-ups and chests"]
    elseif slot.kind == "d" then
        return rarityName .. L["Darkmoon Card"]
    elseif slot.kind == "e" then
        return UI.RarityText(4, L["Legendary"]) .. L[" Evolution"]
    elseif slot.rank <= 1 then
        return slot.kind == "p" and L["|cff20ff20New passive|r"] or L["|cff20ff20New spell|r"]
    elseif slot.kind == "p" then
        return rarityName .. L["Passive"]
    end
    return rarityName .. L["Spell"]
end

local function CountText(slot)
    if slot.kind == "c" or slot.kind == "e" then
        return ""
    elseif slot.kind == "d" then
        if slot.maxRank > 1 then
            return slot.rank .. "/" .. slot.maxRank .. L[" copies"]
        elseif slot.rank > 1 then
            return slot.rank .. L[" copies"]
        end
    elseif slot.maxRank > 1 then
        return L["Rank "] .. slot.rank .. "/" .. slot.maxRank
    elseif slot.rank > 1 then
        return L["Rank "] .. slot.rank
    end
    return ""
end

local function FitDescription(card, width, top)
    local textWidth = width - 40
    card.description:SetWidth(textWidth)
    card.measure:SetWidth(textWidth)
    card.measure:SetText(card.description:GetText() or "")
    local used = top + card.name:GetHeight() + 4 + card.level:GetHeight() + 11 + 1 + 10
    local room = CARD_HEIGHT - used - DESCRIPTION_BOTTOM
    local size = 13
    while size > 9 do
        card.measure:SetFont(UI.FONT, size)
        local needed = card.measure:GetHeight()
        if not needed or needed == 0 or needed <= room then
            break
        end
        size = size - 1
    end
    card.measure:SetFont(UI.FONT, size)
    card.description:SetFont(UI.FONT, size)
    card.description:SetHeight(max(room, 12))
end

local function FillCard(card, slot, width)
    card.name:SetWidth(width - 28)
    card.divider:SetWidth((width - 48) / 2)
    card.dividerRight:SetWidth((width - 48) / 2)
    card.count:SetText(CountText(slot))
    card.buy:SetWidth(width - 32 - 70 - 6)

    local darkmoon = slot.kind == "d"
    if darkmoon then
        card.art:SetTexture(DARKMOON_CLOTH)
        card.art:SetTexCoord(0, 1, 0, 1)
        UI.Shade(card.shade, 0.95, 0.4)
        card.slot:Hide()
        card.crest:Show()
        card.eye.icon:SetTexture(UI.ICON_PATH .. slot.icon)
        card.eye:Show()
        card.name:SetPoint("TOP", card, "TOP", 0, -158)
    else
        card.art:SetTexture("Interface\\TalentFrame\\" .. UI.CardArt(slot.icon) .. "-TopLeft")
        UI.TalentArtCoords(card.art, width - 18, CARD_HEIGHT - 18)
        UI.Shade(card.shade, 0.95, 0.1)
        card.slot:Show()
        card.crest:Hide()
        card.eye:Hide()
        card.name:SetPoint("TOP", card, "TOP", 0, -104)
    end
    card.slot.icon:SetTexture(UI.ICON_PATH .. slot.icon)
    card.name:SetText(slot.name)
    card.level:SetText(LevelText(slot))
    card.description:SetText(slot.description)
    FitDescription(card, width, darkmoon and 158 or 104)

    local rarity = slot.kind == "e" and 4 or slot.rarity
    local color = rarity and UI.RARITY[rarity]
    local forSale = slot.state == 0
    if color then
        card.lineColor = { color.r, color.g, color.b, 0.9 }
        card.glow:SetVertexColor(color.r, color.g, color.b)
        card:SetBackdropBorderColor(color.r, color.g, color.b)
    else
        card.lineColor = { 0.85, 0.75, 0.5, 0.35 }
        card:SetBackdropBorderColor(1, 1, 1)
    end
    if slot.locked and forSale then
        card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
    else
        card.line:SetBackdropBorderColor(card.lineColor[1], card.lineColor[2], card.lineColor[3], card.lineColor[4])
    end

    if forSale then
        card.slot.icon:SetVertexColor(1, 1, 1)
        card.eye.icon:SetVertexColor(1, 1, 1)
        card.crest:SetVertexColor(1, 1, 1)
        card.art:SetVertexColor(1, 1, 1)
        if color then
            card.name:SetTextColor(color.r, color.g, color.b)
            card.glow:Show()
        else
            card.name:SetTextColor(1, 1, 1)
            card.glow:Hide()
        end
        card.description:SetTextColor(1, 0.82, 0)
        local afford = shop.valor >= slot.price
        card.price:SetText((afford and VALOR_COLOR or "|cff9d9d9d") .. slot.price .. "|r")
        if afford then
            card.coin:SetVertexColor(1, 1, 1)
            card.buy:Enable()
        else
            card.coin:SetVertexColor(0.45, 0.45, 0.45)
            card.buy:Disable()
        end
        card.lock:SetText(slot.locked and L["Locked"] or L["Lock"])
        card.price:Show()
        card.coin:Show()
        card.lock:Show()
        card.buy:Show()
        card.status:Hide()
    else
        card.slot.icon:SetVertexColor(0.4, 0.4, 0.4)
        card.eye.icon:SetVertexColor(0.4, 0.4, 0.4)
        card.crest:SetVertexColor(0.5, 0.5, 0.5)
        card.art:SetVertexColor(0.5, 0.5, 0.5)
        card.name:SetTextColor(0.6, 0.6, 0.6)
        card.description:SetTextColor(0.55, 0.55, 0.55)
        card.glow:Hide()
        if slot.state == 1 then
            card.status:SetText(L["|cff20ff20Bought|r"])
        else
            card.status:SetText(L["|cff9d9d9dNo longer fits your build|r"])
        end
        card.price:Hide()
        card.coin:Hide()
        card.lock:Hide()
        card.buy:Hide()
        card.status:Show()
    end
end

local function ShowShelf()
    local fresh = not frame.open
    if not fresh and not frame.anim then
        frame.anim = { mode = "pop", t = 0 }
    end

    frame.title:SetText(shop.name)
    frame.subtitle:SetText(L("Wandering vendor  |cff9d9d9d·|r  You have {1}{2} Valor|r", VALOR_COLOR, shop.valor))

    local gap, apart = 12, 36
    local width = min(200, floor((UIParent:GetWidth() - 40 - 2 * gap - apart) / SLOTS))
    local total = SLOTS * width + 2 * gap + apart
    local left = -total / 2 + width / 2

    local bought = false
    for index, card in ipairs(frame.cards) do
        local slot = shop.slots[index]
        if slot then
            card:SetWidth(width)
            card.x = left + (index - 1) * (width + gap) + (index == SLOTS and apart - gap or 0)
            local look = slot.name .. slot.icon .. slot.rank .. (slot.rarity or "") .. slot.price
            if fresh then
                card.pop = 0.08 + (index - 1) * STAGGER
                PlaceCard(card, 0.8, 0, -24)
            elseif card.look ~= look or not card:IsShown() then
                card.pop = frame.anim.t
                PlaceCard(card, 0.8, 0, -24)
            elseif not card.pop then
                PlaceCard(card, 1, 1, 0)
            end
            if not fresh and card.look == look and card.state == 0 and slot.state == 1 then
                bought = true
            end
            card.look = look
            card.state = slot.state
            FillCard(card, slot, width)
            card:Show()
        else
            card.pop = nil
            card.look = nil
            card:Hide()
        end
    end
    if shop.slots[SLOTS] then
        frame.special:Show()
    else
        frame.special:Hide()
    end

    if shop.restocks > 0 then
        frame.reroll:SetText(L("Restock ({1}{2} Valor|r)", shop.valor >= shop.rerollCost and VALOR_COLOR or "", shop.rerollCost))
    else
        frame.reroll:SetText(L["No restocks"])
    end
    if shop.restocks > 0 and shop.valor >= shop.rerollCost then
        frame.reroll:Enable()
    else
        frame.reroll:Disable()
    end
    frame.reroll:ClearAllPoints()
    frame.reroll:SetPoint("CENTER", frame, "CENTER", -70, -190)
    frame.close:ClearAllPoints()
    frame.close:SetPoint("CENTER", frame, "CENTER", 90, -190)

    frame.hint:SetText("")

    shop.waitUntil = 0
    if bought then
        PlaySound("LOOTWINDOWCOINSOUND")
    end
    if fresh then
        PlaySound("igCharacterInfoOpen")
        frame.open = true
        frame.anim = { mode = "open", t = 0, dimFrom = frame.dimAlpha or 0 }
        frame.chrome:SetAlpha(0)
        frame.dim:SetVertexColor(0, 0, 0, frame.dimAlpha or 0)
        escape:Show()
    end
    frame:Show()
end

local handlers = {}

handlers["vendor"] = function(f)
    shop.valor = tonumber(f[2] or "") or 0
    shop.rerollCost = tonumber(f[3] or "") or 0
    shop.seconds = tonumber(f[4] or "") or 0
    shop.name = (f[5] and f[5] ~= "") and f[5] or L["Zixil"]
    shop.restocks = tonumber(f[6] or "") or 0
    shop.incoming = {}
end

handlers["vslot"] = function(f)
    local index = tonumber(f[2] or "")
    if not index or index < 1 or index > SLOTS then
        return
    end
    local description = gsub(f[8] or "", "|n", "\n")
    if f[3] == "d" then
        description = gsub(description, "%s*You hold %d+%.?$", "")
    end
    shop.incoming = shop.incoming or {}
    shop.incoming[index] = {
        kind = f[3] or "",
        rank = tonumber(f[4] or "") or 1,
        maxRank = tonumber(f[5] or "") or 0,
        name = f[6] or "",
        icon = f[7] or "",
        description = description,
        rarity = tonumber(f[9] or ""),
        locked = f[10] == "1",
        price = tonumber(f[11] or "") or 0,
        state = tonumber(f[12] or "") or 0,
    }
end

handlers["vendorend"] = function()
    if shop.incoming then
        shop.slots = shop.incoming
        shop.incoming = nil
    end
    ShowShelf()
end

handlers["vendorclose"] = function()
    Close()
    shop.slots = {}
end

handlers["start"] = HideNow
handlers["end"] = HideNow

UI.Listen(handlers)
