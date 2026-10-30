VanillaBonkTalents = {}

local T = VanillaBonkTalents

local PANEL_WIDTH = 290
local PANEL_GAP = 12
local COLUMN_STEP = 48
local ROW_STEP = 54
local TOP_PAD = 46
local NODE_SIZE = 30
local CAPSTONE_SIZE = 42
local CHOICE_SIZE = 34
local FRAME_INNER = 0.75
local OCTAGON_ICON = 0.75
local SPLIT_LEFT, SPLIT_RIGHT, SPLIT_WIDTH = 0.285, 0.715, 2
local ROWS = 9
local LINE_WIDTH = 24
local TEXTURES = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\"
local WHITE = "Interface\\Buttons\\WHITE8X8"
local LINE = TEXTURES .. "TalentLine"
local LINE_FACTOR = 32 / 30 / 2
local RANK_FONT = "Fonts\\FRIZQT__.TTF"
local SHAPE_SQUARE, SHAPE_ROUND, SHAPE_CHOICE, SHAPE_CAPSTONE, SHAPE_STARTER = 0, 1, 2, 3, 5
local FRAMES = {
    [SHAPE_ROUND] = "TalentRound",
    [SHAPE_CHOICE] = "TalentOctagon",
    [SHAPE_CAPSTONE] = "TalentCapstone",
    [SHAPE_STARTER] = "TalentRound",
}
local GOLD = { 1, 0.82, 0 }
local GREEN = { 0.25, 0.9, 0.25 }
local GREY = { 0.35, 0.35, 0.35 }
local LINE_LIT = { 1, 0.75, 0.2 }
local LINE_OPEN = { 0.7, 0.7, 0.7 }
local LINE_DARK = { 0.4, 0.4, 0.4 }
T.PRESET_GOLD = { 0.6, 0.49, 0 }

do
    local MUTED_SHADE = 0.6
    local mutedColours = {}

    function T.Shown(colour)
        if not T.muted then
            return colour
        end
        if not mutedColours[colour] then
            mutedColours[colour] = { colour[1] * MUTED_SHADE, colour[2] * MUTED_SHADE, colour[3] * MUTED_SHADE }
        end
        return mutedColours[colour]
    end
end

local state = { panels = {}, data = nil }

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end

local function Split(text, sep)
    local out = {}
    if not text or text == "" then
        return out
    end
    for piece in string.gfind(text, "([^" .. sep .. "]+)") do
        tinsert(out, piece)
    end
    return out
end

function T.Wants(data)
    if not data or not data.trees then
        return false
    end
    for _, tree in ipairs(data.trees) do
        if tree.layout == 1 then
            return true
        end
    end
    return false
end

function T.ParseTree(tree, f)
    tree.layout = tonumber(f[5]) or 0
    tree.gates = {}
    for _, gate in ipairs(Split(f[6], ",")) do
        tinsert(tree.gates, tonumber(gate) or 0)
    end
    tree.spent = tonumber(f[7]) or 0
end

function T.ParseNode(node, f)
    node.shape = tonumber(f[20]) or SHAPE_SQUARE
    node.position = tonumber(f[21]) or node.column
    node.parents = Split(f[22], ",")
    node.excludes = f[23] or "0"
end

local function Gate(tree, row)
    return tree.gates[row + 1] or 0
end

local function NodeOf(id)
    return state.data and state.data.nodes[id]
end

local function IsFree(node)
    return node.shape == SHAPE_STARTER
end

local function HasParent(node)
    if table.getn(node.parents) == 0 then
        return true
    end
    for _, id in ipairs(node.parents) do
        local parent = NodeOf(id)
        if parent and parent.rank > 0 then
            return true
        end
    end
    return false
end

local function Excluded(node)
    local rival = node.excludes ~= "0" and NodeOf(node.excludes)
    return rival and rival.rank > 0 and rival or nil
end

local function TreeOf(node)
    for _, tree in ipairs(state.data.trees) do
        if tree.id == node.tree then
            return tree
        end
    end
end

local function Missing(node)
    if IsFree(node) or node.rank >= node.maxRank then
        return nil
    end
    local tree = TreeOf(node)
    local gate = Gate(tree, node.row)
    if tree.spent < gate then
        return "Requires " .. gate .. " points in " .. tree.name .. "."
    end
    if not HasParent(node) then
        return "Learn a talent that leads here first."
    end
    local rival = Excluded(node)
    if rival then
        return "Can't be learned with " .. rival.name .. "."
    end
    return nil
end

local function StateOf(node)
    if IsFree(node) or node.rank >= node.maxRank then
        return "max"
    end
    if node.rank > 0 then
        return "part"
    end
    if Missing(node) then
        return "locked"
    end
    return (state.data.balance > 0 and not T.muted) and "open" or "locked"
end

local function Colour(which)
    if T.muted then
        return (which == "max" or which == "part") and T.PRESET_GOLD or GREY
    end
    if which == "max" then
        return GOLD
    elseif which == "part" or which == "open" then
        return GREEN
    end
    return GREY
end

local function DescriptionAtRank(node, rank)
    local per = tonumber(node.valuePerRank)
    if not per or per == 0 or rank <= 1 then
        return node.description
    end
    local scaled = false
    local text = string.gsub(node.description, "%d*%.?%d+", function(number)
        if not scaled and tonumber(number) == per then
            scaled = true
            return format("%g", per * rank)
        end
        return number
    end)
    return text
end

local function ShowTooltip(button)
    local node = button.node
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if button.pair then
        GameTooltip:AddLine("Choose one", 1, 1, 1)
        for _, choice in ipairs(button.pair) do
            GameTooltip:AddLine(choice.name, 1, 0.82, 0)
            GameTooltip:AddLine(choice.description, 0.9, 0.9, 0.9, 1)
        end
        VanillaBonkUI.AddGlossary(GameTooltip, { button.pair[1].description, button.pair[2] and button.pair[2].description })
        local missing = Missing(button.pair[1])
        if missing then
            GameTooltip:AddLine(missing, 1, 0.1, 0.1, 1)
        elseif not VanillaBonkTalents.readOnly then
            GameTooltip:AddLine("Click to choose", 0.1, 1, 0.1)
        end
        GameTooltip:Show()
        return
    end
    GameTooltip:AddLine(node.name, 1, 1, 1)
    if not IsFree(node) then
        GameTooltip:AddLine("Rank " .. node.rank .. "/" .. node.maxRank, 1, 1, 1)
    end
    GameTooltip:AddLine(DescriptionAtRank(node, node.rank), 1, 0.82, 0, 1)
    if node.rank > 0 and node.rank < node.maxRank and not IsFree(node) then
        GameTooltip:AddLine(" ")
        GameTooltip:AddLine("Next rank:", 1, 1, 1)
        GameTooltip:AddLine(DescriptionAtRank(node, node.rank + 1), 1, 0.82, 0, 1)
    end
    VanillaBonkUI.AddGlossary(GameTooltip, { node.description })
    local missing = Missing(node)
    if missing then
        GameTooltip:AddLine(missing, 1, 0.1, 0.1, 1)
    elseif IsFree(node) then
        GameTooltip:AddLine("Always yours", 0.6, 0.6, 0.6)
    elseif node.rank < node.maxRank and not VanillaBonkTalents.readOnly then
        GameTooltip:AddLine("Click to learn", 0.1, 1, 0.1)
    end
    if node.rank > 0 and not IsFree(node) and not VanillaBonkTalents.readOnly then
        GameTooltip:AddLine("Right-click to refund", 0.7, 0.7, 0.7)
    end
    GameTooltip:Show()
end

local PICKER_STRATA = "FULLSCREEN_DIALOG"
local picker = CreateFrame("Frame", "VanillaBonkTalentPicker", UIParent)
picker:SetFrameStrata(PICKER_STRATA)
picker:SetWidth(2 * (NODE_SIZE + 110) + 20)
picker:SetHeight(NODE_SIZE + 24)
picker:EnableMouse(true)
picker:Hide()
picker.bg = picker:CreateTexture(nil, "BACKGROUND")
picker.bg:SetAllPoints(picker)
picker.bg:SetTexture(0.03, 0.03, 0.06, 0.95)
picker.slots = {}
tinsert(UISpecialFrames, "VanillaBonkTalentPicker")
picker.close = CreateFrame("Button", nil, picker, "UIPanelCloseButton")
picker.close:SetWidth(24)
picker.close:SetHeight(24)
picker.close:SetPoint("TOPRIGHT", picker, "TOPRIGHT", 2, 2)
picker.close:SetScript("OnClick", function() picker:Hide() end)
for index = 1, 2 do
    local slot = CreateFrame("Button", nil, picker)
    slot:SetWidth(NODE_SIZE + 110)
    slot:SetHeight(NODE_SIZE + 8)
    slot:SetPoint("LEFT", picker, "LEFT", 10 + (index - 1) * (NODE_SIZE + 110), 0)
    slot.icon = slot:CreateTexture(nil, "ARTWORK")
    slot.icon:SetWidth(NODE_SIZE)
    slot.icon:SetHeight(NODE_SIZE)
    slot.icon:SetPoint("LEFT", slot, "LEFT", 4, 0)
    slot.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    slot.label = slot:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    slot.label:SetPoint("LEFT", slot.icon, "RIGHT", 6, 0)
    slot.label:SetWidth(100)
    slot.label:SetJustifyH("LEFT")
    slot:RegisterForClicks("LeftButtonUp")
    slot:SetScript("OnClick", function()
        picker:Hide()
        Command("learn " .. this.node.id)
    end)
    slot:SetScript("OnEnter", function()
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(this.node.name, 1, 1, 1)
        GameTooltip:AddLine(this.node.description, 1, 0.82, 0, 1)
        VanillaBonkUI.AddGlossary(GameTooltip, { this.node.description })
        GameTooltip:Show()
    end)
    slot:SetScript("OnLeave", function() GameTooltip:Hide() end)
    picker.slots[index] = slot
end

local function OpenPicker(button)
    if picker:IsShown() and picker.owner == button then
        picker:Hide()
        return
    end
    picker.owner = button
    picker:SetFrameStrata(PICKER_STRATA)
    picker:SetFrameLevel(button:GetFrameLevel() + 10)
    picker.close:SetFrameStrata(PICKER_STRATA)
    picker.close:SetFrameLevel(picker:GetFrameLevel() + 3)
    for index, slot in ipairs(picker.slots) do
        slot:SetFrameStrata(PICKER_STRATA)
        slot:SetFrameLevel(picker:GetFrameLevel() + 2)
        local node = button.pair[index]
        slot.node = node
        slot.icon:SetTexture("Interface\\Icons\\" .. node.icon)
        slot.label:SetText(node.name)
    end
    picker:ClearAllPoints()
    picker:SetPoint("BOTTOM", button, "TOP", 0, 6)
    picker:Show()
end

local function OnClick()
    local button = this
    GameTooltip:Hide()
    if VanillaBonkTalents.readOnly then
        return
    end
    if button.pair then
        local chosen = button.pair[1].rank > 0 and button.pair[1] or button.pair[2].rank > 0 and button.pair[2]
        if arg1 == "RightButton" then
            if chosen then
                Command("unlearn " .. chosen.id)
            end
            return
        end
        if not chosen and not Missing(button.pair[1]) then
            OpenPicker(button)
        end
        return
    end
    local node = button.node
    if IsFree(node) then
        return
    end
    if arg1 == "RightButton" then
        if node.rank > 0 then
            Command("unlearn " .. node.id)
        end
        return
    end
    if node.rank < node.maxRank then
        Command("learn " .. node.id)
    end
end

local function CreateNode(panel)
    local button = CreateFrame("Button", nil, panel)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button.glow = button:CreateTexture(nil, "BACKGROUND")
    button.glow:SetTexture(TEXTURES .. "TalentGlow")
    button.glow:SetBlendMode("ADD")
    button.back = button:CreateTexture(nil, "BACKGROUND")
    button.back:SetTexture(0, 0, 0, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.half = button:CreateTexture(nil, "ARTWORK")
    button.frame = button:CreateTexture(nil, "OVERLAY")
    button.top = CreateFrame("Frame", nil, button)
    button.top:SetAllPoints(button)
    button.top:SetFrameLevel(button:GetFrameLevel() + 2)
    button.split = button.top:CreateTexture(nil, "BACKGROUND")
    button.split:SetTexture(WHITE)
    button.badge = button.top:CreateTexture(nil, "ARTWORK")
    button.badge:SetTexture(TEXTURES .. "TalentBadge")
    button.rank = button.top:CreateFontString(nil, "OVERLAY")
    button.rank:SetFont(RANK_FONT, 11)
    button.rank:SetShadowColor(0, 0, 0, 1)
    button.rank:SetShadowOffset(1, -1)
    button:SetScript("OnEnter", function() ShowTooltip(this) end)
    button:SetScript("OnLeave", function() GameTooltip:Hide() end)
    button:SetScript("OnClick", OnClick)
    return button
end

local function PlaceFrame(button, shape, size, colour)
    local inner = shape == SHAPE_CHOICE and OCTAGON_ICON or FRAME_INNER
    local pad = size / 2 / inner - size / 2 - 1
    button.frame:SetTexture(TEXTURES .. (FRAMES[shape] or "TalentSquare"))
    button.frame:ClearAllPoints()
    button.frame:SetPoint("TOPLEFT", button, "TOPLEFT", -pad, pad)
    button.frame:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", pad, -pad)
    button.frame:SetVertexColor(colour[1], colour[2], colour[3])
    button.split:SetVertexColor(colour[1], colour[2], colour[3])
    local round = shape == SHAPE_ROUND or shape == SHAPE_CAPSTONE or shape == SHAPE_STARTER
    button.back:ClearAllPoints()
    if shape == SHAPE_CHOICE then
        button.back:SetTexture(TEXTURES .. "TalentOctagonFill")
        button.back:SetPoint("TOPLEFT", button.frame, "TOPLEFT", 0, 0)
        button.back:SetPoint("BOTTOMRIGHT", button.frame, "BOTTOMRIGHT", 0, 0)
    else
        button.back:SetTexture(0, 0, 0, 1)
        button.back:SetPoint("TOPLEFT", button, "TOPLEFT", 2, -2)
        button.back:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", -2, 2)
    end
    if round then
        button.back:Hide()
    else
        button.back:Show()
    end
    return round
end

local function SetIcon(texture, icon, round)
    local path = "Interface\\Icons\\" .. icon
    if round and SetPortraitToTexture then
        texture:SetTexCoord(0, 1, 0, 1)
        SetPortraitToTexture(texture, path)
    else
        texture:SetTexture(path)
        texture:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    end
end

local function Snap(value)
    return math.floor(value + 0.5)
end

local function DrawLine(texture, frame, sx, sy, ex, ey, width)
    local dx, dy = ex - sx, ey - sy
    local cx, cy = (sx + ex) / 2, (sy + ey) / 2
    if dx < 0 then
        dx, dy = -dx, -dy
    end
    local length = sqrt(dx * dx + dy * dy)
    texture:ClearAllPoints()
    if length == 0 then
        texture:Hide()
        return
    end
    local s, c = -dy / length, dx / length
    local sc = s * c
    local bw, bh, blx, bly, tlx, tly, trx, try, brx, bry
    if dy >= 0 then
        bw = ((length * c) - (width * s)) * LINE_FACTOR
        bh = ((width * c) - (length * s)) * LINE_FACTOR
        blx, bly, bry = (width / length) * sc, s * s, (length / width) * sc
        brx, tlx, tly, trx = 1 - bly, bly, 1 - bry, 1 - blx
        try = brx
    else
        bw = ((length * c) + (width * s)) * LINE_FACTOR
        bh = ((width * c) + (length * s)) * LINE_FACTOR
        blx, bly, brx = s * s, -(length / width) * sc, 1 + (width / length) * sc
        bry, tlx, tly, try = blx, 1 - brx, 1 - blx, 1 - bly
        trx = tly
    end
    texture:SetTexCoord(tlx, tly, blx, bly, trx, try, brx, bry)
    texture:SetPoint("BOTTOMLEFT", frame, "BOTTOMLEFT", cx - bw, cy - bh)
    texture:SetPoint("TOPRIGHT", frame, "BOTTOMLEFT", cx + bw, cy + bh)
    texture:Show()
end

local GATE_GOLD = { 0.84, 0.7, 0.38 }
local GATE_DONE = { 0.55, 0.48, 0.34 }

local function CreateGate(panel)
    local gate = {}
    gate.line = panel:CreateTexture(nil, "ARTWORK")
    gate.line:SetTexture(TEXTURES .. "TalentGateLine")
    gate.line:SetHeight(8)
    gate.plaque = {}
    for index, coords in ipairs({ { 0, 0.25 }, { 0.25, 0.75 }, { 0.75, 1 } }) do
        local piece = panel:CreateTexture(nil, "ARTWORK")
        piece:SetTexture(TEXTURES .. "TalentPlaque")
        piece:SetTexCoord(coords[1], coords[2], 0, 1)
        piece:SetHeight(28)
        gate.plaque[index] = piece
    end
    gate.plaque[1]:SetWidth(16)
    gate.plaque[3]:SetWidth(16)
    gate.text = panel:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    gate.regions = { gate.line, gate.plaque[1], gate.plaque[2], gate.plaque[3], gate.text }
    return gate
end

local function PlaceGate(panel, gate, y, text, done)
    local colour = done and GATE_DONE or GATE_GOLD
    gate.line:SetVertexColor(colour[1], colour[2], colour[3])
    gate.line:ClearAllPoints()
    gate.line:SetPoint("LEFT", panel, "TOPLEFT", 8, y)
    gate.line:SetPoint("RIGHT", panel, "TOPRIGHT", -8, y)
    gate.text:SetText(text)
    gate.text:SetTextColor(done and 0.7 or 1, done and 0.7 or 0.82, done and 0.7 or 0)
    gate.text:ClearAllPoints()
    gate.text:SetPoint("CENTER", panel, "TOP", 0, y)
    local left, middle, right = gate.plaque[1], gate.plaque[2], gate.plaque[3]
    left:ClearAllPoints()
    left:SetPoint("RIGHT", gate.text, "LEFT", -2, 0)
    right:ClearAllPoints()
    right:SetPoint("LEFT", gate.text, "RIGHT", 2, 0)
    middle:ClearAllPoints()
    middle:SetPoint("TOPLEFT", left, "TOPRIGHT", 0, 0)
    middle:SetPoint("BOTTOMRIGHT", right, "BOTTOMLEFT", 0, 0)
    for _, piece in ipairs(gate.plaque) do
        piece:SetVertexColor(colour[1], colour[2], colour[3])
    end
    for _, region in ipairs(gate.regions) do
        region:Show()
    end
end

local function HideGates(pool)
    for _, gate in ipairs(pool) do
        for _, region in ipairs(gate.regions) do
            region:Hide()
        end
    end
end

local function CreatePanel(parent)
    local panel = CreateFrame("Frame", nil, parent)
    panel.art = {}
    for i = 1, 4 do
        panel.art[i] = panel:CreateTexture(nil, "BACKGROUND")
    end
    panel.shade = panel:CreateTexture(nil, "BORDER")
    panel.shade:SetAllPoints(panel)
    panel.shade:SetTexture(0, 0, 0, 0.45)
    panel.header = panel:CreateTexture(nil, "BORDER")
    panel.header:SetTexture(0, 0, 0, 0.7)
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.header:SetPoint("TOPRIGHT", panel, "TOPRIGHT", 0, 0)
    panel.header:SetHeight(26)
    panel.name = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.name:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -7)
    panel.spent = panel:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    panel.spent:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -8)
    panel.capstone = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    panel.gates = {}
    panel.lines = {}
    panel.buttons = {}
    return panel
end

local function LayoutArt(panel, background, width, height)
    local base = "Interface\\TalentFrame\\" .. background .. "-"
    local parts = { "TopLeft", "TopRight", "BottomLeft", "BottomRight" }
    local w1, h1 = width * 256 / 296, height * 256 / 336
    for i, texture in ipairs(panel.art) do
        texture:SetTexture(base .. parts[i])
        texture:ClearAllPoints()
    end
    panel.art[1]:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    panel.art[1]:SetWidth(w1)
    panel.art[1]:SetHeight(h1)
    panel.art[2]:SetPoint("TOPLEFT", panel.art[1], "TOPRIGHT", 0, 0)
    panel.art[2]:SetWidth(width - w1)
    panel.art[2]:SetHeight(h1)
    panel.art[2]:SetTexCoord(0, 40 / 64, 0, 1)
    panel.art[3]:SetPoint("TOPLEFT", panel.art[1], "BOTTOMLEFT", 0, 0)
    panel.art[3]:SetWidth(w1)
    panel.art[3]:SetHeight(height - h1)
    panel.art[3]:SetTexCoord(0, 1, 0, 80 / 128)
    panel.art[4]:SetPoint("TOPLEFT", panel.art[1], "BOTTOMRIGHT", 0, 0)
    panel.art[4]:SetWidth(width - w1)
    panel.art[4]:SetHeight(height - h1)
    panel.art[4]:SetTexCoord(0, 40 / 64, 0, 80 / 128)
end

local function NodeCenter(node, height)
    local x = PANEL_WIDTH / 2 + (node.position - 2) * COLUMN_STEP
    local y = height - TOP_PAD - node.row * ROW_STEP
    return Snap(x), Snap(y)
end

local function DrawTree(panel, tree, height)
    local nodes, slots = {}, {}
    for _, node in pairs(state.data.nodes) do
        if node.tree == tree.id then
            tinsert(nodes, node)
        end
    end
    table.sort(nodes, function(a, b) return tonumber(a.id) < tonumber(b.id) end)

    for _, line in ipairs(panel.lines) do
        line:Hide()
    end
    for _, button in ipairs(panel.buttons) do
        button:Hide()
    end

    local lineIndex = 0
    for _, node in ipairs(nodes) do
        local ex, ey = NodeCenter(node, height)
        for _, parentId in ipairs(node.parents) do
            local parent = NodeOf(parentId)
            if parent then
                local sx, sy = NodeCenter(parent, height)
                lineIndex = lineIndex + 1
                local line = panel.lines[lineIndex]
                if not line then
                    line = panel:CreateTexture(nil, "BORDER")
                    line:SetTexture(LINE)
                    panel.lines[lineIndex] = line
                end
                local colour = VanillaBonkTalents.Shown((parent.rank > 0 and node.rank > 0) and LINE_LIT or parent.rank > 0 and LINE_OPEN or LINE_DARK)
                line:SetVertexColor(colour[1], colour[2], colour[3])
                DrawLine(line, panel, sx, sy, ex, ey, LINE_WIDTH)
            end
        end
    end

    local buttonIndex = 0
    local seen = {}
    for _, node in ipairs(nodes) do
        local key = node.row .. ":" .. node.position
        if not seen[key] then
            buttonIndex = buttonIndex + 1
            local button = panel.buttons[buttonIndex] or CreateNode(panel)
            panel.buttons[buttonIndex] = button
            local pair = nil
            if node.shape == SHAPE_CHOICE then
                pair = {}
                for _, other in ipairs(nodes) do
                    if other.row == node.row and other.position == node.position then
                        tinsert(pair, other)
                    end
                end
            end
            seen[key] = true
            button.node = node
            button.pair = pair
            local size = node.shape == SHAPE_CAPSTONE and CAPSTONE_SIZE or node.shape == SHAPE_CHOICE and CHOICE_SIZE or NODE_SIZE
            local x, y = NodeCenter(node, height)
            button:ClearAllPoints()
            button:SetWidth(size)
            button:SetHeight(size)
            button:SetPoint("CENTER", panel, "BOTTOMLEFT", x, y)
            button.icon:ClearAllPoints()
            button.icon:SetAllPoints(button)

            local which, rank, maxRank
            if pair then
                local chosen = pair[1].rank > 0 and pair[1] or pair[2] and pair[2].rank > 0 and pair[2]
                which = chosen and "max" or StateOf(pair[1])
                SetIcon(button.icon, (chosen or pair[1]).icon, false)
                if chosen or not pair[2] then
                    button.half:Hide()
                    button.split:Hide()
                else
                    button.icon:SetTexCoord(SPLIT_LEFT, SPLIT_RIGHT, 0.07, 0.93)
                    button.icon:ClearAllPoints()
                    button.icon:SetPoint("TOPLEFT", button, "TOPLEFT", 0, 0)
                    button.icon:SetPoint("BOTTOMRIGHT", button, "BOTTOM", 0, 0)
                    button.half:SetTexture("Interface\\Icons\\" .. pair[2].icon)
                    button.half:SetTexCoord(SPLIT_LEFT, SPLIT_RIGHT, 0.07, 0.93)
                    button.half:ClearAllPoints()
                    button.half:SetPoint("TOPLEFT", button, "TOP", 0, 0)
                    button.half:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", 0, 0)
                    button.half:Show()
                    button.split:ClearAllPoints()
                    button.split:SetPoint("TOP", button, "TOP", 0, 0)
                    button.split:SetPoint("BOTTOM", button, "BOTTOM", 0, 0)
                    button.split:SetWidth(SPLIT_WIDTH)
                    button.split:Show()
                end
                rank, maxRank = chosen and 1 or 0, 1
            else
                which = StateOf(node)
                local round = node.shape == SHAPE_ROUND or node.shape == SHAPE_CAPSTONE or IsFree(node)
                SetIcon(button.icon, node.icon, round)
                button.half:Hide()
                button.split:Hide()
                rank, maxRank = node.rank, node.maxRank
            end
            local locked = which == "locked"
            button.icon:SetDesaturated(locked)
            button.half:SetDesaturated(locked)
            button.icon:SetVertexColor(locked and 0.55 or 1, locked and 0.55 or 1, locked and 0.55 or 1)
            PlaceFrame(button, node.shape, size, Colour(which))
            if node.shape == SHAPE_CAPSTONE and which == "max" then
                button.glow:ClearAllPoints()
                button.glow:SetPoint("TOPLEFT", button, "TOPLEFT", -size * 0.6, size * 0.6)
                button.glow:SetPoint("BOTTOMRIGHT", button, "BOTTOMRIGHT", size * 0.6, -size * 0.6)
                button.glow:SetVertexColor(1, 0.7, 0.2)
                button.glow:Show()
            else
                button.glow:Hide()
            end

            if IsFree(node) then
                button.rank:Hide()
                button.badge:Hide()
            else
                button.rank:SetText(rank .. "/" .. maxRank)
                local c = Colour(which)
                button.rank:SetTextColor(c[1], c[2], c[3])
                button.rank:ClearAllPoints()
                button.rank:SetPoint("CENTER", button, "BOTTOMRIGHT", -2, 0)
                button.badge:ClearAllPoints()
                button.badge:SetPoint("CENTER", button.rank, "CENTER", 0, 0)
                button.badge:SetWidth(Snap(button.rank:GetStringWidth() + 12))
                button.badge:SetHeight(17)
                button.rank:Show()
                button.badge:Show()
            end
            button:Show()

            if node.shape == SHAPE_CAPSTONE then
                panel.capstone:ClearAllPoints()
                panel.capstone:SetPoint("TOP", button, "BOTTOM", 0, -14)
                panel.capstone:SetText(node.name)
            end
        end
    end

    HideGates(panel.gates)
    for row = 1, ROWS - 1 do
        local gate = Gate(tree, row)
        if tree.spent < gate then
            panel.gates[1] = panel.gates[1] or CreateGate(panel)
            local missing = gate - tree.spent
            PlaceGate(panel, panel.gates[1], -Snap(TOP_PAD + (row - 0.5) * ROW_STEP), missing .. (missing == 1 and " point" or " points") .. " to unlock", false)
            break
        end
    end
end

function T.Show(shop, data, top)
    state.data = data
    picker:SetParent(shop)
    picker:SetFrameStrata(PICKER_STRATA)
    picker:Hide()
    local height = TOP_PAD + (ROWS - 1) * ROW_STEP + CAPSTONE_SIZE + 30
    for index, tree in ipairs(data.trees) do
        local panel = state.panels[index] or CreatePanel(shop)
        state.panels[index] = panel
        panel:ClearAllPoints()
        panel:SetPoint("TOPLEFT", shop, "TOPLEFT", 20 + (index - 1) * (PANEL_WIDTH + PANEL_GAP), -top)
        panel:SetWidth(PANEL_WIDTH)
        panel:SetHeight(height)
        LayoutArt(panel, tree.background, PANEL_WIDTH, height)
        panel.name:SetText(tree.name)
        panel.spent:SetText(tree.spent .. (tree.spent == 1 and " point" or " points"))
        DrawTree(panel, tree, height)
        panel:Show()
    end
    for index = table.getn(data.trees) + 1, table.getn(state.panels) do
        state.panels[index]:Hide()
    end
    local count = math.max(1, table.getn(data.trees))
    return 40 + count * PANEL_WIDTH + (count - 1) * PANEL_GAP, height
end

function T.Hide()
    picker:Hide()
    for _, panel in ipairs(state.panels) do
        panel:Hide()
    end
end

local SHOP_LINES = { lit = LINE_LIT, open = LINE_OPEN, dark = LINE_DARK }
local SHOP_STATES = { on = GOLD, off = GREY }

function T.StyleButton(button)
    button.back = button:CreateTexture(nil, "BACKGROUND")
    button.back:SetTexture(0, 0, 0, 1)
    button.icon = button:CreateTexture(nil, "ARTWORK")
    button.icon:SetAllPoints(button)
    button.frame = button:CreateTexture(nil, "OVERLAY")
    button.top = CreateFrame("Frame", nil, button)
    button.top:SetAllPoints(button)
    button.top:SetFrameLevel(button:GetFrameLevel() + 2)
    button.split = button.top:CreateTexture(nil, "BACKGROUND")
    button.split:Hide()
    button.badge = button.top:CreateTexture(nil, "ARTWORK")
    button.badge:SetTexture(TEXTURES .. "TalentBadge")
    button.rank = button.top:CreateFontString(nil, "OVERLAY")
    button.rank:SetFont(RANK_FONT, 11)
    button.rank:SetShadowColor(0, 0, 0, 1)
    button.rank:SetShadowOffset(1, -1)
end

function T.StyleNode(button, round, which, icon, rankText, rankColour)
    local colour = SHOP_STATES[which] or Colour(which)
    local dim = which == "locked" or which == "off"
    SetIcon(button.icon, icon, round)
    button.icon:SetDesaturated(dim)
    local shade = which == "locked" and 0.55 or which == "off" and 0.75 or 1
    button.icon:SetVertexColor(shade, shade, shade)
    PlaceFrame(button, round and SHAPE_ROUND or SHAPE_SQUARE, button:GetWidth(), colour)
    local text = rankColour or colour
    button.rank:SetText(rankText)
    button.rank:SetTextColor(text[1], text[2], text[3])
    button.rank:ClearAllPoints()
    button.rank:SetPoint("CENTER", button, "BOTTOMRIGHT", -2, 0)
    button.badge:ClearAllPoints()
    button.badge:SetPoint("CENTER", button.rank, "CENTER", 0, 0)
    button.badge:SetWidth(Snap(button.rank:GetStringWidth() + 12))
    button.badge:SetHeight(17)
end

function T.ShopLine(panel, pool, index, sx, sy, ex, ey, kind)
    local line = pool[index]
    if not line then
        line = panel:CreateTexture(nil, "BORDER")
        line:SetTexture(LINE)
        pool[index] = line
    end
    local colour = SHOP_LINES[kind]
    line:SetVertexColor(colour[1], colour[2], colour[3])
    DrawLine(line, panel, sx, sy, ex, ey, LINE_WIDTH)
end

function T.ShopGate(panel, pool, index, y, text, lit)
    pool[index] = pool[index] or CreateGate(panel)
    PlaceGate(panel, pool[index], y, text, lit)
end

function T.HideShopGates(pool)
    HideGates(pool)
end
