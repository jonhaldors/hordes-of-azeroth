local L = VanillaBonkL
local UI = VanillaBonkUI

VanillaBonkRunMaster = {}
local RunMaster = VanillaBonkRunMaster

local W, H = 920, 660
local LEFT_X, LEFT_WIDTH = 22, 214
local PLAQUE_TOP, PLAQUE_HEIGHT, PLAQUE_STEP = 56, 48, 56
local MID_X, LIST_WIDTH = 256, 290
local PANEL_TOP = 124
local RIGHT_X = MID_X + LIST_WIDTH + 14
local RIGHT_WIDTH = W - 22 - RIGHT_X
local BANNER_TOP, BANNER_HEIGHT = 100, 100
local PREVIEW_TOP = 212
local PICKER_WIDTH, PICKER_HEIGHT = 262, 22
local PICKER_X = RIGHT_X + (RIGHT_WIDTH - PICKER_WIDTH) / 2
local PICKER_TOP = H - 62 - 8 - PICKER_HEIGHT
local PICKER_ROWS, PICKER_ROW = 10, 18
local PICKER_LOCKED_AHEAD = 2
local BEST_BOTTOM = PICKER_TOP - 22
local BEST_LINE = 13
local ROW_HEIGHT, ROW_STEP, ROW_ICON = 34, 36, 26
local STAT_STEP = 15
local LOCK_ICON = "Interface\\ChatFrame\\UI-ChatFrame-LockIcon"
local OPEN_ARROW = "Interface\\Buttons\\UI-ScrollBar-ScrollUpButton-Up"
local NAME_COLOR = "|cff8a8278"
local RANDOM_ICON = "INV_Misc_QuestionMark"
local SOFT = { 0.78, 0.75, 0.7 }
local MUTED = { 0.51, 0.49, 0.44 }
local HAIR = { 0.47, 0.39, 0.24 }
local INVADED_COLOR = { 1, 0.6, 0.24 }
local CHALLENGE_RISK = L["Enemies have 30% more health and deal 20% more damage."]
local DUNGEON_REWARD = L["Enemies drop 25% more gold, and mini-bosses drop gear twice as often."]
local INVASION_REWARD = L["More enemies come at once. They drop 25% more gold, and mini-bosses drop gear 50% more often."]
local TIER_LOOKS = {
    normal = { color = { 1, 0.82, 0 }, emblem = "Ability_Warrior_DefensiveStance" },
    heroic = { color = { 0.38, 0.65, 1 }, emblem = "INV_Shield_05" },
    mythic = { color = { 0.77, 0.4, 1 }, emblem = "INV_Misc_Bone_HumanSkull_01" },
}
local DEFAULT_LOOK = TIER_LOOKS.normal
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
    { label = L["Gear drops"], key = "dropTier", tier = true, rewards = true },
    { label = L["White gear"], key = "white", format = "%s%%", rewards = true, odds = true, color = { 1, 1, 1 } },
    { label = L["Green gear"], key = "green", format = "%s%%", rewards = true, odds = true, color = { 0.12, 1, 0 } },
    { label = L["Blue gear"], key = "blue", format = "%s%%", rewards = true, odds = true, color = { 0, 0.44, 0.87 } },
    { label = L["Epic gear"], key = "epic", format = "%s%%", rewards = true, odds = true, luck = true, color = { 0.64, 0.21, 0.93 } },
    { luckHint = true },
    { label = L["Boss drops legendary"], key = "legendary", format = "%s%%", rewards = true, odds = true, color = { 1, 0.5, 0 } },
}

local state = { zone = {}, dungeon = {}, mode = {}, level = {} }
local mapInfo = {}
local levelInfo = {}
local levelBests = {}
local tierInfo = {}
local epicLuck = 0
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

local function LevelsText(shown)
    if (shown.levels or 0) == 0 then
        return L["Endless levels"]
    end
    return L("{1} levels", shown.levels)
end

local function LevelRow(shown, index)
    return (levelInfo[shown.id] or {})[index]
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
    if (shown.levels or 0) > 0 and shown.best >= shown.levels then
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
    plaque.state:SetText(LevelsText(shown) .. "  ·  " .. Progress(shown))
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
        GameTooltip:AddLine(L("Stage 1 takes you to any {1} zone.", tier.name), 1, 1, 1, 1)
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
            local tag = map.reward and map.reward ~= 100 and ("|cff40ff40" .. Multiplier(map.reward) .. L["x Tickets and Mastery|r"]) or nil
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
        banner.tag:SetText(Hex(INVADED_COLOR) .. L["Dungeon challenge  ·  every stage inside|r"])
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
                banner.tag:SetText(L["|cff40ff40Pays "] .. Multiplier(zone.reward) .. L["x Tickets and Mastery|r"])
            else
                banner.tag:SetText("")
            end
            banner.description:SetText(zone and (info.description or "") or L("Stage 1 takes you to any {1} zone.", tier.name))
        end
    end
end

local function LevelCount()
    return max(1, table.getn(levelInfo[tier.id] or {}))
end

local function OpenBand()
    return Clamp(tier.open or 1, 1, LevelCount())
end

local function ChosenLevel()
    return Clamp(state.level[tier.id] or OpenBand(), 1, OpenBand())
end

local function SetLevel(value, quiet)
    value = Clamp(value, 1, OpenBand())
    if value ~= state.level[tier.id] then
        state.level[tier.id] = value
        if not quiet then
            PlaySound("igMainMenuOptionCheckBoxOn")
        end
        RunMaster.Refresh()
    end
end

local function LevelName(band)
    return L("{1} {2}", tier.name, band)
end

local function PickerEntries()
    local open = OpenBand()
    local top = (tier.levels or 0) > 0 and LevelCount() or open + PICKER_LOCKED_AHEAD
    local entries = {}
    for band = top, 1, -1 do
        local row = LevelRow(tier, band)
        local kind = "cleared"
        if band > open then
            kind = "locked"
        elseif not row or row.cleared ~= "1" then
            kind = "next"
        end
        tinsert(entries, { band = band, state = kind })
    end
    return entries
end

local function FillChoices()
    local choices = preview.choices
    local entries = PickerEntries()
    local count = table.getn(entries)
    local visible = min(count, PICKER_ROWS)
    choices.offset = Clamp(choices.offset or 0, 0, count - visible)
    choices:SetHeight(visible * PICKER_ROW + 8)
    local color = Look(tier).color
    local current = ChosenLevel()
    for index, row in ipairs(choices.rows) do
        local entry = entries[index + choices.offset]
        if index > visible or not entry then
            row:Hide()
        else
            row.band = entry.state ~= "locked" and entry.band or nil
            local selected = entry.band == current
            row.name:SetText(LevelName(entry.band))
            if entry.state == "locked" then
                row.lock:Show()
            else
                row.lock:Hide()
            end
            if selected then
                row.selected:Show()
            else
                row.selected:Hide()
            end
            row.selected:SetVertexColor(color[1], color[2], color[3], 0.35)
            if entry.state == "locked" then
                row.name:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
                row.note:SetText(L("Clear {1}", LevelName(entry.band - 1)))
                row.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
            else
                row.name:SetTextColor(selected and 1 or color[1], selected and 1 or color[2], selected and 1 or color[3])
                row.note:SetText(entry.state == "next" and L["next"] or L["cleared"])
                if entry.state == "next" then
                    row.note:SetTextColor(1, 0.82, 0)
                else
                    row.note:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
                end
            end
            row:Show()
        end
    end
    if count > visible then
        local track = visible * PICKER_ROW - 4
        local thumb = max(12, track * visible / count)
        choices.thumb:SetHeight(thumb)
        choices.thumb:ClearAllPoints()
        choices.thumb:SetPoint("TOPRIGHT", choices, "TOPRIGHT", -4, -6 - (track - thumb) * choices.offset / (count - visible))
        choices.thumb:Show()
    else
        choices.thumb:Hide()
    end
end

local function OpenChoices()
    local choices = preview.choices
    local entries = PickerEntries()
    local top = entries[1] and entries[1].band or 1
    choices.offset = (top - ChosenLevel()) - 3
    FillChoices()
    choices:Show()
end

local function ShowPicker(current)
    local color = Look(tier).color
    preview.pickerLabel:SetText(L("{1} level", tier.name))
    preview.picker.text:SetText(LevelName(current))
    preview.picker.text:SetTextColor(color[1], color[2], color[3])
    local best = 0
    for band = 1, LevelCount() do
        local row = LevelRow(tier, band)
        if row and row.cleared == "1" then
            best = band
        end
    end
    preview.picker.best:SetText(best > 0 and L("best {1}", LevelName(best)) or "")
    if preview.choices:IsShown() then
        FillChoices()
    end
end

local function ShortNumber(value)
    if value >= 1000000 then
        return format("%.1fM", value / 1000000)
    elseif value >= 1000 then
        return format("%.1fk", value / 1000)
    end
    return tostring(value)
end

local function GoldText(copper)
    local gold, silver = floor(copper / 10000), floor(mod(copper, 10000) / 100)
    local text = format(L["|cffc7c7cf%ds|r "], silver)
    if gold > 0 then
        text = format(L["|cffffd700%dg|r "], gold) .. text
    end
    return text
end

local function ByName(value, name)
    if not name or name == "" then
        return value
    end
    return value .. " " .. NAME_COLOR .. name .. "|r"
end

local function ShowBest(current)
    local best = preview.best
    local record = (levelBests[tier.id] or {})[current]
    best.title:SetText(L("Your best on {1}", LevelName(current)))
    best.note:ClearAllPoints()
    if not record then
        for _, line in ipairs(best.lines) do
            line.label:Hide()
            line.value:Hide()
        end
        best.clears:SetText("")
        best.note:SetPoint("TOPLEFT", best.title, "BOTTOMLEFT", 0, -4)
        best.note:SetText(L["No clears on this level yet."])
        return
    end
    best.note:SetPoint("BOTTOMLEFT", best, "BOTTOMLEFT", 0, 0)
    best.clears:SetText(record.clears == 1 and L["cleared once"] or L("cleared {1} times", record.clears))
    local values = {
        ByName(UI.FormatTime(floor(record.bestMs / 1000)), record.bestMsBy),
        ByName(UI.Thousands(record.kills), record.killsBy),
        ByName(L("{1}/s", ShortNumber(record.damage)), record.damageBy),
        ByName(GoldText(record.gold), record.goldBy),
        ByName(UI.Thousands(record.valor), record.valorBy),
    }
    for index, line in ipairs(best.lines) do
        line.value:SetText(values[index])
        line.label:Show()
        line.value:Show()
    end
    local note = L("First cleared {1}.", date("%Y-%m-%d", record.first))
    if record.finale > 0 then
        note = note .. " " .. L("Best finale: {1} survived, score {2}.", UI.FormatTime(record.finaleSeconds), record.finale)
    end
    best.note:SetText(note)
end

local DROP_QUALITIES = { { key = "white", quality = 1 }, { key = "green", quality = 2 }, { key = "blue", quality = 3 }, { key = "epic", quality = 4 } }

local function DroppedQualities(row)
    local low, high
    for _, drop in ipairs(DROP_QUALITIES) do
        if (tonumber(row[drop.key] or "") or 0) > 0 then
            low = low or drop.quality
            high = drop.quality
        end
    end
    return low or 1, high or 1
end

local function StatValue(row, spec, withLuck)
    local value = row and row[spec.key]
    if not value or value == "" then
        return "-"
    end
    if spec.tier then
        local low, high = DroppedQualities(row)
        return UI.ItemLevelRange(tonumber(value) or 1, low, high)
    end
    local text = format(spec.format, value)
    if withLuck and spec.luck and epicLuck > 0 and (tonumber(value) or 0) > 0 then
        return text .. " " .. L("(+{1}%)", epicLuck)
    end
    return text
end

local function HiddenOdds(row, spec)
    if not spec.odds then
        return false
    end
    local value = tonumber(row and row[spec.key] or "")
    return not value or value <= 0
end

local function HideStatLine(line)
    line.label:Hide()
    line.value:Hide()
    line.base:Hide()
    line.arrow:Hide()
    if line.hover then
        line.hover:Hide()
    end
end

local function ShowStats(current)
    local row = LevelRow(tier, current)
    local first = LevelRow(tier, 1)
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
        elseif spec.luckHint then
            if epicLuck > 0 and (tonumber(row and row.epic or "") or 0) > 0 then
                line.label:ClearAllPoints()
                line.label:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -y)
                line.label:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -y)
                line.label:SetText(L("Bad luck protection adds {1}% until an epic drops.", epicLuck))
                line.label:Show()
                line.hover:ClearAllPoints()
                line.hover:SetAllPoints(line.label)
                line.hover:Show()
                y = y + STAT_STEP
            else
                line.label:Hide()
                line.hover:Hide()
            end
        elseif HiddenOdds(row, spec) then
            HideStatLine(line)
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
                local value = StatValue(row, spec, true)
                local base = StatValue(first, spec)
                line.value:ClearAllPoints()
                line.value:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -y)
                line.value:SetText(value)
                line.value:Show()
                if line.hover and epicLuck > 0 then
                    line.hover:ClearAllPoints()
                    line.hover:SetPoint("TOPLEFT", preview.stats, "TOPLEFT", 0, -y)
                    line.hover:SetPoint("TOPRIGHT", preview.stats, "TOPRIGHT", 0, -y)
                    line.hover:Show()
                elseif line.hover then
                    line.hover:Hide()
                end
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
                if spec.color then
                    line.value:SetTextColor(spec.color[1], spec.color[2], spec.color[3])
                elseif spec.rewards then
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

local function ShowPreview()
    local current = ChosenLevel()
    state.level[tier.id] = current
    preview.title:SetText(LevelName(current))
    preview.note:SetText(L["Clearing this level opens the next one."])
    local top = PREVIEW_TOP + 40
    preview.stats:ClearAllPoints()
    preview.stats:SetPoint("TOPLEFT", arena, "TOPLEFT", RIGHT_X + 2, -top)
    preview.stats:SetPoint("TOPRIGHT", arena, "TOPLEFT", RIGHT_X + RIGHT_WIDTH - 2, -top)
    ShowStats(current)
    ShowBest(current)
    ShowPicker(current)
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
    preview:SetHeight(360)
    preview:EnableMouseWheel(true)
    preview:SetScript("OnMouseWheel", function()
        SetLevel(ChosenLevel() + (arg1 > 0 and 1 or -1))
    end)
    preview.title = UI.Text(preview, 13)
    preview.title:SetPoint("TOPLEFT", preview, "TOPLEFT", 2, 0)
    preview.title:SetTextColor(1, 0.82, 0)
    preview.note = UI.Text(preview, 9)
    preview.note:SetPoint("TOPLEFT", preview.title, "BOTTOMLEFT", 0, -4)
    preview.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    preview:SetScript("OnHide", function() preview.choices:Hide() end)

    preview.best = CreateFrame("Frame", nil, preview)
    preview.best:SetPoint("BOTTOMLEFT", arena, "TOPLEFT", RIGHT_X + 2, -BEST_BOTTOM)
    preview.best:SetWidth(RIGHT_WIDTH - 4)
    preview.best:SetHeight(15 + 5 * BEST_LINE + 14)
    preview.best.title = UI.Text(preview.best, 10)
    preview.best.title:SetPoint("TOPLEFT", preview.best, "TOPLEFT", 0, 0)
    preview.best.title:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    preview.best.clears = UI.Text(preview.best, 9)
    preview.best.clears:SetPoint("TOPRIGHT", preview.best, "TOPRIGHT", 0, 0)
    preview.best.clears:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    preview.best.lines = {}
    local labels = { L["Fastest clear"], L["Most kills"], L["Top damage"], L["Gold per minute"], L["Valor per minute"] }
    for index, text in ipairs(labels) do
        local y = -(15 + (index - 1) * BEST_LINE)
        local line = {}
        line.label = UI.Text(preview.best, 10)
        line.label:SetPoint("TOPLEFT", preview.best, "TOPLEFT", 0, y)
        line.label:SetTextColor(SOFT[1], SOFT[2], SOFT[3])
        line.label:SetText(text)
        line.value = UI.Text(preview.best, 10)
        line.value:SetPoint("TOPRIGHT", preview.best, "TOPRIGHT", 0, y)
        preview.best.lines[index] = line
    end
    preview.best.note = UI.Text(preview.best, 9)
    preview.best.note:SetWidth(RIGHT_WIDTH - 4)
    preview.best.note:SetJustifyH("LEFT")
    preview.best.note:SetTextColor(MUTED[1], MUTED[2], MUTED[3])

    preview.pickerLabel = UI.Text(preview, 10)
    preview.pickerLabel:SetPoint("BOTTOMLEFT", arena, "TOPLEFT", PICKER_X, -(PICKER_TOP - 3))
    preview.pickerLabel:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    preview.picker = CreateFrame("Button", nil, preview)
    preview.picker:SetPoint("TOPLEFT", arena, "TOPLEFT", PICKER_X, -PICKER_TOP)
    preview.picker:SetWidth(PICKER_WIDTH)
    preview.picker:SetHeight(PICKER_HEIGHT)
    preview.picker:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    preview.picker:SetBackdropColor(0.07, 0.05, 0.04, 1)
    preview.picker:SetBackdropBorderColor(HAIR[1], HAIR[2], HAIR[3], 1)
    preview.picker:SetHighlightTexture(UI.FLAT)
    preview.picker:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.06)
    preview.picker.text = UI.Text(preview.picker, 12)
    preview.picker.text:SetPoint("LEFT", preview.picker, "LEFT", 8, 0)
    preview.picker.arrow = preview.picker:CreateTexture(nil, "OVERLAY")
    preview.picker.arrow:SetTexture(OPEN_ARROW)
    preview.picker.arrow:SetWidth(22)
    preview.picker.arrow:SetHeight(22)
    preview.picker.arrow:SetPoint("RIGHT", preview.picker, "RIGHT", 0, 0)
    preview.picker.best = UI.Text(preview.picker, 9)
    preview.picker.best:SetPoint("RIGHT", preview.picker.arrow, "LEFT", -4, 0)
    preview.picker.best:SetTextColor(MUTED[1], MUTED[2], MUTED[3])
    preview.picker:SetScript("OnClick", function()
        if preview.choices:IsShown() then
            preview.choices:Hide()
        else
            OpenChoices()
        end
        PlaySound("igMainMenuOptionCheckBoxOn")
    end)

    local choices = CreateFrame("Frame", nil, preview)
    preview.choices = choices
    choices:SetPoint("BOTTOMLEFT", preview.picker, "TOPLEFT", 0, 4)
    choices:SetWidth(PICKER_WIDTH)
    choices:SetFrameLevel(preview.picker:GetFrameLevel() + 10)
    choices:SetBackdrop({ bgFile = UI.FLAT, edgeFile = UI.FLAT, edgeSize = 1, insets = { left = 1, right = 1, top = 1, bottom = 1 } })
    choices:SetBackdropColor(0.06, 0.045, 0.035, 0.98)
    choices:SetBackdropBorderColor(0.55, 0.43, 0.17, 1)
    choices:EnableMouse(true)
    choices:EnableMouseWheel(true)
    choices:SetScript("OnMouseWheel", function()
        this.offset = (this.offset or 0) - arg1
        FillChoices()
    end)
    choices.thumb = Flat(choices, "OVERLAY", 0.55, 0.43, 0.17, 1)
    choices.thumb:SetWidth(4)
    choices.rows = {}
    for index = 1, PICKER_ROWS do
        local row = CreateFrame("Button", nil, choices)
        row:SetPoint("TOPLEFT", choices, "TOPLEFT", 4, -4 - (index - 1) * PICKER_ROW)
        row:SetWidth(PICKER_WIDTH - 16)
        row:SetHeight(PICKER_ROW)
        row:SetHighlightTexture(UI.FLAT)
        row:GetHighlightTexture():SetVertexColor(1, 1, 1, 0.07)
        row.selected = Flat(row, "BACKGROUND")
        row.selected:SetAllPoints(row)
        row.lock = row:CreateTexture(nil, "ARTWORK")
        row.lock:SetTexture(LOCK_ICON)
        row.lock:SetWidth(12)
        row.lock:SetHeight(12)
        row.lock:SetPoint("LEFT", row, "LEFT", 4, 0)
        row.lock:SetAlpha(0.6)
        row.name = UI.Text(row, 11)
        row.name:SetPoint("LEFT", row, "LEFT", 20, 0)
        row.note = UI.Text(row, 9)
        row.note:SetPoint("RIGHT", row, "RIGHT", -4, 0)
        row:SetScript("OnClick", function()
            if not this.band then
                return
            end
            choices:Hide()
            SetLevel(this.band)
        end)
        choices.rows[index] = row
    end
    choices:Hide()

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
        elseif spec.luckHint then
            line.label = UI.Text(preview.stats, 10)
            line.label:SetJustifyH("RIGHT")
            line.label:SetTextColor(0.75, 0.55, 0.95)
            line.hover = CreateFrame("Button", nil, preview.stats)
            line.hover:SetScript("OnEnter", function()
                GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                GameTooltip:AddLine(L["Bad luck protection"], 0.64, 0.21, 0.93)
                GameTooltip:AddLine(L("Your epic chance on Mythic levels is raised by {1}%.", epicLuck), 1, 1, 1, 1)
                GameTooltip:AddLine(L["Every Mythic gear drop that isn't an epic adds 5%. It resets when an epic or legendary drops."], 0.8, 0.8, 0.8, 1)
                GameTooltip:Show()
            end)
            line.hover:SetScript("OnLeave", function()
                GameTooltip:Hide()
            end)
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
            if spec.luck then
                line.hover = CreateFrame("Button", nil, preview.stats)
                line.hover:SetHeight(STAT_STEP)
                line.hover:SetScript("OnEnter", function()
                    GameTooltip:SetOwner(this, "ANCHOR_RIGHT")
                    GameTooltip:AddLine(L["Bad luck protection"], 0.64, 0.21, 0.93)
                    GameTooltip:AddLine(L("Your epic chance on Mythic levels is raised by {1}%.", epicLuck), 1, 1, 1, 1)
                    GameTooltip:AddLine(L["Every Mythic gear drop that isn't an epic adds 5%. It resets when an epic or legendary drops."], 0.8, 0.8, 0.8, 1)
                    GameTooltip:Show()
                end)
                line.hover:SetScript("OnLeave", function()
                    GameTooltip:Hide()
                end)
            end
        end
        preview.stats[index] = line
    end
end

local function Build()
    arena = VanillaBonkArena
    content = arena.content
    ladder = {}
    BuildHead()
    BuildList()
    BuildBanner()
    BuildPreview()
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
    return L("{1} {2}", tier.name, ChosenLevel()) .. "  ·  " .. place
end

function RunMaster.Refresh()
    if not tier then
        return
    end
    ShowHead()
    ShowList()
    ShowBanner()
    ShowPreview()
    if arena.tier == tier and arena.button then
        if tier.unlocked and RunMaster.CanStart(tier) then
            arena.button:Enable()
        else
            arena.button:Disable()
        end
        if arena.button.caption then
            arena.button.caption:SetText(RunMaster.Caption())
        end
        if not arena.button.legacy then
            arena.button.legacy = UI.Text(arena.button, 9)
            arena.button.legacy:SetPoint("TOP", arena.button, "BOTTOM", 0, -2)
            arena.button.legacy:SetTextColor(1, 0.45, 0.35)
        end
        arena.button.legacy:SetText(tier.key == "mythic" and UI.WearsLegacyGear() and L["You're wearing legacy gear. This run won't count for the leaderboard."] or "")
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
    return args .. " " .. ChosenLevel()
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
    epicluck = function(f)
        epicLuck = tonumber(f[2] or "") or 0
    end,
    tierinfo = function(f)
        if f[2] then
            levelInfo[f[2]] = {}
            levelBests[f[2]] = {}
            tierInfo[f[2]] = { aim = f[3] or "", boss = f[4] or "", charge = (f[5] and f[5] ~= "") and L("every {1} sec", f[5]) or "",
                crowd = f[6] or "" }
        end
    end,
    level = function(f)
        local tierId, band = f[2], tonumber(f[3] or "")
        if not tierId or not band then
            return
        end
        levelInfo[tierId] = levelInfo[tierId] or {}
        levelInfo[tierId][band] = { health = f[4] or "", damage = f[5] or "", veterans = f[6] or "", affixes = f[7] or "",
            gold = f[8] or "", legendary = f[9] or "", epic = f[10] or "", blue = f[11] or "", green = f[12] or "", white = f[13] or "",
            cleared = f[14] or "0", dropTier = f[15] or "" }
    end,
    levelbest = function(f)
        local tierId, band = f[2], tonumber(f[3] or "")
        if not tierId or not band then
            return
        end
        levelBests[tierId] = levelBests[tierId] or {}
        levelBests[tierId][band] = { clears = tonumber(f[4] or "") or 0, first = tonumber(f[5] or "") or 0, bestMs = tonumber(f[6] or "") or 0,
            bestMsBy = f[7] or "", damage = tonumber(f[8] or "") or 0, damageBy = f[9] or "", kills = tonumber(f[10] or "") or 0,
            killsBy = f[11] or "", gold = tonumber(f[12] or "") or 0, goldBy = f[13] or "", valor = tonumber(f[14] or "") or 0,
            valorBy = f[15] or "", finale = tonumber(f[16] or "") or 0, finaleSeconds = tonumber(f[17] or "") or 0 }
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
