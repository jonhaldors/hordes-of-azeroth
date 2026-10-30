local L = VanillaBonkL
local UI = VanillaBonkUI

local WIDTH, HEIGHT = 720, 496
local VIEW_LEFT, VIEW_TOP = 20, 74
local VIEW_WIDTH, VIEW_HEIGHT = 690, 372
local LIST_TOP = VIEW_TOP + VIEW_HEIGHT + 6
local LIST_ROWS = 4
local LIST_GAP = 6
local LIST_HEIGHT = 28
local MAP_WIDTH, MAP_HEIGHT = 1002, 668
local TILE = 256
local TILE_COLUMNS, TILE_ROWS = 4, 3
local ZOOMS = { 1, 1.4, 1.8, 2.2, 2.7, 3.2 }
local DEFAULT_ZOOM = 3
local PIN_SIZE, SMALL_PIN_SIZE = 24, 18
local EDGE = 16
local ARROW_SIZE = 40
local UPDATE_INTERVAL = 0.03

local window = UI.Window("VanillaBonkMap", WIDTH, HEIGHT)
window:SetFrameStrata("FULLSCREEN_DIALOG")
window:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
window.header:SetText(L["Mouse wheel zooms in and out."])
window.header:SetTextColor(0.7, 0.7, 0.7)

local view = CreateFrame("Frame", nil, window)
view:SetPoint("TOPLEFT", window, "TOPLEFT", VIEW_LEFT, -VIEW_TOP)
view:SetWidth(VIEW_WIDTH)
view:SetHeight(VIEW_HEIGHT)
view:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
view:SetBackdropColor(0, 0, 0, 1)
view:SetBackdropBorderColor(0, 0, 0, 1)
view:EnableMouseWheel(true)

local INNER_WIDTH, INNER_HEIGHT = VIEW_WIDTH - 2, VIEW_HEIGHT - 2

local function Piece(layer, left, top, width, height, uMax, vMax)
    local piece = view:CreateTexture(nil, layer)
    piece.left, piece.top, piece.width, piece.height = left, top, width, height
    piece.uMax, piece.vMax = uMax, vMax
    piece:Hide()
    return piece
end

local tiles = {}
for index = 1, TILE_COLUMNS * TILE_ROWS do
    tiles[index] = Piece("ARTWORK", mod(index - 1, TILE_COLUMNS) * TILE, floor((index - 1) / TILE_COLUMNS) * TILE, TILE, TILE, 1, 1)
end

local explored = {}
local exploredCount = 0

local overlay = CreateFrame("Frame", nil, view)
overlay:SetAllPoints(view)
overlay:SetFrameLevel(view:GetFrameLevel() + 2)

local heroLayer = CreateFrame("Frame", nil, view)
heroLayer:SetAllPoints(view)
heroLayer:SetFrameLevel(overlay:GetFrameLevel() + 10)

local hero = heroLayer:CreateTexture(nil, "OVERLAY")
hero:SetTexture("Interface\\Minimap\\MinimapArrow")
hero:SetWidth(ARROW_SIZE)
hero:SetHeight(ARROW_SIZE)

local noMap = UI.Text(overlay, 13)
noMap:SetPoint("CENTER", view, "CENTER", 0, 0)
noMap:SetTextColor(1, 0.82, 0)
noMap:SetText(L["There is no map for this place."])

local worldButton = UI.Button(window, 110, L["World Map"])
worldButton:SetPoint("TOPRIGHT", window, "TOPRIGHT", -14, -38)

local mapFile
local zoneId
local zoom = DEFAULT_ZOOM
local originX, originY = 0, 0
local mapPins = {}
local sparePins = { normal = {}, small = {} }
local rows = {}

local function IsSmall(objective)
    return UI.SMALL_OBJECTIVE_KINDS[objective.kind]
end

local function Scale()
    return ZOOMS[zoom]
end

local function CurrentZoneMapFile()
    SetMapToCurrentZone()
    if GetCurrentMapZone() == 0 then
        return nil
    end
    local file = GetMapInfo()
    return file ~= "" and file or nil
end

local function PieceSize(index, count, total)
    if index < count then
        return TILE, TILE
    end
    local pixels = mod(total, TILE)
    if pixels == 0 then
        pixels = TILE
    end
    local file = 16
    while file < pixels do
        file = file * 2
    end
    return pixels, file
end

local function LoadExplored()
    exploredCount = 0
    for index = 1, mapFile and GetNumMapOverlays() or 0 do
        local name, textureWidth, textureHeight, offsetX, offsetY = GetMapOverlayInfo(index)
        if name and name ~= "" then
            local wide, tall = ceil(textureWidth / TILE), ceil(textureHeight / TILE)
            for row = 1, tall do
                local height, fileHeight = PieceSize(row, tall, textureHeight)
                for column = 1, wide do
                    local width, fileWidth = PieceSize(column, wide, textureWidth)
                    exploredCount = exploredCount + 1
                    local piece = explored[exploredCount] or Piece("OVERLAY")
                    explored[exploredCount] = piece
                    piece.left, piece.top = offsetX + TILE * (column - 1), offsetY + TILE * (row - 1)
                    piece.width, piece.height = width, height
                    piece.uMax, piece.vMax = width / fileWidth, height / fileHeight
                    piece:SetTexture(name .. ((row - 1) * wide + column))
                end
            end
        end
    end
    for index = exploredCount + 1, table.getn(explored) do
        explored[index]:Hide()
    end
end

local function LoadZone()
    mapFile = CurrentZoneMapFile()
    zoneId = mapFile and C_Map and C_Map.GetMapAreaIDs and C_Map.GetMapAreaIDs()[mapFile] or nil
    window.title:SetText(GetZoneText() or "")
    for index, tile in ipairs(tiles) do
        if mapFile then
            tile:SetTexture("Interface\\WorldMap\\" .. mapFile .. "\\" .. mapFile .. index)
        else
            tile:Hide()
        end
    end
    LoadExplored()
    if mapFile then
        noMap:Hide()
        hero:Show()
    else
        noMap:Show()
        hero:Hide()
    end
end

local function Clamp(value, low, high)
    if value < low then
        return low
    end
    if value > high then
        return high
    end
    return value
end

local function PlacePiece(piece, scale, spanX, spanY)
    local x1 = max(piece.left, originX)
    local x2 = min(piece.left + piece.width, originX + spanX)
    local y1 = max(piece.top, originY)
    local y2 = min(piece.top + piece.height, originY + spanY)
    if x1 >= x2 or y1 >= y2 then
        piece:Hide()
        return
    end
    local u, v = piece.uMax / piece.width, piece.vMax / piece.height
    piece:SetTexCoord((x1 - piece.left) * u, (x2 - piece.left) * u, (y1 - piece.top) * v, (y2 - piece.top) * v)
    piece:SetWidth((x2 - x1) * scale)
    piece:SetHeight((y2 - y1) * scale)
    piece:ClearAllPoints()
    piece:SetPoint("TOPLEFT", view, "TOPLEFT", 1 + (x1 - originX) * scale, -1 - (y1 - originY) * scale)
    piece:Show()
end

local function PlaceTiles(scale)
    local spanX, spanY = INNER_WIDTH / scale, INNER_HEIGHT / scale
    for _, tile in ipairs(tiles) do
        PlacePiece(tile, scale, spanX, spanY)
    end
    for index = 1, exploredCount do
        PlacePiece(explored[index], scale, spanX, spanY)
    end
end

local function RotateArrow(facing)
    local s, c = math.sin(facing), math.cos(facing)
    local function Corner(dx, dy)
        return 0.5 + c * dx - s * dy, 0.5 + s * dx + c * dy
    end
    local ulx, uly = Corner(-0.5, -0.5)
    local llx, lly = Corner(-0.5, 0.5)
    local urx, ury = Corner(0.5, -0.5)
    local lrx, lry = Corner(0.5, 0.5)
    hero:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

local function ObjectiveMapPosition(objective)
    if not zoneId or not C_Map or not C_Map.GetMapPosFromWorldPos then
        return nil
    end
    local _, position = C_Map.GetMapPosFromWorldPos(objective.mapId, { x = objective.shownX, y = objective.shownY }, zoneId)
    if not position then
        return nil
    end
    return position.x, position.y
end

local function YardsTo(objective)
    local north, west = UI.HeroWorldPosition()
    if not north then
        return nil
    end
    local dn, dw = objective.x - north, objective.y - west
    return floor(sqrt(dn * dn + dw * dw))
end

local function TakePin(objective)
    local pin = mapPins[objective]
    if pin then
        return pin
    end
    local pool = IsSmall(objective) and "small" or "normal"
    pin = tremove(sparePins[pool])
    if not pin then
        pin = UI.ObjectivePin(overlay, pool == "small" and SMALL_PIN_SIZE or PIN_SIZE)
        pin.pool = pool
        pin.yards = UI.Text(pin, 11, UI.NUMBER_FONT)
        pin.yards:SetPoint("TOP", pin, "BOTTOM", 0, 1)
        pin.yards:SetTextColor(1, 0.82, 0)
    end
    pin.objective = objective
    mapPins[objective] = pin
    return pin
end

local function ReleaseUnusedPins()
    for objective, pin in pairs(mapPins) do
        if UI.objectives[objective.id] ~= objective then
            pin:Hide()
            pin.objective = nil
            tinsert(sparePins[pin.pool], pin)
            mapPins[objective] = nil
        end
    end
end

local function PlacePin(objective, scale)
    local x, y = ObjectiveMapPosition(objective)
    local pin = TakePin(objective)
    if not x then
        pin:Hide()
        return
    end
    pin.icon:SetTexture(UI.ObjectiveIcon(objective))
    local px = (x * MAP_WIDTH - originX) * scale
    local py = (y * MAP_HEIGHT - originY) * scale
    local inside = px >= EDGE and px <= INNER_WIDTH - EDGE and py >= EDGE and py <= INNER_HEIGHT - EDGE
    if inside then
        pin:SetAlpha(1)
        pin.yards:Hide()
    else
        local cx, cy = INNER_WIDTH / 2, INNER_HEIGHT / 2
        local dx, dy = px - cx, py - cy
        local reach = min((cx - EDGE) / max(abs(dx), 0.001), (cy - EDGE - 10) / max(abs(dy), 0.001))
        px, py = cx + dx * reach, cy + dy * reach
        pin:SetAlpha(0.8)
        local yards = YardsTo(objective)
        pin.yards:SetText(yards and (yards .. L[" yd"]) or "")
        pin.yards:Show()
    end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", view, "TOPLEFT", 1 + px, -1 - py)
    pin:Show()
end

local function SortedObjectives()
    local list = {}
    for id, objective in pairs(UI.objectives) do
        objective.id = id
        objective.distance = YardsTo(objective) or 0
        tinsert(list, objective)
    end
    table.sort(list, function(a, b)
        local aSmall, bSmall = IsSmall(a) and 1 or 0, IsSmall(b) and 1 or 0
        if aSmall ~= bSmall then
            return aSmall < bSmall
        end
        return a.distance < b.distance
    end)
    return list
end

local ROW_WIDTH = (VIEW_WIDTH - (LIST_ROWS - 1) * LIST_GAP) / LIST_ROWS

for index = 1, LIST_ROWS do
    local row = UI.Strip(window)
    row:SetWidth(ROW_WIDTH)
    row:SetHeight(LIST_HEIGHT)
    row:SetPoint("TOPLEFT", window, "TOPLEFT", VIEW_LEFT + (index - 1) * (ROW_WIDTH + LIST_GAP), -LIST_TOP)
    row.pin = UI.ObjectivePin(row, 20)
    row.pin:SetPoint("LEFT", row, "LEFT", 4, 0)
    row.yards = UI.Text(row, 12, UI.NUMBER_FONT)
    row.yards:SetPoint("RIGHT", row, "RIGHT", -6, 0)
    row.yards:SetJustifyH("RIGHT")
    row.label = UI.Text(row, 11)
    row.label:SetPoint("LEFT", row.pin, "RIGHT", 4, 0)
    row.label:SetPoint("RIGHT", row.yards, "LEFT", -4, 0)
    row.label:SetJustifyH("LEFT")
    row.label:SetTextColor(1, 0.82, 0)
    rows[index] = row
end

local emptyList = UI.Text(window, 12)
emptyList:SetPoint("TOPLEFT", window, "TOPLEFT", VIEW_LEFT, -LIST_TOP - 8)
emptyList:SetTextColor(0.7, 0.7, 0.7)
emptyList:SetText(L["There are no objectives right now."])

local function FillList(list)
    for index, row in ipairs(rows) do
        local objective = list[index]
        if objective then
            row.pin.objective = objective
            row.pin.icon:SetTexture(UI.ObjectiveIcon(objective))
            row.pin:Show()
            row.label:SetText(objective.label ~= "" and objective.label or L["Objective"])
            row.yards:SetText(objective.distance .. L[" yd"])
            row:Show()
        else
            row.pin.objective = nil
            row:Hide()
        end
    end
    if list[1] then
        emptyList:Hide()
    else
        emptyList:Show()
    end
end

local function Refresh()
    if not mapFile then
        FillList(SortedObjectives())
        return
    end
    local scale = Scale()
    local heroX, heroY = GetPlayerMapPosition("player")
    local heroPx, heroPy = (heroX or 0.5) * MAP_WIDTH, (heroY or 0.5) * MAP_HEIGHT
    originX = Clamp(heroPx - INNER_WIDTH / 2 / scale, 0, MAP_WIDTH - INNER_WIDTH / scale)
    originY = Clamp(heroPy - INNER_HEIGHT / 2 / scale, 0, MAP_HEIGHT - INNER_HEIGHT / scale)
    PlaceTiles(scale)

    hero:ClearAllPoints()
    hero:SetPoint("CENTER", view, "TOPLEFT", 1 + (heroPx - originX) * scale, -1 - (heroPy - originY) * scale)
    if GetPlayerFacing then
        RotateArrow(GetPlayerFacing() or 0)
    end

    local list = SortedObjectives()
    ReleaseUnusedPins()
    for _, objective in ipairs(list) do
        PlacePin(objective, scale)
    end
    FillList(list)
end

local elapsed = 0
window:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < UPDATE_INTERVAL then
        return
    end
    elapsed = 0
    Refresh()
end)

view:SetScript("OnMouseWheel", function()
    zoom = Clamp(zoom + (arg1 > 0 and 1 or -1), 1, table.getn(ZOOMS))
    Refresh()
end)

window:SetScript("OnShow", function()
    SetPortraitTexture(this.portrait, "player")
    LoadZone()
    elapsed = UPDATE_INTERVAL
    Refresh()
    PlaySound("igQuestLogOpen")
end)

window:SetScript("OnHide", function()
    PlaySound("igQuestLogClose")
end)

window:RegisterEvent("ZONE_CHANGED_NEW_AREA")
window:SetScript("OnEvent", function()
    if this:IsShown() then
        LoadZone()
        Refresh()
    end
end)

local StockToggleWorldMap = ToggleWorldMap

worldButton:SetScript("OnClick", function()
    window:Hide()
    StockToggleWorldMap()
end)

function ToggleWorldMap()
    if window:IsShown() then
        window:Hide()
        return
    end
    if WorldMapFrame:IsShown() then
        StockToggleWorldMap()
        return
    end
    window:Show()
end
