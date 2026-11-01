local FLAT = "Interface\\Buttons\\WHITE8X8"
local BAR = "Interface\\TargetingFrame\\UI-StatusBar"
local SKULL = "Interface\\TargetingFrame\\UI-TargetingFrame-Skull"
local NAME_FONT = "Fonts\\FRIZQT__.TTF"
local NUMBER_FONT = "Fonts\\ARIALN.TTF"
local PLATE_BORDER = "Interface\\Tooltips\\Nameplate-Border"
local PREFIX = "BONK~"
local UI = VanillaBonkUI
local ICON_PATH = "Interface\\Icons\\"

local REFRESH = 0.1
local ICON_SIZE = 13
local MAX_ICONS = 4

local STACK_INTERVAL = 0.05
local STACK_GAP_Y = 1
local STACK_GAP_X = 2
local STACK_MAX_LIFT = 80
local STACK_SPEED = 12
local STACK_HOLD = 8
local STACK_MAX_JUMPS = 32
local STACK_STEP = 0.5
local GRID_W = 64
local GRID_H = 16
local GRID_SPAN = 4096

local RIM_TOP = 14 / 32
local RIM_LIFT = 2
local BAR_INSET_X = 5
local BAR_INSET_Y = 6
local BAR_ROWS = 7

local ALLY_KIND = 4
local BRUISER_KIND = 5
local VETERAN_KIND = 6
local MUTED_OFFSET = 4000

local FRAME_LEVELS = { [0] = 1, [1] = 11, [2] = 21, [3] = 21, [ALLY_KIND] = 11, [BRUISER_KIND] = 3, [VETERAN_KIND] = 3 }

local SIZES = {
    [0] = { width = 78, height = 10, name = 0, percent = 0 },
    [1] = { width = 128, height = 14, name = 10.5, percent = 8.5 },
    [2] = { width = 168, height = 17, name = 12.5, percent = 10 },
    [3] = { width = 168, height = 17, name = 12.5, percent = 10 },
    [ALLY_KIND] = { width = 128, height = 14, name = 10.5, percent = 8.5 },
    [BRUISER_KIND] = { width = 78, height = 10, name = 0, percent = 0 },
    [VETERAN_KIND] = { width = 78, height = 10, name = 0, percent = 0 },
}

local DEBUFF_LOOKS = {
    [0] = UI.DEBUFF_LOOKS.small,
    [1] = UI.DEBUFF_LOOKS.plate,
    [2] = UI.DEBUFF_LOOKS.boss,
    [3] = UI.DEBUFF_LOOKS.boss,
    [ALLY_KIND] = UI.DEBUFF_LOOKS.plate,
    [BRUISER_KIND] = UI.DEBUFF_LOOKS.small,
    [VETERAN_KIND] = UI.DEBUFF_LOOKS.small,
}

local PLATE_HEALTH_BASE = 100000
local mobsByGuid = {}
local mobsById = {}
local mobs = {}
local NO_ICONS = {}
local allies = {}
local allyCount = 0
local allyPlatesForced = false

local stackPlates = {}
local stackSoon = false

local COLOR_HOSTILE = { 0.78, 0.16, 0.16 }
local COLOR_NEUTRAL = { 0.88, 0.72, 0.18 }
local COLOR_FRIENDLY = { 0.24, 0.70, 0.28 }
local KIND_COLORS = {
    [BRUISER_KIND] = { 0.87, 0.47, 0.12 },
    [VETERAN_KIND] = { 0.27, 0.51, 0.92 },
}

local function IsPlainKind(kind)
    return kind == 0 or KIND_COLORS[kind] ~= nil
end

local function IsNameplate(frame)
    if frame:GetName() then
        return false
    end
    local border = frame:GetRegions()
    return border and border.GetObjectType and border:GetObjectType() == "Texture" and border:GetTexture() == PLATE_BORDER
end

local function Recolor(plate)
    local health = plate.vbHealth
    local r, g, b = health:GetStatusBarColor()
    local color
    if r > 0.9 and g < 0.2 and b < 0.2 then
        color = COLOR_HOSTILE
    elseif r > 0.9 and g > 0.9 and b < 0.2 then
        color = COLOR_NEUTRAL
    elseif r < 0.2 and g > 0.9 and b < 0.2 then
        color = COLOR_FRIENDLY
    end
    if color then
        plate.vbFriendly = color == COLOR_FRIENDLY
        health:SetStatusBarColor(color[1], color[2], color[3])
    end
end

local function TintKind(plate)
    local color = not plate.vbFriendly and KIND_COLORS[plate.vbKind]
    if color then
        local r, g, b = plate.vbHealth:GetStatusBarColor()
        if abs(r - color[1]) + abs(g - color[2]) + abs(b - color[3]) > 0.01 then
            plate.vbHealth:SetStatusBarColor(color[1], color[2], color[3])
        end
        plate.vbTinted = true
    elseif plate.vbTinted then
        plate.vbTinted = nil
        local base = plate.vbFriendly and COLOR_FRIENDLY or COLOR_HOSTILE
        plate.vbHealth:SetStatusBarColor(base[1], base[2], base[3])
    end
end

local function KeepColor(plate)
    local r, g, b = plate.vbHealth:GetStatusBarColor()
    if plate.vbColorR == r and plate.vbColorG == g and plate.vbColorB == b and plate.vbColorKind == plate.vbKind then
        return
    end
    Recolor(plate)
    TintKind(plate)
    plate.vbColorR, plate.vbColorG, plate.vbColorB = plate.vbHealth:GetStatusBarColor()
    plate.vbColorKind = plate.vbKind
end

local function PlaceHealth(plate, lift)
    plate.vbHealth:SetPoint("CENTER", plate, "CENTER", 0, lift - 4 + (plate.vbMuted and MUTED_OFFSET or 0))
end

local function IsPartyName(name)
    if not name or name == "" then
        return false
    end
    for index = 1, GetNumPartyMembers() do
        if UnitName("party" .. index) == name then
            return true
        end
    end
    return false
end

local function WantsPartyPlates()
    return VanillaBonkUI.InRun() and VanillaBonkUI.Option("partyPlates", true) and GetNumPartyMembers() > 0
end

local function FriendlyMuted(plate)
    if not plate.vbFriendly or plate.vbKind == ALLY_KIND then
        return false
    end
    if not VanillaBonkUI.InRun() then
        return true
    end
    if IsPartyName(plate.vbName:GetText()) then
        return not VanillaBonkUI.Option("partyPlates", true)
    end
    return allyPlatesForced and not FRIENDNAMEPLATES_ON
end

local function UpdateMuted(plate)
    local muted = FriendlyMuted(plate)
    if plate.vbMuted ~= muted then
        plate.vbMuted = muted
        PlaceHealth(plate, plate.vbShownLift or 0)
    end
end

local function UpdateText(plate)
    local health = plate.vbHealth
    local _, maxValue = health:GetMinMaxValues()
    local value = health:GetValue()
    if maxValue and maxValue > 0 then
        plate.vbPercent:SetText(floor(value / maxValue * 100 + 0.5) .. "%")
    else
        plate.vbPercent:SetText("")
    end
end

local function HideDefaults(plate)
    plate.vbBorder:Hide()
    plate.vbLevel:Hide()
    if plate.vbSkull then
        plate.vbSkull:Hide()
    end
end

local function LayoutLost(plate)
    local health = plate.vbHealth
    return abs(health:GetWidth() - plate.vbBarWidth) > 0.5 or abs(health:GetHeight() - plate.vbBarHeight) > 0.5 or
        plate.vbName:GetWidth() > 0.01
end

local function PlaceDebuffRow(row, health, sy)
    row:ClearAllPoints()
    row:SetPoint("TOPLEFT", health, "BOTTOMLEFT", 0, -((32 - 14 - BAR_INSET_Y - BAR_ROWS) * sy + 1))
end

local function UpdateStackExtent(plate)
    local size, sy = plate.vbSize, plate.vbScaleY
    local rimTop = plate.vbBarHeight / 2 + BAR_INSET_Y * sy
    plate.vbStackWidth = size.width
    plate.vbStackBelow = (32 - 14) * sy - rimTop
    plate.vbStackAbove = rimTop
    if size.name > 0 then
        plate.vbStackAbove = plate.vbStackAbove + size.name + 2
    end
    if plate.vbIconCount > 0 then
        plate.vbStackAbove = plate.vbStackAbove + ICON_SIZE + 3
    end
    if plate.vbDebuffRow.height > 0 then
        plate.vbStackBelow = plate.vbStackBelow + plate.vbDebuffRow.height + 1
    end
end

local function PlateUnit(plate)
    local unit = plate.vbUnit
    if not unit or not plate.vbGuid then
        return nil
    end
    if UnitGUID(unit) ~= plate.vbGuid then
        unit = UnitTokenFromGUID and UnitTokenFromGUID(plate.vbGuid)
        plate.vbUnit = unit
    end
    return unit
end

local function UpdateDebuffs(plate)
    local row = plate.vbDebuffRow
    local count = 0
    if not plate.vbFriendly then
        count = UI.ReadKeywordDebuffs(PlateUnit(plate), plate.vbDebuffList)
    end
    if count == 0 and row.count == 0 then
        return
    end
    local before = row.height
    row:SetDebuffs(plate.vbDebuffList, count)
    if row.height ~= before then
        UpdateStackExtent(plate)
    end
end

local function ApplyKind(plate)
    local mob = plate.vbGuid and mobsByGuid[plate.vbGuid]
    if not mob then
        local _, maxValue = plate.vbHealth:GetMinMaxValues()
        if maxValue and maxValue > PLATE_HEALTH_BASE then
            mob = mobsById[maxValue - PLATE_HEALTH_BASE]
        elseif not plate.vbGuid then
            mob = mobs[plate.vbName:GetText() or ""]
        end
    end
    local kind = mob and mob.kind or 0
    local icons = mob and mob.icons or NO_ICONS
    if plate.vbKind == kind and plate.vbIcons == icons and not LayoutLost(plate) then
        return
    end
    plate.vbKind = kind
    plate.vbIcons = icons

    local size = SIZES[kind] or SIZES[0]
    local sx, sy = size.width / 128, size.height / 15
    local health = plate.vbHealth
    plate.vbSize, plate.vbScaleY = size, sy
    plate.vbBarWidth = (128 - 2 * BAR_INSET_X) * sx
    plate.vbBarHeight = BAR_ROWS * sy
    health:ClearAllPoints()
    plate.vbShownLift = plate.vbLift or 0
    PlaceHealth(plate, plate.vbShownLift)
    health:SetWidth(plate.vbBarWidth)
    health:SetHeight(plate.vbBarHeight)

    local level = FRAME_LEVELS[kind] or FRAME_LEVELS[0]
    plate:SetFrameLevel(level)
    health:SetFrameLevel(level + 1)
    plate.vbRimFrame:SetFrameLevel(level + 2)

    local left, right = plate.vbRim[1], plate.vbRim[2]
    for _, piece in ipairs(plate.vbRim) do
        piece:SetWidth(size.width / 2)
        piece:SetHeight((32 - 14) * sy)
        SetDesaturation(piece, IsPlainKind(kind))
    end
    left:ClearAllPoints()
    left:SetPoint("TOPLEFT", health, "TOPLEFT", -BAR_INSET_X * sx, BAR_INSET_Y * sy)
    right:ClearAllPoints()
    right:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)

    local boss = kind == 2 or kind == 3
    plate.vbName:SetWidth(0.001)
    local title = plate.vbTitle
    title:ClearAllPoints()
    title:SetPoint("BOTTOM", health, "TOP", 0, (BAR_INSET_Y - RIM_LIFT) * sy + 1)
    if size.name > 0 then
        title:SetFont(NAME_FONT, size.name, "OUTLINE")
        title:Show()
        plate.vbPercent:SetFont(NUMBER_FONT, size.percent, "OUTLINE")
        plate.vbPercent:Show()
    else
        title:Hide()
        plate.vbPercent:Hide()
    end
    if boss then
        title:SetTextColor(1, 0.82, 0)
        plate.vbBossSkull:ClearAllPoints()
        plate.vbBossSkull:SetPoint("RIGHT", health, "LEFT", -BAR_INSET_X * sx - 3, 0)
        plate.vbBossSkull:Show()
    else
        title:SetTextColor(1, 1, 1)
        plate.vbBossSkull:Hide()
    end

    local count = min(getn(icons), MAX_ICONS)
    plate.vbIconCount = count
    plate.vbStackRank = boss and 0 or (kind == 1 and 1 or 2)

    for index = 1, MAX_ICONS do
        local slot = plate.vbIconSlots[index]
        if index <= count then
            slot.icon:SetTexture(ICON_PATH .. icons[index])
            slot.icon:ClearAllPoints()
            slot.icon:SetPoint("BOTTOM", title, "TOP", (index - (count + 1) / 2) * (ICON_SIZE + 3), 3)
            slot.icon:Show()
            slot.back:Show()
        else
            slot.icon:Hide()
            slot.back:Hide()
        end
    end

    UI.SetDebuffRowLook(plate.vbDebuffRow, DEBUFF_LOOKS[kind] or DEBUFF_LOOKS[0])
    plate.vbDebuffRow:SetDebuffs(plate.vbDebuffList, plate.vbDebuffRow.count)
    PlaceDebuffRow(plate.vbDebuffRow, health, sy)
    UpdateStackExtent(plate)
end

local function Refresh(plate)
    HideDefaults(plate)
    Recolor(plate)
    UpdateText(plate)
    ApplyKind(plate)
    TintKind(plate)
    UpdateMuted(plate)
    UpdateDebuffs(plate)
    if plate.vbTitle:IsShown() then
        plate.vbTitle:SetText(plate.vbName:GetText())
    end

    if plate.vbGlow and plate.vbGlow:IsShown() then
        plate.vbLight:Show()
    else
        plate.vbLight:Hide()
    end
end

local function Style(plate)
    plate.vbStyled = true

    local border, glow, name, level, skull, raid = plate:GetRegions()
    local health = plate:GetChildren()
    if not health or not name or not level then
        return
    end
    plate.vbBorder, plate.vbGlow, plate.vbLevel, plate.vbSkull, plate.vbHealth = border, glow, level, skull, health
    plate.vbName = name

    border:SetTexture(nil)
    if glow then
        glow:SetTexture(nil)
    end

    health:SetStatusBarTexture(BAR)
    plate.vbBarWidth, plate.vbBarHeight = 0, 0

    local back = health:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(FLAT)
    back:SetVertexColor(0.05, 0.04, 0.03, 0.86)
    back:SetAllPoints(health)

    local light = health:CreateTexture(nil, "OVERLAY")
    light:SetTexture(FLAT)
    light:SetVertexColor(1, 1, 1, 0.43)
    light:SetAllPoints(health)
    light:Hide()
    plate.vbLight = light

    local rim = CreateFrame("Frame", nil, health)
    rim:SetAllPoints(health)
    rim:SetFrameLevel(health:GetFrameLevel() + 1)
    plate.vbRimFrame = rim
    plate.vbRim = {}
    for index = 1, 2 do
        local piece = rim:CreateTexture(nil, "ARTWORK")
        piece:SetTexture(PLATE_BORDER)
        if index == 1 then
            piece:SetTexCoord(0, 0.5, RIM_TOP, 1)
        else
            piece:SetTexCoord(0.5, 0, RIM_TOP, 1)
        end
        plate.vbRim[index] = piece
    end

    local percent = rim:CreateFontString(nil, "OVERLAY")
    percent:SetFont(NUMBER_FONT, 9, "OUTLINE")
    percent:SetPoint("RIGHT", health, "RIGHT", -2, 0)
    percent:SetTextColor(1, 1, 1)
    plate.vbPercent = percent

    local bossSkull = rim:CreateTexture(nil, "ARTWORK")
    bossSkull:SetTexture(SKULL)
    bossSkull:SetWidth(16)
    bossSkull:SetHeight(16)
    bossSkull:Hide()
    plate.vbBossSkull = bossSkull

    plate.vbIconSlots = {}
    for index = 1, MAX_ICONS do
        local icon = rim:CreateTexture(nil, "ARTWORK")
        icon:SetWidth(ICON_SIZE)
        icon:SetHeight(ICON_SIZE)
        icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
        icon:Hide()
        local edge = rim:CreateTexture(nil, "BACKGROUND")
        edge:SetTexture(FLAT)
        edge:SetVertexColor(0, 0, 0, 1)
        edge:SetWidth(ICON_SIZE + 2)
        edge:SetHeight(ICON_SIZE + 2)
        edge:SetPoint("CENTER", icon, "CENTER", 0, 0)
        edge:Hide()
        plate.vbIconSlots[index] = { icon = icon, back = edge }
    end
    plate.vbDebuffRow = UI.DebuffRow(rim, DEBUFF_LOOKS[0])
    plate.vbDebuffList = {}

    local title = rim:CreateFontString(nil, "OVERLAY")
    title:SetFont(NAME_FONT, 11, "OUTLINE")
    title:SetShadowOffset(0, 0)
    plate.vbTitle = title

    if raid then
        raid:ClearAllPoints()
        raid:SetPoint("RIGHT", health, "LEFT", -8, 0)
        raid:SetWidth(16)
        raid:SetHeight(16)
    end

    plate.vbTimer = 0
    plate:SetScript("OnShow", function()
        this.vbKind = nil
        this.vbFriendly = nil
        this.vbColorR = nil
        this.vbLift, this.vbTargetLift, this.vbPlaced = 0, 0, nil
        stackSoon = true
        Refresh(this)
    end)
    plate:SetScript("OnUpdate", function()
        if this:GetWidth() > 1 then
            this:SetWidth(1)
            this:SetHeight(1)
        end
        local lift, target = this.vbLift, this.vbTargetLift
        if lift ~= target then
            lift = lift + (target - lift) * min(1, arg1 * STACK_SPEED)
            if abs(target - lift) < 0.25 then
                lift = target
            end
            this.vbLift = lift
            if lift == target or abs(lift - this.vbShownLift) >= STACK_STEP then
                this.vbShownLift = lift
                PlaceHealth(this, lift)
            end
        end
        if this.vbHealth then
            KeepColor(this)
        end
        this.vbTimer = this.vbTimer + arg1
        if this.vbTimer >= REFRESH then
            this.vbTimer = 0
            Refresh(this)
        end
    end)
    health:SetScript("OnValueChanged", function()
        local owner = this:GetParent()
        Recolor(owner)
        TintKind(owner)
        UpdateText(owner)
    end)

    plate:SetWidth(1)
    plate:SetHeight(1)
    plate.vbLift, plate.vbTargetLift, plate.vbShownLift = 0, 0, 0
    if plate.vbPendingGuid then
        plate.vbGuid, plate.vbUnit = plate.vbPendingGuid, plate.vbPendingUnit
        plate.vbPendingGuid, plate.vbPendingUnit = nil, nil
    end
    tinsert(stackPlates, plate)
    Refresh(plate)
end

local stackOrder = {}
local grid = {}
local gridKeys = {}
local gridKeyCount = 0
local seenStamp = 0

local function StackBefore(a, b)
    if a.vbStackRank ~= b.vbStackRank then
        return a.vbStackRank < b.vbStackRank
    end
    return a.vbStackKey < b.vbStackKey
end

local function ClearGrid()
    for index = 1, gridKeyCount do
        grid[gridKeys[index]].n = 0
    end
    gridKeyCount = 0
end

local function AddToGrid(plate)
    local half = plate.vbStackWidth / 2
    local x, y = plate.vbBaseX, plate.vbStackY
    for cx = floor((x - half) / GRID_W), floor((x + half) / GRID_W) do
        for cy = floor((y - plate.vbStackBelow) / GRID_H), floor((y + plate.vbStackAbove) / GRID_H) do
            local key = cx * GRID_SPAN + cy
            local cell = grid[key]
            if not cell then
                cell = { n = 0 }
                grid[key] = cell
            end
            if cell.n == 0 then
                gridKeyCount = gridKeyCount + 1
                gridKeys[gridKeyCount] = key
            end
            cell.n = cell.n + 1
            cell[cell.n] = plate
        end
    end
end

local function FindOverlap(x, y, halfWidth, below, above)
    seenStamp = seenStamp + 1
    for cx = floor((x - halfWidth - STACK_GAP_X) / GRID_W), floor((x + halfWidth + STACK_GAP_X) / GRID_W) do
        for cy = floor((y - below - STACK_GAP_Y) / GRID_H), floor((y + above + STACK_GAP_Y) / GRID_H) do
            local cell = grid[cx * GRID_SPAN + cy]
            if cell then
                for index = 1, cell.n do
                    local o = cell[index]
                    if o.vbSeen ~= seenStamp then
                        o.vbSeen = seenStamp
                        if abs(o.vbBaseX - x) < halfWidth + o.vbStackWidth / 2 + STACK_GAP_X and
                            y - below < o.vbStackY + o.vbStackAbove + STACK_GAP_Y and
                            y + above > o.vbStackY - o.vbStackBelow - STACK_GAP_Y then
                            return o
                        end
                    end
                end
            end
        end
    end
    return nil
end

local function LayoutPlates()
    local count = 0
    for _, plate in ipairs(stackPlates) do
        if plate.vbStackWidth and plate:IsVisible() and not plate.vbMuted then
            local x, y = plate:GetCenter()
            if x then
                plate.vbBaseX, plate.vbBaseY = x, y - 4
                plate.vbStackKey = plate.vbBaseY + min(plate.vbTargetLift, STACK_HOLD)
                count = count + 1
                stackOrder[count] = plate
            end
        end
    end
    for index = getn(stackOrder), count + 1, -1 do
        stackOrder[index] = nil
    end
    sort(stackOrder, StackBefore)

    ClearGrid()
    for index = 1, count do
        local plate = stackOrder[index]
        local x, baseY = plate.vbBaseX, plate.vbBaseY
        local halfWidth = plate.vbStackWidth / 2
        local below, above = plate.vbStackBelow, plate.vbStackAbove
        local y = baseY
        local jumps = 0
        local other = FindOverlap(x, y, halfWidth, below, above)
        while other and jumps < STACK_MAX_JUMPS do
            y = other.vbStackY + other.vbStackAbove + STACK_GAP_Y + below
            jumps = jumps + 1
            if y - baseY > STACK_MAX_LIFT then
                break
            end
            other = FindOverlap(x, y, halfWidth, below, above)
        end
        if y - baseY > STACK_MAX_LIFT then
            y = baseY + STACK_MAX_LIFT
        end
        plate.vbStackY = y
        AddToGrid(plate)

        plate.vbTargetLift = y - baseY
        if not plate.vbPlaced then
            plate.vbPlaced = true
            plate.vbLift = plate.vbTargetLift
            plate.vbShownLift = plate.vbLift
            PlaceHealth(plate, plate.vbLift)
        end
    end
end

local PLATE_PICK_BELOW = 30
local PLATE_PICK_ABOVE = 140

function VanillaBonkUI.PlateTopAbove(screenX, screenY)
    local bestTop, bestDistance
    for _, plate in ipairs(stackPlates) do
        if plate.vbStackWidth and plate:IsVisible() and not plate.vbMuted then
            local x, y = plate.vbHealth:GetCenter()
            if x then
                local scale = plate.vbHealth:GetEffectiveScale()
                x, y = x * scale, y * scale
                local rise = y - screenY
                local reach = plate.vbStackWidth / 2 * scale
                if abs(x - screenX) <= reach and rise >= -PLATE_PICK_BELOW * scale and rise <= PLATE_PICK_ABOVE * scale then
                    local distance = abs(x - screenX) + abs(rise)
                    if not bestDistance or distance < bestDistance then
                        bestDistance = distance
                        bestTop = y + plate.vbStackAbove * scale
                    end
                end
            end
        end
    end
    return bestTop
end

local scanner = CreateFrame("Frame")
local knownChildren = 0
local stackTimer = 0
scanner:SetScript("OnUpdate", function()
    local count = WorldFrame:GetNumChildren()
    if count ~= knownChildren then
        knownChildren = count
        local children = { WorldFrame:GetChildren() }
        for _, frame in ipairs(children) do
            if not frame.vbStyled and IsNameplate(frame) then
                Style(frame)
            end
        end
    end

    stackTimer = stackTimer + arg1
    if stackTimer >= STACK_INTERVAL or stackSoon then
        stackTimer = 0
        stackSoon = false
        LayoutPlates()
    end
end)

scanner:RegisterEvent("PLAYER_ENTERING_WORLD")
function VanillaBonkUI.ApplyEnemyPlates()
    if VanillaBonkUI.Option("enemyPlates", true) then
        ShowNameplates()
        NAMEPLATES_ON = 1
    else
        HideNameplates()
        NAMEPLATES_ON = nil
    end
end

scanner:SetScript("OnEvent", function()
    VanillaBonkUI.ApplyEnemyPlates()
    this:UnregisterEvent("PLAYER_ENTERING_WORLD")
end)

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

local function OnPlateUnit(token, guid)
    local plate = C_NamePlate.GetNamePlateForUnit(token)
    if not plate then
        return
    end
    if not plate.vbStyled and IsNameplate(plate) then
        Style(plate)
    end
    if plate.vbHealth then
        plate.vbGuid = guid
        plate.vbUnit = guid and token
        plate.vbKind = nil
        Refresh(plate)
    else
        plate.vbPendingGuid = guid
        plate.vbPendingUnit = guid and token
    end
end

if C_NamePlate and C_NamePlate.GetNamePlateForUnit and UnitGUID then
    local units = CreateFrame("Frame")
    units:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    units:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    units:SetScript("OnEvent", function()
        if not arg1 then
            return
        end
        if event == "NAME_PLATE_UNIT_ADDED" then
            OnPlateUnit(arg1, UnitGUID(arg1))
        else
            OnPlateUnit(arg1, nil)
        end
    end)
end

local handlers = {}

handlers["mob"] = function(f)
    local name = f[3]
    if not name then
        return
    end
    local icons = {}
    for _, icon in ipairs(Split(f[4] or "", ",")) do
        if icon ~= "" then
            tinsert(icons, icon)
        end
    end
    local kind = tonumber(f[2]) or 1
    local id = tonumber(f[5] or "")
    if id and id > 0 then
        mobsById[id] = { kind = kind, icons = icons }
    end
    if f[6] and f[6] ~= "" then
        mobsByGuid[f[6]] = { kind = kind, icons = icons }
    end
    if IsPlainKind(kind) then
        return
    end
    local mob = mobs[name]
    mobs[name] = { kind = kind, icons = icons, alive = (mob and mob.alive or 0) + 1 }
end

function VanillaBonkUI.SamplePlate(parent, kind, name, icons, customSize, debuffs)
    local size = customSize or SIZES[kind] or SIZES[0]
    local sx, sy = size.width / 128, size.height / 15
    local health = CreateFrame("StatusBar", nil, parent)
    health:SetStatusBarTexture(BAR)
    health:SetWidth((128 - 2 * BAR_INSET_X) * sx)
    health:SetHeight(BAR_ROWS * sy)
    health:SetMinMaxValues(0, 100)
    health:SetValue(80)
    local color = KIND_COLORS[kind] or COLOR_HOSTILE
    health:SetStatusBarColor(color[1], color[2], color[3])

    local back = health:CreateTexture(nil, "BACKGROUND")
    back:SetTexture(FLAT)
    back:SetVertexColor(0.05, 0.04, 0.03, 0.86)
    back:SetAllPoints(health)

    local rim = CreateFrame("Frame", nil, health)
    rim:SetAllPoints(health)
    rim:SetFrameLevel(health:GetFrameLevel() + 1)
    local left
    for index = 1, 2 do
        local piece = rim:CreateTexture(nil, "ARTWORK")
        piece:SetTexture(PLATE_BORDER)
        piece:SetWidth(size.width / 2)
        piece:SetHeight((32 - 14) * sy)
        SetDesaturation(piece, IsPlainKind(kind))
        if index == 1 then
            piece:SetTexCoord(0, 0.5, RIM_TOP, 1)
            piece:SetPoint("TOPLEFT", health, "TOPLEFT", -BAR_INSET_X * sx, BAR_INSET_Y * sy)
            left = piece
        else
            piece:SetTexCoord(0.5, 0, RIM_TOP, 1)
            piece:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
        end
    end

    if size.name > 0 and name then
        local title = rim:CreateFontString(nil, "OVERLAY")
        title:SetFont(NAME_FONT, size.name, "OUTLINE")
        title:SetPoint("BOTTOM", health, "TOP", 0, (BAR_INSET_Y - RIM_LIFT) * sy + 1)
        title:SetText(name)
        local percent = rim:CreateFontString(nil, "OVERLAY")
        percent:SetFont(NUMBER_FONT, size.percent, "OUTLINE")
        percent:SetPoint("RIGHT", health, "RIGHT", -2, 0)
        percent:SetText("80%")
        local count = icons and min(getn(icons), MAX_ICONS) or 0
        for index = 1, count do
            local icon = rim:CreateTexture(nil, "ARTWORK")
            icon:SetTexture(ICON_PATH .. icons[index])
            icon:SetWidth(ICON_SIZE)
            icon:SetHeight(ICON_SIZE)
            icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
            icon:SetPoint("BOTTOM", title, "TOP", (index - (count + 1) / 2) * (ICON_SIZE + 3), 3)
            local edge = rim:CreateTexture(nil, "BACKGROUND")
            edge:SetTexture(FLAT)
            edge:SetVertexColor(0, 0, 0, 1)
            edge:SetWidth(ICON_SIZE + 2)
            edge:SetHeight(ICON_SIZE + 2)
            edge:SetPoint("CENTER", icon, "CENTER", 0, 0)
        end
    end
    if debuffs and getn(debuffs) > 0 then
        local row = UI.DebuffRow(rim, DEBUFF_LOOKS[kind] or DEBUFF_LOOKS[0])
        row:SetDebuffs(debuffs, getn(debuffs))
        PlaceDebuffRow(row, health, sy)
    end
    return health
end

handlers["mobdead"] = function(f)
    local id = tonumber(f[3] or "")
    if id then
        mobsById[id] = nil
    end
    if f[4] then
        mobsByGuid[f[4]] = nil
    end
    local mob = f[2] and mobs[f[2]]
    if mob then
        mob.alive = mob.alive - 1
        if mob.alive <= 0 then
            mobs[f[2]] = nil
        end
    end
end

local function RefreshAllPlates()
    for _, plate in ipairs(stackPlates) do
        if plate.vbHealth then
            plate.vbKind = nil
            Refresh(plate)
        end
    end
end

local function WantsFriendlyPlates()
    return allyCount > 0 or WantsPartyPlates()
end

local function UpdateFriendlyPlates()
    if WantsFriendlyPlates() then
        if allyPlatesForced or FRIENDNAMEPLATES_ON then
            RefreshAllPlates()
            return
        end
        allyPlatesForced = true
        ShowFriendNameplates()
        RefreshAllPlates()
        return
    end
    if not allyPlatesForced then
        RefreshAllPlates()
        return
    end
    allyPlatesForced = false
    if not FRIENDNAMEPLATES_ON then
        HideFriendNameplates()
        if NAMEPLATES_ON then
            ShowNameplates()
        end
    end
    RefreshAllPlates()
end

local function ShowAllyPlates()
    UpdateFriendlyPlates()
end

local function ReleaseAllyPlates()
    UpdateFriendlyPlates()
end

VanillaBonkUI.ApplyPartyPlates = UpdateFriendlyPlates

local partyWatch = CreateFrame("Frame")
local partyWatchTimer = 0
local partyWatchWanted = false
partyWatch:SetScript("OnUpdate", function()
    partyWatchTimer = partyWatchTimer + arg1
    if partyWatchTimer < 0.5 then
        return
    end
    partyWatchTimer = 0
    local wanted = WantsFriendlyPlates()
    if wanted ~= partyWatchWanted then
        partyWatchWanted = wanted
        UpdateFriendlyPlates()
    end
end)

local function ForgetAlly(id)
    local guid = allies[id]
    if guid == nil then
        return
    end
    allies[id] = nil
    allyCount = allyCount - 1
    mobsById[id] = nil
    if guid ~= "" then
        mobsByGuid[guid] = nil
    end
end

handlers["ally"] = function(f)
    local id = tonumber(f[3] or "")
    if not id or id <= 0 then
        return
    end
    local guid = f[4] or ""
    local ally = { kind = ALLY_KIND, icons = NO_ICONS }
    mobsById[id] = ally
    if guid ~= "" then
        mobsByGuid[guid] = ally
    end
    if allies[id] == nil then
        allyCount = allyCount + 1
    end
    allies[id] = guid
    ShowAllyPlates()
end

handlers["allydone"] = function(f)
    local id = tonumber(f[2] or "")
    if id then
        ForgetAlly(id)
    else
        for each in pairs(allies) do
            ForgetAlly(each)
        end
    end
    if allyCount <= 0 then
        allyCount = 0
        ReleaseAllyPlates()
    end
end

handlers["mobclear"] = function()
    mobsByGuid = {}
    mobsById = {}
    mobs = {}
    allies = {}
    allyCount = 0
    ReleaseAllyPlates()
end

local events = CreateFrame("Frame")
events:RegisterEvent("CHAT_MSG_SYSTEM")
events:SetScript("OnEvent", function()
    if not arg1 or strsub(arg1, 1, strlen(PREFIX)) ~= PREFIX then
        return
    end
    local start = strlen(PREFIX) + 1
    local stop = strfind(arg1, "~", start, true)
    local handler = handlers[strsub(arg1, start, stop and stop - 1 or -1)]
    if handler then
        handler(Split(strsub(arg1, start), "~"))
    end
end)
