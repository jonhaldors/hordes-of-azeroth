local L = VanillaBonkL
VanillaBonkUI = {}
local UI = VanillaBonkUI

UI.FONT = "Fonts\\FRIZQT__.TTF"
UI.NUMBER_FONT = "Fonts\\ARIALN.TTF"
UI.TITLE_FONT = "Fonts\\MORPHEUS.TTF"
UI.FLAT = "Interface\\Buttons\\WHITE8X8"
UI.ICON_PATH = "Interface\\Icons\\"

UI.RARITY = {
    [0] = { name = L["Common"], r = 1, g = 1, b = 1 },
    [1] = { name = L["Uncommon"], r = 0.12, g = 1, b = 0 },
    [2] = { name = L["Rare"], r = 0, g = 0.44, b = 0.87 },
    [3] = { name = L["Epic"], r = 0.64, g = 0.21, b = 0.93 },
    [4] = { name = L["Legendary"], r = 1, g = 0.5, b = 0 },
}

UI.DAMAGE_TYPES = {
    phys = { name = L["Physical"], r = 0.78, g = 0.61, b = 0.43, icon = "Ability_MeleeDamage" },
    bleed = { name = L["Bleed"], r = 0.83, g = 0.16, b = 0.16, icon = "Ability_BackStab", note = L["Physical damage over time."] },
    poison = { name = L["Poison"], r = 0.3, g = 0.76, b = 0.23, icon = "Spell_Nature_CorrosiveBreath", note = L["Nature damage over time."] },
    fire = { name = L["Fire"], r = 1, g = 0.49, b = 0.1, icon = "Spell_Fire_FlameBolt" },
    burn = { name = L["Burning"], r = 1, g = 0.71, b = 0.24, icon = "Spell_Fire_Incinerate", note = L["Fire damage over time."] },
    frost = { name = L["Frost"], r = 0.41, g = 0.8, b = 0.94, icon = "Spell_Frost_FrostBolt02" },
    arcane = { name = L["Arcane"], r = 0.82, g = 0.49, b = 1, icon = "Spell_Nature_StarFall" },
    shadow = { name = L["Shadow"], r = 0.56, g = 0.42, b = 0.85, icon = "Spell_Shadow_ShadowBolt" },
    nature = { name = L["Nature"], r = 0.25, g = 0.78, b = 0.71, icon = "Spell_Nature_Lightning" },
    holy = { name = L["Holy"], r = 1, g = 0.9, b = 0.5, icon = "Spell_Holy_HolyBolt" },
    decay = { name = L["Decay"], r = 0.45, g = 0.3, b = 0.7, icon = "Spell_Shadow_ChillTouch", note = L["Shadow damage over time."] },
    agony = { name = L["Agony"], r = 0.55, g = 0.2, b = 0.55, icon = "Spell_Shadow_CurseOfSargeras", note = L["Shadow damage over time that grows."] },
    moonkin = { name = L["Moonkin Form"], r = 0.55, g = 0.6, b = 1, icon = "Spell_Nature_ForceOfNature", note = L["Wrath and Starfall."] },
    cat = { name = L["Cat Form"], r = 1, g = 0.82, b = 0.25, icon = "Ability_Druid_CatForm", note = L["Claw."] },
    bear = { name = L["Bear Form"], r = 0.75, g = 0.45, b = 0.25, icon = "Ability_Racial_BearForm", note = L["Maul."] },
    tree = { name = L["Tree of Life"], r = 0.35, g = 0.85, b = 0.35, icon = "Spell_Nature_ProtectionformNature", note = L["Vines."] },
}
UI.DAMAGE_TYPE_BY_KEYWORD = { Bleed = "bleed", Poison = "poison", Burning = "burn", Decay = "decay", Agony = "agony" }

local ICON_SCHOOLS = {
    { "_FIRE_", "fire" }, { "FIREBALL", "fire" }, { "_FROST_", "frost" }, { "_ARCANE_", "arcane" }, { "STARFALL", "arcane" },
    { "_SHADOW_", "shadow" }, { "_HOLY_", "holy" }, { "_NATURE_", "nature" }, { "_LIGHTNING", "nature" },
}

function UI.DamageTypeFromIcon(icon)
    local upper = strupper(icon or "")
    for _, school in ipairs(ICON_SCHOOLS) do
        if strfind(upper, school[1], 1, true) then
            return school[2]
        end
    end
    return "phys"
end

function UI.DamageType(key)
    return UI.DAMAGE_TYPES[key or ""] or UI.DAMAGE_TYPES.phys
end

function UI.DamageParts(description, total, icon)
    local parts = {}
    local fields = (description and description ~= "") and UI.Split(description, "/") or {}
    local school = (fields[1] and UI.DAMAGE_TYPES[fields[1]]) and fields[1] or UI.DamageTypeFromIcon(icon)
    local direct = total or 0
    for index = 2, getn(fields) do
        local pair = UI.Split(fields[index], ":")
        local amount = tonumber(pair[2] or "") or 0
        if UI.DAMAGE_TYPES[pair[1]] and amount > 0 then
            tinsert(parts, { key = pair[1], damage = amount })
            direct = direct - amount
        end
    end
    if direct > 0 or getn(parts) == 0 then
        tinsert(parts, 1, { key = school, damage = max(0, direct) })
    end
    return parts
end

UI.BAR_FADE = { r = 0.87, g = 0.72, b = 0.88 }
UI.HEAL_COLOR = { r = 0.29, g = 0.82, b = 0.33 }
UI.ABSORB_COLOR = { r = 0.86, g = 0.9, b = 1 }

function UI.ShadeBar(fill, color, from, to, brightness)
    local function Channel(value, fade, position)
        return value * brightness * (fade + (1 - fade) * position)
    end
    local fade = UI.BAR_FADE
    fill:SetGradient("HORIZONTAL",
        Channel(color.r, fade.r, from), Channel(color.g, fade.g, from), Channel(color.b, fade.b, from),
        Channel(color.r, fade.r, to), Channel(color.g, fade.g, to), Channel(color.b, fade.b, to))
end

UI.CLASS_ICONS = "Interface\\Glues\\CharacterCreate\\UI-CharacterCreate-Classes"
UI.CLASS_COORDS = {
    WARRIOR = { 0, 0.25, 0, 0.25 },
    MAGE = { 0.25, 0.49609375, 0, 0.25 },
    ROGUE = { 0.49609375, 0.7421875, 0, 0.25 },
    DRUID = { 0.7421875, 0.98828125, 0, 0.25 },
    HUNTER = { 0, 0.25, 0.25, 0.5 },
    SHAMAN = { 0.25, 0.49609375, 0.25, 0.5 },
    PRIEST = { 0.49609375, 0.7421875, 0.25, 0.5 },
    WARLOCK = { 0.7421875, 0.98828125, 0.25, 0.5 },
    PALADIN = { 0, 0.25, 0.5, 0.75 },
}

function UI.RarityText(rarity, text)
    local color = UI.RARITY[rarity] or UI.RARITY[0]
    return format("|cff%02x%02x%02x%s|r", color.r * 255, color.g * 255, color.b * 255, text)
end

function UI.FormatGold(copper)
    copper = tonumber(copper) or 0
    local gold = floor(copper / 10000)
    local silver = floor(mod(copper, 10000) / 100)
    local text = format(L["|cffeda55f%dc|r"], mod(copper, 100))
    if silver > 0 or gold > 0 then
        text = format(L["|cffc7c7cf%ds|r "], silver) .. text
    end
    if gold > 0 then
        text = format(L["|cffffd700%dg|r "], gold) .. text
    end
    return text
end

function UI.Thousands(value)
    local text = tostring(math.floor(tonumber(value) or 0))
    local result = ""
    while strlen(text) > 3 do
        result = "," .. strsub(text, -3) .. result
        text = strsub(text, 1, -4)
    end
    return text .. result
end

function UI.AddQuestProgress(tooltip, lock)
    if lock and lock.amount and lock.amount > 1 then
        tooltip:AddLine(L["Progress: "] .. UI.Thousands(math.min(lock.progress, lock.amount)) .. "/" .. UI.Thousands(lock.amount), 0.62, 0.62, 0.62)
    end
end

function UI.FormatTime(seconds)
    seconds = tonumber(seconds) or 0
    return format("%d:%02d", floor(seconds / 60), mod(seconds, 60))
end

function UI.Split(text, separator)
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

function UI.Text(parent, size, font, flags, layer)
    local text = parent:CreateFontString(nil, layer or "OVERLAY")
    text:SetFont(font or UI.FONT, size, flags or "")
    if not flags or flags == "" then
        text:SetShadowColor(0, 0, 0, 1)
        text:SetShadowOffset(1, -1)
    end
    return text
end

function UI.Listen(handlers)
    local frame = CreateFrame("Frame")
    frame:RegisterEvent("CHAT_MSG_SYSTEM")
    frame:SetScript("OnEvent", function()
        if not arg1 or strsub(arg1, 1, 5) ~= "BONK~" then
            return
        end
        local stop = strfind(arg1, "~", 6, true)
        local handler = handlers[strsub(arg1, 6, stop and stop - 1 or -1)]
        if handler then
            handler(UI.Split(strsub(arg1, 6), "~"))
        end
    end)
    return frame
end

local GENERAL = "Interface\\PaperDollInfoFrame\\UI-Character-General-"
local EDGE_LEFT, EDGE_RIGHT, EDGE_TOP, EDGE_BOTTOM = 70, 30, 72, 16
local TILE = 128
local TILE_FROM = 100

UI.CONTENT_LEFT, UI.CONTENT_TOP, UI.CONTENT_RIGHT, UI.CONTENT_BOTTOM = 20, 74, 10, 9

local function Tile(frame, file, texW, texH, x1, y1, w, h, x, y)
    frame.tileCount = frame.tileCount + 1
    local texture = frame.tiles[frame.tileCount]
    if not texture then
        texture = frame:CreateTexture(nil, "BORDER")
        frame.tiles[frame.tileCount] = texture
    end
    texture:SetTexture(GENERAL .. file)
    texture:SetTexCoord(x1 / texW, (x1 + w) / texW, y1 / texH, (y1 + h) / texH)
    texture:SetWidth(w)
    texture:SetHeight(h)
    texture:ClearAllPoints()
    texture:SetPoint("TOPLEFT", frame, "TOPLEFT", x, -y)
    texture:Show()
end

local function LayoutWindow(frame)
    local width, height = floor(frame:GetWidth() + 0.5), floor(frame:GetHeight() + 0.5)
    frame.tileCount = 0
    local innerWidth = width - EDGE_LEFT - EDGE_RIGHT
    local innerHeight = height - EDGE_TOP - EDGE_BOTTOM

    Tile(frame, "TopLeft", 256, 256, 0, 0, EDGE_LEFT, EDGE_TOP, 0, 0)
    Tile(frame, "TopRight", 128, 256, 94 - EDGE_RIGHT, 0, EDGE_RIGHT, EDGE_TOP, width - EDGE_RIGHT, 0)
    Tile(frame, "BottomLeft", 256, 256, 0, 183 - EDGE_BOTTOM, EDGE_LEFT, EDGE_BOTTOM, 0, height - EDGE_BOTTOM)
    Tile(frame, "BottomRight", 128, 256, 94 - EDGE_RIGHT, 183 - EDGE_BOTTOM, EDGE_RIGHT, EDGE_BOTTOM, width - EDGE_RIGHT, height - EDGE_BOTTOM)

    local x = 0
    while x < innerWidth do
        local from = x == 0 and EDGE_LEFT or TILE_FROM
        local w = min(TILE, innerWidth - x)
        Tile(frame, "TopLeft", 256, 256, from, 0, w, EDGE_TOP, EDGE_LEFT + x, 0)
        Tile(frame, "BottomLeft", 256, 256, from, 183 - EDGE_BOTTOM, w, EDGE_BOTTOM, EDGE_LEFT + x, height - EDGE_BOTTOM)
        local y = 0
        while y < innerHeight do
            local h = min(TILE, innerHeight - y)
            Tile(frame, "TopLeft", 256, 256, 80, 80, w, h, EDGE_LEFT + x, EDGE_TOP + y)
            y = y + TILE
        end
        x = x + TILE
    end

    local y = 0
    while y < innerHeight do
        local h = min(TILE, innerHeight - y)
        Tile(frame, "TopLeft", 256, 256, 0, EDGE_TOP, EDGE_LEFT, h, 0, EDGE_TOP + y)
        Tile(frame, "TopRight", 128, 256, 94 - EDGE_RIGHT, EDGE_TOP, EDGE_RIGHT, h, width - EDGE_RIGHT, EDGE_TOP + y)
        y = y + TILE
    end

    for index = frame.tileCount + 1, table.getn(frame.tiles) do
        frame.tiles[index]:Hide()
    end
end

function UI.SetWindowSize(frame, width, height)
    frame:SetWidth(width)
    frame:SetHeight(height)
    LayoutWindow(frame)
end

function UI.Window(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    tinsert(UISpecialFrames, name)

    frame.portrait = frame:CreateTexture(nil, "BACKGROUND")
    frame.portrait:SetWidth(60)
    frame.portrait:SetHeight(60)
    frame.portrait:SetPoint("TOPLEFT", frame, "TOPLEFT", 5, -4)

    frame.tiles = {}
    UI.SetWindowSize(frame, width, height)

    frame.title = UI.Text(frame, 13)
    frame.title:SetPoint("TOP", frame, "TOP", (EDGE_LEFT - EDGE_RIGHT) / 2, -16)
    frame.title:SetTextColor(1, 0.82, 0)

    frame.header = UI.Text(frame, 12)
    frame.header:SetPoint("TOPLEFT", frame, "TOPLEFT", 78, -44)
    frame.header:SetTextColor(1, 0.82, 0)
    frame.headerRight = UI.Text(frame, 12)
    frame.headerRight:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -40, -44)
    frame.headerRight:SetJustifyH("RIGHT")

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 3, -6)
    frame.close:SetScript("OnClick", function() this:GetParent():Hide() end)

    return frame
end

function UI.SetPortrait(frame)
    if UnitExists("npc") then
        SetPortraitTexture(frame.portrait, "npc")
    else
        SetPortraitTexture(frame.portrait, "player")
    end
end

function UI.Tabs(frame, labels, onClick)
    local name = frame:GetName()
    for index, label in ipairs(labels) do
        local tab = getglobal(name .. "Tab" .. index)
        if not tab then
            tab = CreateFrame("Button", name .. "Tab" .. index, frame, "CharacterFrameTabButtonTemplate")
            tab:SetID(index)
            tab:SetScript("OnClick", function()
                PanelTemplates_Tab_OnClick(this:GetParent())
                PlaySound("igCharacterInfoTab")
                onClick(this:GetID())
            end)
            tab:ClearAllPoints()
            if index == 1 then
                tab:SetPoint("CENTER", frame, "BOTTOMLEFT", 60, -11)
            else
                tab:SetPoint("LEFT", getglobal(name .. "Tab" .. (index - 1)), "RIGHT", -16, 0)
            end
        end
        tab:SetText(label)
        PanelTemplates_TabResize(0, tab)
        tab:Show()
    end
    local index = table.getn(labels) + 1
    while getglobal(name .. "Tab" .. index) do
        getglobal(name .. "Tab" .. index):Hide()
        index = index + 1
    end
    PanelTemplates_SetNumTabs(frame, table.getn(labels))
end

function UI.SelectTab(frame, id)
    PanelTemplates_SetTab(frame, id)
end

function UI.LoadingScreenCoords(texture, width, height, focus)
    local logo = 0.25
    local band = (4 / 3) * height / width
    local room = 0.79 - logo
    if band <= room then
        local top = logo + (room - band) * (focus or 0.5)
        texture:SetTexCoord(0, 1, top, top + band)
    else
        local span = room / band
        texture:SetTexCoord((1 - span) / 2, (1 + span) / 2, logo, logo + room)
    end
end

function UI.TalentArtCoords(texture, width, height)
    local ratio = height / width
    if ratio <= 1 then
        local top = (1 - ratio) * 0.35
        texture:SetTexCoord(0, 1, top, top + ratio)
    else
        local span = 1 / ratio
        texture:SetTexCoord((1 - span) / 2, (1 + span) / 2, 0, 1)
    end
end

local CARD_ART = {
    { "_FIRE_", "MageFire" }, { "_FROST_", "MageFrost" }, { "_ARCANE_", "MageArcane" }, { "STARFALL", "MageArcane" },
    { "WISPSPLODE", "MageArcane" }, { "_SHADOW_", "WarlockDestruction" }, { "_HOLY_", "PriestHoly" },
    { "_NATURE_", "DruidBalance" }, { "ABILITY_HUNTER", "HunterMarksmanship" }, { "MARKSMANSHIP", "HunterMarksmanship" },
    { "ABILITY_ROGUE", "RogueCombat" }, { "ABILITY_WARRIOR", "WarriorArms" }, { "ABILITY_", "WarriorFury" },
}
function UI.CardArt(icon)
    local upper = strupper(icon or "")
    for _, pair in ipairs(CARD_ART) do
        if strfind(upper, pair[1], 1, true) then
            return pair[2]
        end
    end
    return "PaladinHoly"
end

local function Shade(texture, bottomAlpha, topAlpha)
    texture:SetTexture(UI.FLAT)
    if texture.SetGradientAlpha then
        texture:SetGradientAlpha("VERTICAL", 0, 0, 0, bottomAlpha, 0, 0, 0, topAlpha)
    else
        texture:SetVertexColor(0, 0, 0, (bottomAlpha + topAlpha) / 2)
    end
end
UI.Shade = Shade

function UI.Pane(parent, x, y, width, height, art, dim)
    local pane = CreateFrame("Frame", nil, parent)
    pane:SetPoint("TOPLEFT", parent, "TOPLEFT", x, -y)
    pane:SetWidth(width)
    pane:SetHeight(height)
    pane:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
    pane:SetBackdropBorderColor(0, 0, 0, 1)

    pane.art = pane:CreateTexture(nil, "BACKGROUND")
    pane.art:SetPoint("TOPLEFT", pane, "TOPLEFT", 1, -1)
    pane.art:SetPoint("BOTTOMRIGHT", pane, "BOTTOMRIGHT", -1, 1)
    pane.shade = pane:CreateTexture(nil, "BORDER")
    pane.shade:SetAllPoints(pane.art)
    pane.dim = dim or 0.6
    UI.SetPaneArt(pane, art)
    return pane
end

function UI.SetPaneArt(pane, art, focus)
    local width, height = pane:GetWidth() - 2, pane:GetHeight() - 2
    if strfind(art, "TalentFrame") then
        pane.art:SetTexture(art .. "-TopLeft")
        UI.TalentArtCoords(pane.art, width, height)
    else
        pane.art:SetTexture(art)
        UI.LoadingScreenCoords(pane.art, width, height, focus)
    end
    Shade(pane.shade, min(0.92, pane.dim + 0.25), max(0, pane.dim - 0.3))
end

function UI.Strip(parent)
    local strip = CreateFrame("Frame", nil, parent)
    strip:SetBackdrop({
        bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1,
        insets = { left = 1, right = 1, top = 1, bottom = 1 },
    })
    UI.SetStripHighlight(strip, false)
    return strip
end

function UI.SetStripHighlight(strip, on)
    if on then
        strip:SetBackdropColor(0.12, 0.09, 0.02, 0.75)
        strip:SetBackdropBorderColor(1, 0.82, 0, 0.6)
    else
        strip:SetBackdropColor(0, 0, 0, 0.6)
        strip:SetBackdropBorderColor(0, 0, 0, 0.85)
    end
end

local ICON_BORDER_CROP = 0.08

function UI.CropIcon(texture)
    texture:SetTexCoord(ICON_BORDER_CROP, 1 - ICON_BORDER_CROP, ICON_BORDER_CROP, 1 - ICON_BORDER_CROP)
end

local QUICKSLOT_TEXELS = 64
local QUICKSLOT_ART_OFFSET = 1

function UI.CenterSlotFrame(frame, slot, size)
    local texel = size * 66 / 36 / QUICKSLOT_TEXELS
    frame:SetPoint("CENTER", slot, "CENTER", texel * QUICKSLOT_ART_OFFSET, -texel * QUICKSLOT_ART_OFFSET)
end

function UI.Slot(parent, size, kind)
    local slot = CreateFrame(kind or "Button", nil, parent)
    slot:SetWidth(size)
    slot:SetHeight(size)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetAllPoints(slot)
    slot.frame = slot:CreateTexture(nil, "OVERLAY")
    slot.frame:SetTexture("Interface\\Buttons\\UI-Quickslot2")
    slot.frame:SetWidth(size * 66 / 36)
    slot.frame:SetHeight(size * 66 / 36)
    UI.CenterSlotFrame(slot.frame, slot, size)
    return slot
end

local BUTTON_ART = {
    up = "Interface\\Buttons\\UI-Panel-Button-Up",
    down = "Interface\\Buttons\\UI-Panel-Button-Down",
    disabled = "Interface\\Buttons\\UI-Panel-Button-Disabled",
    highlight = "Interface\\Buttons\\UI-Panel-Button-Highlight",
}
local BUTTON_SLICES = { { 0, 0.09375 }, { 0.09375, 0.53125 }, { 0.53125, 0.625 } }
local BUTTON_ART_HEIGHT = 0.6875
local BUTTON_CAP_RATIO = 12 / 22

local function SliceSet(button, layer, blend)
    local set = {}
    for index, range in ipairs(BUTTON_SLICES) do
        local slice = button:CreateTexture(nil, layer)
        slice:SetTexCoord(range[1], range[2], 0, BUTTON_ART_HEIGHT)
        if blend then
            slice:SetBlendMode(blend)
        end
        set[index] = slice
    end
    set[1]:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
    set[1]:SetPoint("BOTTOMLEFT", button, "BOTTOMLEFT", 0, 0)
    set[3]:SetPoint("TOPRIGHT", button, "TOPRIGHT", 0, 0)
    set[3]:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
    set[2]:SetPoint("TOPLEFT", set[1], "TOPRIGHT", 0, 0)
    set[2]:SetPoint("BOTTOMRIGHT", set[3], "BOTTOMLEFT", 0, 0)
    return set
end

local function SizeSlices(button)
    local cap = math.floor(button:GetHeight() * BUTTON_CAP_RATIO + 0.5)
    for _, set in ipairs({ button.face, button.shine }) do
        set[1]:SetWidth(cap)
        set[3]:SetWidth(cap)
    end
end

local function PaintSlices(button, state)
    local file = BUTTON_ART[state]
    for _, slice in ipairs(button.face) do
        slice:SetTexture(file)
    end
end

local function RefreshSlices(button)
    if not button:IsEnabled() or button:IsEnabled() == 0 then
        PaintSlices(button, "disabled")
    elseif button.held then
        PaintSlices(button, "down")
    else
        PaintSlices(button, "up")
    end
end

function UI.SliceButton(button)
    button:SetNormalTexture("")
    button:SetPushedTexture("")
    button:SetDisabledTexture("")
    button:SetHighlightTexture("")
    button.face = SliceSet(button, "BACKGROUND")
    button.shine = SliceSet(button, "HIGHLIGHT", "ADD")
    for _, slice in ipairs(button.shine) do
        slice:SetTexture(BUTTON_ART.highlight)
    end
    local setHeight, enable, disable = button.SetHeight, button.Enable, button.Disable
    button.SetHeight = function(self, height)
        setHeight(self, height)
        SizeSlices(self)
    end
    button.Enable = function(self)
        enable(self)
        RefreshSlices(self)
    end
    button.Disable = function(self)
        disable(self)
        RefreshSlices(self)
    end
    local down, up, hide = button:GetScript("OnMouseDown"), button:GetScript("OnMouseUp"), button:GetScript("OnHide")
    button:SetScript("OnMouseDown", function()
        if down then
            down()
        end
        this.held = true
        RefreshSlices(this)
    end)
    button:SetScript("OnMouseUp", function()
        if up then
            up()
        end
        this.held = nil
        RefreshSlices(this)
    end)
    button:SetScript("OnHide", function()
        if hide then
            hide()
        end
        this.held = nil
        RefreshSlices(this)
    end)
    SizeSlices(button)
    RefreshSlices(button)
    return button
end

function UI.Button(parent, width, text, onClick)
    local button = UI.SliceButton(CreateFrame("Button", nil, parent, "UIPanelButtonTemplate"))
    button:SetWidth(width)
    button:SetHeight(22)
    button:SetText(text or "")
    if onClick then
        button:SetScript("OnClick", onClick)
    end
    return button
end

UI.PANEL_EDGE = { 0.69, 0.59, 0.38 }
UI.PANEL_EDGE_DIM = { 0.36, 0.31, 0.23 }
UI.WINDOW_BG = { 0.035, 0.03, 0.045, 0.97 }
UI.PANEL_BG = { 0.012, 0.01, 0.015, 0.75 }
local GOLD_HEADER_WIDTH = 300

function UI.GoldWindow(name, width, height)
    local frame = CreateFrame("Frame", name, UIParent)
    frame:SetFrameStrata("DIALOG")
    frame:SetWidth(width)
    frame:SetHeight(height)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    if frame.SetClampedToScreen then
        frame:SetClampedToScreen(true)
    end
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", function() this:StartMoving() end)
    frame:SetScript("OnDragStop", function() this:StopMovingOrSizing() end)
    frame:Hide()
    tinsert(UISpecialFrames, name)
    frame:SetBackdrop({ bgFile = UI.FLAT, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Gold-Border", tile = false, edgeSize = 32,
        insets = { left = 11, right = 11, top = 11, bottom = 11 } })
    frame:SetBackdropColor(UI.WINDOW_BG[1], UI.WINDOW_BG[2], UI.WINDOW_BG[3], UI.WINDOW_BG[4])

    frame.headerArt = frame:CreateTexture(nil, "ARTWORK")
    frame.headerArt:SetTexture("Interface\\DialogFrame\\UI-DialogBox-Gold-Header")
    frame.headerArt:SetWidth(GOLD_HEADER_WIDTH)
    frame.headerArt:SetHeight(64)
    frame.headerArt:SetPoint("TOP", frame, "TOP", 0, 12)
    frame.title = UI.Text(frame, 13)
    frame.title:SetPoint("TOP", frame.headerArt, "TOP", 0, -14)
    frame.title:SetTextColor(1, 0.82, 0)

    frame.close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
    frame.close:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -4, -4)
    frame.close:SetScript("OnClick", function() this:GetParent():Hide() end)
    return frame
end

function UI.Panel(parent, edge)
    local panel = CreateFrame("Frame", nil, parent)
    panel:SetBackdrop({ bgFile = UI.FLAT, edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border", tile = false, edgeSize = 16,
        insets = { left = 4, right = 4, top = 4, bottom = 4 } })
    panel:SetBackdropColor(UI.PANEL_BG[1], UI.PANEL_BG[2], UI.PANEL_BG[3], UI.PANEL_BG[4])
    edge = edge or UI.PANEL_EDGE
    panel:SetBackdropBorderColor(edge[1], edge[2], edge[3])
    return panel
end

function UI.Gradient(texture, direction, r, g, b, fromAlpha, toAlpha)
    texture:SetTexture(UI.FLAT)
    if texture.SetGradientAlpha then
        texture:SetGradientAlpha(direction, r, g, b, fromAlpha, r, g, b, toAlpha)
    else
        texture:SetVertexColor(r, g, b, (fromAlpha + toAlpha) / 2)
    end
end

function UI.Divider(parent, width)
    local holder = CreateFrame("Frame", nil, parent)
    holder:SetWidth(width)
    holder:SetHeight(1)
    holder.left = holder:CreateTexture(nil, "ARTWORK")
    holder.left:SetPoint("TOPLEFT", holder, "TOPLEFT", 0, 0)
    holder.left:SetWidth(width / 2)
    holder.left:SetHeight(1)
    UI.Gradient(holder.left, "HORIZONTAL", 0.78, 0.63, 0.27, 0, 0.8)
    holder.right = holder:CreateTexture(nil, "ARTWORK")
    holder.right:SetPoint("TOPRIGHT", holder, "TOPRIGHT", 0, 0)
    holder.right:SetWidth(width / 2)
    holder.right:SetHeight(1)
    UI.Gradient(holder.right, "HORIZONTAL", 0.78, 0.63, 0.27, 0.8, 0)
    return holder
end

local PANEL_TAB_HEIGHT = 30
local PANEL_TAB_PAD = 36
local PANEL_TAB_GAP = 5
local PANEL_TAB_OVERLAP = 5
local PANEL_TAB_CORNER = 3
local PANEL_TAB_BASE = { 0.02, 0.018, 0.022 }

local function ShadeTab(texture, top, bottom)
    texture:SetTexture(UI.FLAT)
    texture:SetGradient("VERTICAL", bottom[1], bottom[2], bottom[3], top[1], top[2], top[3])
end

local function TabLine(tab)
    local line = tab:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.FLAT)
    return line
end

local function PaintTabEdges(tab, r, g, b)
    for _, line in ipairs(tab.edges) do
        line:SetVertexColor(r, g, b, 1)
    end
end

local function StylePanelTab(tab, active, color)
    tab.active = active
    tab:SetHeight(active and PANEL_TAB_HEIGHT + PANEL_TAB_OVERLAP or PANEL_TAB_HEIGHT - 4)
    tab:ClearAllPoints()
    tab:SetPoint("BOTTOMLEFT", tab.set.panel, "TOPLEFT", tab.left, active and -PANEL_TAB_OVERLAP or -1)
    if active then
        ShadeTab(tab.fill, { 0.23, 0.19, 0.125 }, PANEL_TAB_BASE)
        PaintTabEdges(tab, 0.66, 0.54, 0.28)
        tab.label:SetTextColor(1, 1, 1)
        tab.label:ClearAllPoints()
        tab.label:SetPoint("CENTER", tab, "CENTER", 0, 2)
        local r, g, b = 1, 0.82, 0
        if color then
            r, g, b = color[1], color[2], color[3]
        end
        UI.Gradient(tab.glow, "VERTICAL", r, g, b, 0, 0.16)
        tab.glow:Show()
        tab.shine:Show()
    else
        ShadeTab(tab.fill, { 0.11, 0.098, 0.078 }, { 0.047, 0.043, 0.035 })
        PaintTabEdges(tab, 0.35, 0.29, 0.17)
        tab.label:SetTextColor(1, 0.82, 0)
        tab.label:ClearAllPoints()
        tab.label:SetPoint("CENTER", tab, "CENTER", 0, 0)
        tab.glow:Hide()
        tab.shine:Hide()
    end
end

local function CreatePanelTab(set, index, onClick)
    local tab = CreateFrame("Button", nil, set.panel)
    tab.set = set
    tab:SetFrameLevel(set.panel:GetFrameLevel() + 3)
    tab.fill = tab:CreateTexture(nil, "BACKGROUND")
    tab.fill:SetPoint("TOPLEFT", tab, "TOPLEFT", 1, -1)
    tab.fill:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", -1, 0)
    local top = TabLine(tab)
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", tab, "TOPLEFT", PANEL_TAB_CORNER, 0)
    top:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -PANEL_TAB_CORNER, 0)
    local left = TabLine(tab)
    left:SetWidth(1)
    left:SetPoint("TOPLEFT", tab, "TOPLEFT", 0, -PANEL_TAB_CORNER)
    left:SetPoint("BOTTOMLEFT", tab, "BOTTOMLEFT", 0, 0)
    local right = TabLine(tab)
    right:SetWidth(1)
    right:SetPoint("TOPRIGHT", tab, "TOPRIGHT", 0, -PANEL_TAB_CORNER)
    right:SetPoint("BOTTOMRIGHT", tab, "BOTTOMRIGHT", 0, 0)
    tab.edges = { top, left, right }
    for step = 1, PANEL_TAB_CORNER - 1 do
        for _, side in ipairs({ "LEFT", "RIGHT" }) do
            local dot = TabLine(tab)
            dot:SetWidth(1)
            dot:SetHeight(1)
            local x = side == "LEFT" and step or -step
            dot:SetPoint("TOP" .. side, tab, "TOP" .. side, x, -(PANEL_TAB_CORNER - step))
            tinsert(tab.edges, dot)
        end
    end
    tab.label = UI.Text(tab, 12)
    tab.glow = tab:CreateTexture(nil, "BORDER")
    tab.glow:SetPoint("TOPLEFT", tab, "TOPLEFT", 1, -1)
    tab.glow:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -1, -1)
    tab.glow:SetHeight(12)
    tab.shine = tab:CreateTexture(nil, "OVERLAY")
    tab.shine:SetPoint("TOPLEFT", tab, "TOPLEFT", 8, -1)
    tab.shine:SetPoint("TOPRIGHT", tab, "TOPRIGHT", -8, -1)
    tab.shine:SetHeight(1)
    tab.shine:SetTexture(UI.FLAT)
    tab.shine:SetVertexColor(1, 0.9, 0.6, 0.5)
    tab.index = index
    tab:SetScript("OnClick", function()
        if not this.active then
            PlaySound("igCharacterInfoTab")
            onClick(this.index)
        end
    end)
    return tab
end

function UI.PanelTabs(panel, x, onClick)
    local set = { tabs = {}, panel = panel }
    function set:SetTabs(labels)
        local left = x
        for index, label in ipairs(labels) do
            local tab = self.tabs[index] or CreatePanelTab(self, index, onClick)
            self.tabs[index] = tab
            tab.label:SetText(label)
            tab:SetWidth(tab.label:GetStringWidth() + PANEL_TAB_PAD)
            tab.left = left
            StylePanelTab(tab, tab.active, nil)
            tab:Show()
            left = left + tab:GetWidth() + PANEL_TAB_GAP
        end
        for index = table.getn(labels) + 1, table.getn(self.tabs) do
            self.tabs[index]:Hide()
        end
    end
    function set:Select(selected, color)
        for index, tab in ipairs(self.tabs) do
            StylePanelTab(tab, index == selected, color)
        end
    end
    return set
end

UI.INNKEEPER_ENTRY = 900140
UI.INNKEEPER_NAME = L["Tarn Oakhoof"]

local KEYCAP_TEXTURE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\KeyCap"
local KEYCAP_CAP_SHARE = 0.5
local KEYCAP_PAD_SHARE = 7 / 22

local function KeyCapPiece(cap, left, right, height)
    local piece = cap:CreateTexture(nil, "ARTWORK")
    piece:SetTexture(KEYCAP_TEXTURE)
    piece:SetTexCoord(left, right, 0, 1)
    piece:SetHeight(height)
    return piece
end

function UI.KeyCap(parent, height, textSize)
    height = height or 22
    local cap = CreateFrame("Frame", nil, parent)
    cap:SetHeight(height)
    cap.capHeight = height
    cap.left = KeyCapPiece(cap, 0, 0.25, height)
    cap.left:SetWidth(height * KEYCAP_CAP_SHARE)
    cap.left:SetPoint("LEFT", cap, "LEFT", 0, 0)
    cap.right = KeyCapPiece(cap, 0.75, 1, height)
    cap.right:SetWidth(height * KEYCAP_CAP_SHARE)
    cap.right:SetPoint("RIGHT", cap, "RIGHT", 0, 0)
    cap.middle = KeyCapPiece(cap, 0.25, 0.75, height)
    cap.middle:SetPoint("LEFT", cap.left, "RIGHT", 0, 0)
    cap.middle:SetPoint("RIGHT", cap.right, "LEFT", 0, 0)
    cap.text = UI.Text(cap, textSize or 11)
    cap.text:SetPoint("CENTER", cap, "CENTER", 0, 0)
    cap.text:SetTextColor(0.95, 0.92, 0.82)
    return cap
end

function UI.SetKeyCap(cap, text)
    cap.text:SetText(text)
    cap:SetWidth(math.max(cap.capHeight, cap.text:GetStringWidth() + 2 * KEYCAP_PAD_SHARE * cap.capHeight))
end

UI.CLASS_CRESTS = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\ClassCrests"
local CREST_ORDER = { "WARRIOR", "MAGE", "ROGUE", "DRUID", "HUNTER", "SHAMAN", "PRIEST", "WARLOCK", "PALADIN" }

function UI.SetRoundClassCrest(texture, class)
    for index, token in ipairs(CREST_ORDER) do
        if token == class then
            local column, row = mod(index - 1, 4), floor((index - 1) / 4)
            texture:SetTexture(UI.CLASS_CRESTS)
            texture:SetTexCoord(column / 4, (column + 1) / 4, row / 4, (row + 1) / 4)
            return
        end
    end
    UI.SetClassCrest(texture, class)
end

function UI.SetClassCrest(texture, class)
    local coords = UI.CLASS_COORDS[class or ""]
    if coords then
        texture:SetTexture(UI.CLASS_ICONS)
        texture:SetTexCoord(coords[1], coords[2], coords[3], coords[4])
    else
        texture:SetTexture(UI.ICON_PATH .. "INV_Misc_QuestionMark")
        texture:SetTexCoord(0, 1, 0, 1)
    end
end

local CAST_BORDER = "Interface\\CastingBar\\UI-CastingBar-Border"
function UI.CastRim(parent, width)
    local rim = CreateFrame("Frame", nil, parent)
    rim:SetWidth(width)
    rim:SetHeight(30)
    rim.art = CreateFrame("Frame", nil, rim)
    rim.art:SetAllPoints(rim)
    rim.art:SetFrameLevel(rim:GetFrameLevel() + 4)
    local function part(x1, x2)
        local texture = rim.art:CreateTexture(nil, "OVERLAY")
        texture:SetTexture(CAST_BORDER)
        texture:SetTexCoord(x1 / 256, x2 / 256, 17 / 64, 47 / 64)
        texture:SetHeight(30)
        return texture
    end
    rim.left = part(0, 36)
    rim.left:SetWidth(36)
    rim.left:SetPoint("TOPLEFT", rim, "TOPLEFT", 0, 0)
    rim.right = part(222, 256)
    rim.right:SetWidth(34)
    rim.right:SetPoint("TOPRIGHT", rim, "TOPRIGHT", 0, 0)
    rim.middle = part(36, 222)
    rim.middle:SetPoint("TOPLEFT", rim.left, "TOPRIGHT", 0, 0)
    rim.middle:SetPoint("BOTTOMRIGHT", rim.right, "BOTTOMLEFT", 0, 0)

    rim.opening = CreateFrame("Frame", nil, rim)
    rim.opening:SetPoint("TOPLEFT", rim, "TOPLEFT", 36, -11)
    rim.opening:SetPoint("BOTTOMRIGHT", rim, "BOTTOMRIGHT", -34, 9)
    rim.opening:SetFrameLevel(rim:GetFrameLevel() + 1)
    rim.back = rim.opening:CreateTexture(nil, "BACKGROUND")
    rim.back:SetTexture(UI.FLAT)
    rim.back:SetVertexColor(0, 0, 0, 0.75)
    rim.back:SetAllPoints(rim.opening)
    return rim
end

function UI.Ring(parent, size, minimapStyle)
    local ring = CreateFrame("Frame", nil, parent)
    ring:SetWidth(size)
    ring:SetHeight(size)
    ring.disc = ring:CreateTexture(nil, "BACKGROUND")
    ring.disc:SetTexture("Interface\\CharacterFrame\\TempPortraitAlphaMask")
    ring.disc:SetVertexColor(0.08, 0.05, 0.02)
    ring.minimapStyle = size >= 30 or minimapStyle
    if ring.minimapStyle then
        local inset = size * 10 / 148
        ring.disc:SetPoint("TOPLEFT", ring, "TOPLEFT", inset, -inset)
        ring.disc:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -inset, inset)
        ring.top = ring:CreateTexture(nil, "OVERLAY")
        ring.top:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
        ring.top:SetTexCoord(94 / 256, 242 / 256, 180 / 256, 106 / 256)
        ring.top:SetPoint("TOPLEFT", ring, "TOPLEFT", 0, 0)
        ring.top:SetPoint("BOTTOMRIGHT", ring, "RIGHT", 0, 0)
        ring.bottom = ring:CreateTexture(nil, "OVERLAY")
        ring.bottom:SetTexture("Interface\\Minimap\\UI-Minimap-Border")
        ring.bottom:SetTexCoord(94 / 256, 242 / 256, 106 / 256, 180 / 256)
        ring.bottom:SetPoint("TOPLEFT", ring, "LEFT", 0, 0)
        ring.bottom:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", 0, 0)
    else
        ring.disc:SetPoint("TOPLEFT", ring, "TOPLEFT", size * 0.16, -size * 0.16)
        ring.disc:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -size * 0.16, size * 0.16)
        ring.border = ring:CreateTexture(nil, "OVERLAY")
        ring.border:SetTexture("Interface\\Minimap\\MiniMap-TrackingBorder")
        ring.border:SetTexCoord(0, 40 / 64, 0, 40 / 64)
        ring.border:SetAllPoints(ring)
    end
    return ring
end

function UI.RingArt(ring, path, layer)
    local size = ring:GetWidth()
    local art = ring:CreateTexture(nil, layer or "BORDER")
    local inset = ring.minimapStyle and size * 10 / 148 or size * 0.16
    art:SetPoint("TOPLEFT", ring, "TOPLEFT", inset, -inset)
    art:SetPoint("BOTTOMRIGHT", ring, "BOTTOMRIGHT", -inset, inset)
    if art.SetMask then
        art:SetTexture(path)
        art:SetTexCoord(0.1, 0.9, 0.1, 0.9)
        art:SetMask("Textures\\MinimapMask")
    else
        local setTexture = art.SetTexture
        art.SetTexture = function(self, file)
            if file and file ~= "" and SetPortraitToTexture then
                SetPortraitToTexture(self, file)
            else
                setTexture(self, file)
            end
        end
        art:SetTexture(path)
    end
    return art
end

function UI.Option(key, default)
    local value = VanillaBonkOptions and VanillaBonkOptions[key]
    if value == nil then
        return default
    end
    return value
end

function UI.SetOption(key, value)
    VanillaBonkOptions = VanillaBonkOptions or {}
    VanillaBonkOptions[key] = value
end

UI.SHIELD_COLOR = { 0.45, 0.9, 1, 0.85 }

function UI.DressShield(bar)
    bar:SetStatusBarTexture("Interface\\TargetingFrame\\UI-StatusBar")
    bar:SetStatusBarColor(UI.SHIELD_COLOR[1], UI.SHIELD_COLOR[2], UI.SHIELD_COLOR[3], UI.SHIELD_COLOR[4])
    bar:GetStatusBarTexture():SetBlendMode("ADD")
    bar:SetMinMaxValues(0, 1)
end
