local L = VanillaBonkL
local UI = VanillaBonkUI

VanillaBonkRunMaster = {}
local RunMaster = VanillaBonkRunMaster

local W, H = 920, 600
local LEFT_X, LEFT_WIDTH = 22, 214
local PLAQUE_TOP, PLAQUE_HEIGHT, PLAQUE_STEP = 56, 48, 56
local MID_X, LIST_WIDTH = 256, 290
local PANEL_TOP = 124
local RIGHT_X = MID_X + LIST_WIDTH + 14
local RIGHT_WIDTH = W - 22 - RIGHT_X
local BANNER_TOP, BANNER_HEIGHT = 100, 100
local PREVIEW_TOP = 212
local SLIDER_Y = PREVIEW_TOP + 92
local SLIDER_INSET = 14
local ROW_HEIGHT, ROW_STEP, ROW_ICON = 34, 36, 26
local STAT_STEP = 15
local MAX_FLOORS = 20
local KNOB_TEXTURE = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\SliderKnob"
local RANDOM_ICON = "INV_Misc_QuestionMark"
local SOFT = { 0.78, 0.75, 0.7 }
local MUTED = { 0.51, 0.49, 0.44 }
local HAIR = { 0.47, 0.39, 0.24 }
local INVADED_COLOR = { 1, 0.6, 0.24 }
local CHALLENGE_RISK = L["Enemies have 30% more health and deal 20% more damage."]
local DUNGEON_REWARD = L["Enemies drop 50% more gold, and loot is one quality higher."]
local INVASION_REWARD = L["More enemies come at once. They drop 25% more gold, and loot has a 50% chance to be one quality higher."]
local TIER_LOOKS = {
    normal = { color = { 1, 0.82, 0 }, emblem = "Ability_Warrior_DefensiveStance" },
    heroic = { color = { 0.38, 0.65, 1 }, emblem = "INV_Shield_05" },
    mythic = { color = { 0.77, 0.4, 1 }, emblem = "INV_Misc_Bone_HumanSkull_01" },
}
local DEFAULT_LOOK = TIER_LOOKS.normal
local BANDS = {
    { name = L["Climb"], color = { 0.91, 0.77, 0.41 } },
    { name = L["Push"], color = { 0.94, 0.59, 0.24 } },
    { name = L["Peak"], color = { 0.9, 0.31, 0.25 } },
}
local MILESTONE_ICONS = { affix = "Ability_Warrior_Challange", veteran = "INV_Helmet_03" }
local CONTINENT_ART = {
    ["0"] = "Interface\\Glues\\LoadingScreens\\LoadScreenEasternKingdom",
    ["1"] = "Interface\\Glues\\LoadingScreens\\LoadScreenKalimdor",
}
local DUNGEON_ART = {
    moltencore = "Interface\\Glues\\LoadingScreens\\LoadScreenMoltenCore",
    zulgurub = "Interface\\Glues\\LoadingScreens\\LoadScreenZulGurub",
    ruinsaq = "Interface\\Glues\\LoadingScreens\\LoadScreenAhnQiraj20man",
}
local MAP_TYPES = { ["0"] = L["Open zone"], ["1"] = L["Enclosed raid"], ["2"] = L["Dungeon room"] }
local WORLD_MAP_PATH = "Interface\\WorldMap\\"
local ZONE_MAP_WIDTH, ZONE_MAP_HEIGHT = 1002, 668
local MAP_TILE = 256
local MAP_TILE_COLUMNS, MAP_TILE_ROWS = 4, 3
local MAP_CROP = 0.62
local INVASION_TINT = {
    moltencore = { 1, 0.42, 0.28 },
    zulgurub = { 0.55, 0.85, 0.45 },
    ruinsaq = { 1, 0.82, 0.45 },
}
local DEFAULT_TINT = { 1, 0.6, 0.45 }
local MODES = { "zones", "dungeon", "invasion" }
local MODE_LABELS = { zones = L["Zones"], dungeon = L["Dungeon"], invasion = L["Invasion"] }
local STAT_ROWS = {
    { group = L["Enemies"] },
    { label = L["Health"], key = "health", format = "+%s%%", rising = true },
    { label = L["Damage"], key = "damage", format = "+%s%%", rising = true },
    { label = L["Veterans"], key = "veterans", format = "%s%%", rising = true },
    { label = L["Elite affixes"], key = "affixes", format = "%s", rising = true },
    { behavior = true },
    { group = L["Rewards"], rewards = true },
    { label = L["Gold and Tickets per kill"], key = "gold", format = "+%s%%", rewards = true },
    { label = L["Boss legendary drop chance"], key = "legendary", format = "%s%%", rewards = true },
}

local state = { zone = {}, dungeon = {}, mode = {}, floor = {}, start = {} }
local checkpoints = {}
local CHECKPOINT_Y = 404
local CHECKPOINT_BUTTON = 38
local mapInfo = {}
local floorInfo = {}
local tierInfo = {}
local BEHAVIOR_CELLS = { { L["Caster aim"], "aim" }, { L["Boss attacks"], "boss" }, { L["Max enemies"], "crowd" } }
local zoneOverlays, overlaySeen = {}, {}
local arena, content, tier, onTierClick
local head, ladder, list, banner, preview

local function Icon(name)
    return UI.ICON_PATH .. ((name and name ~= "") and name or RANDOM_ICON)
end

local function Look(shown)
    return TIER_LOOKS[shown and shown.key or ""] or DEFAULT_LOOK
end

local function Hex(color)
    return format("|cff%02x%02x%02x", floor(color[1] * 255), floor(color[2] * 255), floor(color[3] * 255))
end

local function Multiplier(percent)
    local text = format("%.2f", percent / 100)
    text = gsub(text, "0$", "")
    return gsub(text, "%.$", ".0")
end

local function Info(key)
    return mapInfo[key or ""] or {}
end

local function Floors(count)
    return count .. (count == 1 and L[" floor"] or L[" floors"])
end

local function FloorRow(shown, index)
    return (floorInfo[shown.id] or {})[index]
end

local function Clamp(value, low, high)
    return max(low, min(high, value))
end

local function Flat(parent, layer, r, g, b, a)
    local texture = parent:CreateTexture(nil, layer or "ARTWORK")
    texture:SetTexture(UI.FLAT)
    texture:SetVertexColor(r or 1, g or 1, b or 1, a or 1)
    return texture
end

local function Hairline(parent, width)
    local line = UI.Divider(parent, width)
    line.left:SetVertexColor(HAIR[1], HAIR[2], HAIR[3])
    line.right:SetVertexColor(HAIR[1], HAIR[2], HAIR[3])
    return line
end

local function Mode()
    local mode = state.mode[tier.id] or "zones"
    if mode ~= "zones" and table.getn(tier.dungeons or {}) == 0 then
        return "zones"
    end
    return mode
end

local function ChosenZone()
    local key = state.zone[tier.id]
    for _, map in ipairs(tier.maps) do
        if map.key == key then
            return map
        end
    end
    state.zone[tier.id] = nil
end

local function ChosenDungeon()
    if Mode() == "zones" then
        return nil
    end
    local key = state.dungeon[tier.id]
    for _, dungeon in ipairs(tier.dungeons or {}) do
        if dungeon.key == key and dungeon.open then
            return dungeon
        end
    end
end

local function FirstOpenDungeon()
    for _, dungeon in ipairs(tier.dungeons or {}) do
        if dungeon.open then
            return dungeon
        end
    end
end

local function Plaque(index)
    local plaque = ladder[index]
    if plaque then
        return plaque
    end
    plaque = CreateFrame("Button", nil, content)
    plaque:SetWidth(LEFT_WIDTH)
    plaque:SetHeight(PLAQUE_HEIGHT)
    plaque:SetPoint("TOPLEFT", arena, "TOPLEFT", LEFT_X, -(PLAQUE_TOP + (index - 1) * PLAQUE_STEP))
    plaque:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    plaque.wash = plaque:CreateTexture(nil, "BORDER")
    plaque.wash:SetPoint("TOPLEFT", plaque, "TOPLEFT", 1, -1)
    plaque.wash:SetPoint("BOTTOMRIGHT", plaque, "BOTTOMRIGHT", -1, 1)
    plaque.bar = Flat(plaque, "ARTWORK")
    plaque.bar:SetPoint("TOPLEFT", plaque, "TOPLEFT", 0, 0)
    plaque.bar:SetPoint("BOTTOMLEFT", plaque, "BOTTOMLEFT", 0, 0)
    plaque.bar:SetWidth(3)
    plaque.icon = plaque:CreateTexture(nil, "ARTWORK")
    plaque.icon:SetWidth(30)
    plaque.icon:SetHeight(30)
    plaque.icon:SetPoint("LEFT", plaque, "LEFT", 12, 0)
    UI.CropIcon(plaque.icon)
    plaque.shade = Flat(plaque, "OVERLAY", 0, 0, 0, 0.45)
    plaque.shade:SetAllPoints(plaque.icon)
    plaque.name = UI.Text(plaque, 18, UI.TITLE_FONT)
    plaque.name:SetPoint("TOPLEFT", plaque, "TOPLEFT", 52, -6)
    plaque.state = UI.Text(plaque, 10)
    plaque.state:SetPoint("TOPLEFT", plaque, "TOPLEFT", 53, -29)
    plaque:SetScript("OnClick", function()
        if this.tier and this.tier ~= tier and onTierClick then
            PlaySound("igCharacterInfoTab")
            onTierClick(this.tier)
        end
    end)
    plaque:SetScript("OnEnter", function()
        local shown = this.tier
        if not shown then
            return
        end
        GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
        local color = Look(shown).color
        GameTooltip:AddLine(shown.name, color[1], color[2], color[3])
        for _, line in ipairs(shown.details ~= "" and UI.Split(shown.details, "^") or {}) do
            GameTooltip:AddLine(line, 1, 1, 1, 1)
        end
        if not shown.unlocked and shown.hint ~= "" then
            GameTooltip:AddLine(shown.hint, 1, 0.3, 0.3, 1)
        end
        GameTooltip:Show()
    end)
    plaque:SetScript("OnLeave", function() GameTooltip:Hide() end)
    ladder[index] = plaque
    return plaque
end

local function Progress(shown)
    if not shown.unlocked then
        return L["Locked"]
    end
    local stages = shown.stages or 1
    if shown.best > stages then
        return L["Cleared"]
    elseif shown.best > 0 then
        return L("best {1}", shown.best)
    end
    return L["new"]
end

local function FillPlaque(plaque, shown, selected)
    local color = Look(shown).color
    plaque.tier = shown
    plaque.icon:SetTexture(Icon(Look(shown).emblem))
    plaque.name:SetText(shown.name)
    plaque.state:SetText(Floors(shown.stages or 1) .. "  ·  " .. Progress(shown))
    SetDesaturation(plaque.icon, not selected or not shown.unlocked)
    if selected then
        plaque:SetBackdropColor(0, 0, 0, 0.47)
        plaque:SetBackdropBorderColor(color[1] * 0.7, color[2] * 0.7, color[3] * 0.7, 1)
        UI.Gradient(plaque.wash, "HORIZONTAL", color[1], color[2], color[3], 0.18, 0)
        plaque.wash:Show()
        plaque.bar:SetVertexColor(color[1], color[2], color[3], 1)
        plaque.bar:Show()
        plaque.shade:Hide()
        plaque.name:SetTextColor(color[1], color[2], color[3])
        plaque.state:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    else
        plaque:SetBackdropColor(0, 0, 0, 0.27)
        plaque:SetBackdropBorderColor(0.22, 0.2, 0.16, 1)
        plaque.wash:Hide()
        plaque.bar:Hide()
        plaque.shade:Show()
        plaque.name:SetTextColor(color[1] * 0.55, color[2] * 0.55, color[3] * 0.55)
        plaque.state:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    end
    plaque:Show()
end

local function ShowHead()
    local color = Look(tier).color
    head.name:SetText(tier.name)
    head.name:SetTextColor(color[1], color[2], color[3])
    head.description:SetText(tier.description or "")
    head.description:SetWidth(W - 60 - MID_X - head.name:GetStringWidth() - 16)
    UI.Gradient(head.tint, "VERTICAL", color[1], color[2], color[3], 0, 0.12)
    head.art:SetTexture(tier.art ~= "" and tier.art or "Interface\\Glues\\LoadingScreens\\LoadScreenEnviroment")
    UI.LoadingScreenCoords(head.art, W - 22, 160, 0.4)
    SetDesaturation(head.art, not tier.unlocked)
end

local function ListRow(index)
    local row = list.rows[index]
    if row then
        return row
    end
    row = CreateFrame("Button", nil, list.child)
    row:SetWidth(LIST_WIDTH - 36)
    row:SetHeight(ROW_HEIGHT)
    row:SetPoint("TOPLEFT", list.child, "TOPLEFT", 0, -(index - 1) * ROW_STEP)
    row.back = Flat(row, "BACKGROUND", 0, 0, 0, 0.35)
    row.back:SetAllPoints(row)
    row.wash = row:CreateTexture(nil, "BORDER")
    row.wash:SetAllPoints(row)
    row.bar = Flat(row, "ARTWORK")
    row.bar:SetPoint("TOPLEFT", row, "TOPLEFT", 0, 0)
    row.bar:SetPoint("BOTTOMLEFT", row, "BOTTOMLEFT", 0, 0)
    row.bar:SetWidth(2)
    row:SetHighlightTexture("Interface\\QuestFrame\\UI-QuestTitleHighlight", "ADD")
    row.icon = row:CreateTexture(nil, "ARTWORK")
    row.icon:SetWidth(ROW_ICON)
    row.icon:SetHeight(ROW_ICON)
    row.icon:SetPoint("LEFT", row, "LEFT", 8, 0)
    UI.CropIcon(row.icon)
    row.name = UI.Text(row, 12)
    row.name:SetPoint("TOPLEFT", row, "TOPLEFT", ROW_ICON + 16, -4)
    row.name:SetJustifyH("LEFT")
    row.summary = UI.Text(row, 9)
    row.summary:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
    row.summary:SetWidth(LIST_WIDTH - 36 - ROW_ICON - 22)
    row.summary:SetJustifyH("LEFT")
    row.tag = UI.Text(row, 9)
    row.tag:SetPoint("TOPRIGHT", row, "TOPRIGHT", -6, -5)
    row:SetScript("OnClick", function()
        if not tier.unlocked or not this.pick then
            return
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
        this.pick()
        RunMaster.Refresh()
    end)
    row:SetScript("OnEnter", function()
        if this.tooltip then
            this.tooltip(this)
        end
    end)
    row:SetScript("OnLeave", function() GameTooltip:Hide() end)
    list.rows[index] = row
    return row
end

local function FillRow(row, icon, name, summary, chosen, dimmed, tag)
    local color = Look(tier).color
    row.icon:SetTexture(Icon(icon))
    SetDesaturation(row.icon, dimmed)
    row.name:SetText(name)
    row.summary:SetText(summary or "")
    row.tag:SetText(tag or "")
    if chosen then
        UI.Gradient(row.wash, "HORIZONTAL", color[1], color[2], color[3], 0.24, 0)
        row.wash:Show()
        row.bar:SetVertexColor(color[1], color[2], color[3], 1)
        row.bar:Show()
        row.back:Show()
        row.name:SetTextColor(1, 1, 1)
        row.summary:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    else
        row.wash:Hide()
        row.bar:Hide()
        row.back:Hide()
        if dimmed then
            row.name:SetTextColor(0.5, 0.5, 0.5)
        else
            row.name:SetTextColor(0.92, 0.78, 0.35)
        end
        row.summary:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    end
    row:Show()
end

local function ZoneTooltip(row)
    local map = row.map
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    if not map then
        GameTooltip:AddLine(L["Random zone"], 1, 0.82, 0)
        GameTooltip:AddLine(L("Floor 1 takes you to any {1} zone.", tier.name), 1, 1, 1, 1)
    else
        GameTooltip:AddLine(map.name, 1, 0.82, 0)
        if MAP_TYPES[map.type] then
            GameTooltip:AddLine(MAP_TYPES[map.type], 0.7, 0.7, 0.7)
        end
        local info = Info(map.key)
        if info.description and info.description ~= "" then
            GameTooltip:AddLine(info.description, 1, 1, 1, 1)
        end
        if map.reward and map.reward ~= 100 then
            GameTooltip:AddLine(L["Pays "] .. Multiplier(map.reward) .. L["x gold, Darkmoon Tickets and Mastery experience."], 0.25, 1, 0.25, 1)
        end
    end
    GameTooltip:Show()
end

local function DungeonTooltip(row)
    local dungeon = row.dungeon
    GameTooltip:SetOwner(row, "ANCHOR_RIGHT")
    GameTooltip:AddLine(dungeon.name, dungeon.open and 1 or 0.6, dungeon.open and 0.82 or 0.6, dungeon.open and 0 or 0.6)
    local info = Info(dungeon.key)
    if info.description and info.description ~= "" then
        GameTooltip:AddLine(info.description, 1, 1, 1, 1)
    end
    GameTooltip:AddLine(CHALLENGE_RISK, 1, 0.5, 0.5, 1)
    GameTooltip:AddLine(Mode() == "invasion" and INVASION_REWARD or DUNGEON_REWARD, 0.25, 1, 0.25, 1)
    if not dungeon.open then
        GameTooltip:AddLine(L("Clear {1} first.", tier.name), 1, 0.3, 0.3, 1)
    end
    GameTooltip:Show()
end

local function ShowList()
    local mode = Mode()
    local labels = { MODE_LABELS.zones }
    if table.getn(tier.dungeons or {}) > 0 then
        tinsert(labels, MODE_LABELS.dungeon)
        tinsert(labels, MODE_LABELS.invasion)
    end
    list.tabs:SetTabs(labels)
    for index, key in ipairs(MODES) do
        if key == mode then
            list.tabs:Select(index, Look(tier).color)
        end
    end
    for _, row in ipairs(list.rows) do
        row:Hide()
    end
    local dimmed = not tier.unlocked
    local count = 0
    if mode == "zones" then
        local zone = ChosenZone()
        count = 1
        local row = ListRow(1)
        row.map, row.dungeon, row.tooltip = nil, nil, ZoneTooltip
        row.pick = function() state.zone[tier.id] = nil end
        FillRow(row, RANDOM_ICON, L["Random zone"], L("Any {1} zone, picked when the run starts", tier.name), zone == nil, dimmed)
        for _, map in ipairs(tier.maps) do
            count = count + 1
            row = ListRow(count)
            row.map, row.dungeon, row.tooltip = map, nil, ZoneTooltip
            local key = map.key
            row.pick = function() state.zone[tier.id] = key end
            local tag = map.reward and map.reward ~= 100 and ("|cff40ff40" .. Multiplier(map.reward) .. L["x gold|r"]) or nil
            FillRow(row, map.icon, map.name, Info(map.key).summary, zone == map, dimmed, tag)
        end
    else
        local chosen = ChosenDungeon()
        for _, dungeon in ipairs(tier.dungeons or {}) do
            count = count + 1
            local row = ListRow(count)
            row.map, row.dungeon, row.tooltip = nil, dungeon, DungeonTooltip
            local key, open = dungeon.key, dungeon.open
            row.pick = open and function() state.dungeon[tier.id] = key end or nil
            FillRow(row, dungeon.icon, dungeon.name, Info(dungeon.key).summary, chosen == dungeon, dimmed or not open,
                not open and L["|cffff6060Locked|r"] or nil)
        end
    end
    list.child:SetHeight(max(1, count * ROW_STEP))
    list.scroll:UpdateScrollChildRect()
    if count * ROW_STEP <= list.scroll:GetHeight() then
        list.scroll:SetVerticalScroll(0)
    end
end

local function MapTexture(index, layer)
    local canvas = banner.map.canvas
    local texture = canvas.textures[index]
    if not texture then
        texture = canvas:CreateTexture(nil, layer)
        canvas.textures[index] = texture
    end
    texture:SetDrawLayer(layer)
    texture:ClearAllPoints()
    return texture
end

local function PlaceMapTexture(index, layer, path, x, y, width, height, fileWidth, fileHeight, scale)
    local texture = MapTexture(index, layer)
    texture:SetTexture(path)
    texture:SetTexCoord(0, width / fileWidth, 0, height / fileHeight)
    texture:SetWidth(width * scale)
    texture:SetHeight(height * scale)
    texture:SetPoint("TOPLEFT", banner.map.canvas, "TOPLEFT", x * scale, -y * scale)
    texture:Show()
    return index + 1
end

local function FilePixels(pixels)
    local size = 16
    while size < pixels do
        size = size * 2
    end
    return size
end

local function PlaceOverlay(index, file, overlay, scale)
    local wide, tall = ceil(overlay.width / MAP_TILE), ceil(overlay.height / MAP_TILE)
    for row = 1, tall do
        local height, fileHeight = MAP_TILE, MAP_TILE
        if row == tall then
            height = mod(overlay.height, MAP_TILE)
            if height == 0 then
                height = MAP_TILE
            end
            fileHeight = FilePixels(height)
        end
        for column = 1, wide do
            local width, fileWidth = MAP_TILE, MAP_TILE
            if column == wide then
                width = mod(overlay.width, MAP_TILE)
                if width == 0 then
                    width = MAP_TILE
                end
                fileWidth = FilePixels(width)
            end
            local path = WORLD_MAP_PATH .. file .. "\\" .. overlay.texture .. ((row - 1) * wide + column)
            index = PlaceMapTexture(index, "ARTWORK", path, overlay.x + MAP_TILE * (column - 1), overlay.y + MAP_TILE * (row - 1),
                width, height, fileWidth, fileHeight, scale)
        end
    end
    return index
end

local function DrawZoneMap(file)
    local map = banner.map
    if map.file == file then
        return
    end
    map.file = file
    local scale = RIGHT_WIDTH / (ZONE_MAP_WIDTH * MAP_CROP)
    map.scale = scale
    map.canvas:SetWidth(ZONE_MAP_WIDTH * scale)
    map.canvas:SetHeight(ZONE_MAP_HEIGHT * scale)
    local index = 1
    for tile = 1, MAP_TILE_COLUMNS * MAP_TILE_ROWS do
        index = PlaceMapTexture(index, "BACKGROUND", WORLD_MAP_PATH .. file .. "\\" .. file .. tile,
            mod(tile - 1, MAP_TILE_COLUMNS) * MAP_TILE, floor((tile - 1) / MAP_TILE_COLUMNS) * MAP_TILE, MAP_TILE, MAP_TILE, MAP_TILE, MAP_TILE, scale)
    end
    for _, overlay in ipairs(zoneOverlays[file] or {}) do
        index = PlaceOverlay(index, file, overlay, scale)
    end
    for unused = index, table.getn(map.canvas.textures) do
        map.canvas.textures[unused]:Hide()
    end
end

local function ShowZoneMap(info, tint, locked)
    local map = banner.map
    DrawZoneMap(info.file)
    local scale = map.scale
    local x = Clamp((info.u or 0.5) * ZONE_MAP_WIDTH * scale - RIGHT_WIDTH / 2, 0, ZONE_MAP_WIDTH * scale - RIGHT_WIDTH)
    local y = Clamp((info.v or 0.5) * ZONE_MAP_HEIGHT * scale - BANNER_HEIGHT / 2, 0, ZONE_MAP_HEIGHT * scale - BANNER_HEIGHT)
    map:SetHorizontalScroll(-x)
    map:SetVerticalScroll(y)
    local r, g, b = 1, 1, 1
    if tint then
        r, g, b = tint[1], tint[2], tint[3]
    end
    for _, texture in ipairs(map.canvas.textures) do
        texture:SetVertexColor(r, g, b)
        SetDesaturation(texture, locked)
    end
    banner.art:Hide()
    map:Show()
end

local function SetArt(path, invaded, locked)
    banner.map:Hide()
    banner.art:Show()
    banner.art:SetTexture(path)
    UI.LoadingScreenCoords(banner.art, RIGHT_WIDTH, BANNER_HEIGHT, 0.5)
    if invaded then
        banner.art:SetVertexColor(1, 0.7, 0.5)
    else
        banner.art:SetVertexColor(1, 1, 1)
    end
    SetDesaturation(banner.art, locked)
end

local function ShowBanner()
    local zone = ChosenZone()
    local dungeon = ChosenDungeon()
    local mode = Mode()
    local locked = not tier.unlocked
    banner.risk = nil
    if mode == "dungeon" and dungeon then
        SetArt(DUNGEON_ART[dungeon.key] or tier.art, false, locked)
        banner.tag:SetText(Hex(INVADED_COLOR) .. L["Dungeon challenge  ·  every floor inside|r"])
        banner.name:SetText(dungeon.name)
        banner.description:SetText(Info(dungeon.key).summary or "")
        banner.risk = DUNGEON_REWARD
    elseif mode ~= "zones" and not dungeon then
        SetArt(tier.art, false, true)
        banner.tag:SetText("")
        banner.name:SetText(mode == "dungeon" and L["Dungeon"] or L["Invasion"])
        banner.description:SetText(L("Clear {1} to unlock challenges.", tier.name))
    else
        local invader = mode == "invasion" and dungeon or nil
        local info = Info(zone and zone.key)
        if zone and info.file and info.file ~= "" then
            ShowZoneMap(info, invader and (INVASION_TINT[invader.key] or DEFAULT_TINT), locked)
        else
            local art = zone and CONTINENT_ART[info.continent or ""] or tier.art
            SetArt(art ~= "" and art or CONTINENT_ART["0"], invader ~= nil, locked)
        end
        banner.name:SetText(zone and zone.name or L["Random zone"])
        if invader then
            banner.tag:SetText(Hex(INVADED_COLOR) .. L["Invaded by "] .. invader.name .. "|r")
            banner.description:SetText((Info(invader.key).summary or L["Its enemies"]) .. L[" roam the zone."])
            banner.risk = INVASION_REWARD
        else
            if zone and zone.reward and zone.reward ~= 100 then
                banner.tag:SetText(L["|cff40ff40Pays "] .. Multiplier(zone.reward) .. L["x gold, Tickets and Mastery|r"])
            else
                banner.tag:SetText("")
            end
            banner.description:SetText(zone and (info.description or "") or L("Floor 1 takes you to any {1} zone.", tier.name))
        end
    end
end

local function FloorCount()
    return min(MAX_FLOORS, tier.stages or 1)
end

local function BandOf(row)
    return BANDS[tonumber(row and row.band or "") or 1] or BANDS[1]
end

local function SliderX(floorNumber)
    local count = FloorCount()
    if count <= 1 then
        return 0
    end
    return (floorNumber - 1) / (count - 1) * preview.bar:GetWidth()
end

local function SetFloor(value, quiet)
    value = Clamp(value, 1, FloorCount())
    if value ~= state.floor[tier.id] then
        state.floor[tier.id] = value
        if not quiet then
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        RunMaster.Refresh()
    end
end

local function FloorAtCursor(bar)
    local x = GetCursorPosition() / bar:GetEffectiveScale() - bar:GetLeft()
    local count = FloorCount()
    return floor(Clamp(x / bar:GetWidth(), 0, 1) * (count - 1) + 1.5)
end

local function Pooled(pool, index, make)
    if not pool[index] then
        pool[index] = make()
    end
    return pool[index]
end

local function MakeSegment()
    local segment = {}
    segment.back = preview.bar:CreateTexture(nil, "BORDER")
    segment.back:SetHeight(6)
    segment.fill = preview.bar:CreateTexture(nil, "ARTWORK")
    segment.fill:SetHeight(6)
    segment.label = UI.Text(preview.bar, 9)
    segment.edge = Flat(preview.bar, "OVERLAY", 0.59, 0.51, 0.35, 1)
    segment.edge:SetWidth(1)
    segment.edge:SetHeight(13)
    return segment
end

local function MakeNotch()
    local notch = {}
    notch.groove = preview.bar:CreateTexture(nil, "OVERLAY")
    notch.groove:SetWidth(1)
    notch.groove:SetHeight(6)
    UI.Gradient(notch.groove, "VERTICAL", 0, 0, 0, 0.67, 0.24)
    notch.shine = preview.bar:CreateTexture(nil, "OVERLAY")
    notch.shine:SetWidth(1)
    notch.shine:SetHeight(6)
    UI.Gradient(notch.shine, "VERTICAL", 1, 0.94, 0.82, 0.04, 0.2)
    notch.tick = preview.bar:CreateTexture(nil, "ARTWORK")
    notch.tick:SetWidth(1)
    notch.tick:SetHeight(4)
    return notch
end

local function MakePin()
    local pin = CreateFrame("Button", nil, preview)
    pin:SetWidth(16)
    pin:SetHeight(16)
    pin:SetFrameLevel(preview:GetFrameLevel() + 3)
    pin.frame = Flat(pin, "BACKGROUND")
    pin.frame:SetPoint("TOPLEFT", pin, "TOPLEFT", -1, 1)
    pin.frame:SetPoint("BOTTOMRIGHT", pin, "BOTTOMRIGHT", 1, -1)
    pin.icon = pin:CreateTexture(nil, "ARTWORK")
    pin.icon:SetAllPoints(pin)
    UI.CropIcon(pin.icon)
    pin.shade = Flat(pin, "OVERLAY", 0, 0, 0, 0.45)
    pin.shade:SetAllPoints(pin)
    pin.glow = pin:CreateTexture(nil, "BACKGROUND")
    pin.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    pin.glow:SetBlendMode("ADD")
    pin.glow:SetVertexColor(1, 0.78, 0.35)
    pin.glow:SetWidth(30)
    pin.glow:SetHeight(30)
    pin.glow:SetPoint("CENTER", pin, "CENTER", 0, 0)
    pin.stem = Flat(preview, "ARTWORK")
    pin.stem:SetWidth(1)
    pin:SetScript("OnClick", function() SetFloor(this.floor) end)
    pin:SetScript("OnEnter", function()
        local row = FloorRow(tier, this.floor)
        if not row then
            return
        end
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(L("Floor {1} milestone", this.floor), 1, 0.82, 0)
        GameTooltip:AddLine(row.change, 1, 1, 1, 1)
        if row.reward ~= "" then
            GameTooltip:AddLine(L["First clear: "] .. row.reward .. ".", 0.25, 1, 0.25, 1)
        end
        GameTooltip:Show()
    end)
    pin:SetScript("OnLeave", function() GameTooltip:Hide() end)
    return pin
end

local function Bands(count)
    local ranges = {}
    for floorNumber = 1, count do
        local band = tonumber((FloorRow(tier, floorNumber) or {}).band or "") or 1
        local last = ranges[table.getn(ranges)]
        if last and last.band == band then
            last.last = floorNumber
        else
            tinsert(ranges, { band = band, first = floorNumber, last = floorNumber })
        end
    end
    return ranges
end

local function ShowSlider(count, current)
    for _, segment in ipairs(preview.segments) do
        segment.back:Hide()
        segment.fill:Hide()
        segment.label:Hide()
        segment.edge:Hide()
    end
    for _, notch in ipairs(preview.notches) do
        notch.groove:Hide()
        notch.shine:Hide()
        notch.tick:Hide()
    end
    for _, pin in ipairs(preview.pins) do
        pin:Hide()
        pin.stem:Hide()
    end
    if count <= 1 then
        preview.slider:Hide()
        return
    end
    preview.slider:Show()
    local ranges = Bands(count)
    local multi = table.getn(ranges) > 1
    for index, range in ipairs(ranges) do
        local segment = Pooled(preview.segments, index, MakeSegment)
        local band = BANDS[range.band] or BANDS[1]
        local color = multi and band.color or Look(tier).color
        local left = range.first == 1 and 0 or SliderX(range.first - 1)
        local right = SliderX(range.last)
        segment.back:ClearAllPoints()
        segment.back:SetPoint("LEFT", preview.bar, "LEFT", left, 0)
        segment.back:SetWidth(max(1, right - left))
        UI.Gradient(segment.back, "VERTICAL", color[1] * 0.42, color[2] * 0.42, color[3] * 0.42, 1, 0.8)
        segment.back:Show()
        local filled = min(right, SliderX(current)) - left
        if filled > 0 then
            segment.fill:ClearAllPoints()
            segment.fill:SetPoint("LEFT", preview.bar, "LEFT", left, 0)
            segment.fill:SetWidth(filled)
            UI.Gradient(segment.fill, "VERTICAL", color[1] * 0.75, color[2] * 0.75, color[3] * 0.75, 1, 1)
            segment.fill:SetVertexColor(color[1], color[2], color[3], 1)
            segment.fill:Show()
        end
        if multi then
            segment.label:ClearAllPoints()
            segment.label:SetPoint("TOP", preview.bar, "BOTTOMLEFT", (left + right) / 2, -14)
            segment.label:SetText(band.name .. "  " .. range.first .. "-" .. range.last)
            segment.label:SetTextColor(color[1], color[2], color[3])
            segment.label:Show()
            if index > 1 then
                segment.edge:ClearAllPoints()
                segment.edge:SetPoint("CENTER", preview.bar, "LEFT", left, 0)
                segment.edge:Show()
            end
        end
    end
    preview.shine:SetWidth(max(1, SliderX(current)))
    local edges = {}
    for _, range in ipairs(ranges) do
        edges[range.last] = true
    end
    local pins = 0
    for floorNumber = 1, count do
        local row = FloorRow(tier, floorNumber)
        local color = multi and BandOf(row).color or Look(tier).color
        local notch = Pooled(preview.notches, floorNumber, MakeNotch)
        local x = SliderX(floorNumber)
        if floorNumber > 1 and floorNumber < count and not edges[floorNumber] then
            notch.groove:ClearAllPoints()
            notch.groove:SetPoint("CENTER", preview.bar, "LEFT", x - 0.5, 0)
            notch.groove:Show()
            notch.shine:ClearAllPoints()
            notch.shine:SetPoint("CENTER", preview.bar, "LEFT", x + 0.5, 0)
            notch.shine:Show()
        end
        notch.tick:ClearAllPoints()
        notch.tick:SetPoint("TOP", preview.bar, "BOTTOMLEFT", x, -3)
        notch.tick:SetTexture(UI.FLAT)
        notch.tick:SetVertexColor(color[1], color[2], color[3], floorNumber <= current and 0.8 or 0.3)
        notch.tick:Show()
        local kind = row and row.kind or ""
        if MILESTONE_ICONS[kind] then
            pins = pins + 1
            local pin = Pooled(preview.pins, pins, MakePin)
            pin.floor = floorNumber
            pin.icon:SetTexture(Icon(MILESTONE_ICONS[kind]))
            pin:ClearAllPoints()
            pin:SetPoint("BOTTOM", preview.bar, "TOPLEFT", x, 14)
            pin.stem:ClearAllPoints()
            pin.stem:SetPoint("TOP", pin, "BOTTOM", 0, -1)
            pin.stem:SetPoint("BOTTOM", preview.bar, "TOP", 0, 2)
            pin.stem:SetPoint("LEFT", preview.bar, "LEFT", x, 0)
            if floorNumber == current then
                pin.frame:SetVertexColor(1, 0.84, 0.43, 1)
                pin.stem:SetVertexColor(1, 0.84, 0.43, 1)
                pin.glow:Show()
                pin.shade:Hide()
                SetDesaturation(pin.icon, false)
            elseif floorNumber < current then
                pin.frame:SetVertexColor(0.75, 0.63, 0.35, 1)
                pin.stem:SetVertexColor(0.75, 0.63, 0.35, 1)
                pin.glow:Hide()
                pin.shade:Hide()
                SetDesaturation(pin.icon, false)
            else
                pin.frame:SetVertexColor(0.35, 0.32, 0.26, 1)
                pin.stem:SetVertexColor(0.35, 0.32, 0.26, 1)
                pin.glow:Hide()
                pin.shade:Show()
                SetDesaturation(pin.icon, true)
            end
            pin:Show()
            pin.stem:Show()
        end
    end
    local tone = multi and BandOf(FloorRow(tier, current)).color or Look(tier).color
    local knobX = SliderX(current)
    preview.knob:ClearAllPoints()
    preview.knob:SetPoint("CENTER", preview.bar, "LEFT", knobX, 0)
    preview.knob:SetVertexColor(tone[1], tone[2], tone[3])
    local onPin = MILESTONE_ICONS[(FloorRow(tier, current) or {}).kind or ""]
    if onPin then
        preview.badge:Hide()
        preview.badgeStem:Hide()
    else
        preview.badge:ClearAllPoints()
        preview.badge:SetPoint("BOTTOM", preview.bar, "TOPLEFT", knobX, 36)
        preview.badge:SetBackdropColor(tone[1] * 0.18, tone[2] * 0.18, tone[3] * 0.18, 0.95)
        preview.badge:SetBackdropBorderColor(tone[1], tone[2], tone[3], 1)
        preview.badge.text:SetText(current)
        preview.badge.text:SetTextColor(tone[1], tone[2], tone[3])
        preview.badge:Show()
        preview.badgeStem:ClearAllPoints()
        preview.badgeStem:SetPoint("TOP", preview.badge, "BOTTOM", 0, 0)
        preview.badgeStem:SetPoint("BOTTOM", preview.bar, "TOP", 0, 4)
        preview.badgeStem:SetPoint("LEFT", preview.bar, "LEFT", knobX, 0)
        preview.badgeStem:SetVertexColor(tone[1] * 0.6, tone[2] * 0.6, tone[3] * 0.6, 1)
        preview.badgeStem:Show()
    end
end

local function StatValue(row, spec)
    local value = row and row[spec.key]
    if not value or value == "" then
        return "-"
    end
    return format(spec.format, value)
end

local function ShowStats(current, count)
    local row = FloorRow(tier, current)
    local first = FloorRow(tier, 1)
    local showRewards = count > 2
    local y = 0
    for index, spec in ipairs(STAT_ROWS) do
        local line = preview.stats[index]
        if spec.behavior then
            local info = tierInfo[tier.id]
            if info then
                line:ClearAllPoints()
                line:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -(y + 3))
                line:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -(y + 3))
                for cell, def in ipairs(BEHAVIOR_CELLS) do
                    line.values[cell]:SetText(info[def[2]] or "")
                end
                line:Show()
                y = y + 33
            else
                line:Hide()
            end
        elseif spec.rewards and not showRewards then
            line.label:Hide()
            if line.base then
                line.base:Hide()
                line.arrow:Hide()
                line.value:Hide()
            end
        else
            line.label:ClearAllPoints()
            line.label:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -y)
            line.label:Show()
            if spec.group then
                y = y + (index > 1 and 4 or 0)
                line.label:ClearAllPoints()
                line.label:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -y)
                y = y + 16
            else
                local value = StatValue(row, spec)
                local base = StatValue(first, spec)
                line.value:ClearAllPoints()
                line.value:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -y)
                line.value:SetText(value)
                line.value:Show()
                if current > 1 then
                    line.base:ClearAllPoints()
                    line.base:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", -72, -y - 1)
                    line.base:SetText(base)
                    line.base:Show()
                    line.arrow:ClearAllPoints()
                    line.arrow:SetPoint("TOP", preview.stats, "TOPRIGHT", -62, -y - 1)
                    line.arrow:Show()
                else
                    line.base:Hide()
                    line.arrow:Hide()
                end
                if spec.rewards then
                    line.value:SetTextColor(0.25, 1, 0.25)
                elseif value ~= base then
                    line.value:SetTextColor(1, 0.55, 0.47)
                else
                    line.value:SetTextColor(1, 1, 1)
                end
                y = y + STAT_STEP
            end
        end
    end
    return y
end

local function NextMilestone(current, count)
    for floorNumber = current + 1, count do
        local row = FloorRow(tier, floorNumber)
        if row and MILESTONE_ICONS[row.kind or ""] then
            return floorNumber, row
        end
    end
end

local function LowerFirst(text)
    return strlower(strsub(text, 1, 1)) .. strsub(text, 2)
end

local HARDER = "|cffff8a78"

local function ShowMilestone(current, count, y)
    local footer = preview.milestone
    footer:ClearAllPoints()
    footer:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -(y + 4))
    footer:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -(y + 4))
    local row = FloorRow(tier, current)
    local reward = row and row.reward or ""
    local done = row and row.cleared == "1"
    local rewardLine = reward ~= "" and L(done and "|cff9d9d9dFirst clear (done): {1}.|r" or "|cff40ff40First clear: {1}.|r", reward) or ""
    local onMilestone = row and MILESTONE_ICONS[row.kind or ""]
    local nextFloor, nextRow = NextMilestone(current, count)
    local harder = ""
    if onMilestone then
        harder = HARDER .. L["From here on: "] .. LowerFirst(row.change) .. "|r"
    elseif nextFloor then
        harder = Hex(MUTED) .. L["Floor "] .. nextFloor .. ":|r " .. HARDER .. LowerFirst(nextRow.change) .. "|r"
    end
    if rewardLine == "" and harder == "" then
        footer:Hide()
        return
    end
    local kind = onMilestone and row.kind or (nextRow and nextRow.kind)
    footer.icon:SetTexture(Icon(MILESTONE_ICONS[kind or ""] or "INV_Misc_Note_01"))
    SetDesaturation(footer.icon, not onMilestone)
    if onMilestone then
        footer.shade:Hide()
        footer.glow:Show()
    else
        footer.shade:Show()
        footer.glow:Hide()
    end
    footer.top:SetText(rewardLine ~= "" and rewardLine or harder)
    footer.bottom:SetText(rewardLine ~= "" and harder or "")
    footer:Show()
end

local function ShowPreview()
    local count = FloorCount()
    local sliding = count > 2
    local current = sliding and Clamp(state.floor[tier.id] or 1, 1, count) or count
    state.floor[tier.id] = current
    if sliding then
        preview.title:SetText(L["Floor difficulty preview"])
        preview.note:SetText(L["Drag the slider to see any floor."])
    else
        preview.title:SetText(L["Floor difficulty"])
        preview.note:SetText(count == 2 and L["Floor 2 compared with floor 1."] or "")
    end
    ShowSlider(sliding and count or 1, current)
    local top = sliding and SLIDER_Y + 30 or PREVIEW_TOP + 40
    preview.stats:ClearAllPoints()
    preview.stats:SetPoint("TOPLEFT", arena, "TOPLEFT", RIGHT_X + 2, -top)
    preview.stats:SetPoint("TOPRIGHT", arena, "TOPLEFT", RIGHT_X + RIGHT_WIDTH - 2, -top)
    local y = ShowStats(current, count)
    ShowMilestone(current, count, y)
end

local function BuildHead()
    head = {}
    head.art = arena:CreateTexture(nil, "BACKGROUND")
    head.art:SetPoint("TOPLEFT", arena, "TOPLEFT", 11, -11)
    head.art:SetPoint("TOPRIGHT", arena, "TOPRIGHT", -11, -11)
    head.art:SetHeight(160)
    head.art:SetVertexColor(0.27, 0.25, 0.27)
    head.fade = arena:CreateTexture(nil, "BORDER")
    head.fade:SetPoint("BOTTOMLEFT", head.art, "BOTTOMLEFT", 0, 0)
    head.fade:SetPoint("BOTTOMRIGHT", head.art, "BOTTOMRIGHT", 0, 0)
    head.fade:SetHeight(100)
    UI.Gradient(head.fade, "VERTICAL", UI.WINDOW_BG[1], UI.WINDOW_BG[2], UI.WINDOW_BG[3], 1, 0)
    head.tint = arena:CreateTexture(nil, "BORDER")
    head.tint:SetPoint("TOPLEFT", head.art, "TOPLEFT", 0, 0)
    head.tint:SetPoint("TOPRIGHT", head.art, "TOPRIGHT", 0, 0)
    head.tint:SetHeight(70)
    head.label = UI.Text(content, 11)
    head.label:SetPoint("TOPLEFT", arena, "TOPLEFT", LEFT_X, -38)
    head.label:SetTextColor(1, 0.82, 0)
    head.label:SetText(L["Difficulty"])
    head.name = UI.Text(content, 30, UI.TITLE_FONT)
    head.name:SetPoint("TOPLEFT", arena, "TOPLEFT", MID_X, -34)
    head.description = UI.Text(content, 10)
    head.description:SetPoint("LEFT", head.name, "RIGHT", 16, -2)
    head.description:SetJustifyH("LEFT")
    head.description:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    head.line = Hairline(content, W - 22 - MID_X)
    head.line:SetPoint("TOPLEFT", arena, "TOPLEFT", MID_X, -86)
end

local function BuildList()
    list = { rows = {} }
    list.panel = UI.Panel(content)
    list.panel:SetPoint("TOPLEFT", arena, "TOPLEFT", MID_X, -PANEL_TOP)
    list.panel:SetWidth(LIST_WIDTH)
    list.panel:SetHeight(H - 20 - PANEL_TOP)
    list.scroll = CreateFrame("ScrollFrame", "VanillaBonkRunMasterScroll", list.panel, "UIPanelScrollFrameTemplate")
    list.scroll:SetPoint("TOPLEFT", list.panel, "TOPLEFT", 6, -8)
    list.scroll:SetPoint("BOTTOMRIGHT", list.panel, "BOTTOMRIGHT", -28, 8)
    list.child = CreateFrame("Frame", nil, list.scroll)
    list.child:SetWidth(LIST_WIDTH - 36)
    list.child:SetHeight(1)
    list.scroll:SetScrollChild(list.child)
    list.tabs = UI.PanelTabs(list.panel, 8, function(index)
        local mode = MODES[index]
        state.mode[tier.id] = mode
        if mode ~= "zones" and not ChosenDungeon() then
            local first = FirstOpenDungeon()
            state.dungeon[tier.id] = first and first.key or nil
        end
        list.scroll:SetVerticalScroll(0)
        RunMaster.Refresh()
    end)
end

local function BuildBanner()
    banner = CreateFrame("Frame", nil, content)
    banner:SetPoint("TOPLEFT", arena, "TOPLEFT", RIGHT_X, -BANNER_TOP)
    banner:SetWidth(RIGHT_WIDTH)
    banner:SetHeight(BANNER_HEIGHT)
    banner:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
    banner:SetBackdropBorderColor(0.27, 0.24, 0.17, 1)
    banner:EnableMouse(true)
    banner.art = banner:CreateTexture(nil, "BACKGROUND")
    banner.art:SetAllPoints(banner)
    banner.map = CreateFrame("ScrollFrame", nil, banner)
    banner.map:SetAllPoints(banner)
    banner.map.canvas = CreateFrame("Frame", nil, banner.map)
    banner.map.canvas.textures = {}
    banner.map.canvas:SetWidth(ZONE_MAP_WIDTH)
    banner.map.canvas:SetHeight(ZONE_MAP_HEIGHT)
    banner.map:SetScrollChild(banner.map.canvas)
    banner.map:Hide()
    local overlay = CreateFrame("Frame", nil, banner)
    overlay:SetAllPoints(banner)
    overlay:SetFrameLevel(banner.map:GetFrameLevel() + 3)
    banner.fade = overlay:CreateTexture(nil, "BACKGROUND")
    banner.fade:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 1, 1)
    banner.fade:SetPoint("BOTTOMRIGHT", banner, "BOTTOMRIGHT", -1, 1)
    banner.fade:SetHeight(76)
    UI.Gradient(banner.fade, "VERTICAL", 0.04, 0.035, 0.045, 0.96, 0)
    banner.description = UI.Text(overlay, 10)
    banner.description:SetPoint("BOTTOMLEFT", banner, "BOTTOMLEFT", 13, 9)
    banner.description:SetWidth(RIGHT_WIDTH - 26)
    banner.description:SetJustifyH("LEFT")
    banner.description:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
    banner.name = UI.Text(overlay, 22, UI.TITLE_FONT)
    banner.name:SetPoint("BOTTOMLEFT", banner.description, "TOPLEFT", -1, 3)
    banner.name:SetTextColor(1, 0.82, 0)
    banner.tag = UI.Text(overlay, 9)
    banner.tag:SetPoint("BOTTOMLEFT", banner.name, "TOPLEFT", 1, 2)
    banner:SetScript("OnEnter", function()
        if not this.risk then
            return
        end
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(CHALLENGE_RISK, 1, 0.5, 0.5, 1)
        GameTooltip:AddLine(this.risk, 0.25, 1, 0.25, 1)
        GameTooltip:Show()
    end)
    banner:SetScript("OnLeave", function() GameTooltip:Hide() end)
end

local function BuildPreview()
    preview = CreateFrame("Frame", nil, content)
    preview:SetPoint("TOPLEFT", arena, "TOPLEFT", RIGHT_X, -PREVIEW_TOP)
    preview:SetWidth(RIGHT_WIDTH)
    preview:SetHeight(300)
    preview:EnableMouseWheel(true)
    preview:SetScript("OnMouseWheel", function()
        SetFloor((state.floor[tier.id] or 1) + (arg1 > 0 and 1 or -1))
    end)
    preview.title = UI.Text(preview, 13)
    preview.title:SetPoint("TOPLEFT", preview, "TOPLEFT", 2, 0)
    preview.title:SetTextColor(1, 0.82, 0)
    preview.note = UI.Text(preview, 9)
    preview.note:SetPoint("TOPLEFT", preview.title, "BOTTOMLEFT", 0, -4)
    preview.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    preview.slider = CreateFrame("Frame", nil, preview)
    preview.slider:SetAllPoints(preview)
    preview.bar = CreateFrame("Button", nil, preview.slider)
    preview.bar:SetPoint("TOPLEFT", arena, "TOPLEFT", RIGHT_X + SLIDER_INSET, -(SLIDER_Y - 3))
    preview.bar:SetWidth(RIGHT_WIDTH - 2 * SLIDER_INSET)
    preview.bar:SetHeight(6)
    preview.bar:SetHitRectInsets(-6, -6, -10, -10)
    preview.bar:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
    preview.bar:SetBackdropBorderColor(0.05, 0.045, 0.04, 1)
    preview.well = preview.bar:CreateTexture(nil, "BACKGROUND")
    preview.well:SetPoint("TOPLEFT", preview.bar, "TOPLEFT", -3, 3)
    preview.well:SetPoint("BOTTOMRIGHT", preview.bar, "BOTTOMRIGHT", 3, -3)
    UI.Gradient(preview.well, "VERTICAL", 0.045, 0.04, 0.05, 1, 1)
    preview.wellTop = Flat(preview.bar, "BACKGROUND", 0, 0, 0, 0.5)
    preview.wellTop:SetPoint("TOPLEFT", preview.well, "TOPLEFT", 0, 0)
    preview.wellTop:SetPoint("TOPRIGHT", preview.well, "TOPRIGHT", 0, 0)
    preview.wellTop:SetHeight(1)
    preview.wellBottom = Flat(preview.bar, "BACKGROUND", 1, 0.9, 0.7, 0.06)
    preview.wellBottom:SetPoint("BOTTOMLEFT", preview.well, "BOTTOMLEFT", 0, 0)
    preview.wellBottom:SetPoint("BOTTOMRIGHT", preview.well, "BOTTOMRIGHT", 0, 0)
    preview.wellBottom:SetHeight(1)
    preview.shine = preview.bar:CreateTexture(nil, "OVERLAY")
    preview.shine:SetPoint("TOPLEFT", preview.bar, "TOPLEFT", 0, 0)
    preview.shine:SetHeight(3)
    UI.Gradient(preview.shine, "VERTICAL", 1, 1, 1, 0, 0.3)
    preview.segments, preview.notches, preview.pins = {}, {}, {}
    preview.knobFrame = CreateFrame("Frame", nil, preview.bar)
    preview.knobFrame:SetAllPoints(preview.bar)
    preview.knobFrame:SetFrameLevel(preview.bar:GetFrameLevel() + 4)
    preview.knob = preview.knobFrame:CreateTexture(nil, "OVERLAY")
    preview.knob:SetTexture(KNOB_TEXTURE)
    preview.knob:SetWidth(18)
    preview.knob:SetHeight(18)
    preview.bar:RegisterForClicks("LeftButtonDown", "LeftButtonUp")
    preview.bar:SetScript("OnMouseDown", function()
        this.dragging = true
        SetFloor(FloorAtCursor(this))
    end)
    preview.bar:SetScript("OnMouseUp", function() this.dragging = nil end)
    preview.bar:SetScript("OnUpdate", function()
        if this.dragging then
            SetFloor(FloorAtCursor(this), true)
        end
    end)
    preview.badge = CreateFrame("Frame", nil, preview.slider)
    preview.badge:SetWidth(26)
    preview.badge:SetHeight(16)
    preview.badge:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    preview.badge.text = UI.Text(preview.badge, 10)
    preview.badge.text:SetPoint("CENTER", preview.badge, "CENTER", 0, 0)
    preview.badgeStem = Flat(preview.slider, "ARTWORK")
    preview.badgeStem:SetWidth(1)

    preview.stats = CreateFrame("Frame", nil, preview)
    preview.stats:SetHeight(1)
    for index, spec in ipairs(STAT_ROWS) do
        local line = {}
        if spec.behavior then
            line = CreateFrame("Frame", nil, preview.stats)
            line:SetHeight(30)
            line.values = {}
            for cell, def in ipairs(BEHAVIOR_CELLS) do
                local label = UI.Text(line, 10)
                local column = mod(cell - 1, 2)
                local rowIndex = floor((cell - 1) / 2)
                label:SetPoint("TOPLEFT", line, "TOPLEFT", column * (RIGHT_WIDTH / 2), -rowIndex * 15)
                label:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
                label:SetText(def[1])
                local value = UI.Text(line, 10)
                value:SetPoint("TOPRIGHT", line, "TOPLEFT", column * (RIGHT_WIDTH / 2) + RIGHT_WIDTH / 2 - (column == 0 and 14 or 4), -rowIndex * 15)
                value:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
                line.values[cell] = value
            end
        elseif spec.group then
            line.label = UI.Text(preview.stats, 10)
            line.label:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.label:SetText(spec.group)
        else
            line.label = UI.Text(preview.stats, 11)
            line.label:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
            line.label:SetText(spec.label)
            line.base = UI.Text(preview.stats, 10)
            line.base:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.arrow = UI.Text(preview.stats, 10, UI.NUMBER_FONT)
            line.arrow:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            line.arrow:SetText("->")
            line.value = UI.Text(preview.stats, 11)
        end
        preview.stats[index] = line
    end

    local footer = CreateFrame("Frame", nil, preview)
    footer:SetHeight(40)
    footer.line = Hairline(footer, RIGHT_WIDTH)
    footer.line:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, 0)
    footer.glow = footer:CreateTexture(nil, "BACKGROUND")
    footer.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
    footer.glow:SetBlendMode("ADD")
    footer.glow:SetVertexColor(1, 0.78, 0.35)
    footer.glow:SetWidth(44)
    footer.glow:SetHeight(44)
    footer.icon = footer:CreateTexture(nil, "ARTWORK")
    footer.icon:SetWidth(24)
    footer.icon:SetHeight(24)
    footer.icon:SetPoint("TOPLEFT", footer, "TOPLEFT", 0, -7)
    UI.CropIcon(footer.icon)
    footer.glow:SetPoint("CENTER", footer.icon, "CENTER", 0, 0)
    footer.shade = Flat(footer, "OVERLAY", 0, 0, 0, 0.4)
    footer.shade:SetAllPoints(footer.icon)
    footer.top = UI.Text(footer, 10)
    footer.top:SetPoint("TOPLEFT", footer.icon, "TOPRIGHT", 8, 1)
    footer.top:SetWidth(RIGHT_WIDTH - 34)
    footer.top:SetJustifyH("LEFT")
    footer.bottom = UI.Text(footer, 10)
    footer.bottom:SetPoint("TOPLEFT", footer.top, "BOTTOMLEFT", 0, -3)
    footer.bottom:SetWidth(RIGHT_WIDTH - 34)
    footer.bottom:SetJustifyH("LEFT")
    preview.milestone = footer
end

local startRow

local function StartFloor()
    local chosen = tier and state.start[tier.id] or 1
    for _, floorNumber in ipairs(tier and checkpoints[tier.id] or {}) do
        if floorNumber == chosen then
            return chosen
        end
    end
    return 1
end

local function CheckpointButton(index)
    local button = startRow.buttons[index]
    if button then
        return button
    end
    button = UI.Button(startRow, CHECKPOINT_BUTTON, "", function()
        PlaySound("igMainMenuOptionCheckBoxOn")
        state.start[tier.id] = this.floor
        if this.floor > 1 then
            state.floor[tier.id] = this.floor
        end
        RunMaster.Refresh()
    end)
    startRow.buttons[index] = button
    return button
end

local function ShowCheckpoints()
    local list = tier and checkpoints[tier.id]
    if not list or table.getn(list) == 0 or Mode() ~= "zones" then
        startRow:Hide()
        return
    end
    local chosen = StartFloor()
    local floors = { 1 }
    for _, floorNumber in ipairs(list) do
        tinsert(floors, floorNumber)
    end
    local x = 2
    for index, floorNumber in ipairs(floors) do
        local button = CheckpointButton(index)
        button.floor = floorNumber
        button:SetText(floorNumber)
        button:ClearAllPoints()
        button:SetPoint("TOPLEFT", startRow.label, "BOTTOMLEFT", x - 2, -6)
        if floorNumber == chosen then
            button:LockHighlight()
        else
            button:UnlockHighlight()
        end
        button:Show()
        x = x + CHECKPOINT_BUTTON + 4
    end
    for index = table.getn(floors) + 1, table.getn(startRow.buttons) do
        startRow.buttons[index]:Hide()
    end
    startRow.note:SetText(chosen > 1 and ("You start at level " .. (RunMaster.CheckpointLevel(chosen)) .. " and pick your build first. Skipped floors give only their glyph choices.")
        or "Checkpoints open 15 floors below your best floor for this class.")
    startRow:Show()
end

local function BuildCheckpoints()
    startRow = CreateFrame("Frame", nil, content)
    startRow:SetPoint("TOPLEFT", arena, "TOPLEFT", LEFT_X, -CHECKPOINT_Y)
    startRow:SetWidth(LEFT_WIDTH)
    startRow:SetHeight(60)
    startRow.label = UI.Text(startRow, 12)
    startRow.label:SetPoint("TOPLEFT", startRow, "TOPLEFT", 0, 0)
    startRow.label:SetTextColor(1, 0.82, 0)
    startRow.label:SetText("Start on floor")
    startRow.note = UI.Text(startRow, 9)
    startRow.note:SetPoint("TOPLEFT", startRow.label, "BOTTOMLEFT", 0, -34)
    startRow.note:SetWidth(LEFT_WIDTH)
    startRow.note:SetJustifyH("LEFT")
    startRow.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    startRow.buttons = {}
    startRow:Hide()
end

function RunMaster.CheckpointLevel(floorNumber)
    local steps = { { 1, 1 }, { 5, 69 }, { 10, 89 }, { 15, 96 }, { 20, 104 } }
    local last = steps[getn(steps)]
    if floorNumber >= last[1] then
        return last[2] + floor((floorNumber - last[1]) * 0.5 + 0.5)
    end
    for index = 2, getn(steps) do
        local low, high = steps[index - 1], steps[index]
        if floorNumber <= high[1] then
            return low[2] + floor((floorNumber - low[1]) / (high[1] - low[1]) * (high[2] - low[2]) + 0.5)
        end
    end
    return 1
end

local function Build()
    arena = VanillaBonkArena
    content = arena.content
    ladder = {}
    BuildHead()
    BuildList()
    BuildBanner()
    BuildPreview()
    BuildCheckpoints()
end

function RunMaster.SetTiers(tiers, selectedId, onClick)
    if not head then
        Build()
    end
    onTierClick = onClick
    for _, plaque in ipairs(ladder) do
        plaque:Hide()
    end
    for index, shown in ipairs(tiers) do
        FillPlaque(Plaque(index), shown, shown.id == selectedId)
    end
end

function RunMaster.Caption()
    if not tier then
        return ""
    end
    local mode = Mode()
    local dungeon = ChosenDungeon()
    local zone = ChosenZone()
    local place = zone and zone.name or L["Random zone"]
    if mode == "dungeon" and dungeon then
        place = dungeon.name
    elseif mode == "invasion" and dungeon then
        place = place .. L[", invaded"]
    end
    local start = StartFloor()
    if start > 1 and mode == "zones" then
        place = place .. ", floor " .. start
    end
    return tier.name .. "  ·  " .. place
end

function RunMaster.Refresh()
    if not tier then
        return
    end
    ShowHead()
    ShowList()
    ShowBanner()
    ShowPreview()
    ShowCheckpoints()
    if arena.tier == tier and arena.button then
        if tier.unlocked and RunMaster.CanStart(tier) then
            arena.button:Enable()
        else
            arena.button:Disable()
        end
        if arena.button.caption then
            arena.button.caption:SetText(RunMaster.Caption())
        end
    end
end

function RunMaster.Show(shownTier)
    if not head then
        Build()
    end
    tier = shownTier
    RunMaster.Refresh()
end

function RunMaster.CanStart(startTier)
    local previous = tier
    tier = startTier
    local ok = Mode() == "zones" or ChosenDungeon() ~= nil
    tier = previous
    return ok
end

function RunMaster.StartArgs(startTier)
    tier = startTier
    local args = tier.key
    local mode = Mode()
    local dungeon = ChosenDungeon()
    local zone = ChosenZone()
    if zone and mode ~= "dungeon" then
        args = args .. " " .. zone.key
    end
    if dungeon then
        args = args .. " " .. dungeon.key .. (mode == "invasion" and " invade" or "")
    end
    local start = StartFloor()
    if start > 1 and mode == "zones" then
        args = args .. " floor" .. start
    end
    return args
end

RunMaster.LEFT_X, RunMaster.LEFT_WIDTH = LEFT_X, LEFT_WIDTH
RunMaster.RIGHT_X, RunMaster.RIGHT_WIDTH = RIGHT_X, RIGHT_WIDTH
RunMaster.Hairline = Hairline
RunMaster.SOFT, RunMaster.MUTED = SOFT, MUTED

UI.Listen({
    mapinfo = function(f)
        if f[2] and f[2] ~= "" then
            mapInfo[f[2]] = { continent = f[3] or "", summary = f[4] or "", description = f[5] or "",
                file = f[6] or "", u = tonumber(f[7] or ""), v = tonumber(f[8] or "") }
        end
    end,
    tierinfo = function(f)
        if f[2] then
            tierInfo[f[2]] = { aim = f[3] or "", boss = f[4] or "", charge = (f[5] and f[5] ~= "") and L("every {1} sec", f[5]) or "",
                crowd = f[6] or "" }
        end
    end,
    checkpoints = function(f)
        local tierId = f[2]
        if not tierId or tierId == "" then
            return
        end
        local list = {}
        for _, text in ipairs(UI.Split(f[3] or "", ",")) do
            local floorNumber = tonumber(text)
            if floorNumber then
                tinsert(list, floorNumber)
            end
        end
        checkpoints[tierId] = list
    end,
    floor = function(f)
        local tierId, floorNumber = f[2], tonumber(f[3] or "")
        if not tierId or not floorNumber then
            return
        end
        floorInfo[tierId] = floorInfo[tierId] or {}
        floorInfo[tierId][floorNumber] = { health = f[4] or "", damage = f[5] or "", veterans = f[6] or "", affixes = f[7] or "",
            gold = f[8] or "", legendary = f[9] or "", change = f[10] or "", reward = f[11] or "", cleared = f[12] or "0",
            band = f[13] or "1", kind = f[14] or "" }
    end,
    zoneart = function(f)
        local file, texture = f[2], f[3]
        if not file or not texture or overlaySeen[file .. "\\" .. texture] then
            return
        end
        overlaySeen[file .. "\\" .. texture] = true
        zoneOverlays[file] = zoneOverlays[file] or {}
        tinsert(zoneOverlays[file], { texture = texture, width = tonumber(f[4]) or 0, height = tonumber(f[5]) or 0,
            x = tonumber(f[6]) or 0, y = tonumber(f[7]) or 0 })
        if banner then
            banner.map.file = nil
        end
    end,
})
