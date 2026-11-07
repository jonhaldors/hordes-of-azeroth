local L = VanillaBonkL
local UI = VanillaBonkUI
local VB = VanillaBonkRun
local Command = VB.Command
local DialogBackdrop = VB.DialogBackdrop
local FONT = VB.FONT
local ICON_PATH = VB.ICON_PATH
local SetFont = VB.SetFont
local handlers = VB.handlers
local Offer = UI.Module("offer")

local RARITIES = {
    [0] = { name = L["hoa.addon.common"], r = 1, g = 1, b = 1 },
    [1] = { name = L["hoa.addon.uncommon"], r = 0.12, g = 1, b = 0 },
    [2] = { name = L["hoa.addon.rare"], r = 0, g = 0.44, b = 0.87 },
    [3] = { name = L["hoa.addon.epic"], r = 0.64, g = 0.21, b = 0.93 },
    [4] = { name = L["hoa.addon.legendary"], r = 1, g = 0.5, b = 0 },
}

function Offer:RarityText(rarity, text)
    local color = RARITIES[rarity] or RARITIES[0]
    return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

Offer.frame = CreateFrame("Frame", "VanillaBonkOffer", UIParent)
local offerFrame = Offer.frame
offerFrame:SetAllPoints(UIParent)
offerFrame:SetFrameStrata("DIALOG")
offerFrame:EnableMouse(false)
offerFrame:Hide()

offerFrame.dim = offerFrame:CreateTexture(nil, "BACKGROUND")
offerFrame.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
offerFrame.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
offerFrame.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)

offerFrame.chrome = CreateFrame("Frame", nil, offerFrame)
offerFrame.chrome:SetAllPoints(offerFrame)

offerFrame.title = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
offerFrame.title:SetFont(VanillaBonkUI.TITLE_FONT, 46, "OUTLINE")
offerFrame.title:SetPoint("CENTER", offerFrame, "CENTER", 0, 230)
offerFrame.title:SetTextColor(1, 0.82, 0)

offerFrame.subtitle = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.subtitle, 13, "")
offerFrame.subtitle:SetShadowColor(0, 0, 0, 1)
offerFrame.subtitle:SetShadowOffset(1, -1)
offerFrame.subtitle:SetPoint("CENTER", offerFrame, "CENTER", 0, 186)
offerFrame.subtitle:SetTextColor(0.9, 0.83, 0.64)
offerFrame.subtitle:SetText(L["hoa.addon.choose_an_upgrade"])

for side = 1, 2 do
    local line = offerFrame.chrome:CreateTexture(nil, "ARTWORK")
    line:SetTexture(VanillaBonkUI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", offerFrame.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", offerFrame.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

offerFrame.hint = offerFrame.chrome:CreateFontString(nil, "OVERLAY")
SetFont(offerFrame.hint, 11, "")
offerFrame.hint:SetShadowColor(0, 0, 0, 1)
offerFrame.hint:SetShadowOffset(1, -1)
offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206)
offerFrame.hint:SetTextColor(0.78, 0.78, 0.78)

Offer.cards = {}
offerFrame.cardDrop = 0
offerFrame.MAX_GROWTH = 120

local BANISH_RED = { 1, 0.25, 0.2 }

offerFrame.banishEscape = CreateFrame("Frame", "VanillaBonkBanishEscape", UIParent)
offerFrame.banishEscape:SetWidth(1)
offerFrame.banishEscape:SetHeight(1)
offerFrame.banishEscape:Hide()
tinsert(UISpecialFrames, "VanillaBonkBanishEscape")

function VB.IsBanishTarget(card)
    local option = VB.offer[card.index]
    return Offer.banishing and option ~= nil and option.banishable
end

function Offer:SetBanishMode(on)
    on = on and true or false
    Offer.banishing = on
    Offer.banishWarned = nil
    for _, card in ipairs(Offer.cards) do
        if card:IsShown() and card.lineColor then
            local target = VB.IsBanishTarget(card)
            if target then
                card:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3])
                card.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
                card.art:SetVertexColor(1, 0.55, 0.5)
                card.highlight:SetVertexColor(1, 0.3, 0.25)
            else
                local color = card.lineColor
                local border = card.borderColor
                local shade = on and 0.45 or 1
                card:SetBackdropBorderColor(border[1], border[2], border[3])
                card.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
                card.art:SetVertexColor(shade, shade, shade)
                card.highlight:SetVertexColor(1, 1, 1)
            end
            if GetMouseFocus() == card then
                if target then
                    card.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
                else
                    card.line:SetBackdropBorderColor(1, 0.82, 0, 1)
                end
            end
        end
    end
    if offerFrame.banish then
        offerFrame.banish:SetText(on and L["hoa.addon.cancel"] or (L("hoa.addon.cffff6060banish_1_r", VB.banishes or 0)))
    end
    offerFrame.hint:SetText(on and L["hoa.addon.cffff6060click_a_card_to_banish_it_or_press_escape_to_cancel"] or "")
    if on then
        offerFrame.banishEscape:Show()
    else
        offerFrame.banishEscape:Hide()
    end
end

offerFrame.banishEscape:SetScript("OnHide", function()
    if not this:IsShown() and Offer.banishing then
        Offer:SetBanishMode(false)
    end
end)

function Offer:Pick(index)
    if not VB.offer[index] or (VB.picking and GetTime() - (VB.pickingAt or 0) < 3) then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    VB.pickedIndex = index
    Command((VB.offerSource == "ley" and "leypick " or "pick ") .. index)
end

function Offer:Banish(index)
    if not VB.offer[index] or VB.picking or (VB.banishes or 0) < 1 or VB.offerSource == "ley" then
        return
    end
    if not VB.offer[index].banishable then
        if Offer.banishWarned then
            return
        end
        Offer.banishWarned = true
        UIErrorsFrame:AddMessage(L["hoa.addon.you_can_t_banish_an_upgrade_you_already_have"], 1, 0.1, 0.1, 1)
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    Offer:SetBanishMode(false)
    Command("banish " .. index)
end

function Offer:ToggleBanish()
    if Offer.banishing then
        Offer:SetBanishMode(false)
    elseif not VB.picking and (VB.banishes or 0) > 0 and VB.offerSource ~= "ley" then
        Offer:SetBanishMode(true)
    end
end

function Offer:Reroll()
    if VB.picking or (VB.rerolls or 0) < 1 then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    Command("reroll")
end

function Offer:Skip()
    if VB.picking or (VB.skips or 0) < 1 then
        return
    end
    VB.picking = true
    VB.pickingAt = GetTime()
    Command("pass")
end

function Offer:Lock(index)
    if not VB.offer[index] or VB.picking or VB.offerSource ~= "chest" then
        return
    end
    Command("lock " .. index)
end

offerFrame.skip = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.skip:SetWidth(120)
offerFrame.skip:SetHeight(24)
offerFrame.skip:SetScript("OnClick", function() Offer:Skip() end)

offerFrame.reroll = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.reroll:SetWidth(120)
offerFrame.reroll:SetHeight(24)
offerFrame.reroll:SetScript("OnClick", function() Offer:Reroll() end)

offerFrame.banish = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, offerFrame.chrome, "UIPanelButtonTemplate"))
offerFrame.banish:SetWidth(120)
offerFrame.banish:SetHeight(24)
offerFrame.banish:SetScript("OnClick", function() Offer:ToggleBanish() end)

do
    local KEY_PROMPT_BUTTONS = { skip = "VANILLABONK_SKIP", reroll = "VANILLABONK_REROLL", banish = "VANILLABONK_BANISH" }

    local function RefreshKeyPrompt(button)
        local text = VanillaBonkUI.BindingText and VanillaBonkUI.BindingText(button.keyCommand) or ""
        button.keyPrompt:SetText(text)
    end

    function Offer:RefreshKeyPrompts()
        for name in pairs(KEY_PROMPT_BUTTONS) do
            RefreshKeyPrompt(offerFrame[name])
        end
    end

    for name, command in pairs(KEY_PROMPT_BUTTONS) do
        local button = offerFrame[name]
        button.keyCommand = command
        button.keyPrompt = VanillaBonkUI.Text(button, 11, VanillaBonkUI.NUMBER_FONT, "OUTLINE")
        button.keyPrompt:SetPoint("RIGHT", button, "RIGHT", -8, 0)
        button.keyPrompt:SetTextColor(0.85, 0.85, 0.85)
        local show = button:GetScript("OnShow")
        button:SetScript("OnShow", function()
            if show then
                show()
            end
            RefreshKeyPrompt(this)
        end)
    end

    UI.Module("offerKeyPrompts"):OnBindings(function() Offer:RefreshKeyPrompts() end)
end

local CardArt = VanillaBonkUI.CardArt

local CARD_HEIGHT = 300
local DAMAGE_ROW_HEIGHT = 14
local DAMAGE_ROW_GAP = 4
local DAMAGE_ARROW_SIZE = 12
local DAMAGE_ARROW = "Interface\\MoneyFrame\\Arrow-Right-Up"
local STAT_BLOCK = { labelSize = 10, valueSize = 16, step = 40, arrowGap = 4 }

local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }
local DARKMOON_CLOTH = "World\\ENVIRONMENT\\DOODAD\\Carnival\\bm_Carnie_tarp01"
local DARKMOON_BANNER = "World\\ENVIRONMENT\\DOODAD\\Carnival\\Darkmoon_Banner01"
local MAX_CARDS = 6
local KEYWORD_ALIASES = {
    [L["hoa.addon.chill"]] = { L["hoa.addon.chilled"] },
    [L["hoa.addon.frozen"]] = { L["hoa.addon.freezes"], L["hoa.addon.freeze"], L["hoa.addon.shatter"] },
    [L["hoa.addon.hunter_s_mark"]] = { L["hoa.addon.marked"] },
    [L["hoa.addon.poison"]] = { L["hoa.addon.poisoned"] },
    [L["hoa.addon.bleed"]] = { L["hoa.addon.bleeding"] },
    [L["hoa.addon.dazed"]] = { L["hoa.addon.dazes"], L["hoa.addon.daze"] },
}
VB.keywords = {}

local function IsLetter(char)
    return char ~= "" and strfind(char, "%a") ~= nil
end

function Offer:KeywordTerms()
    if VB.keywordTerms then
        return VB.keywordTerms
    end
    local terms = {}
    for id, keyword in pairs(VB.keywords) do
        tinsert(terms, { text = keyword.name, id = id })
        for _, alias in ipairs(KEYWORD_ALIASES[keyword.name] or {}) do
            tinsert(terms, { text = alias, id = id })
        end
    end
    for _, term in ipairs(VB.statTerms or {}) do
        tinsert(terms, term)
    end
    table.sort(terms, function(a, b) return strlen(a.text) > strlen(b.text) end)
    VB.keywordTerms = terms
    return terms
end

local HTML_ESCAPES = { ["&"] = "&amp;", ["<"] = "&lt;", [">"] = "&gt;" }

function Offer:MatchKeyword(text, pos, terms)
    if IsLetter(strsub(text, pos - 1, pos - 1)) then
        return nil
    end
    for _, term in ipairs(terms) do
        local stop = pos + strlen(term.text) - 1
        if strsub(text, pos, stop) == term.text and not IsLetter(strsub(text, stop + 1, stop + 1)) then
            local wholeLabel = pos == 1 and stop == strlen(text)
            if not term.stat or wholeLabel or strfind(strsub(text, max(1, pos - 2), pos - 1), "^[%d%%] $") then
                return term, stop
            end
        end
    end
end

VB.keywordColors = {
    [L["hoa.addon.chill"]] = { 0.41, 0.8, 0.94 },
    [L["hoa.addon.frozen"]] = { 0.41, 0.8, 0.94 },
    [L["hoa.addon.burning"]] = { 1, 0.71, 0.24 },
    [L["hoa.addon.fire_vulnerability"]] = { 1, 0.49, 0.1 },
    [L["hoa.addon.bleed"]] = { 1, 0.33, 0.33 },
    [L["hoa.addon.poison"]] = { 0.4, 0.85, 0.3 },
    [L["hoa.addon.nature_vulnerability"]] = { 0.25, 0.78, 0.71 },
    [L["hoa.addon.static"]] = { 0.25, 0.78, 0.71 },
    [L["hoa.addon.decay"]] = { 0.7, 0.55, 1 },
    [L["hoa.addon.shadow_vulnerability"]] = { 0.7, 0.55, 1 },
    [L["hoa.addon.sunder_armor"]] = { 0.78, 0.61, 0.43 },
    [L["hoa.addon.dazed"]] = { 0.78, 0.61, 0.43 },
    [L["hoa.addon.hunter_s_mark"]] = { 0.78, 0.61, 0.43 },
}

function VB.KeywordRGB(id)
    if VB.statTips and VB.statTips[id] then
        return 1, 1, 1
    end
    local keyword = VB.keywords[id]
    local color = keyword and VB.keywordColors[keyword.name]
    if color then
        return color[1], color[2], color[3]
    end
    return 0.41, 0.8, 0.94
end

function VB.TermColor(term)
    local r, g, b = VB.KeywordRGB(term.id)
    return format("|cff%02x%02x%02x", floor(r * 255 + 0.5), floor(g * 255 + 0.5), floor(b * 255 + 0.5))
end

function Offer:KeywordHtml(text)
    local terms = Offer:KeywordTerms()
    local pieces, links = {}, {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local char = strsub(text, pos, pos)
        if char == "|" then
            local size = strsub(text, pos + 1, pos + 1) == "c" and 10 or 2
            tinsert(pieces, strsub(text, pos, pos + size - 1))
            pos = pos + size
        elseif char == "\n" then
            tinsert(pieces, "<br/>")
            pos = pos + 1
        else
            local term, stop = Offer:MatchKeyword(text, pos, terms)
            if term then
                tinsert(pieces, VB.TermColor(term) .. '<a href="bonkkw:' .. term.id .. '">' .. term.text .. "</a>|r")
                tinsert(links, term.id)
                pos = stop + 1
            else
                tinsert(pieces, HTML_ESCAPES[char] or char)
                pos = pos + 1
            end
        end
    end
    return '<html><body><p align="center">' .. table.concat(pieces) .. "</p></body></html>", links
end

function Offer:FindKeyword(text)
    local terms = Offer:KeywordTerms()
    for pos = 1, strlen(text) do
        local term, stop = Offer:MatchKeyword(text, pos, terms)
        if term then
            return term, pos, stop
        end
    end
end

function Offer:ColorKeywords(text)
    local terms = Offer:KeywordTerms()
    local pieces = {}
    local pos, length = 1, strlen(text)
    while pos <= length do
        local term, stop = Offer:MatchKeyword(text, pos, terms)
        if term then
            tinsert(pieces, VB.TermColor(term) .. term.text .. "|r")
            pos = stop + 1
        else
            tinsert(pieces, strsub(text, pos, pos))
            pos = pos + 1
        end
    end
    return table.concat(pieces)
end

function VanillaBonkUI.InspectShown()
    return VanillaBonkShop:IsShown() and VB.shop ~= nil and VB.shop.inspect == true
end

function VanillaBonkUI.HideInspect()
    VanillaBonkShop:Hide()
end

function VanillaBonkUI.InRun()
    return VB.inRun
end

function VanillaBonkUI.HasKeywordTip(id)
    return id ~= nil and ((VB.statTips and VB.statTips[id]) or VB.keywords[id]) ~= nil
end

function VanillaBonkUI.FillKeywordTip(tooltip, id)
    local stat = VB.statTips and VB.statTips[id]
    if stat then
        tooltip:AddLine(stat.name, 1, 1, 1)
        tooltip:AddLine(stat.text, 1, 0.82, 0, 1)
        return
    end
    local keyword = VB.keywords[id]
    tooltip:AddLine(keyword.name, VB.KeywordRGB(id))
    tooltip:AddLine(keyword.description, 1, 1, 1, 1)
end

function Offer:ShowKeywordTooltip(id, owner)
    if not VanillaBonkUI.HasKeywordTip(id) then
        return
    end
    GameTooltip:SetOwner(owner, "ANCHOR_TOP")
    VanillaBonkUI.FillKeywordTip(GameTooltip, id)
    GameTooltip:Show()
end

local OfferCard = {}

function OfferCard:Highlight()
    if VB.IsBanishTarget(self) then
        self.line:SetBackdropBorderColor(1, 0.1, 0.05, 1)
    else
        self.line:SetBackdropBorderColor(1, 0.82, 0, 1)
    end
end

function OfferCard:Unhighlight()
    if VB.IsBanishTarget(self) then
        self.line:SetBackdropBorderColor(BANISH_RED[1], BANISH_RED[2], BANISH_RED[3], 1)
        return
    end
    local color = self.lineColor
    self.line:SetBackdropBorderColor(color[1], color[2], color[3], color[4])
end

function OfferCard:Click(button)
    if button == "RightButton" then
        if Offer.banishing then
            Offer:SetBanishMode(false)
        end
    elseif Offer.banishing then
        Offer:Banish(self.index)
    else
        Offer:Pick(self.index)
    end
end

local KEYWORD_HOVER_MIN_FRAMES = 2
local KEYWORD_HOVER_MAX_FRAMES = 120
function Offer:UnderlineKeyword(hover, width)
    local dotWidth, dotStep = 2, 4
    hover.dots = hover.dots or {}
    local count = floor((width - dotWidth) / dotStep) + 1
    local r, g, b = VB.KeywordRGB(hover.keyword)
    for index = 1, count do
        local dot = hover.dots[index]
        if not dot then
            dot = hover:CreateTexture(nil, "OVERLAY")
            dot:SetTexture(VanillaBonkUI.FLAT)
            dot:SetWidth(dotWidth)
            dot:SetHeight(1)
            hover.dots[index] = dot
        end
        dot:SetVertexColor(r, g, b, 0.85)
        dot:ClearAllPoints()
        dot:SetPoint("BOTTOMLEFT", hover, "BOTTOMLEFT", (index - 1) * dotStep, 0)
        dot:Show()
    end
    for index = count + 1, table.getn(hover.dots) do
        hover.dots[index]:Hide()
    end
end

local function ReadingOrder(a, b)
    local aTop, bTop = a:GetTop(), b:GetTop()
    if math.abs(aTop - bTop) > 2 then
        return aTop > bTop
    end
    return a:GetLeft() < b:GetLeft()
end

function Offer:KeywordSpans(html)
    local spans = {}
    for _, span in ipairs({ html:GetChildren() }) do
        if span:IsShown() and span:GetLeft() and span:GetTop() then
            span:EnableMouse(false)
            tinsert(spans, span)
        end
    end
    table.sort(spans, ReadingOrder)
    return spans
end

function OfferCard:CreateKeywordHover(index, parent)
    local hover = CreateFrame("Button", nil, parent or self)
    hover:SetFrameLevel(self.description:GetFrameLevel() + 2)
    hover:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    hover.card = self
    hover:SetScript("OnEnter", function()
        this.card:Highlight()
        Offer:ShowKeywordTooltip(this.keyword, this)
    end)
    hover:SetScript("OnLeave", function()
        GameTooltip:Hide()
        if not MouseIsOver(this.card) then
            this.card:Unhighlight()
        end
    end)
    hover:SetScript("OnClick", function()
        this.card:Click(arg1)
    end)
    if index then
        self.hovers[index] = hover
    end
    return hover
end

function OfferCard:PlaceKeywordHovers(spans)
    local html = self.description
    for index, span in ipairs(spans) do
        local hover = self.hovers[index] or self:CreateKeywordHover(index)
        hover:ClearAllPoints()
        hover:SetPoint("TOPLEFT", html, "TOPLEFT", span:GetLeft() - html:GetLeft(), span:GetTop() - html:GetTop())
        hover:SetWidth(span:GetWidth())
        hover:SetHeight(span:GetHeight())
        hover.keyword = self.descriptionLinks and self.descriptionLinks[index]
        Offer:UnderlineKeyword(hover, span:GetWidth())
        hover:Show()
    end
    for index = table.getn(spans) + 1, table.getn(self.hovers) do
        self.hovers[index]:Hide()
    end
end

function OfferCard:SetKeywordText()
    for _, hover in ipairs(self.hovers) do
        hover:Hide()
    end
    self.description:SetText(self.descriptionHtml or "")
    self.description.hoverFrames = 0
end

function Offer:UpdateKeywordHovers(html)
    local links = table.getn(html.card.descriptionLinks or {})
    if links == 0 then
        html.hoverFrames = nil
        return
    end
    html.hoverFrames = html.hoverFrames + 1
    if html.hoverFrames < KEYWORD_HOVER_MIN_FRAMES then
        return
    end
    local spans = Offer:KeywordSpans(html)
    if table.getn(spans) >= links then
        html.hoverFrames = nil
        html.card:PlaceKeywordHovers(spans)
    elseif html.hoverFrames >= KEYWORD_HOVER_MAX_FRAMES then
        html.hoverFrames = nil
    end
end

function OfferCard:RebuildKeywordLinks()
    if self.descriptionHtml then
        self:SetKeywordText()
    end
end

for index = 1, MAX_CARDS do
    local card = CreateFrame("Button", nil, offerFrame)
    card:SetHeight(CARD_HEIGHT)
    card:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    card.index = index

    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    VanillaBonkUI.Shade(card.shade, 0.95, 0.1)

    card:SetBackdrop(STONE_BORDER)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })

    card.slot = VanillaBonkUI.Slot(card, 56, "Frame")
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
    card.eye = VanillaBonkUI.Ring(card, 52, true)
    card.eye:SetPoint("CENTER", card.crest, "CENTER", 0, 0)
    card.eye.icon = VanillaBonkUI.RingArt(card.eye, "")
    card.eye:Hide()

    card.key = VanillaBonkUI.Ring(card, 28)
    card.key:SetPoint("TOPLEFT", card, "TOPLEFT", 13, -13)
    card.key.text = VanillaBonkUI.Text(card.key, 13)
    card.key.text:SetPoint("CENTER", card.key, "CENTER", 0, 0)
    card.key.text:SetTextColor(1, 0.82, 0)
    card.key.text:SetText(index)

    card.name = VanillaBonkUI.Text(card, 17)
    card.name:SetPoint("TOP", card, "TOP", 0, -104)
    card.name:SetJustifyH("CENTER")

    card.level = VanillaBonkUI.Text(card, 11)
    card.level:SetPoint("TOP", card.name, "BOTTOM", 0, -4)
    card.level:SetTextColor(0.85, 0.85, 0.85)

    card.divider = card:CreateTexture(nil, "ARTWORK")
    card.divider:SetTexture(VanillaBonkUI.FLAT)
    card.divider:SetHeight(1)
    card.divider:SetPoint("TOPRIGHT", card.level, "BOTTOM", 0, -11)
    card.divider:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
    card.dividerRight = card:CreateTexture(nil, "ARTWORK")
    card.dividerRight:SetTexture(VanillaBonkUI.FLAT)
    card.dividerRight:SetHeight(1)
    card.dividerRight:SetPoint("TOPLEFT", card.level, "BOTTOM", 0, -11)
    card.dividerRight:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)

    card.count = VanillaBonkUI.Text(card, 11)
    card.count:SetPoint("TOPRIGHT", card, "TOPRIGHT", -16, -17)
    card.count:SetTextColor(0.85, 0.85, 0.85)

    card.measure = VanillaBonkUI.Text(card, 13)
    card.measure:SetPoint("TOPLEFT", card, "TOPLEFT", 0, 0)
    card.measure:SetJustifyH("CENTER")
    card.measure:SetTextColor(0, 0, 0, 0)
    card.measure:SetShadowColor(0, 0, 0, 0)

    card.damage = CreateFrame("Frame", nil, card)
    card.damage:SetHeight(DAMAGE_ROW_HEIGHT)
    card.damage.label = VanillaBonkUI.Text(card.damage, 12)
    card.damage.label:SetTextColor(0.85, 0.85, 0.85)
    card.damage.before = VanillaBonkUI.Text(card.damage, 12)
    card.damage.before:SetTextColor(0.6, 0.6, 0.6)
    card.damage.strike = card.damage:CreateTexture(nil, "OVERLAY")
    card.damage.strike:SetTexture(VanillaBonkUI.FLAT)
    card.damage.strike:SetVertexColor(0.75, 0.75, 0.75)
    card.damage.strike:SetHeight(1)
    card.damage.strike:SetPoint("LEFT", card.damage.before, "LEFT", 0, 0)
    card.damage.arrow = card.damage:CreateTexture(nil, "ARTWORK")
    card.damage.arrow:SetTexture(DAMAGE_ARROW)
    card.damage.arrow:SetWidth(DAMAGE_ARROW_SIZE)
    card.damage.arrow:SetHeight(DAMAGE_ARROW_SIZE)
    card.damage.after = VanillaBonkUI.Text(card.damage, 12)
    card.damage.after:SetTextColor(0.13, 1, 0.13)
    card.damage:Hide()

    card.description = CreateFrame("SimpleHTML", nil, card)
    card.description:SetPoint("TOP", card.divider, "BOTTOMRIGHT", 0, -10)
    card.description:SetFont("P", FONT, 13, "")
    card.description:SetTextColor("P", 1, 0.82, 0)
    card.description:SetShadowColor("P", 0, 0, 0, 1)
    card.description:SetShadowOffset("P", 1, -1)
    card.description.card = card
    card.hovers = {}
    card.description:SetScript("OnUpdate", function()
        if this.hoverFrames then
            Offer:UpdateKeywordHovers(this)
        end
    end)

    card.highlight = card:CreateTexture(nil, "HIGHLIGHT")
    card.highlight:SetTexture("Interface\\Buttons\\UI-Panel-Button-Highlight")
    card.highlight:SetBlendMode("ADD")
    card.highlight:SetTexCoord(0, 0.625, 0, 0.6875)
    card.highlight:SetAlpha(0.35)
    card.highlight:SetAllPoints(card.art)

    card:SetScript("OnClick", function()
        card:Click(arg1)
    end)
    card:SetScript("OnEnter", function()
        card:Highlight()
    end)
    card:SetScript("OnLeave", function()
        card:Unhighlight()
    end)

    card.lock = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, card, "UIPanelButtonTemplate"))
    card.lock:SetWidth(80)
    card.lock:SetHeight(20)
    card.lock:SetPoint("BOTTOM", card, "BOTTOM", 0, 18)
    card.lock.index = index
    card.lock:SetScript("OnClick", function()
        Offer:Lock(this.index)
    end)

    Offer.cards[index] = card
end

local OFFER_POP = 0.24
local OFFER_STAGGER = 0.05
local OFFER_CLOSE = 0.18
local OFFER_DIM = 1
local GARBAGE_DUE = 0.75

local function CollectGarbageIfDue()
    local used, threshold = gcinfo()
    if used and threshold and threshold > 0 and used >= threshold * GARBAGE_DUE then
        collectgarbage()
    end
end

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

offerFrame.SIDE_SCALE = 0.5
offerFrame.SIDE_BOTTOM = 140
offerFrame.SIDE_BUTTON_STEP = 28

function OfferCard:Place(scale, alpha, rise)
    self:SetAlpha(alpha)
    self.alphaNow = alpha
    self:ClearAllPoints()
    if offerFrame.side then
        local sideScale = scale * offerFrame.SIDE_SCALE
        self:SetScale(sideScale)
        self:SetPoint("BOTTOM", UIParent, "BOTTOM", self.x * offerFrame.SIDE_SCALE / sideScale, (offerFrame.SIDE_BOTTOM + rise * offerFrame.SIDE_SCALE) / sideScale)
        return
    end
    self:SetScale(scale)
    self:SetPoint("CENTER", offerFrame, "CENTER", self.x / scale, (16 - offerFrame.cardDrop + rise) / scale)
end

function Offer:ApplySideChrome()
    offerFrame.title:ClearAllPoints()
    offerFrame.subtitle:ClearAllPoints()
    if offerFrame.side then
        offerFrame.title:Hide()
        offerFrame.subtitle:SetPoint("TOP", UIParent, "BOTTOM", 0, offerFrame.SIDE_BOTTOM - 6)
        offerFrame.dim:Hide()
        offerFrame.hint:Hide()
        return
    end
    offerFrame.title:SetPoint("CENTER", offerFrame, "CENTER", 0, 230)
    offerFrame.title:Show()
    offerFrame.subtitle:SetPoint("CENTER", offerFrame, "CENTER", 0, 186)
    offerFrame.dim:Show()
    offerFrame.hint:Show()
end

local CHOICE_KEYS = {
    ["1"] = "VANILLABONK_CHOICE1", ["2"] = "VANILLABONK_CHOICE2", ["3"] = "VANILLABONK_CHOICE3",
    ["4"] = "VANILLABONK_CHOICE4", ["5"] = "VANILLABONK_CHOICE5", ["6"] = "VANILLABONK_CHOICE6",
    ["R"] = "VANILLABONK_REROLL", ["X"] = "VANILLABONK_SKIP", ["B"] = "VANILLABONK_BANISH",
}
BINDING_HEADER_VANILLABONK = L["hoa.addon.hordes_of_azeroth"]
for index = 1, 6 do
    setglobal("BINDING_NAME_VANILLABONK_CHOICE" .. index, L("hoa.addon.choose_card_1", index))
end
BINDING_NAME_VANILLABONK_REROLL = L["hoa.addon.reroll_cards"]
BINDING_NAME_VANILLABONK_SKIP = L["hoa.addon.skip_cards"]
BINDING_NAME_VANILLABONK_BANISH = L["hoa.addon.banish_card"]

function Offer:GiveBackChoiceKeys()
    if not VanillaBonkChoiceKeys or (VanillaBonkGlyphs and VanillaBonkGlyphs.open) then
        return
    end
    for key, action in pairs(VanillaBonkChoiceKeys) do
        if action ~= "" then
            SetBinding(key, action)
        else
            SetBinding(key)
        end
    end
    VanillaBonkChoiceKeys = nil
end

function Offer:TakeChoiceKeys()
    if VanillaBonkChoiceKeys then
        return
    end
    local before = {}
    for key, action in pairs(CHOICE_KEYS) do
        before[key] = GetBindingAction(key) or ""
        SetBinding(key, action)
    end
    VanillaBonkChoiceKeys = before
    Offer:RefreshKeyPrompts()
end

VanillaBonk_TakeChoiceKeys = function() Offer:TakeChoiceKeys() end
VanillaBonk_GiveBackChoiceKeys = function() Offer:GiveBackChoiceKeys() end

function VanillaBonk_ChoiceKey(key)
    if VanillaBonkMenu and VanillaBonkMenu:IsShown() then
        return
    end
    local index = tonumber(key)
    if index and VanillaBonk_GlyphKey and VanillaBonk_GlyphKey(index) then
        return
    end
    if key == "R" and VanillaBonk_GlyphReroll and VanillaBonk_GlyphReroll() then
        return
    end
    if not Offer.open then
        return
    end
    if index and Offer.banishing then
        Offer:Banish(index)
    elseif index then
        Offer:Pick(index)
    elseif key == "R" then
        Offer:Reroll()
    elseif key == "X" then
        Offer:Skip()
    elseif key == "B" then
        Offer:ToggleBanish()
    end
end

UI.Module("choiceKeys"):Listen({
    VARIABLES_LOADED = function() Offer:GiveBackChoiceKeys() end,
    PLAYER_LOGOUT = function() Offer:GiveBackChoiceKeys() end,
})

local CARD_TEXT_WIDTH = 220
function OfferCard:LayoutDamageRow(option, hasLock)
    local row = self.damage
    local after = option and option.damageAfter or ""
    if after == "" then
        row:Hide()
        return 0
    end
    local before = option.damageBefore or ""
    local label = option.damageLabel or ""
    if label == "" then
        label = L["hoa.addon.damage_2"]
    end
    row.label:SetText(label ~= "" and label .. ":" or "")
    row.before:SetText(before)
    row.after:SetText(after)
    local changed = before ~= ""
    local labelWidth = label ~= "" and row.label:GetStringWidth() + DAMAGE_ROW_GAP or 0
    local beforeWidth = changed and row.before:GetStringWidth() or 0
    local arrowWidth = changed and DAMAGE_ARROW_SIZE + 2 * DAMAGE_ROW_GAP or 0
    local total = labelWidth + beforeWidth + arrowWidth + row.after:GetStringWidth()
    if labelWidth > 0 and total > self:GetWidth() - 16 then
        row.label:SetText("")
        total = total - labelWidth
        labelWidth = 0
    end
    row:SetWidth(total)
    row:ClearAllPoints()
    row:SetPoint("BOTTOM", self, "BOTTOM", 0, hasLock and 46 or 18)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", row, "LEFT", 0, 0)
    row.before:ClearAllPoints()
    row.before:SetPoint("LEFT", row, "LEFT", labelWidth, 0)
    row.strike:SetWidth(max(1, beforeWidth))
    row.arrow:ClearAllPoints()
    row.arrow:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + DAMAGE_ROW_GAP, 0)
    row.after:ClearAllPoints()
    row.after:SetPoint("LEFT", row, "LEFT", labelWidth + beforeWidth + arrowWidth, 0)
    if changed then
        row.before:Show()
        row.strike:Show()
        row.arrow:Show()
    else
        row.before:Hide()
        row.strike:Hide()
        row.arrow:Hide()
    end
    row:Show()
    return DAMAGE_ROW_HEIGHT + DAMAGE_ROW_GAP
end

function OfferCard:FitCardText(width, darkmoon, hasLock, damageRoom)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    self.name:SetFont(FONT, max(12, floor(17 * scale + 0.5)))
    self.name:SetWidth(width - 28)
    self.level:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    self.level:SetWidth(width - 20)
    self.count:SetFont(FONT, max(9, floor(11 * scale + 0.5)))
    self.description:SetWidth(width - 36)
    self.measure:SetWidth(width - 36)
    self.measure:SetText(self.descriptionText or "")

    local top = darkmoon and 158 or 104
    local used = top + self.name:GetHeight() + 4 + self.level:GetHeight() + 11 + 1 + 10
    local room = offerFrame.cardHeight - used - (hasLock and 46 or 18) - (damageRoom or 0)
    local size = max(10, floor(13 * scale + 0.5))
    while size > 9 do
        self.measure:SetFont(FONT, size)
        local needed = self.measure:GetHeight()
        if not needed or needed == 0 or needed <= room then
            break
        end
        size = size - 1
    end
    self.measure:SetFont(FONT, size)
    self.overflow = max(0, (self.measure:GetHeight() or 0) - room)
    self.description:SetFont("P", FONT, size, "")
    self.description:SetHeight(max(room, 12))
    self.descriptionHtml, self.descriptionLinks = Offer:KeywordHtml(self.descriptionText or "")
    self:SetKeywordText()
    return room
end

function OfferCard:GetStatBlock(index)
    self.stats = self.stats or {}
    local block = self.stats[index]
    if block then
        return block
    end
    block = CreateFrame("Frame", nil, self)
    block.label = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.label:SetTextColor(0.65, 0.65, 0.65)
    block.label:SetJustifyH("CENTER")
    block.label:SetPoint("TOP", block, "TOP", 0, 0)
    block.before = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.before:SetTextColor(0.6, 0.6, 0.6)
    block.arrow = block:CreateTexture(nil, "ARTWORK")
    block.arrow:SetTexture(DAMAGE_ARROW)
    block.after = VanillaBonkUI.Text(block, STAT_BLOCK.valueSize)
    block.after:SetTextColor(0.13, 1, 0.13)
    block.measure = VanillaBonkUI.Text(block, STAT_BLOCK.labelSize)
    block.measure:SetTextColor(0, 0, 0, 0)
    block.measure:SetShadowColor(0, 0, 0, 0)
    block.measure:SetPoint("TOPLEFT", block, "TOPLEFT", 0, 0)
    block.hover = self:CreateKeywordHover(nil, block)
    self.stats[index] = block
    return block
end

function OfferCard:HideStats(from)
    if not self.stats then
        return
    end
    for index = from, getn(self.stats) do
        self.stats[index]:Hide()
    end
end

function Offer:PlaceStatKeyword(block, label, size)
    local hover = block.hover
    local term, start = Offer:FindKeyword(label)
    if not term then
        hover:Hide()
        return
    end
    block.measure:SetFont(FONT, size)
    block.measure:SetText(strsub(label, 1, start - 1))
    local prefix = start > 1 and block.measure:GetStringWidth() or 0
    block.measure:SetText(term.text)
    local word = block.measure:GetStringWidth()
    hover:ClearAllPoints()
    hover:SetPoint("TOPLEFT", block, "TOP", prefix - block.label:GetStringWidth() / 2, 0)
    hover:SetWidth(word)
    hover:SetHeight(size + 2)
    hover.keyword = term.id
    Offer:UnderlineKeyword(hover, word)
    hover:Show()
end

function OfferCard:LayoutStats(stats, width, room)
    local scale = min(1, width / CARD_TEXT_WIDTH)
    local count = getn(stats)
    local labelSize = max(8, floor(STAT_BLOCK.labelSize * scale + 0.5))
    local step = min(floor(STAT_BLOCK.step * scale + 0.5), floor(room / max(1, count)))
    local valueSize = max(10, min(floor(STAT_BLOCK.valueSize * scale + 0.5), step - labelSize - 8))
    local arrowSize = floor(valueSize * 0.8 + 0.5)
    for index, stat in ipairs(stats) do
        local block = self:GetStatBlock(index)
        block:SetWidth(width - 20)
        block:SetHeight(step)
        block:ClearAllPoints()
        block:SetPoint("TOP", self.divider, "BOTTOMRIGHT", 0, -8 - (index - 1) * step)
        block.label:SetFont(FONT, labelSize)
        block.label:SetWidth(width - 24)
        block.label:SetText(Offer:ColorKeywords(stat.label))
        Offer:PlaceStatKeyword(block, stat.label, labelSize)
        block.before:SetFont(FONT, valueSize)
        block.after:SetFont(FONT, valueSize)
        local capped = stat.before == stat.after
        block.before:SetText(capped and L("hoa.addon.1_max", stat.before) or stat.before)
        block.after:SetText(capped and "" or stat.after)
        block.arrow:SetWidth(arrowSize)
        block.arrow:SetHeight(arrowSize)
        local total = block.before:GetStringWidth()
        if capped then
            block.arrow:Hide()
        else
            block.arrow:Show()
            total = total + arrowSize + 2 * STAT_BLOCK.arrowGap + block.after:GetStringWidth()
        end
        block.before:ClearAllPoints()
        block.before:SetPoint("TOPLEFT", block, "TOP", -total / 2, -(block.label:GetHeight() + 3))
        block.arrow:ClearAllPoints()
        block.arrow:SetPoint("LEFT", block.before, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block.after:ClearAllPoints()
        block.after:SetPoint("LEFT", block.arrow, "RIGHT", STAT_BLOCK.arrowGap, 0)
        block:Show()
    end
    self:HideStats(count + 1)
end

function OfferCard:FitCard(option, width, hasLock)
    local darkmoon = option.kind == "c"
    if not darkmoon then
        VanillaBonkUI.TalentArtCoords(self.art, width - 18, offerFrame.cardHeight - 18)
    end
    if option.stats and getn(option.stats) > 0 then
        self.descriptionText = ""
        self.damage:Hide()
        self:LayoutStats(option.stats, width, self:FitCardText(width, darkmoon, hasLock, 0))
    else
        self:HideStats(1)
        self.descriptionText = option.description
        self:FitCardText(width, darkmoon, hasLock, self:LayoutDamageRow(option, hasLock))
    end
end

for _, card in ipairs(Offer.cards) do
    UI.Mixin(card, { OfferCard })
end

function Offer:GrowCardsToFit(width, hasLock)
    local grow = 0
    for index, card in ipairs(Offer.cards) do
        if VB.offer[index] then
            grow = max(grow, card.overflow or 0)
        end
    end
    grow = min(ceil(grow), offerFrame.MAX_GROWTH)
    if grow > 0 then
        offerFrame.cardHeight = CARD_HEIGHT + grow
        for index, card in ipairs(Offer.cards) do
            local option = VB.offer[index]
            if option then
                card:SetHeight(offerFrame.cardHeight)
                card:FitCard(option, width, hasLock)
            end
        end
    end
    offerFrame.cardDrop = grow / 2
    for index, card in ipairs(Offer.cards) do
        if VB.offer[index] and not card.pop then
            card:Place(1, 1, 0)
        end
    end
    offerFrame.hint:SetPoint("CENTER", offerFrame, "CENTER", 0, -206 - grow)
    return grow
end

function Offer:Subtitle()
    if VB.offerSource == "ley" then
        return L["hoa.addon.choose_a_blessing"]
    end
    local cards, upgrades = 0, 0
    for _, option in ipairs(VB.offer) do
        if option.kind == "c" then
            cards = cards + 1
        else
            upgrades = upgrades + 1
        end
    end
    if cards > 0 and upgrades > 0 then
        return L["hoa.addon.choose_a_reward"]
    end
    return cards > 0 and L["hoa.addon.choose_a_darkmoon_card"] or L["hoa.addon.choose_an_upgrade"]
end

function Offer:ShowOffer(level)
    if Offer.anim and Offer.anim.mode == "close" then
        Offer.deferred = { level = level }
        return
    end
    local fresh = not Offer.open
    offerFrame.side = VB.sideOffers and true or false
    offerFrame.SIDE_SCALE = VanillaBonkUI.SideScale(0.5)
    Offer:ApplySideChrome()
    if not fresh and not Offer.anim then
        Offer.anim = { mode = "pop", t = 0 }
    end

    if VB.offerSource == "chest" then
        offerFrame.title:SetText(L["hoa.addon.chest"])
    elseif VB.offerSource == "ley" then
        offerFrame.title:SetText(L["hoa.addon.ley_line"])
    else
        offerFrame.title:SetText(L("hoa.addon.level_1", level))
    end
    offerFrame.subtitle:SetText(Offer:Subtitle())

    local count = getn(VB.offer)
    local gap = count <= 3 and 20 or 12
    local width = count <= 3 and 220 or (count == 4 and 200 or 180)
    width = min(width, floor((UIParent:GetWidth() - 40 - (count - 1) * gap) / max(1, count)))
    local left = -((count * width + (count - 1) * gap) / 2) + width / 2
    local hasLock = VB.offerSource == "chest"
    offerFrame.cardHeight = CARD_HEIGHT

    for index, card in ipairs(Offer.cards) do
        local option = VB.offer[index]
        if option then
            card:SetWidth(width)
            card:SetHeight(CARD_HEIGHT)
            card.x = left + (index - 1) * (width + gap)
            local look = option.name .. option.icon .. option.newLevel .. (option.rarity or "")
            if fresh then
                card.pop = 0.08 + (index - 1) * OFFER_STAGGER
                card:Place(0.8, 0, -24)
            elseif card.look ~= look or not card:IsShown() then
                card.pop = Offer.anim.t
                card:Place(0.8, 0, -24)
            elseif not card.pop then
                card:Place(1, 1, 0)
            end
            card.look = look
            card.divider:SetWidth((width - 48) / 2)
            card.dividerRight:SetWidth((width - 48) / 2)

            local darkmoon = option.kind == "c"
            if darkmoon then
                card.art:SetTexture(DARKMOON_CLOTH)
                card.art:SetTexCoord(0, 1, 0, 1)
                VanillaBonkUI.Shade(card.shade, 0.95, 0.4)
                card.slot:Hide()
                card.crest:Show()
                card.eye.icon:SetTexture(ICON_PATH .. option.icon)
                card.eye:Show()
                card.name:SetPoint("TOP", card, "TOP", 0, -158)
            else
                card.art:SetTexture("Interface\\TalentFrame\\" .. CardArt(option.icon) .. "-TopLeft")
                VanillaBonkUI.Shade(card.shade, 0.95, 0.1)
                card.slot:Show()
                card.crest:Hide()
                card.eye:Hide()
                card.name:SetPoint("TOP", card, "TOP", 0, -104)
            end
            card.slot.icon:SetTexture(ICON_PATH .. option.icon)
            card.name:SetText(option.name)

            local rarity = option.kind == "e" and 4 or option.rarity
            local color = rarity and RARITIES[rarity]
            if color then
                card.name:SetTextColor(color.r, color.g, color.b)
                card.lineColor = { color.r, color.g, color.b, 0.9 }
                card.glow:SetVertexColor(color.r, color.g, color.b)
                card.glow:Show()
            else
                card.name:SetTextColor(1, 1, 1)
                card.lineColor = { 0.85, 0.75, 0.5, 0.35 }
                card.glow:Hide()
            end
            local rarityName = option.rarity and RARITIES[option.rarity] and Offer:RarityText(option.rarity, RARITIES[option.rarity].name)
            if option.kind == "e" then
                card.level:SetText(L("hoa.addon.1_evolution", Offer:RarityText(4, L["hoa.addon.legendary"])))
            elseif option.kind == "ley" then
                card.level:SetText(rarityName and L("hoa.addon.1_blessing", rarityName) or L["hoa.addon.blessing"])
            elseif option.kind == "c" then
                card.level:SetText(rarityName and L("hoa.addon.1_darkmoon_card", rarityName) or L["hoa.addon.darkmoon_card_2"])
            elseif option.newLevel == 1 then
                card.level:SetText(option.kind == "p" and L["hoa.addon.cff20ff20new_passive_r"] or L["hoa.addon.cff20ff20new_spell_r"])
            elseif option.kind == "p" then
                card.level:SetText(rarityName and L("hoa.addon.1_passive", rarityName) or L["hoa.addon.passive"])
            else
                card.level:SetText(rarityName and L("hoa.addon.1_spell", rarityName) or L["hoa.addon.spell"])
            end
            if option.kind == "ley" or option.kind == "e" then
                card.count:SetText("")
            elseif option.kind == "c" and option.maxLevel > 1 then
                card.count:SetText(L("hoa.addon.1_2_copies", option.newLevel, option.maxLevel))
            elseif option.kind == "c" and option.newLevel > 1 then
                card.count:SetText(L("hoa.addon.1_copies", option.newLevel))
            elseif option.maxLevel > 1 then
                card.count:SetText(L("hoa.addon.rank_1_2_2", option.newLevel, option.maxLevel))
            elseif option.newLevel > 1 then
                card.count:SetText(L("hoa.addon.rank_1", option.newLevel))
            else
                card.count:SetText("")
            end
            card.line:SetBackdropBorderColor(card.lineColor[1], card.lineColor[2], card.lineColor[3], card.lineColor[4])
            card.borderColor = color and { color.r, color.g, color.b } or { 1, 1, 1 }
            card:SetBackdropBorderColor(card.borderColor[1], card.borderColor[2], card.borderColor[3])
            card:FitCard(option, width, hasLock)
            if hasLock then
                card.lock:SetText(option.locked and L["hoa.addon.locked"] or L["hoa.addon.lock"])
                card.lock:Show()
            else
                card.lock:Hide()
            end
            card:Show()
        else
            card.pop = nil
            card.look = nil
            card:Hide()
        end
    end

    local grow = Offer:GrowCardsToFit(width, hasLock)
    local canBanish = (VB.banishes or 0) > 0 and VB.offerSource ~= "ley"

    local buttons = {}
    if (VB.rerolls or 0) > 0 then
        offerFrame.reroll:SetText(L("hoa.addon.reroll_1", VB.rerolls))
        tinsert(buttons, offerFrame.reroll)
    else
        offerFrame.reroll:Hide()
    end
    if canBanish then
        tinsert(buttons, offerFrame.banish)
    else
        offerFrame.banish:Hide()
    end
    if (VB.skips or 0) > 0 then
        offerFrame.skip:SetText(L("hoa.addon.skip_1", VB.skips))
        tinsert(buttons, offerFrame.skip)
    else
        offerFrame.skip:Hide()
    end
    local total = getn(buttons) * 120 + (getn(buttons) - 1) * 12
    local sideEdge = (count * width + (count - 1) * gap) * offerFrame.SIDE_SCALE / 2 + 8
    local leftY, rightY = offerFrame.SIDE_BOTTOM, offerFrame.SIDE_BOTTOM
    for index, button in ipairs(buttons) do
        button:ClearAllPoints()
        if not offerFrame.side then
            button:SetPoint("CENTER", offerFrame, "CENTER", -total / 2 + 60 + (index - 1) * 132, -170 - grow)
        elseif button == offerFrame.skip then
            button:SetPoint("BOTTOMLEFT", UIParent, "BOTTOM", sideEdge, rightY)
            rightY = rightY + offerFrame.SIDE_BUTTON_STEP
        else
            button:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOM", -sideEdge, leftY)
            leftY = leftY + offerFrame.SIDE_BUTTON_STEP
        end
        button:Show()
    end

    VB.picking = false
    VB.pickedIndex = nil
    Offer:SetBanishMode(false)
    if fresh then
        CollectGarbageIfDue()
        PlaySound("LEVELUP")
        Offer.open = true
        Offer:TakeChoiceKeys()
        Offer.anim = { mode = "open", t = 0, dimFrom = offerFrame.dimAlpha or 0 }
        offerFrame.chrome:SetAlpha(0)
        offerFrame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * (offerFrame.dimAlpha or 0))
    end
    offerFrame:Show()
end

function Offer:AnimateOffer(frame, elapsed)
    local anim = self.anim
    anim.t = anim.t + elapsed
    local t = anim.t

    if anim.mode == "close" then
        local e = Progress(t, 0, OFFER_CLOSE)
        if not self.deferred then
            frame.dimAlpha = anim.dimFrom * (1 - e)
            frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        end
        frame.chrome:SetAlpha(anim.chromeFrom * (1 - e))
        for _, card in ipairs(self.cards) do
            if card:IsShown() then
                if card.index == VB.pickedIndex then
                    card:Place(1 + 0.08 * EaseOut(e), card.closeFrom * (1 - e), 6 * e)
                else
                    card:Place(1 - 0.06 * e, card.closeFrom * max(0, 1 - e * 1.5), -12 * e)
                end
            end
        end
        if e >= 1 then
            self.anim = nil
            local deferred = self.deferred
            self.deferred = nil
            if deferred then
                Offer:ShowOffer(deferred.level)
            else
                frame:Hide()
            end
        end
        return
    end

    local busy = false
    if anim.mode == "open" then
        frame.dimAlpha = anim.dimFrom + (1 - anim.dimFrom) * EaseOut(Progress(t, 0, 0.2))
        frame.dim:SetVertexColor(0, 0, 0, OFFER_DIM * frame.dimAlpha)
        local header = EaseOut(Progress(t, 0.04, 0.26))
        frame.chrome:SetAlpha(header)
        frame.title:SetPoint("CENTER", frame, "CENTER", 0, 230 + 16 * (1 - header))
        busy = header < 1
    end
    for _, card in ipairs(self.cards) do
        if card.pop then
            local p = Progress(t, card.pop, OFFER_POP)
            card:Place(0.8 + 0.2 * EaseBack(p), min(1, p * 2), -24 * (1 - EaseOut(p)))
            if p >= 1 then
                card.pop = nil
                card:RebuildKeywordLinks()
            else
                busy = true
            end
        end
    end
    if not busy then
        self.anim = nil
    end
end

offerFrame:SetScript("OnUpdate", function()
    if Offer.anim then
        Offer:AnimateOffer(this, arg1)
    end
end)

offerFrame:SetScript("OnShow", function()
    if Offer.open then
        Offer:TakeChoiceKeys()
    end
    for _, card in ipairs(Offer.cards) do
        if card:IsShown() and not card.pop then
            card:RebuildKeywordLinks()
        end
    end
end)

offerFrame:SetScript("OnHide", function()
    Offer:GiveBackChoiceKeys()
    if this:IsShown() then
        return
    end
    Offer:SetBanishMode(false)
    Offer.anim = nil
    Offer.open = false
    Offer.deferred = nil
    this.dimAlpha = 0
end)

function Offer:CloseOffer()
    if not offerFrame:IsShown() or not Offer.open then
        return
    end
    Offer:GiveBackChoiceKeys()
    Offer:SetBanishMode(false)
    offerFrame:EnableMouse(false)
    Offer.open = false
    Offer.anim = { mode = "close", t = 0, dimFrom = offerFrame.dimAlpha or 1, chromeFrom = offerFrame.chrome:GetAlpha() }
    for _, card in ipairs(Offer.cards) do
        card.pop = nil
        card.closeFrom = card.alphaNow or 1
    end
end

local Results = UI.Module("results")
Results.frame = CreateFrame("Frame", "VanillaBonkResults", UIParent)
local results = Results.frame
results:SetWidth(360)
results:SetHeight(210)
results:SetPoint("CENTER", UIParent, "CENTER", 0, 100)
results:SetFrameStrata("DIALOG")
DialogBackdrop(results)
results:Hide()

results.title = results:CreateFontString(nil, "OVERLAY")
SetFont(results.title, 26)
results.title:SetPoint("TOP", results, "TOP", 0, -24)

results.body = results:CreateFontString(nil, "OVERLAY")
SetFont(results.body, 13, "")
results.body:SetPoint("TOP", results.title, "BOTTOM", 0, -14)
results.body:SetJustifyH("CENTER")

results.close = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, results, "UIPanelButtonTemplate"))
results.close:SetWidth(100)
results.close:SetHeight(22)
results.close:SetPoint("BOTTOM", results, "BOTTOM", 0, 18)
results.close:SetText(L["hoa.addon.close"])
results.close:SetScript("OnClick", function()
    results:Hide()
end)




function Offer:ApplyOffer(f)
    VB.offer = {}
    VB.offerLevel = f[2]
    VB.offerSource = f[4]
    VB.rerolls = tonumber(f[5]) or 0
    VB.banishes = tonumber(f[6]) or 0
    VB.skips = tonumber(f[7]) or 0
end

function Offer:ApplyOption(f)
    local description = gsub(f[8] or "", "|n", "\n")
    if f[3] == "c" then
        description = gsub(description, "%s*You hold %d+%.?$", "")
    end
    VB.offer[tonumber(f[2])] = {
        kind = f[3],
        newLevel = tonumber(f[4]) or 1,
        maxLevel = tonumber(f[5]) or 0,
        name = f[6],
        icon = f[7],
        description = description,
        rarity = tonumber(f[9] or ""),
        locked = f[10] == "1",
        damageBefore = f[11] or "",
        damageAfter = f[12] or "",
        damageLabel = f[13] or "",
        banishable = f[14] ~= "0",
        stats = {},
    }
end

function Offer:ApplyStat(f)
    local option = VB.offer[tonumber(f[2])]
    if option then
        tinsert(option.stats, { label = f[3] or "", before = f[4] or "", after = f[5] or "" })
    end
end

function Offer:EndOffer()
    Offer:ShowOffer(VB.offerLevel)
end

function Offer:Picked()
    VB.offer = {}
    Offer:CloseOffer()
end

function Offer:LeyOffer()
    VB.offer = {}
    VB.offerLevel = nil
    VB.offerSource = "ley"
    VB.rerolls, VB.banishes, VB.skips = 0, 0, 0
end

function Offer:ApplyLeyOption(f)
    local index = tonumber(f[2] or "")
    if not index then
        return
    end
    local card = f[7] == "c"
    VB.offer[index] = {
        kind = card and "c" or "ley",
        newLevel = card and tonumber(f[8] or "") or 1,
        maxLevel = card and tonumber(f[9] or "") or 0,
        name = f[3] or "",
        icon = f[4] or "",
        description = card and gsub(f[5] or "", "%s*You hold %d+%.?$", "") or (f[5] or ""),
        rarity = tonumber(f[6] or ""),
    }
end

function Offer:EndLeyOffer()
    Offer:ShowOffer(nil)
end

function Offer:CloseLeyOffer()
    VB.offer = {}
    Offer:CloseOffer()
end


handlers["offer"] = function(f) Offer:ApplyOffer(f) end
handlers["opt"] = function(f) Offer:ApplyOption(f) end
handlers["ostat"] = function(f) Offer:ApplyStat(f) end
handlers["offerend"] = function() Offer:EndOffer() end
handlers["picked"] = function() Offer:Picked() end
handlers["leyoffer"] = function() Offer:LeyOffer() end
handlers["leyopt"] = function(f) Offer:ApplyLeyOption(f) end
handlers["leyofferend"] = function() Offer:EndLeyOffer() end
handlers["leyofferclose"] = function() Offer:CloseLeyOffer() end

VB.offerFrame = Offer.frame
VB.results = results
VB.ShowOffer = function(level) Offer:ShowOffer(level) end
VB.CloseOffer = function() Offer:CloseOffer() end
