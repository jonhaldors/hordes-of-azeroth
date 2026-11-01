local L = VanillaBonkL
local UI = VanillaBonkUI

local KIND_ICONS = {
    shrine = "Spell_Holy_PowerInfusion",
    vendor = "INV_Misc_Bag_10",
    event = "Ability_Warrior_BattleShout",
    chest = "INV_Box_02",
    boss = "INV_Misc_Bone_HumanSkull_01",
    miniboss = "INV_Misc_Bone_ElfSkull_01",
}
local PIN_SIZE = 20
local MAP_PIN_SIZE = 24
local SMALL_PIN_SIZE = 14
local SMALL_MAP_PIN_SIZE = 18
local SMALL_KINDS = { chest = true }
local LARGE_KINDS = { boss = true }
local LARGE_PIN_SIZE = 26
local LARGE_MAP_PIN_SIZE = 30
local RED_RING_KINDS = { boss = true, miniboss = true }
local OUTDOOR_YARDS = { [0] = 466.67, 400, 333.33, 266.67, 200, 133.33 }
local INDOOR_YARDS = { [0] = 300, 240, 180, 120, 80, 50 }
local UPDATE_INTERVAL = 0.03
local GLIDE = 10
local JUMP = 40
local PING_TIME = 1.2
local PING_SIZE = 3.2

local objectives = {}

local function Icon(objective)
    if objective.icon ~= "" then
        return UI.ICON_PATH .. objective.icon
    end
    return UI.ICON_PATH .. (KIND_ICONS[objective.kind] or "INV_Misc_QuestionMark")
end

local function HeroPosition()
    if not UnitPosition then
        return nil
    end
    local west, north, _, mapId = UnitPosition("player")
    if not west then
        return nil
    end
    return north, west, mapId
end

local function TooltipFor(pin)
    if pin:GetParent() == WorldMapButton and WorldMapTooltip then
        return WorldMapTooltip
    end
    return GameTooltip
end

local function ShowTooltip()
    local objective = this.objective
    if not objective then
        return
    end
    local tooltip = TooltipFor(this)
    tooltip:SetOwner(this, "ANCHOR_RIGHT")
    tooltip:AddLine(objective.label ~= "" and objective.label or L["Objective"], 1, 1, 1)
    if objective.description ~= "" then
        tooltip:AddLine(objective.description, 1, 0.82, 0, 1)
    end
    local north, west = HeroPosition()
    if north then
        local dn, dw = objective.x - north, objective.y - west
        tooltip:AddLine(floor(sqrt(dn * dn + dw * dw)) .. L[" yards away"], 0.7, 0.7, 0.7)
    end
    if objective.leaves then
        tooltip:AddLine(L("Gone in {1} sec", max(0, ceil(objective.leaves - GetTime()))), 0.7, 0.7, 0.7)
    end
    tooltip:Show()
end

local function MakePin(parent, size)
    local pin = VanillaBonkUI.Ring(parent, size)
    pin:SetFrameLevel(parent:GetFrameLevel() + 5)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetPoint("TOPLEFT", pin, "TOPLEFT", size * 0.18, -size * 0.18)
    pin.icon:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", -size * 0.18, size * 0.18)
    pin.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    if pin.icon.SetMask then
        pin.icon:SetMask("Textures\\MinimapMask")
    end
    pin.rings = {}
    for index = 1, 2 do
        local ring = pin:CreateTexture(nil, "OVERLAY")
        ring:SetTexture("Interface\\MiniMap\\Ping\\ping4")
        ring:SetBlendMode("ADD")
        ring:SetPoint("CENTER", pin, "CENTER", 0, 0)
        ring:Hide()
        pin.rings[index] = ring
    end
    pin:EnableMouse(true)
    pin:SetScript("OnEnter", ShowTooltip)
    pin:SetScript("OnLeave", function() TooltipFor(this):Hide() end)
    pin:Hide()
    return pin
end

local spare = { normal = {}, small = {}, large = {} }

local function PinPool(kind)
    if LARGE_KINDS[kind] then
        return "large"
    end
    return SMALL_KINDS[kind] and "small" or "normal"
end

local function TakePins(kind)
    local pool = PinPool(kind)
    local pins = tremove(spare[pool])
    if pins then
        return pins[1], pins[2]
    end
    if pool == "small" then
        return MakePin(Minimap, SMALL_PIN_SIZE), MakePin(WorldMapButton, SMALL_MAP_PIN_SIZE)
    elseif pool == "large" then
        return MakePin(Minimap, LARGE_PIN_SIZE), MakePin(WorldMapButton, LARGE_MAP_PIN_SIZE)
    end
    return MakePin(Minimap, PIN_SIZE), MakePin(WorldMapButton, MAP_PIN_SIZE)
end

local function Remove(id)
    local objective = objectives[id]
    if not objective then
        return
    end
    objective.pin:Hide()
    objective.mapPin:Hide()
    objective.pin.pinged = nil
    for _, ring in ipairs(objective.pin.rings) do
        ring:Hide()
    end
    objective.pin.objective = nil
    objective.mapPin.objective = nil
    tinsert(spare[objective.pool], { objective.pin, objective.mapPin })
    objectives[id] = nil
end

local function RemoveAll()
    for id in pairs(objectives) do
        Remove(id)
    end
end

local function PlaceOnMinimap(objective, north, west, mapId)
    local pin = objective.pin
    if not north or mapId ~= objective.mapId then
        pin:Hide()
        return
    end
    local zoom = Minimap:GetZoom()
    local yards = (IsIndoors and IsIndoors() and INDOOR_YARDS[zoom] or OUTDOOR_YARDS[zoom]) or OUTDOOR_YARDS[0]
    local radius = Minimap:GetWidth() / 2
    local perYard = radius * 2 / yards
    local right = (west - objective.shownY) * perYard
    local up = (objective.shownX - north) * perYard
    local rim = radius - PIN_SIZE / 2 - 2
    local distance = sqrt(right * right + up * up)
    if distance > rim then
        right, up = right * rim / distance, up * rim / distance
        pin:SetAlpha(0.75)
    else
        pin:SetAlpha(1)
    end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", Minimap, "CENTER", right, up)
    pin:Show()
end

local function ViewedZone()
    if not C_Map or not C_Map.GetMapAreaIDs then
        return nil
    end
    local mapName = GetMapInfo()
    return mapName and C_Map.GetMapAreaIDs()[mapName]
end

local function PlaceOnWorldMap(objective, zone)
    local pin = objective.mapPin
    if not zone or not C_Map.GetMapPosFromWorldPos then
        pin:Hide()
        return
    end
    local _, position = C_Map.GetMapPosFromWorldPos(objective.mapId, { x = objective.shownX, y = objective.shownY }, zone)
    if not position or position.x < 0 or position.x > 1 or position.y < 0 or position.y > 1 then
        pin:Hide()
        return
    end
    pin:ClearAllPoints()
    pin:SetPoint("CENTER", WorldMapButton, "TOPLEFT", position.x * WorldMapButton:GetWidth(), -position.y * WorldMapButton:GetHeight())
    pin:Show()
end

local function AnimatePing(pin, now)
    if not pin.pinged then
        return
    end
    local size = pin:GetWidth()
    local done = true
    for index, ring in ipairs(pin.rings) do
        local t = (now - pin.pinged - (index - 1) * 0.3) / PING_TIME
        if t >= 0 and t < 1 then
            done = false
            local grown = size * (1 + (PING_SIZE - 1) * (1 - (1 - t) * (1 - t)))
            ring:SetWidth(grown)
            ring:SetHeight(grown)
            ring:SetVertexColor(1, 0.9, 0.4, 1 - t)
            ring:Show()
        else
            ring:Hide()
            if t < 0 then
                done = false
            end
        end
    end
    if done then
        pin.pinged = nil
    end
end

local function Glide(objective, step)
    local follow = min(1, step * GLIDE)
    objective.shownX = objective.shownX + (objective.x - objective.shownX) * follow
    objective.shownY = objective.shownY + (objective.y - objective.shownY) * follow
end

local updater = CreateFrame("Frame")
updater:Hide()
local elapsed = 0
updater:SetScript("OnUpdate", function()
    elapsed = elapsed + arg1
    if elapsed < UPDATE_INTERVAL then
        return
    end
    local step = elapsed
    elapsed = 0

    local now = GetTime()
    local north, west, mapId = HeroPosition()
    local zone = WorldMapFrame:IsVisible() and ViewedZone() or nil
    local any = false
    for id, objective in pairs(objectives) do
        if objective.leaves and now >= objective.leaves then
            Remove(id)
        else
            any = true
            Glide(objective, step)
            PlaceOnMinimap(objective, north, west, mapId)
            AnimatePing(objective.pin, now)
            if zone then
                PlaceOnWorldMap(objective, zone)
            else
                objective.mapPin:Hide()
            end
        end
    end
    if not any then
        this:Hide()
    end
end)

local handlers = {}

handlers["objective"] = function(f)
    local id = f[2]
    local x, y, mapId = tonumber(f[4] or ""), tonumber(f[5] or ""), tonumber(f[6] or "")
    if not id or not x or not y or not mapId then
        return
    end
    local objective = objectives[id]
    local jumped = not objective or objective.mapId ~= mapId
    if not objective then
        objective = {}
        objective.pool = PinPool(f[3])
        objective.pin, objective.mapPin = TakePins(f[3])
        objective.pin.objective = objective
        objective.mapPin.objective = objective
        objectives[id] = objective
    elseif not jumped then
        local dx, dy = x - objective.shownX, y - objective.shownY
        jumped = dx * dx + dy * dy > JUMP * JUMP
    end
    objective.kind = f[3] or ""
    objective.x, objective.y, objective.mapId = x, y, mapId
    if jumped then
        objective.shownX, objective.shownY = x, y
    end
    objective.label = f[7] or ""
    objective.icon = f[9] or ""
    objective.description = f[10] or ""
    local seconds = tonumber(f[8] or "") or 0
    local leaves = seconds > 0 and GetTime() + seconds or nil
    if leaves and objective.leaves and abs(leaves - objective.leaves) < 1.5 then
        leaves = objective.leaves
    end
    objective.leaves = leaves
    objective.pin.icon:SetTexture(Icon(objective))
    objective.mapPin.icon:SetTexture(Icon(objective))
    for _, pin in ipairs({ objective.pin, objective.mapPin }) do
        if pin.border then
            if RED_RING_KINDS[objective.kind] then
                pin.border:SetVertexColor(1, 0.25, 0.2)
            else
                pin.border:SetVertexColor(1, 1, 1)
            end
        end
    end
    elapsed = UPDATE_INTERVAL
    updater:Show()
end

handlers["objectiveping"] = function(f)
    local objective = objectives[f[2] or ""]
    if not objective then
        return
    end
    objective.pin.pinged = GetTime()
    PlaySound("MapPing")
    elapsed = UPDATE_INTERVAL
    updater:Show()
end

handlers["objectiveclear"] = function(f)
    if f[2] and f[2] ~= "" then
        Remove(f[2])
    else
        RemoveAll()
    end
end

handlers["end"] = function()
    RemoveAll()
end

UI.Listen(handlers)

UI.objectives = objectives
UI.SMALL_OBJECTIVE_KINDS = SMALL_KINDS
UI.ObjectiveIcon = Icon
UI.ObjectivePin = MakePin
UI.HeroWorldPosition = HeroPosition
