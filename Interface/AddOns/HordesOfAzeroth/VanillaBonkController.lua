VanillaBonkController = { kind = nil, focus = 1, window = nil }

local Controller = VanillaBonkController
local DEFAULTS = { yawSpeed = 1, pitchSpeed = 1, invertPitch = false, deadzone = 0.24, cursorSpeed = 1, prompts = "auto", interactPrompts = true }
local DLL_OPTIONS = { yawSpeed = true, pitchSpeed = true, invertPitch = true, deadzone = true, cursorSpeed = true }
local OBJECT_REACH = { [900031] = 8 }

function Controller.Setting(key)
    local saved = VanillaBonkControllerSettings
    if saved and saved[key] ~= nil then
        return saved[key]
    end
    return DEFAULTS[key]
end

local function PushOption(key)
    if DLL_OPTIONS[key] and HoAController_SetOption then
        HoAController_SetOption(key, Controller.Setting(key))
    end
end

function Controller.SetSetting(key, value)
    VanillaBonkControllerSettings = VanillaBonkControllerSettings or {}
    VanillaBonkControllerSettings[key] = value
    PushOption(key)
    Controller.restyled = true
end

local ACTION_BUTTONS = { dash = "rt", shapeshift = "lb", hearth = "rb", interact = "x", character = "y", map = "view" }
Controller.REBINDABLE = { rt = true, lb = true, rb = true, x = true, y = true, view = true, l3 = true, up = true, down = true, left = true, right = true }
Controller.bindingsVersion = 0

function Controller.ButtonFor(action)
    local buttons = Controller.Setting("buttons")
    return buttons and buttons[action] or ACTION_BUTTONS[action]
end

function Controller.ActionFor(button)
    for action in pairs(ACTION_BUTTONS) do
        if Controller.ButtonFor(action) == button then
            return action
        end
    end
end

function Controller.BindButton(action, button)
    local buttons = {}
    for each in pairs(ACTION_BUTTONS) do
        buttons[each] = Controller.ButtonFor(each)
    end
    local displaced = Controller.ActionFor(button)
    if displaced and displaced ~= action then
        buttons[displaced] = buttons[action]
    end
    buttons[action] = button
    Controller.SetSetting("buttons", buttons)
    Controller.bindingsVersion = Controller.bindingsVersion + 1
    if VanillaBonkUI.RefreshHearthKey then
        VanillaBonkUI.RefreshHearthKey()
    end
end

function Controller.PadSignature()
    return Controller.Style() .. Controller.bindingsVersion
end

function Controller.ResetSettings()
    VanillaBonkControllerSettings = {}
    Controller.bindingsVersion = Controller.bindingsVersion + 1
    for key in pairs(DLL_OPTIONS) do
        PushOption(key)
    end
    Controller.restyled = true
end

function Controller.Style()
    local forced = Controller.Setting("prompts")
    if forced == "xbox" or forced == "ps" or forced == "deck" then
        return forced
    end
    return Controller.kind or (HoAController_GetConnected and HoAController_GetConnected()) or "xbox"
end
local NEXT = { right = 1, down = 1, left = -1, up = -1 }

local GLOW_TEXTURE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\FocusGlow"
local GLOW_SLICE = 40 / 128
local GLOW_LINE_SHARE = 32 / 40

local function GlowPiece(frame, left, right, top, bottom)
    local piece = frame:CreateTexture(nil, "OVERLAY")
    piece:SetTexture(GLOW_TEXTURE)
    piece:SetTexCoord(left, right, top, bottom)
    piece:SetBlendMode("ADD")
    piece:SetVertexColor(1, 0.8, 0.2)
    return piece
end

local function AddGlowLayer(frame, corner)
    local a, b = GLOW_SLICE, 1 - GLOW_SLICE
    local tl = GlowPiece(frame, 0, a, 0, a)
    local tr = GlowPiece(frame, b, 1, 0, a)
    local bl = GlowPiece(frame, 0, a, b, 1)
    local br = GlowPiece(frame, b, 1, b, 1)
    for _, piece in ipairs({ tl, tr, bl, br }) do
        piece:SetWidth(corner)
        piece:SetHeight(corner)
    end
    tl:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    tr:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    bl:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", 0, 0)
    br:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 0, 0)
    local top = GlowPiece(frame, a, b, 0, a)
    top:SetPoint("TOPLEFT", tl, "TOPRIGHT", 0, 0)
    top:SetPoint("BOTTOMRIGHT", tr, "BOTTOMLEFT", 0, 0)
    local bottom = GlowPiece(frame, a, b, b, 1)
    bottom:SetPoint("TOPLEFT", bl, "TOPRIGHT", 0, 0)
    bottom:SetPoint("BOTTOMRIGHT", br, "BOTTOMLEFT", 0, 0)
    local left = GlowPiece(frame, 0, a, a, b)
    left:SetPoint("TOPLEFT", tl, "BOTTOMLEFT", 0, 0)
    left:SetPoint("BOTTOMRIGHT", bl, "TOPRIGHT", 0, 0)
    local right = GlowPiece(frame, b, 1, a, b)
    right:SetPoint("TOPLEFT", tr, "BOTTOMLEFT", 0, 0)
    right:SetPoint("BOTTOMRIGHT", br, "TOPRIGHT", 0, 0)
    for _, piece in ipairs({ tl, tr, bl, br, top, bottom, left, right }) do
        table.insert(frame.pieces, piece)
    end
end

local function MakeGlow(corner, strength)
    local frame = CreateFrame("Frame", nil, UIParent)
    frame.pieces = {}
    frame.strength = strength or 1
    AddGlowLayer(frame, corner)
    frame.outset = corner * GLOW_LINE_SHARE
    frame:SetScript("OnUpdate", function()
        this:SetAlpha(this.strength * (0.8 + 0.2 * math.sin(GetTime() * 6)))
    end)
    frame:Hide()
    return frame
end

local function TintGlow(glow, r, g, b)
    for _, piece in ipairs(glow.pieces) do
        piece:SetVertexColor(r, g, b)
    end
end

local function AttachGlow(glow, target)
    glow:SetParent(target)
    glow:ClearAllPoints()
    glow:SetPoint("TOPLEFT", target, "TOPLEFT", -glow.outset, glow.outset)
    glow:SetPoint("BOTTOMRIGHT", target, "BOTTOMRIGHT", glow.outset, -glow.outset)
    glow:SetFrameLevel(target:GetFrameLevel() + 8)
    glow:Show()
end

local focusGlow = MakeGlow(40)

local function RunScript(frame, name)
    local script = frame:GetScript(name)
    if not script then
        return
    end
    local saved = this
    this = frame
    script()
    this = saved
end

local function Unfocus()
    local card = focusGlow.card
    focusGlow.card = nil
    focusGlow:Hide()
    if not card then
        return
    end
    if card.UnlockHighlight then
        card:UnlockHighlight()
    end
    RunScript(card, "OnLeave")
end

local function Focus(card)
    if focusGlow.card == card and focusGlow:IsShown() and focusGlow.banishing == (VanillaBonkOffer and VanillaBonkOffer.banishing) then
        return
    end
    Unfocus()
    focusGlow.banishing = VanillaBonkOffer and VanillaBonkOffer.banishing
    focusGlow.card = card
    if VanillaBonkOffer and VanillaBonkOffer.banishing then
        TintGlow(focusGlow, 1, 0.25, 0.15)
    else
        TintGlow(focusGlow, 1, 0.8, 0.2)
    end
    AttachGlow(focusGlow, card)
    if card.LockHighlight then
        card:LockHighlight()
    end
    RunScript(card, "OnEnter")
end

local function ChoiceWindow()
    if VanillaBonkGlyphs and VanillaBonkGlyphs.open then
        return VanillaBonkGlyphs
    end
    if VanillaBonkOffer and VanillaBonkOffer.open then
        return VanillaBonkOffer
    end
end

local function CardCount(window)
    local count = 0
    for _, card in ipairs(window.cards) do
        if card:IsShown() then
            count = count + 1
        end
    end
    return count
end

local function ShowFocus(window)
    local card = window and window.cards[Controller.focus]
    if not card or not card:IsShown() or not Controller.kind then
        Unfocus()
        return
    end
    Focus(card)
end

local function MoveFocus(window, step)
    local count = CardCount(window)
    if count == 0 then
        return
    end
    Controller.focus = math.mod(Controller.focus - 1 + step + count, count) + 1
    ShowFocus(window)
end

local function ChoiceButton(window, name)
    if NEXT[name] then
        MoveFocus(window, NEXT[name])
    elseif name == "a" then
        VanillaBonk_ChoiceKey(tostring(Controller.focus))
    elseif window == VanillaBonkOffer and name == "x" then
        VanillaBonk_ChoiceKey("R")
    elseif window == VanillaBonkOffer and name == "y" then
        VanillaBonk_ChoiceKey("B")
    elseif window == VanillaBonkOffer and name == "b" then
        VanillaBonk_ChoiceKey("X")
    end
end

local function Dash()
    local saved = keystate
    keystate = "down"
    VanillaBonk_Dash()
    keystate = saved
end

local function CloseOrClear()
    if CloseAllWindows() then
        return
    end
    if UnitExists("target") then
        ClearTarget()
    end
end

local function Shapeshift()
    local saved = keystate
    keystate = "down"
    VanillaBonk_Shapeshift()
    keystate = saved
end

local function Interact()
    if HoAController_Interact then
        HoAController_Interact()
    end
end

local function ToggleCharacterAndBags()
    if CharacterFrame:IsVisible() or (VanillaBonkBags and VanillaBonkBags:IsVisible()) then
        HideUIPanel(CharacterFrame)
        CloseAllBags()
        return
    end
    ToggleCharacter("PaperDollFrame")
    OpenAllBags(true)
end

Controller.ToggleCharacterAndBags = ToggleCharacterAndBags

local PLAY_ACTIONS = {
    dash = Dash,
    shapeshift = Shapeshift,
    hearth = function() VanillaBonk_UseHearthstone() end,
    interact = Interact,
    character = ToggleCharacterAndBags,
    map = function() ToggleWorldMap() end,
}

local PLAY = {
    menu = function() ToggleGameMenu() end,
    b = CloseOrClear,
}

local ZOOM_DPAD = { up = true, down = true }

local function PlayAction(name)
    if Controller.inspectHeld and ZOOM_DPAD[name] then
        return nil
    end
    return PLAY[name] or PLAY_ACTIONS[Controller.ActionFor(name) or ""]
end

local GLYPH_FILE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ControllerGlyphs"
local GLYPH_GRID = 8
local GLYPH_CELLS = {
    xbox = {
        a = { 0, 0 }, b = { 1, 0 }, x = { 2, 0 }, y = { 3, 0 }, lb = { 4, 0 }, rb = { 5, 0 }, lt = { 6, 0 }, rt = { 7, 0 },
        view = { 0, 2 }, menu = { 1, 2 }, ls = { 2, 2 }, rs = { 3, 2 }, l3 = { 4, 2 }, r3 = { 5, 2 }, home = { 6, 2 },
    },
    ps = {
        a = { 0, 1 }, b = { 1, 1 }, x = { 2, 1 }, y = { 3, 1 }, lb = { 4, 1 }, rb = { 5, 1 }, lt = { 6, 1 }, rt = { 7, 1 },
        view = { 0, 3 }, menu = { 1, 3 }, ls = { 2, 3 }, rs = { 3, 3 }, l3 = { 4, 3 }, r3 = { 5, 3 }, home = { 6, 3 },
    },
    deck = {
        a = { 0, 5 }, b = { 1, 5 }, x = { 2, 5 }, y = { 3, 5 }, lb = { 4, 5 }, rb = { 5, 5 }, lt = { 6, 5 }, rt = { 7, 5 },
        view = { 0, 6 }, menu = { 1, 6 }, ls = { 2, 6 }, rs = { 3, 6 }, l3 = { 4, 6 }, r3 = { 5, 6 }, home = { 6, 6 },
    },
    any = {
        dpad = { 0, 4 }, up = { 1, 4 }, down = { 2, 4 }, left = { 3, 4 }, right = { 4, 4 }, updown = { 5, 4 }, leftright = { 6, 4 },
    },
}
local PROMPT_GLYPH = 24
local PROMPT_LABEL_GAP = 5
local PROMPT_GAP = 14
local PROMPT_FONT_SIZE = 12
local PROMPT_SHADE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\CornerShade"
local PROMPT_SHADE_MIN_WIDTH = 460
local PROMPT_SHADE_EXTRA = 160
local PROMPT_SHADE_HEIGHT = 120
local PROMPT_RIGHT = 10
local PROMPT_BOTTOM = 5
local PROMPT_HEIGHT = 34
local BAND_SHADE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\PromptShade"
local BAND_PAD_X = 64
local BAND_PAD_Y = 6
local OFFER_BUTTON_ROW_Y = -170

function Controller.SetGlyph(texture, name)
    local cell = (GLYPH_CELLS[Controller.Style()] or GLYPH_CELLS.xbox)[name] or GLYPH_CELLS.any[name]
    if not cell then
        texture:Hide()
        return false
    end
    texture:SetTexture(GLYPH_FILE)
    texture:SetTexCoord(cell[1] / GLYPH_GRID, (cell[1] + 1) / GLYPH_GRID, cell[2] / GLYPH_GRID, (cell[2] + 1) / GLYPH_GRID)
    texture:Show()
    return true
end

function Controller.ShowKey(text, glyph, button, keyText)
    if Controller.kind and Controller.SetGlyph(glyph, button) then
        text:SetText("")
        return
    end
    glyph:Hide()
    text:SetText(keyText)
end

local function MakePromptRow(strata)
    local row = CreateFrame("Frame", nil, UIParent)
    row:SetHeight(PROMPT_HEIGHT)
    row:SetFrameStrata(strata)
    row.slots = {}
    row.shade = row:CreateTexture(nil, "BACKGROUND")
    row:Hide()
    return row
end

local cornerRow = MakePromptRow("FULLSCREEN_DIALOG")
cornerRow:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", -PROMPT_RIGHT, PROMPT_BOTTOM)
cornerRow.shade:SetTexture(PROMPT_SHADE)
cornerRow.shade:SetHeight(PROMPT_SHADE_HEIGHT)
cornerRow.shade:SetPoint("BOTTOMRIGHT", UIParent, "BOTTOMRIGHT", 0, 0)

local centerRow = MakePromptRow("FULLSCREEN")
centerRow.shade:SetTexture(BAND_SHADE)
centerRow.shade:SetPoint("TOPLEFT", centerRow, "TOPLEFT", -BAND_PAD_X, BAND_PAD_Y)
centerRow.shade:SetPoint("BOTTOMRIGHT", centerRow, "BOTTOMRIGHT", BAND_PAD_X, -BAND_PAD_Y)

local function PromptSlot(row, index)
    local slot = row.slots[index]
    if slot then
        return slot
    end
    slot = {}
    slot.glyph = row:CreateTexture(nil, "ARTWORK")
    slot.glyph:SetWidth(PROMPT_GLYPH)
    slot.glyph:SetHeight(PROMPT_GLYPH)
    slot.label = VanillaBonkUI.Text(row, PROMPT_FONT_SIZE)
    row.slots[index] = slot
    return slot
end

local function PromptSignature(prompts)
    local signature = Controller.Style()
    for _, prompt in ipairs(prompts) do
        signature = signature .. "|" .. prompt[1] .. "=" .. prompt[2] .. (prompt[3] and "~" or "")
    end
    return signature
end

local function FillRow(row, prompts)
    local signature = PromptSignature(prompts)
    if row.signature == signature and row:IsShown() and not Controller.restyled then
        return false
    end
    row.signature = signature
    local x = 0
    for index, prompt in ipairs(prompts) do
        local slot = PromptSlot(row, index)
        Controller.SetGlyph(slot.glyph, prompt[1])
        slot.glyph:ClearAllPoints()
        slot.glyph:SetPoint("LEFT", row, "LEFT", x, 0)
        slot.label:SetText(prompt[2])
        slot.label:ClearAllPoints()
        slot.label:SetPoint("LEFT", slot.glyph, "RIGHT", PROMPT_LABEL_GAP, 0)
        slot.label:Show()
        if prompt[3] then
            slot.glyph:SetAlpha(0.4)
            slot.label:SetTextColor(0.5, 0.5, 0.5)
        else
            slot.glyph:SetAlpha(1)
            slot.label:SetTextColor(1, 1, 1)
        end
        x = x + PROMPT_GLYPH + PROMPT_LABEL_GAP + slot.label:GetStringWidth() + PROMPT_GAP
    end
    for index = table.getn(prompts) + 1, table.getn(row.slots) do
        row.slots[index].glyph:Hide()
        row.slots[index].label:Hide()
    end
    row:SetWidth(math.max(1, x - PROMPT_GAP))
    row:Show()
    return true
end

function Controller.HidePrompts()
    cornerRow.signature = nil
    cornerRow:Hide()
    centerRow.signature = nil
    centerRow:Hide()
end

function Controller.PromptsVisible()
    return cornerRow:IsShown() or centerRow:IsShown()
end

function Controller.ShowPrompts(prompts)
    centerRow:Hide()
    if FillRow(cornerRow, prompts) then
        cornerRow.shade:SetWidth(math.max(PROMPT_SHADE_MIN_WIDTH, cornerRow:GetWidth() + PROMPT_SHADE_EXTRA))
    end
end

function Controller.ShowCenterPrompts(relative, x, y, prompts)
    cornerRow:Hide()
    if centerRow.relative ~= relative or centerRow.x ~= x or centerRow.y ~= y then
        centerRow.relative, centerRow.x, centerRow.y = relative, x, y
        centerRow:ClearAllPoints()
        centerRow:SetPoint("CENTER", relative, "BOTTOMLEFT", x, y)
    end
    FillRow(centerRow, prompts)
end

local function ButtonPrompt(prompts, glyph, button)
    if button and button:IsShown() and button:IsEnabled() == 1 then
        table.insert(prompts, { glyph, button:GetText() or "" })
    end
end

local INSPECT_TIPS = 4
local INSPECT_GAP = 6
local inspectTips = {}

local function KeywordHovers(card)
    local hovers = {}
    for _, hover in ipairs(card.hovers or {}) do
        table.insert(hovers, hover)
    end
    for _, block in ipairs(card.stats or {}) do
        if block.hover then
            table.insert(hovers, block.hover)
        end
    end
    local shown = {}
    for _, hover in ipairs(hovers) do
        if hover:IsVisible() and VanillaBonkUI.HasKeywordTip(hover.keyword) then
            table.insert(shown, hover)
        end
    end
    return shown
end

local function CardKeywords(card)
    local ids, seen = {}, {}
    for _, hover in ipairs(KeywordHovers(card)) do
        if not seen[hover.keyword] then
            seen[hover.keyword] = true
            table.insert(ids, hover.keyword)
        end
    end
    return ids
end

local function InspectTip(index)
    if not inspectTips[index] then
        inspectTips[index] = CreateFrame("GameTooltip", "VanillaBonkInspectTip" .. index, UIParent, "GameTooltipTemplate")
    end
    return inspectTips[index]
end

local function MarkHover(hover, on)
    if on and not hover.inspectMark then
        hover.inspectMark = hover:CreateTexture(nil, "OVERLAY")
        hover.inspectMark:SetTexture(VanillaBonkUI.FLAT)
        hover.inspectMark:SetBlendMode("ADD")
        hover.inspectMark:SetAllPoints(hover)
    end
    if hover.inspectMark then
        if on then
            hover.inspectMark:SetVertexColor(1, 0.82, 0.2, 0.3)
            hover.inspectMark:Show()
        else
            hover.inspectMark:Hide()
        end
    end
end

local inspected = {}

local function HideInspect()
    for _, tip in ipairs(inspectTips) do
        tip:Hide()
    end
    for _, hover in ipairs(inspected.hovers or {}) do
        MarkHover(hover, false)
    end
    inspected = {}
end

local function ShowInspect(card)
    local ids = CardKeywords(card)
    local signature = table.concat(ids, ",")
    if inspected.card == card and inspected.signature == signature then
        return
    end
    HideInspect()
    inspected = { card = card, signature = signature, hovers = KeywordHovers(card) }
    for _, hover in ipairs(inspected.hovers) do
        MarkHover(hover, true)
    end
    local rightSide = (card:GetCenter() or 0) * card:GetEffectiveScale() < UIParent:GetWidth() * UIParent:GetEffectiveScale() / 2
    local previous
    for index = 1, math.min(INSPECT_TIPS, table.getn(ids)) do
        local tip = InspectTip(index)
        tip:SetOwner(UIParent, "ANCHOR_NONE")
        VanillaBonkUI.FillKeywordTip(tip, ids[index])
        tip:Show()
        tip:ClearAllPoints()
        if previous then
            tip:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -INSPECT_GAP)
        elseif rightSide then
            tip:SetPoint("TOPLEFT", card, "TOPRIGHT", INSPECT_GAP, 0)
        else
            tip:SetPoint("TOPRIGHT", card, "TOPLEFT", -INSPECT_GAP, 0)
        end
        previous = tip
    end
end

local function UpdateInspect(window)
    local card = window and window.cards[Controller.focus]
    if not Controller.inspectHeld or not Controller.kind or not card or not card:IsShown() then
        if inspected.card then
            HideInspect()
        end
        return
    end
    ShowInspect(card)
end

local function AnyCardDetails(window)
    for _, card in ipairs(window.cards) do
        if card:IsShown() and table.getn(CardKeywords(card)) > 0 then
            return true
        end
    end
    return false
end

local function ChoicePrompts(window)
    local prompts = { { "leftright", "Choose" }, { "a", "Pick" } }
    if window == VanillaBonkOffer then
        ButtonPrompt(prompts, "x", window.reroll)
        ButtonPrompt(prompts, "y", window.banish)
        ButtonPrompt(prompts, "b", window.skip)
    end
    if AnyCardDetails(window) then
        local card = window.cards[Controller.focus]
        local hasDetails = card and card:IsShown() and table.getn(CardKeywords(card)) > 0
        table.insert(prompts, { "lt", "Hold for details", not hasDetails })
    end
    return prompts
end

local MOUSE_BUTTONS = {
    { "VanillaBonkOffer", "reroll" }, { "VanillaBonkOffer", "banish" }, { "VanillaBonkOffer", "skip" },
    { "VanillaBonkGear", "equip" }, { "VanillaBonkGear", "equipOther" }, { "VanillaBonkGear", "loot" }, { "VanillaBonkGear", "salvage" },
}

local function MouseButton(entry)
    local owner = getglobal(entry[1])
    return owner and owner[entry[2]]
end

local function KeepMouseButtonsHidden()
    for _, entry in ipairs(MOUSE_BUTTONS) do
        local button = MouseButton(entry)
        if button and button.controllerHidden and button:GetAlpha() > 0 then
            button:SetAlpha(0)
        end
    end
end

local function HookFadingParent(frame)
    if not frame or frame.controllerAlphaHook then
        return
    end
    local setAlpha = frame.SetAlpha
    frame.controllerAlphaHook = true
    frame.SetAlpha = function(self, alpha)
        setAlpha(self, alpha)
        KeepMouseButtonsHidden()
    end
end

HookFadingParent(VanillaBonkOffer)
HookFadingParent(VanillaBonkOffer and VanillaBonkOffer.chrome)
HookFadingParent(VanillaBonkGear)

local function HideMouseButtons(hidden)
    for _, entry in ipairs(MOUSE_BUTTONS) do
        local button = MouseButton(entry)
        if button and button.controllerHidden ~= hidden then
            button.controllerHidden = hidden
            button:SetAlpha(hidden and 0 or 1)
            button:EnableMouse(not hidden)
        end
    end
    KeepMouseButtonsHidden()
end

local hiddenHint = nil

local function RestoreHint()
    if hiddenHint then
        hiddenHint:SetAlpha(1)
        hiddenHint = nil
    end
end

local function UpdatePrompts(window)
    if not window or not Controller.kind or not window.hint then
        RestoreHint()
        Controller.HidePrompts()
        return
    end
    if hiddenHint ~= window.hint then
        RestoreHint()
        hiddenHint = window.hint
        hiddenHint:SetAlpha(0)
    end
    if window == VanillaBonkOffer then
        local x, y = VanillaBonkOffer:GetCenter()
        Controller.ShowCenterPrompts(UIParent, x or 0, (y or 0) + OFFER_BUTTON_ROW_Y, ChoicePrompts(window))
    else
        local x, y = window.hint:GetCenter()
        Controller.ShowCenterPrompts(UIParent, x or 0, y or 0, ChoicePrompts(window))
    end
end

local NAV_DIRECTIONS = { up = { 0, 1 }, down = { 0, -1 }, left = { -1, 0 }, right = { 1, 0 } }
local NAV_ACROSS_WEIGHT = 2.5
local NAV_MIN_SIZE = 10
local POPUP_COUNT = 4
local EXTRA_WINDOWS = { "VanillaBonkGear", "VanillaBonkMenu", "VanillaBonkVendor", "GameMenuFrame" }
local KEEP_OPEN = { VanillaBonkGear = true }
local SKIPPED_WINDOWS = { VanillaBonkBanishEscape = true, VanillaBonkVendorEscape = true, VanillaBonkOffer = true, VanillaBonkGlyphs = true, VanillaBonkMap = true }

local navGlow = MakeGlow(22, 0.65)

local function IsSlider(frame)
    return frame:GetObjectType() == "Slider"
end

local TAB_STRIPS = { MerchantFrame = "VanillaBonkGearTab" }

local function IsWindowTab(button)
    local name = button:GetName()
    if not name or not string.find(name, "Tab%d+$") then
        return false
    end
    for _, prefix in pairs(TAB_STRIPS) do
        if string.find(name, "^" .. prefix .. "%d+$") then
            return true
        end
    end
    local owner = getglobal((string.gsub(name, "Tab%d+$", "")))
    return owner ~= nil and owner.numTabs ~= nil and owner.numTabs > 1
end

local function IsUsable(button)
    if not button:IsVisible() or button:GetWidth() < NAV_MIN_SIZE or button:GetHeight() < NAV_MIN_SIZE then
        return false
    end
    if button:GetAlpha() < 0.05 then
        return false
    end
    if button.IsMouseEnabled and not button:IsMouseEnabled() then
        return false
    end
    if IsWindowTab(button) then
        return false
    end
    local name = button:GetName()
    if name and string.find(name, "ScrollBar") then
        return false
    end
    if IsSlider(button) then
        return button:GetScript("OnValueChanged") ~= nil or (name ~= nil and string.find(name, "^OptionsFrameSlider%d+$") ~= nil)
    end
    if name and string.find(name, "%u%l+Button$") and string.find(name, "Money") then
        return false
    end
    if button.IsEnabled and button:IsEnabled() ~= 1 then
        return false
    end
    if not button:GetScript("OnClick") and not button.navTooltip then
        return false
    end
    local normal = button.GetNormalTexture and button:GetNormalTexture()
    local texture = normal and normal:GetTexture()
    return not (texture and string.find(texture, "MinimizeButton"))
end

local function Collect(frame, out)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsVisible() then
            local kind = child:GetObjectType()
            if (kind == "Button" or kind == "CheckButton" or kind == "Slider") and IsUsable(child) then
                table.insert(out, child)
            end
            Collect(child, out)
        end
    end
    return out
end

local function HasFocusable(frame)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsVisible() then
            local kind = child:GetObjectType()
            if ((kind == "Button" or kind == "CheckButton" or kind == "Slider") and IsUsable(child)) or HasFocusable(child) then
                return true
            end
        end
    end
    return false
end

local function CanScroll(frame)
    if frame.GetVerticalScrollRange and frame:GetVerticalScrollRange() > 0 then
        return true
    end
    local name = frame:GetName()
    local bar = name and getglobal(name .. "ScrollBar")
    return bar ~= nil and bar:IsVisible() == 1
end

local function FindWheel(frame)
    local children = { frame:GetChildren() }
    for _, child in ipairs(children) do
        if child:IsVisible() then
            if child:GetScript("OnMouseWheel") and CanScroll(child) then
                return child
            end
            local found = FindWheel(child)
            if found then
                return found
            end
        end
    end
end

local function TabList(window)
    local name = window:GetName()
    if not name then
        return nil
    end
    local strip = TAB_STRIPS[name]
    local prefix = strip or (window.numTabs and window.numTabs > 1 and name .. "Tab")
    if not prefix then
        return nil
    end
    local tabs, selected = {}, nil
    local index = 1
    local tab = getglobal(prefix .. index)
    while tab and (strip or index <= window.numTabs) do
        if tab:IsVisible() then
            table.insert(tabs, tab)
            local current
            if strip then
                current = tab.IsEnabled and tab:IsEnabled() ~= 1
            else
                current = window.selectedTab == index
            end
            if current then
                selected = table.getn(tabs)
            end
        end
        index = index + 1
        tab = getglobal(prefix .. index)
    end
    if table.getn(tabs) < 2 then
        return nil
    end
    return tabs, selected or 1
end

local function HasTabs(window)
    return TabList(window) ~= nil
end

local function AddWindow(list, seen, frame)
    if not frame or seen[frame] or not frame:IsVisible() or frame:GetAlpha() < 0.05 then
        return
    end
    local name = frame:GetName()
    if name and SKIPPED_WINDOWS[name] then
        return
    end
    seen[frame] = true
    if HasFocusable(frame) or HasTabs(frame) or FindWheel(frame) then
        table.insert(list, frame)
    end
end

local DROPDOWN_LEVELS = 3

local function OpenDropdownLists()
    local lists = {}
    for level = DROPDOWN_LEVELS, 1, -1 do
        local list = getglobal("DropDownList" .. level)
        if list and list:IsVisible() then
            table.insert(lists, list)
        end
    end
    return lists
end

local function OpenWindows()
    local list, seen = {}, {}
    for index = 1, POPUP_COUNT do
        AddWindow(list, seen, getglobal("StaticPopup" .. index))
    end
    if table.getn(list) > 0 then
        return list
    end
    for _, dropdown in ipairs(OpenDropdownLists()) do
        AddWindow(list, seen, dropdown)
    end
    if table.getn(list) > 0 then
        return list
    end
    for _, name in ipairs(EXTRA_WINDOWS) do
        AddWindow(list, seen, getglobal(name))
    end
    for _, name in ipairs(UISpecialFrames) do
        AddWindow(list, seen, getglobal(name))
    end
    if UIPanelWindows then
        for name in pairs(UIPanelWindows) do
            AddWindow(list, seen, getglobal(name))
        end
    end
    table.sort(list, function(a, b)
        return (a:GetLeft() or 0) < (b:GetLeft() or 0)
    end)
    return list
end

local function Center(frame)
    local x, y = frame:GetCenter()
    local scale = frame:GetEffectiveScale()
    return (x or 0) * scale, (y or 0) * scale
end

local function WindowOf(button, windows)
    for _, window in ipairs(windows) do
        local frame = button
        while frame do
            if frame == window then
                return window
            end
            frame = frame:GetParent()
        end
    end
end

local function InventorySlot(button)
    local name = button:GetName()
    if not name or not string.find(name, "^Character.+Slot$") then
        return nil
    end
    return button:GetID()
end

local function ContainerSlot(button)
    local parent = button:GetParent()
    local name = button:GetName()
    if not parent or not name or not getglobal(name .. "IconTexture") or InventorySlot(button) then
        return nil
    end
    if not string.find(name, "^VanillaBonkBagsItem%d+_%d+$") and not string.find(name, "^ContainerFrame%d+Item%d+$") then
        return nil
    end
    local bag, slot = parent:GetID(), button:GetID()
    if bag < 0 or bag > 4 or slot < 1 or slot > GetContainerNumSlots(bag) then
        return nil
    end
    return bag, slot
end

local function Unfocused()
    if Controller.grabbed then
        Controller.GrabSlider(nil)
    end
    local button = navGlow.target
    navGlow.target = nil
    navGlow:Hide()
    if button then
        RunScript(button, "OnLeave")
    end
end

function Controller.FocusedButton()
    return navGlow.target
end

local function NavFocus(button)
    if navGlow.target == button and navGlow:IsShown() then
        return
    end
    Unfocused()
    navGlow.target = button
    AttachGlow(navGlow, button)
    RunScript(button, "OnEnter")
end

local function FirstIn(window)
    local primary = window.navButtons and window.navButtons[1]
    if primary and primary:IsVisible() and IsUsable(primary) then
        return primary
    end
    local buttons = Collect(window, {})
    local best, bestScore
    for _, button in ipairs(buttons) do
        local x, y = Center(button)
        local score = -y * 4 + x
        if not best or score < bestScore then
            best, bestScore = button, score
        end
    end
    return best
end

local function Step(direction, windows)
    local current = navGlow.target
    local candidates = {}
    for _, window in ipairs(windows) do
        Collect(window, candidates)
    end
    if not current or not current:IsVisible() then
        return candidates[1] and FirstIn(windows[1])
    end
    local fromX, fromY = Center(current)
    local dx, dy = direction[1], direction[2]
    local best, bestScore
    for _, button in ipairs(candidates) do
        if button ~= current then
            local x, y = Center(button)
            local along = (x - fromX) * dx + (y - fromY) * dy
            if along > 2 then
                local across = math.abs((x - fromX) * dy - (y - fromY) * dx)
                local score = along + across * NAV_ACROSS_WEIGHT
                if not best or score < bestScore then
                    best, bestScore = button, score
                end
            end
        end
    end
    return best or Controller.WrapStep(current, direction, windows, candidates)
end

Controller.WRAP_WINDOWS = { VanillaBonkMenu = true, GameMenuFrame = true }

function Controller.WrapStep(current, direction, windows, candidates)
    local window = WindowOf(current, windows)
    if direction[1] ~= 0 or not window or not Controller.WRAP_WINDOWS[window:GetName() or ""] then
        return nil
    end
    local fromX, fromY = Center(current)
    local best, bestAlong
    for _, button in ipairs(candidates) do
        if button ~= current and WindowOf(button, windows) == window then
            local x, y = Center(button)
            local along = (y - fromY) * direction[2]
            if not best or along < bestAlong then
                best, bestAlong = button, along
            end
        end
    end
    return best
end

local function SwitchWindow(windows, step)
    local current = navGlow.target and WindowOf(navGlow.target, windows)
    local index = 1
    for position, window in ipairs(windows) do
        if window == current then
            index = position
        end
    end
    local count = table.getn(windows)
    local nextWindow = windows[math.mod(index - 1 + step + count, count) + 1]
    return FirstIn(nextWindow)
end

local function Unequip(slot)
    PickupInventoryItem(slot)
    if not CursorHasItem() then
        return
    end
    PutItemInBackpack()
    for bag = 1, 4 do
        if CursorHasItem() then
            PutItemInBag(19 + bag)
        end
    end
    if CursorHasItem() then
        ClearCursor()
    end
end

StaticPopupDialogs["HOA_CONTROLLER_DELETE"] = {
    text = "Delete %s?",
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        local pending = Controller.pendingDelete
        Controller.pendingDelete = nil
        if pending and GetContainerItemLink(pending.bag, pending.slot) == pending.link then
            PickupContainerItem(pending.bag, pending.slot)
            DeleteCursorItem()
        end
    end,
    OnCancel = function()
        Controller.pendingDelete = nil
    end,
    timeout = 0,
    whileDead = 1,
    hideOnEscape = 1,
}

local function AskDelete(bag, slot)
    local link = GetContainerItemLink(bag, slot)
    if not link then
        return
    end
    Controller.pendingDelete = { bag = bag, slot = slot, link = link }
    StaticPopup_Show("HOA_CONTROLLER_DELETE", link)
end

local function CloseWindow(window)
    if not window then
        CloseAllWindows()
        return
    end
    local name = window:GetName() or ""
    if string.find(name, "^StaticPopup") then
        local cancel = getglobal(name .. "Button2")
        if cancel and cancel:IsVisible() then
            cancel:Click()
            return
        end
    end
    if UIPanelWindows and UIPanelWindows[name] then
        HideUIPanel(window)
    else
        window:Hide()
    end
end

local function RightClick(button)
    local saved = arg1
    arg1 = "RightButton"
    RunScript(button, "OnClick")
    arg1 = saved
end

local function IsMerchantItem(button)
    if button.buysOnRightClick then
        return true
    end
    local name = button:GetName()
    return name ~= nil and string.find(name, "^MerchantItem%d+ItemButton$") ~= nil
end

local function Activate(button)
    if IsMerchantItem(button) then
        RightClick(button)
        return
    end
    local bag, slot = ContainerSlot(button)
    if bag then
        if GetContainerItemLink(bag, slot) then
            UseContainerItem(bag, slot)
        end
        return
    end
    local inventory = InventorySlot(button)
    if inventory then
        if GetInventoryItemLink("player", inventory) then
            Unequip(inventory)
        end
        return
    end
    button:Click()
end

local promptFocus = { box = nil, index = 1 }

local function ActivePrompt()
    for _, box in ipairs(VanillaBonkUI.navPrompts or {}) do
        local primary = box.navButtons[1]
        if box:IsVisible() and primary and primary:IsVisible() then
            return box
        end
    end
end

local function PromptButton(box)
    if promptFocus.box ~= box then
        promptFocus.box, promptFocus.index = box, 1
    end
    local button = box.navButtons[promptFocus.index]
    if not button or not button:IsVisible() then
        promptFocus.index = 1
        button = box.navButtons[1]
    end
    return button
end

local function PromptPress(box, name)
    if name == "a" then
        Activate(PromptButton(box))
        return true
    end
    if name == "left" or name == "right" then
        local count = table.getn(box.navButtons)
        promptFocus.index = math.mod(promptFocus.index, count) + 1
        return true
    end
    return false
end

local function ShowPromptFocus()
    local box = Controller.kind and ActivePrompt()
    if not box then
        return false
    end
    local button = PromptButton(box)
    NavFocus(button)
    Controller.ShowPrompts({ { "a", button:GetText() or "OK" } })
    return true
end

local function TabWindow(windows, target)
    local window = target and WindowOf(target, windows)
    if window and HasTabs(window) then
        return window
    end
    for _, candidate in ipairs(windows) do
        if HasTabs(candidate) then
            return candidate
        end
    end
end

local function SwitchTab(window, step)
    local tabs, current = TabList(window)
    if not tabs then
        return false
    end
    local count = table.getn(tabs)
    for offset = 1, count - 1 do
        local index = math.mod(current - 1 + step * offset + count * offset, count) + 1
        local tab = tabs[index]
        if not tab.IsEnabled or tab:IsEnabled() == 1 then
            tab:Click()
            return true
        end
    end
    return false
end

local VERB_PARTICLES = { back = true, on = true, off = true, out = true, ["in"] = true }

local function VerbLabel(phrase)
    local label
    for word in string.gfind(phrase, "[%a']+") do
        local lower = string.lower(word)
        if not label then
            label = string.upper(string.sub(word, 1, 1)) .. string.sub(word, 2)
        elseif VERB_PARTICLES[lower] then
            label = label .. " " .. lower
        elseif lower ~= "it" then
            break
        end
    end
    return label
end

local function TooltipLineText(tip, index)
    if tip == GameTooltip then
        local line = getglobal("GameTooltipTextLeft" .. index)
        return line and line:GetText()
    end
    return tip:LineText(index)
end

local function TooltipVerb(button, prefix)
    local tip = VanillaBonkSpellTip
    if not tip:IsOwned(button) then
        tip = GameTooltip
        if not GameTooltip:IsShown() or not GameTooltip:IsOwned(button) then
            return nil
        end
    end
    for index = 1, tip:NumLines() do
        local text = TooltipLineText(tip, index)
        if text then
            text = string.gsub(string.gsub(text, "|c%x%x%x%x%x%x%x%x", ""), "|r", "")
            local _, _, rest = string.find(text, "^" .. prefix .. " to (.+)")
            if rest then
                return VerbLabel(rest)
            end
        end
    end
    return nil
end


local function RefreshTooltip(button)
    if button and button:IsVisible() then
        RunScript(button, "OnEnter")
    end
end

local function NudgeSlider(slider, sign)
    local low, high = slider:GetMinMaxValues()
    local step = slider:GetValueStep()
    if not step or step <= 0 then
        step = (high - low) / 20
    end
    slider:SetValue(math.max(low, math.min(high, slider:GetValue() + sign * step)))
end

function Controller.GrabSlider(slider)
    Controller.grabbed = slider
    if slider then
        TintGlow(navGlow, 0.4, 1, 0.4)
    else
        TintGlow(navGlow, 1, 0.8, 0.2)
    end
end

local function NavButton(name, windows)
    local direction = NAV_DIRECTIONS[name]
    local target = navGlow.target
    local grabbed = Controller.grabbed
    if grabbed and (grabbed ~= target or not grabbed:IsVisible()) then
        Controller.GrabSlider(nil)
        grabbed = nil
    end
    if grabbed and (name == "left" or name == "right") then
        NudgeSlider(grabbed, name == "right" and 1 or -1)
        return true
    end
    if grabbed and (name == "a" or name == "b") then
        Controller.GrabSlider(nil)
        return true
    end
    if direction then
        if grabbed then
            Controller.GrabSlider(nil)
        end
        local nextButton = Step(direction, windows)
        if nextButton then
            NavFocus(nextButton)
        end
        return true
    end
    if name == "lb" or name == "rb" then
        local window = TabWindow(windows, target)
        if window and SwitchTab(window, name == "rb" and 1 or -1) then
            Controller.refocus = window
        end
        return true
    end
    if name == "lt" or name == "rt" then
        local nextButton = SwitchWindow(windows, name == "rt" and 1 or -1)
        if nextButton then
            NavFocus(nextButton)
        end
        return true
    end
    if name == "a" then
        if target and target:IsVisible() and IsSlider(target) then
            Controller.GrabSlider(target)
        elseif target and target:IsVisible() then
            local wasOpen = table.getn(OpenDropdownLists()) > 0
            Activate(target)
            RefreshTooltip(target)
            if not wasOpen and table.getn(OpenDropdownLists()) > 0 then
                Controller.dropdownOpener = target
            end
        end
        return true
    end
    if name == "x" then
        local bag, slot
        if target then
            bag, slot = ContainerSlot(target)
        end
        if bag then
            AskDelete(bag, slot)
        elseif target and target:IsVisible() and TooltipVerb(target, "Right%-click") then
            RightClick(target)
            RefreshTooltip(target)
        end
        return true
    end
    if name == "b" then
        if table.getn(OpenDropdownLists()) > 0 then
            CloseDropDownMenus()
            return true
        end
        local window = target and WindowOf(target, windows) or windows[1]
        if window and not KEEP_OPEN[window:GetName() or ""] then
            CloseWindow(window)
        end
        return true
    end
    return false
end

local GEAR_SHORTCUTS = { lb = "equip", x = "equipOther", y = "loot", rb = "salvage" }

local function GearOpen()
    return VanillaBonkGear and VanillaBonkGear.open
end

local function GearButton(name)
    local key = GEAR_SHORTCUTS[name]
    local button = key and VanillaBonkGear[key]
    if not button then
        return false
    end
    if button:IsVisible() and button:IsEnabled() == 1 then
        button:Click()
    end
    return true
end

local function GearPrompts()
    local prompts = {}
    for _, name in ipairs({ "lb", "x", "y", "rb" }) do
        local button = VanillaBonkGear[GEAR_SHORTCUTS[name]]
        if button and button:IsVisible() then
            table.insert(prompts, { name, button:GetText() or "" })
        end
    end
    return prompts
end

local function IsGear(link)
    local _, _, item = string.find(link, "(item:[%d:]+)")
    if not item then
        return false
    end
    local _, _, _, _, _, _, _, equipLoc = GetItemInfo(item)
    return equipLoc ~= nil and equipLoc ~= ""
end

local function WindowPrompts(windows)
    local prompts = {}
    local target = navGlow.target
    if target then
        table.insert(prompts, { "dpad", "Move" })
    end
    local bag, slot, inventory
    if target then
        bag, slot = ContainerSlot(target)
        inventory = InventorySlot(target)
    end
    if target and IsSlider(target) then
        table.insert(prompts, { "leftright", "Adjust" })
    elseif bag then
        local link = GetContainerItemLink(bag, slot)
        if link then
            table.insert(prompts, { "a", IsGear(link) and "Equip" or "Use" })
            table.insert(prompts, { "x", "Delete" })
        end
    elseif inventory then
        if GetInventoryItemLink("player", inventory) then
            table.insert(prompts, { "a", "Unequip" })
        end
    elseif target and IsMerchantItem(target) then
        local buyback = target.buysOnRightClick and target.item and target.item.buyback
        if not target.buysOnRightClick then
            buyback = MerchantFrame.selectedTab == 2
        end
        local upgrade = target.buysOnRightClick and target.item and target.item.upgrade
        table.insert(prompts, { "a", upgrade and "Upgrade" or buyback and "Buy back" or "Buy" })
    elseif target and not target.navTooltip then
        table.insert(prompts, { "a", TooltipVerb(target, "Click") or "Select" })
        local rightVerb = TooltipVerb(target, "Right%-click")
        if rightVerb then
            table.insert(prompts, { "x", rightVerb })
        end
    end
    table.insert(prompts, { "b", "Close" })
    if table.getn(windows) > 1 then
        table.insert(prompts, { "rt", "Next window" })
    end
    if Controller.scrollMode then
        table.insert(prompts, { "rs", "Scroll" })
        table.insert(prompts, { "r3", "Cursor" })
    else
        table.insert(prompts, { "rs", "Cursor" })
    end
    return prompts
end

local TAB_GLYPH = 24
local TAB_GLYPH_INSET = 6
local SCROLL_THRESHOLD = 0.3
local SCROLL_REPEAT = 0.12
local tabGlyphWindows = {}

local function TabGlyphs(window)
    if not window.padTabs then
        window.padTabs = { left = window:CreateTexture(nil, "OVERLAY"), right = window:CreateTexture(nil, "OVERLAY") }
        for _, glyph in pairs(window.padTabs) do
            glyph:SetWidth(TAB_GLYPH)
            glyph:SetHeight(TAB_GLYPH)
        end
    end
    return window.padTabs
end

local function ShowTabGlyphs(window)
    local glyphs = TabGlyphs(window)
    local tabs = TabList(window)
    local first = tabs and tabs[1]
    local last = tabs and tabs[table.getn(tabs)]
    if not first then
        glyphs.left:Hide()
        glyphs.right:Hide()
        return
    end
    Controller.SetGlyph(glyphs.left, "lb")
    Controller.SetGlyph(glyphs.right, "rb")
    glyphs.left:ClearAllPoints()
    glyphs.left:SetPoint("RIGHT", first, "LEFT", TAB_GLYPH_INSET, 0)
    glyphs.right:ClearAllPoints()
    glyphs.right:SetPoint("LEFT", last, "RIGHT", -TAB_GLYPH_INSET, 0)
end

local function UpdateTabGlyphs(windows)
    local wanted = {}
    if Controller.kind then
        for _, window in ipairs(windows) do
            if HasTabs(window) then
                wanted[window] = true
                ShowTabGlyphs(window)
            end
        end
    end
    for window in pairs(tabGlyphWindows) do
        if not wanted[window] and window.padTabs then
            window.padTabs.left:Hide()
            window.padTabs.right:Hide()
        end
    end
    tabGlyphWindows = wanted
end

local function WheelTarget(windows, target)
    local window = target and WindowOf(target, windows)
    local found = window and FindWheel(window)
    if found then
        return found
    end
    for _, candidate in ipairs(windows) do
        found = FindWheel(candidate)
        if found then
            return found
        end
    end
end

local function SetScrollMode(enabled)
    if Controller.scrollMode == enabled then
        return
    end
    Controller.scrollMode = enabled
    if HoAController_SetScrollMode then
        HoAController_SetScrollMode(enabled)
    end
end

local function UpdateScroll(windows)
    local wheel = WheelTarget(windows, navGlow.target)
    SetScrollMode(wheel ~= nil)
    if not wheel or not HoAController_GetSticks then
        Controller.scrollAt = nil
        return
    end
    local _, _, _, ry = HoAController_GetSticks()
    if not ry or math.abs(ry) < SCROLL_THRESHOLD then
        Controller.scrollAt = nil
        return
    end
    local now = GetTime()
    if Controller.scrollAt and now < Controller.scrollAt then
        return
    end
    local saved = arg1
    arg1 = ry > 0 and 1 or -1
    RunScript(wheel, "OnMouseWheel")
    arg1 = saved
    Controller.scrollAt = now + SCROLL_REPEAT / math.abs(ry)
end

local CURSOR_PROMPTS = { { "rs", "Move cursor" }, { "a", "Click" }, { "x", "Right-click" }, { "dpad", "Buttons" }, { "b", "Close" } }

local function HideNavForCursor()
    local button = navGlow.target
    if not navGlow:IsShown() then
        return
    end
    navGlow:Hide()
    if button then
        RunScript(button, "OnLeave")
    end
end

local function NearestTo(button, windows)
    local window = WindowOf(button, windows)
    if not window then
        return nil
    end
    local fromX, fromY = Center(button)
    local best, bestDistance
    for _, candidate in ipairs(Collect(window, {})) do
        local x, y = Center(candidate)
        local distance = (x - fromX) * (x - fromX) + (y - fromY) * (y - fromY)
        if not best or distance < bestDistance then
            best, bestDistance = candidate, distance
        end
    end
    return best
end

local function UpdateWindows(windows)
    if not Controller.kind then
        Unfocused()
        Controller.HidePrompts()
        UpdateTabGlyphs(windows)
        SetScrollMode(false)
        return
    end
    if HoAController_CursorMode and HoAController_CursorMode() then
        HideNavForCursor()
        Controller.ShowPrompts(CURSOR_PROMPTS)
        return
    end
    UpdateTabGlyphs(windows)
    UpdateScroll(windows)
    if Controller.refocus then
        local first = Controller.refocus:IsVisible() and FirstIn(Controller.refocus)
        Controller.refocus = nil
        if first then
            NavFocus(first)
        end
    end
    local target = navGlow.target
    local opener = Controller.dropdownOpener
    if opener and table.getn(OpenDropdownLists()) == 0 then
        Controller.dropdownOpener = nil
        if opener:IsVisible() and WindowOf(opener, windows) then
            NavFocus(opener)
            target = opener
        end
    end
    if not target or not target:IsVisible() or not WindowOf(target, windows) then
        local first = FirstIn(windows[1])
        if first then
            NavFocus(first)
        else
            Unfocused()
        end
    elseif target.IsEnabled and target:IsEnabled() ~= 1 then
        local nearest = NearestTo(target, windows)
        if nearest then
            NavFocus(nearest)
        else
            Unfocused()
        end
    elseif not navGlow:IsShown() then
        NavFocus(target)
    end
    if GearOpen() then
        local x = VanillaBonkGear:GetCenter()
        local _, y = VanillaBonkGear.salvage:GetCenter()
        Controller.ShowCenterPrompts(UIParent, x or 0, y or 0, GearPrompts())
        return
    end
    Controller.ShowPrompts(WindowPrompts(windows))
end

local INTERACT_GLYPH = 30
local INTERACT_LIFT = 26
local INTERACT_FADE = 6
local INTERACT_PLATE_GAP = 4
local INTERACT_KEYCAP = 26
local INTERACT_COMMAND = "VANILLABONK_INTERACT"
local OBJECT_VERBS = { [900001] = "Open", [900002] = "Open", [900003] = "Enter", [900041] = "Open", [900060] = "Search" }
local OBJECT_TYPE_VERBS = { [3] = "Open", [19] = "Mail" }
local NPC_FLAG_GOSSIP = 1
local NPC_FLAG_VENDOR = 4
local NPC_FLAG_BANKER = 256

local interactPrompt = CreateFrame("Frame", nil, UIParent)
interactPrompt:SetFrameStrata("LOW")
interactPrompt:SetHeight(INTERACT_GLYPH)
interactPrompt.glyph = interactPrompt:CreateTexture(nil, "ARTWORK")
interactPrompt.glyph:SetWidth(INTERACT_GLYPH)
interactPrompt.glyph:SetHeight(INTERACT_GLYPH)
interactPrompt.glyph:SetPoint("LEFT", interactPrompt, "LEFT", 0, 0)
interactPrompt.cap = VanillaBonkUI.KeyCap(interactPrompt, INTERACT_KEYCAP, 13)
interactPrompt.cap:SetPoint("LEFT", interactPrompt, "LEFT", 0, 0)
interactPrompt.label = interactPrompt:CreateFontString(nil, "ARTWORK", "GameFontHighlightLarge")
interactPrompt.label:SetShadowOffset(1, -1)
interactPrompt:Hide()
Controller.interactPrompt = interactPrompt

local function HasFlag(value, flag)
    return math.mod(math.floor(value / flag), 2) == 1
end

local function InteractVerb(kind, entry, detail)
    if kind == "object" then
        return OBJECT_VERBS[entry] or OBJECT_TYPE_VERBS[detail] or "Use"
    end
    if HasFlag(detail, NPC_FLAG_GOSSIP) then
        return "Talk"
    end
    if HasFlag(detail, NPC_FLAG_BANKER) then
        return "Bank"
    end
    if HasFlag(detail, NPC_FLAG_VENDOR) then
        return "Shop"
    end
    return "Talk"
end

local function HideInteract()
    interactPrompt:Hide()
    interactPrompt.key = nil
end

local function PlaceOnWorld(frame, point, x, y, lift)
    local worldScale = WorldFrame:GetEffectiveScale()
    local scale = frame:GetEffectiveScale()
    local offsetX = x * WorldFrame:GetWidth() * worldScale / scale
    local offsetY = y * WorldFrame:GetHeight() * worldScale / scale + lift
    frame:ClearAllPoints()
    frame:SetPoint(point, WorldFrame, "BOTTOMLEFT", offsetX, offsetY)
end

local function DressInteract(keyText)
    local mark = interactPrompt.glyph
    if keyText then
        interactPrompt.glyph:Hide()
        VanillaBonkUI.SetKeyCap(interactPrompt.cap, keyText)
        interactPrompt.cap:Show()
        mark = interactPrompt.cap
    else
        interactPrompt.cap:Hide()
        Controller.SetGlyph(interactPrompt.glyph, Controller.ButtonFor("interact"))
        interactPrompt.glyph:Show()
    end
    interactPrompt.label:ClearAllPoints()
    interactPrompt.label:SetPoint("LEFT", mark, "RIGHT", 4, 0)
    return mark:GetWidth()
end

local function PlaceInteract(headX, headY)
    local worldScale = WorldFrame:GetEffectiveScale()
    local screenX = headX * WorldFrame:GetWidth() * worldScale
    local screenY = headY * WorldFrame:GetHeight() * worldScale
    local plateTop = VanillaBonkUI.PlateTopAbove(screenX, screenY)
    if not plateTop then
        PlaceOnWorld(interactPrompt, "BOTTOM", headX, headY, INTERACT_LIFT)
        return
    end
    local scale = interactPrompt:GetEffectiveScale()
    interactPrompt:ClearAllPoints()
    interactPrompt:SetPoint("BOTTOM", WorldFrame, "BOTTOMLEFT", screenX / scale, plateTop / scale + INTERACT_PLATE_GAP)
end

local function ShowInteract(kind, entry, detail, headX, headY, keyText)
    local key = kind .. entry .. Controller.Style() .. (keyText or "")
    if interactPrompt.key ~= key then
        interactPrompt.key = key
        interactPrompt.shownAt = GetTime()
        interactPrompt.label:SetText(InteractVerb(kind, entry, detail))
        interactPrompt:SetWidth(DressInteract(keyText) + 4 + interactPrompt.label:GetStringWidth())
    end
    PlaceInteract(headX, headY)
    interactPrompt:SetAlpha(math.min(1, (GetTime() - interactPrompt.shownAt) * INTERACT_FADE))
    interactPrompt:Show()
end

local function InteractKeyText()
    if Controller.kind then
        return nil
    end
    local text = VanillaBonkUI.BindingText(INTERACT_COMMAND)
    if text == "" then
        return false
    end
    return text
end

local function UpdateInteract(allowed)
    local keyText = InteractKeyText()
    if not allowed or keyText == false or not Controller.Setting("interactPrompts") or not HoAController_GetInteract or UnitIsDeadOrGhost("player") then
        HideInteract()
        return
    end
    local kind, entry, detail, headX, headY = HoAController_GetInteract()
    if not kind then
        HideInteract()
        return
    end
    ShowInteract(kind, entry, detail, headX, headY, keyText)
end

function HoAController_OnButton(name, down)
    if name == "lt" then
        Controller.inspectHeld = down
    end
    if not down then
        return
    end
    if Controller.listening then
        Controller.listening(name)
        return
    end
    local window = ChoiceWindow()
    if window then
        ChoiceButton(window, name)
        return
    end
    if GearOpen() and GearButton(name) then
        return
    end
    local windows = OpenWindows()
    if table.getn(windows) > 0 and NavButton(name, windows) then
        return
    end
    local prompt = table.getn(windows) == 0 and ActivePrompt()
    if prompt and PromptPress(prompt, name) then
        return
    end
    local action = PlayAction(name)
    if action then
        action()
    end
end

function VanillaBonkUI.ShowBindings(forController)
    local panel = VanillaBonkControllerPanel
    if forController then
        if KeyBindingFrame and KeyBindingFrame:IsShown() then
            HideUIPanel(KeyBindingFrame)
        end
        if BenillaOptionsFrame and BenillaOptionsFrame:IsShown() then
            HideUIPanel(BenillaOptionsFrame)
        end
        panel.asBindings = true
        panel:Show()
        return
    end
    if panel:IsShown() then
        panel:Hide()
    end
    panel.asBindings = nil
    if VanillaBonkUI.ShowClientSettings("Keybindings") then
        return
    end
    KeyBindingFrame_LoadUI()
    ShowUIPanel(KeyBindingFrame)
end

function Controller.SwapBindings(kind)
    local panel = VanillaBonkControllerPanel
    local benillaKeys = BenillaOptionsFrame and BenillaOptionsFrame:IsShown()
        and BenillaOptionsFrame.selectedCategory == "Keybindings"
    if kind and (benillaKeys or KeyBindingFrame and KeyBindingFrame:IsShown()) then
        VanillaBonkUI.ShowBindings(true)
    elseif not kind and panel and panel:IsShown() and panel.asBindings then
        VanillaBonkUI.ShowBindings(false)
    end
end

function HoAController_OnDevice(kind)
    Controller.kind = kind
    ShowFocus(ChoiceWindow())
    Controller.SwapBindings(kind)
    if VanillaBonkUI.RefreshHearthKey then
        VanillaBonkUI.RefreshHearthKey()
    end
end

local KEYBOARD_REFRESH = 0.1
local watcher = CreateFrame("Frame")
watcher:SetScript("OnUpdate", function()
    if HoAController_Frame then
        HoAController_Frame()
    end
    if Controller.kind == nil and Controller.optionsPushed then
        Controller.sinceRefresh = (Controller.sinceRefresh or 0) + arg1
        if Controller.sinceRefresh < KEYBOARD_REFRESH and ChoiceWindow() == Controller.window and not Controller.restyled then
            UpdateInteract(not Controller.captured)
            return
        end
        Controller.sinceRefresh = 0
    end
    if not Controller.optionsPushed and HoAController_SetOption then
        Controller.optionsPushed = true
        if HoAController_GetType and HoAController_GetType() ~= Controller.kind then
            HoAController_OnDevice(HoAController_GetType())
        end
        for key in pairs(DLL_OPTIONS) do
            PushOption(key)
        end
        if HoAController_SetObjectReach then
            for entry, yards in pairs(OBJECT_REACH) do
                HoAController_SetObjectReach(entry, yards)
            end
        end
    end
    local window = ChoiceWindow()
    local anim = window and window.anim
    local freshCards = anim and anim ~= Controller.lastAnim and (anim.mode == "open" or anim.mode == "pop")
    Controller.lastAnim = anim
    if window ~= Controller.window or freshCards then
        Controller.window = window
        Controller.focus = 1
    elseif window and Controller.focus > CardCount(window) then
        Controller.focus = 1
    end
    local windows = window and {} or OpenWindows()
    local capture = window ~= nil or table.getn(windows) > 0
    if capture ~= Controller.captured then
        Controller.captured = capture
        if HoAController_SetCapture then
            HoAController_SetCapture(capture)
        end
    end
    HideMouseButtons(Controller.kind ~= nil)
    ShowFocus(window)
    UpdateInspect(window)
    UpdateInteract(not capture)
    if window then
        Unfocused()
        UpdatePrompts(window)
    elseif table.getn(windows) > 0 then
        RestoreHint()
        UpdateWindows(windows)
    elseif not ShowPromptFocus() then
        Unfocused()
        UpdatePrompts(nil)
    end
    if table.getn(windows) == 0 then
        UpdateTabGlyphs(windows)
        SetScrollMode(false)
    end
    Controller.restyled = nil
end)
