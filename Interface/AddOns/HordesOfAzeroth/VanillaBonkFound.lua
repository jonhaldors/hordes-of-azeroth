local L = VanillaBonkL
local UI = VanillaBonkUI

local REFRESH_DELAY = 0.4
local REFRESH_GAP = 1.0
UI.FOUND_LINE_COLOR = { 1, 0.4, 0.8 }

local found, incoming = {}, nil

local function ParseLines(text)
    local lines = {}
    for _, pair in ipairs(UI.Split(text or "", ",")) do
        local colon = strfind(pair, ":", 1, true)
        local stat = colon and tonumber(strsub(pair, 1, colon - 1))
        if stat then
            tinsert(lines, { stat = stat, value = tonumber(strsub(pair, colon + 1)) or 0 })
        end
    end
    return lines
end

function UI.ParseFound(tier, linesText, extraText)
    local tierNumber = tonumber(tier or "") or 0
    if tierNumber <= 0 then
        return nil
    end
    local extra = {}
    for _, line in ipairs(ParseLines(extraText)) do
        extra[line.stat] = line.value
    end
    return { tier = tierNumber, lines = ParseLines(linesText), extra = extra }
end

local function ItemIdAt(bag, slot)
    local link
    if bag == "inv" then
        link = GetInventoryItemLink("player", slot)
    else
        link = GetContainerItemLink(bag, slot)
    end
    local _, _, id = strfind(link or "", "item:(%d+)")
    return tonumber(id)
end

function UI.FoundAt(bag, slot)
    if not bag or not slot then
        return nil
    end
    local piece = found[bag .. ":" .. slot]
    if piece and ItemIdAt(bag, slot) == piece.entry then
        return piece
    end
    return nil
end

function UI.FoundWorn(entry)
    if not entry then
        return nil
    end
    for place, piece in pairs(found) do
        if piece.entry == entry and strsub(place, 1, 4) == "inv:" then
            return UI.FoundAt("inv", tonumber(strsub(place, 5)))
        end
    end
    return nil
end

function UI.WearsLegacyGear()
    for slot = 1, 19 do
        local piece = UI.FoundAt("inv", slot)
        if piece and piece.legacy then
            return true
        end
    end
    return false
end

function UI.TakeHyperlinkFound()
    local piece = UI.nextFound
    UI.nextFound = nil
    return piece
end

local ITEM_LEVEL_PER_SCALE = 10
local ITEM_LEVEL_TIER_STEP = 0.25
local ITEM_LEVEL_BLUE = 1.1
local ITEM_LEVEL_EPIC = 1.45

function UI.ItemLevel(tier, quality)
    local scale = 1 + ITEM_LEVEL_TIER_STEP * (math.max(tier or 1, 1) - 1)
    local qualityScale = 1
    if (quality or 0) >= 4 then
        qualityScale = ITEM_LEVEL_EPIC
    elseif quality == 3 then
        qualityScale = ITEM_LEVEL_BLUE
    end
    return floor(ITEM_LEVEL_PER_SCALE * scale * qualityScale + 0.5)
end

function UI.ItemLevelText(tier, quality)
    return L("ilvl {1}", UI.ItemLevel(tier, quality))
end

function UI.ItemLevelRange(tier, lowQuality, highQuality)
    return L("ilvl {1}-{2}", UI.ItemLevel(tier, lowQuality), UI.ItemLevel(tier, highQuality))
end

function UI.FoundLineText(piece)
    local count = piece and table.getn(piece.lines) or 0
    if count == 0 then
        return ""
    end
    return count == 1 and L["1 bonus stat"] or L("{1} bonus stats", count)
end

local handlers = {}

handlers["foundclear"] = function()
    incoming = {}
end

handlers["founditem"] = function(f)
    local place, entry = f[2], tonumber(f[3] or "")
    local piece = UI.ParseFound(f[4], f[5], f[6])
    if not incoming or not place or not entry or not piece then
        return
    end
    piece.entry = entry
    piece.legacy = f[7] == "1"
    incoming[place] = piece
end

handlers["foundend"] = function()
    if incoming then
        found = incoming
        incoming = nil
    end
end

UI.Listen(handlers)

local refresh = CreateFrame("Frame")
refresh:Hide()
refresh.wait = 0
refresh.since = REFRESH_GAP
refresh:SetScript("OnUpdate", function()
    this.since = this.since + arg1
    this.wait = this.wait - arg1
    if this.wait > 0 or this.since < REFRESH_GAP then
        return
    end
    this:Hide()
    this.since = 0
    SendChatMessage(".bonk gear found", "SAY")
end)

local inWorld = false
local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("UNIT_INVENTORY_CHANGED")
events:RegisterEvent("BANKFRAME_OPENED")
events:RegisterEvent("PLAYERBANKSLOTS_CHANGED")
events:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
        return
    end
    if not inWorld or (event == "UNIT_INVENTORY_CHANGED" and arg1 ~= "player") then
        return
    end
    refresh.wait = REFRESH_DELAY
    refresh:Show()
end)
