local L = VanillaBonkL
local UI = VanillaBonkUI

local QUESTION_MARK = "INV_Misc_QuestionMark"
local GAP = 3
local HOLD_STEP = 0.1
local PRUNE_INTERVAL = 5
local HALF_MASK = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\HalfMask"
local TURN_MASK_SCALE = 1.5
local PIE_OVERLAP = 2
local SPENT_SHADE = 0.35

UI.DEBUFF_LOOKS = {
    small = { size = 12, count = 9 },
    plate = { size = 14, count = 10 },
    boss = { size = 16, count = 11 },
    bar = { size = 22, count = 14, mouse = true },
    group = { size = 18, count = 12, mouse = true },
}

local keywords = {}
local keywordsBySpell = {}
local auraSlots = {}
local timers = {}
local rows = {}

local function KeywordEntry(id)
    local keyword = keywords[id]
    if not keyword then
        keyword = { id = id, name = "", icon = UI.ICON_PATH .. QUESTION_MARK, description = "", maxStacks = 1, color = UI.DamageType() }
        keywords[id] = keyword
    end
    return keyword
end

function UI.Keyword(id)
    return keywords[id]
end

local function SortByKeyword(list, count)
    for index = 2, count do
        local entry = list[index]
        local slot = index
        while slot > 1 and list[slot - 1].keyword.id > entry.keyword.id do
            list[slot] = list[slot - 1]
            slot = slot - 1
        end
        list[slot] = entry
    end
end

local function StoreDebuff(list, count, keyword, stacks)
    local entry = list[count]
    if not entry then
        entry = {}
        list[count] = entry
    end
    entry.keyword = keyword
    entry.stacks = stacks
end

function UI.ReadKeywordDebuffs(unit, list)
    if not unit or not C_UnitAuras or not C_UnitAuras.GetAuraSlots then
        return 0
    end
    local _, slotCount = C_UnitAuras.GetAuraSlots(unit, "HARMFUL", nil, nil, auraSlots)
    local count = 0
    for index = 1, slotCount or 0 do
        local _, _, stacks, _, _, _, _, _, _, spellId = C_UnitAuras.UnitAuraBySlot(unit, auraSlots[index])
        local keyword = spellId and keywordsBySpell[spellId]
        if keyword then
            count = count + 1
            StoreDebuff(list, count, keyword, max(1, stacks or 1))
        end
    end
    SortByKeyword(list, count)
    return count
end

function UI.ParseKeywordDebuffs(text, list)
    local count = 0
    for _, pair in ipairs(UI.Split(text or "", ",")) do
        local colon = strfind(pair, ":", 1, true)
        local keyword = colon and keywords[tonumber(strsub(pair, 1, colon - 1)) or 0]
        if keyword then
            count = count + 1
            StoreDebuff(list, count, keyword, max(1, tonumber(strsub(pair, colon + 1)) or 1))
        end
    end
    SortByKeyword(list, count)
    return count
end

local function ShowEntryTooltip()
    local keyword = this.keyword
    if not keyword then
        return
    end
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMRIGHT")
    GameTooltip:AddDoubleLine(keyword.name, this.stacks > 1 and (this.stacks .. L[" stacks"]) or "", 1, 0.82, 0, 1, 1, 1)
    if keyword.description ~= "" then
        GameTooltip:AddLine(keyword.description, 1, 1, 1, 1)
    end
    GameTooltip:Show()
end

local function ApplyLook(entry, look)
    if entry.look == look then
        return
    end
    entry.look = look
    entry:SetHeight(look.size)
    entry.icon:SetWidth(look.size - 2)
    entry.icon:SetHeight(look.size - 2)
    entry.count:SetFont(UI.NUMBER_FONT, look.count, "OUTLINE")
    entry:EnableMouse(look.mouse and true or false)
end

local function CreateEntry(row)
    local entry = CreateFrame("Frame", nil, row)

    entry.edge = entry:CreateTexture(nil, "BACKGROUND")
    entry.edge:SetTexture(UI.FLAT)
    entry.edge:SetVertexColor(0, 0, 0, 1)

    entry.icon = entry:CreateTexture(nil, "ARTWORK")
    entry.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    entry.icon:SetPoint("LEFT", entry, "LEFT", 1, 0)
    entry.edge:SetPoint("TOPLEFT", entry.icon, "TOPLEFT", -1, 1)
    entry.edge:SetPoint("BOTTOMRIGHT", entry.icon, "BOTTOMRIGHT", 1, -1)

    entry.count = entry:CreateFontString(nil, "OVERLAY")
    entry.count:SetPoint("LEFT", entry.icon, "RIGHT", 2, 0)

    entry:SetScript("OnEnter", ShowEntryTooltip)
    entry:SetScript("OnLeave", function() GameTooltip:Hide() end)
    tinsert(row.entries, entry)
    return entry
end

local function StretchLeftHalf(half, overlap)
    if half.fixedOverlap == overlap then
        return
    end
    half.fixedOverlap = overlap
    half.fixed:ClearAllPoints()
    half.fixed:SetPoint("TOPLEFT", half.icon, "TOPLEFT", 0, 0)
    half.fixed:SetPoint("BOTTOMRIGHT", half.icon, "BOTTOMRIGHT", overlap, 0)
end

local function PieHalf(pie, icon, rightSide)
    local half = pie:CreateTexture(nil, "ARTWORK")
    half:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    half:SetAllPoints(icon)
    half.icon = icon
    half.fixed = pie:CreateMaskTexture()
    half.fixed:SetTexture(HALF_MASK)
    if rightSide then
        half.fixed:SetPoint("TOPLEFT", icon, "TOPLEFT", -PIE_OVERLAP, 0)
        half.fixed:SetPoint("BOTTOMRIGHT", icon, "BOTTOMRIGHT", 0, 0)
        half.fixed:SetRotation(math.pi)
    else
        StretchLeftHalf(half, 0)
    end
    half:AddMaskTexture(half.fixed)
    half.turn = pie:CreateMaskTexture()
    half.turn:SetTexture(HALF_MASK)
    half.turn:SetPoint("CENTER", icon, "CENTER", 0, 0)
    half:AddMaskTexture(half.turn)
    return half
end

local function ShiftTurn(half, offset)
    if half.turnOffset == offset then
        return
    end
    half.turnOffset = offset
    half.turn:ClearAllPoints()
    half.turn:SetPoint("CENTER", half.icon, "CENTER", offset, 0)
end

local function DrawPie(pie, done)
    local angle = done * 360
    if angle >= 360 then
        pie.left:Hide()
        pie.right:Hide()
        return
    end
    StretchLeftHalf(pie.left, angle < 180 and 0 or -PIE_OVERLAP)
    ShiftTurn(pie.left, angle < 180 and 2 * PIE_OVERLAP or 0)
    pie.left.turn:SetRotation(-math.rad(max(angle, 180) - 180))
    pie.left:Show()
    if angle < 180 then
        pie.right.turn:SetRotation(-math.rad(angle - 180))
        pie.right:Show()
    else
        pie.right:Hide()
    end
end

local function UpdatePie()
    DrawPie(this, min(1, max(0, (GetTime() - this.start) / this.duration)))
end

local function SizePie(pie, size)
    local turn = size * TURN_MASK_SCALE
    for _, half in ipairs({ pie.left, pie.right }) do
        half.turn:SetWidth(turn)
        half.turn:SetHeight(turn)
    end
end

local function CreatePie(entry)
    local pie = CreateFrame("Frame", nil, entry)
    pie:SetAllPoints(entry.icon)
    pie.left = PieHalf(pie, entry.icon, false)
    pie.right = PieHalf(pie, entry.icon, true)
    SizePie(pie, entry.look.size)
    pie:SetScript("OnUpdate", UpdatePie)
    return pie
end

local function CanDrawPie(entry)
    return entry.icon.AddMaskTexture and entry.CreateMaskTexture
end

local function ShowPie(entry, start, duration)
    if not entry.pie then
        entry.pie = CreatePie(entry)
    end
    entry.pie.left:SetTexture(entry.keyword.icon)
    entry.pie.right:SetTexture(entry.keyword.icon)
    entry.pie.start, entry.pie.duration = start, duration
    entry.pie:Show()
    entry.icon:SetVertexColor(SPENT_SHADE, SPENT_SHADE, SPENT_SHADE)
end

local function HidePie(entry)
    if entry.pie then
        entry.pie:Hide()
    end
    entry.icon:SetVertexColor(1, 1, 1)
end

local function ApplyTimer(entry, guid)
    local mob = guid and timers[guid]
    local timer = mob and mob[entry.keyword.id]
    local start = timer and timer.start or 0
    local duration = timer and timer.duration or 0
    if entry.timerStart == start and entry.timerDuration == duration and entry.timerIcon == entry.keyword.icon then
        return
    end
    entry.timerStart, entry.timerDuration, entry.timerIcon = start, duration, entry.keyword.icon
    if duration > 0 and CanDrawPie(entry) then
        ShowPie(entry, start, duration)
    else
        HidePie(entry)
    end
end

local function DressEntry(entry, debuff, guid)
    local keyword, color = debuff.keyword, debuff.keyword.color
    entry.keyword = keyword
    entry.stacks = debuff.stacks
    entry.icon:SetTexture(keyword.icon)
    entry.count:SetText(keyword.maxStacks > 1 and tostring(debuff.stacks) or "")
    entry.count:SetTextColor(min(1, color.r + 0.25), min(1, color.g + 0.25), min(1, color.b + 0.25))
    ApplyTimer(entry, guid)
end

local function SetDebuffs(row, list, count, guid)
    local size = row.look.size
    local x = 0
    for index = 1, count do
        local entry = row.entries[index] or CreateEntry(row)
        ApplyLook(entry, row.look)
        DressEntry(entry, list[index], guid)
        local width = size + (entry.count:GetText() ~= "" and entry.count:GetStringWidth() + 3 or 0)
        entry:SetWidth(width)
        entry:ClearAllPoints()
        entry:SetPoint("TOPLEFT", row, "TOPLEFT", x, 0)
        entry:Show()
        x = x + width + GAP
    end
    for index = count + 1, getn(row.entries) do
        row.entries[index]:Hide()
    end
    row.count = count
    row.guid = guid
    if count == 0 then
        row:Hide()
        row.height = 0
        return 0
    end
    row:SetWidth(x)
    row:SetHeight(size)
    row:Show()
    row.height = size
    return size
end

function UI.DebuffRow(parent, look)
    local row = CreateFrame("Frame", nil, parent)
    row.look = look
    row.entries = {}
    row.count = 0
    row.height = 0
    row.SetDebuffs = SetDebuffs
    row:Hide()
    tinsert(rows, row)
    return row
end

function UI.SetDebuffRowLook(row, look)
    row.look = look
end

local function RefreshShownTimers()
    for _, row in ipairs(rows) do
        if row.count > 0 and row:IsVisible() then
            for index = 1, row.count do
                ApplyTimer(row.entries[index], row.guid)
            end
        end
    end
end

local function ReadTimers(text)
    local now = GetTime()
    for _, item in ipairs(UI.Split(text or "", ",")) do
        local fields = UI.Split(item, ":")
        local guid, id = fields[1], tonumber(fields[2] or "")
        local left, full = tonumber(fields[3] or ""), tonumber(fields[4] or "")
        if guid and guid ~= "" and id and left and full and full > 0 then
            local mob = timers[guid]
            if not mob then
                mob = {}
                timers[guid] = mob
            end
            local timer = mob[id]
            if not timer then
                timer = {}
                mob[id] = timer
            end
            timer.start = now - (full - min(left, full)) / 1000
            timer.duration = full / 1000
        end
    end
    RefreshShownTimers()
end

local function ClearTimers()
    timers = {}
    RefreshShownTimers()
end

local function HoldTimers(elapsed)
    for _, mob in pairs(timers) do
        for _, timer in pairs(mob) do
            timer.start = timer.start + elapsed
        end
    end
    RefreshShownTimers()
end

local function PruneTimers()
    local now = GetTime()
    for guid, mob in pairs(timers) do
        local alive = false
        for id, timer in pairs(mob) do
            if timer.start + timer.duration < now - 1 then
                mob[id] = nil
            else
                alive = true
            end
        end
        if not alive then
            timers[guid] = nil
        end
    end
end

local clock = CreateFrame("Frame")
clock.held, clock.prune = 0, 0
clock:SetScript("OnUpdate", function()
    if UI.RunHeld and UI.RunHeld() then
        this.held = this.held + arg1
        if this.held >= HOLD_STEP then
            HoldTimers(this.held)
            this.held = 0
        end
    elseif this.held > 0 then
        HoldTimers(this.held)
        this.held = 0
    end
    this.prune = this.prune + arg1
    if this.prune >= PRUNE_INTERVAL then
        this.prune = 0
        PruneTimers()
    end
end)

local glossary = { order = {}, entries = {} }

local function Mentions(text, word)
    if strfind(word, "[^%a]") then
        return strfind(text, word, 1, true) ~= nil
    end
    for found in string.gfind(text, "%a+") do
        if found == word then
            return true
        end
    end
    return false
end

local function EntryMentioned(entry, texts)
    for _, word in ipairs(entry.words) do
        for _, text in ipairs(texts) do
            if text and Mentions(text, word) then
                return true
            end
        end
    end
    return false
end

function UI.HighlightGlossary(text, color)
    local words = {}
    for _, term in ipairs(glossary.order) do
        for _, word in ipairs(glossary.entries[term].words) do
            if not strfind(word, "[^%a]") then
                words[word] = true
            end
        end
    end
    local out, pos, afterName = "", 1, false
    while true do
        local first, last = strfind(text, "%a+", pos)
        if not first then
            return out .. strsub(text, pos)
        end
        local gap, word = strsub(text, pos, first - 1), strsub(text, first, last)
        local partOfName = afterName and gap == " "
        if words[word] and not partOfName then
            out = out .. gap .. "|cff71d5ff" .. word .. "|r" .. (color or "")
        else
            out = out .. gap .. word
        end
        afterName = strfind(word, "^%u") ~= nil and first > 1
        pos = last + 1
    end
end

function UI.AddGlossary(tooltip, texts)
    local spaced = false
    for _, term in ipairs(glossary.order) do
        local entry = glossary.entries[term]
        if EntryMentioned(entry, texts) then
            if not spaced then
                tooltip:AddLine(" ")
                spaced = true
            end
            tooltip:AddLine("|cffffd100" .. term .. ":|r " .. entry.description, 0.85, 0.85, 0.85, 1)
        end
    end
end

UI.Listen({
    ["gls"] = function(f)
        local term = f[2]
        if not term or term == "" or not f[4] then
            return
        end
        if not glossary.entries[term] then
            tinsert(glossary.order, term)
        end
        glossary.entries[term] = { words = UI.Split(f[3] or "", ","), description = f[4] }
    end,
    ["kwdaura"] = function(f)
        local id = tonumber(f[2] or "")
        if not id then
            return
        end
        local keyword = KeywordEntry(id)
        local icon = (f[4] and f[4] ~= "") and f[4] or QUESTION_MARK
        keyword.name = f[3] or ""
        keyword.icon = UI.ICON_PATH .. icon
        keyword.maxStacks = tonumber(f[6] or "") or 1
        keyword.color = UI.DamageType(UI.DAMAGE_TYPE_BY_KEYWORD[keyword.name] or UI.DamageTypeFromIcon(icon))
        local spellId = tonumber(f[5] or "")
        if spellId then
            keywordsBySpell[spellId] = keyword
        end
    end,
    ["kwd"] = function(f)
        local id = tonumber(f[2] or "")
        if id then
            KeywordEntry(id).description = f[5] or ""
        end
    end,
    ["kwdt"] = function(f)
        ReadTimers(f[2])
    end,
    ["mobdead"] = function(f)
        if f[4] and f[4] ~= "" then
            timers[f[4]] = nil
        end
    end,
    ["mobclear"] = ClearTimers,
    ["start"] = ClearTimers,
    ["end"] = ClearTimers,
})
