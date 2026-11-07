local L = VanillaBonkL
local UI = VanillaBonkUI
local VB = VanillaBonkRun
local handlers = VB.handlers
local Command = VB.Command
local FormatGold = VB.FormatGold
local Notice = VB.Notice
local SetFont = VB.SetFont
local GossipWindowHidden = VB.GossipWindowHidden
local ReplaceNextGossip = VB.ReplaceNextGossip
local Shop = UI.Module("shop")

local SHOP_TITLES = { ["1"] = L["hoa.addon.upgrades"], ["2"] = L["hoa.addon.sayge_s_fortunes"], ["3"] = L["hoa.addon.talents"] }
local SHOP_HINTS = {
    ["1"] = L["hoa.addon.upgrades_apply_to_all_your_characters_right_click_to_refund_"],
    ["2"] = L["hoa.addon.click_a_dark_fortune_to_buy_it_or_switch_it_on_or_off_right_"],
    ["3"] = L["hoa.addon.earn_talent_points_from_mastery_levels_right_click_a_talent_"],
}
local MASTERY_SHOP = "3"
local FORTUNE_SHOP = "2"
-- The typed shop handler in the run core tells the two shop payloads apart by this kind.
VB.FORTUNE_SHOP = FORTUNE_SHOP
local SHOP_REFUNDS = {
    ["1"] = { label = L["hoa.addon.refund_all"], text = L["hoa.addon.refunds_all_upgrades_for_their_full_gold_cost"] },
    ["2"] = { label = L["hoa.addon.refund_all"], text = L["hoa.addon.refunds_all_dark_fortunes_for_their_full_darkmoon_ticket_cos"] },
    ["3"] = { label = L["hoa.addon.reset_talents"], text = L["hoa.addon.refunds_every_talent_point_you_spent"] },
}

local TREE_LAYOUTS = {
    wide = { width = 296, column = 63, left = 35 },
    narrow = { width = 251, column = 54, left = 26 },
}
local treeLayout = TREE_LAYOUTS.wide
local TREE_GAP = 12
local TREE_SPACING = 63
local TREE_OFFSET_Y = 34
local TREE_MIN_ROWS = 4
local TREE_TOP = 74
local SHOP_FOOTER = 40

local SHOP_NODE_SIZE = 36
local SHOP_NODE_HALF = SHOP_NODE_SIZE / 2

Shop.frame = VanillaBonkUI.Window("VanillaBonkShop", 400, 400)
local shop = Shop.frame
shop:SetPoint("CENTER", UIParent, "CENTER", 0, 40)

shop.gold = shop.headerRight

shop.hint = shop:CreateFontString(nil, "OVERLAY")
SetFont(shop.hint, 11, "")
shop.hint:SetShadowColor(0, 0, 0, 1)
shop.hint:SetShadowOffset(1, -1)
shop.hint:SetPoint("BOTTOMLEFT", shop, "BOTTOMLEFT", 26, 26)
shop.hint:SetTextColor(0.7, 0.7, 0.7)

shop.respec = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, shop, "UIPanelButtonTemplate"))
shop.respec:SetWidth(110)
shop.respec:SetHeight(22)
shop.respec:SetPoint("BOTTOMRIGHT", shop, "BOTTOMRIGHT", -28, 22)
shop.respec:SetText(L["hoa.addon.reset_talents"])
shop.respec:SetScript("OnClick", function()
    if VB.shopBusy then
        return
    end
    VB.shopBusy = GetTime()
    Command("respec")
end)
UI.Hover(shop.respec, function()
    local refund = SHOP_REFUNDS[shop.kind] or SHOP_REFUNDS[MASTERY_SHOP]
    GameTooltip:SetOwner(this, "ANCHOR_TOP")
    GameTooltip:AddLine(refund.label, 1, 1, 1)
    GameTooltip:AddLine(refund.text, 1, 0.82, 0, 1)
    GameTooltip:Show()
end)
shop.respec:Hide()

do
    local bar = CreateFrame("Frame", nil, shop)
    bar:SetWidth(1)
    bar:SetHeight(22)
    bar:SetPoint("BOTTOMRIGHT", shop.respec, "BOTTOMLEFT", -14, 0)
    bar:Hide()
    shop.presetBar = bar

    local function SendPreset()
        if VB.shopBusy or not shop.presetSlot then
            return
        end
        VB.shopBusy = GetTime()
        Command("preset " .. shop.presetSlot)
    end

    local function ShowTip(title, text)
        GameTooltip:SetOwner(this, "ANCHOR_TOP")
        GameTooltip:AddLine(title, 1, 1, 1)
        GameTooltip:AddLine(text, 1, 0.82, 0, 1)
        GameTooltip:Show()
    end

    local function AddButton(width, label, anchor)
        local button = VanillaBonkUI.SliceButton(CreateFrame("Button", nil, bar, "UIPanelButtonTemplate"))
        button:SetWidth(width)
        button:SetHeight(22)
        if anchor then
            button:SetPoint("RIGHT", anchor, "LEFT", -4, 0)
        else
            button:SetPoint("BOTTOMRIGHT", bar, "BOTTOMRIGHT", 0, 0)
        end
        button:SetText(label)
        return button
    end

    bar.activate = AddButton(84, L["hoa.addon.activate"])
    bar.activate:SetScript("OnClick", SendPreset)
    UI.Hover(bar.activate, function()
        ShowTip(L["hoa.addon.activate"], L["hoa.addon.switches_to_this_preset_s_talents_your_current_talents_stay_"])
    end)

    bar.slots = {}
    local anchor = bar.activate
    for slot = 3, 1, -1 do
        local button = AddButton(26, tostring(slot), anchor)
        button.slot = slot
        button:SetScript("OnClick", function()
            PlaySound("igMainMenuOptionCheckBoxOn")
            shop.presetSlot = this.slot
            Shop:Refresh()
        end)
        UI.Hover(button, function()
            local points = shop.presets and shop.presets.points[this.slot] or 0
            local text = points > 0 and (points == 1 and L["hoa.addon.1_talent_point"] or L("hoa.addon.1_talent_points_2", points)) or L["hoa.addon.empty_2"]
            if shop.presets and shop.presets.active == this.slot then
                text = text .. "\n|cff20ff20" .. L["hoa.addon.active_talent_changes_are_saved_to_this_preset"] .. "|r"
            end
            ShowTip(L("hoa.addon.preset_1", this.slot), text)
        end)
        bar.slots[slot] = button
        anchor = button
    end

    bar.label = bar:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    bar.label:SetPoint("RIGHT", bar.slots[1], "LEFT", -6, 0)
    bar.label:SetText(L["hoa.addon.presets"])

    function Shop:PreviewSlot(data)
        local presets = not data.inspect and data.presets
        local slot = presets and (shop.presetSlot or presets.active)
        if not slot or slot == presets.active then
            return nil
        end
        return slot
    end

    function Shop:PreviewData(data, slot)
        local ranks = data.presets.ranks[slot]
        local view = {}
        for key, value in pairs(data) do
            view[key] = value
        end
        view.nodes = {}
        local spentByTree, spent = {}, 0
        for id, node in pairs(data.nodes) do
            local copy = {}
            for key, value in pairs(node) do
                copy[key] = value
            end
            copy.rank = ranks[id] or 0
            if copy.rank > 0 then
                spentByTree[copy.tree] = (spentByTree[copy.tree] or 0) + copy.rank
                spent = spent + copy.rank
            end
            view.nodes[id] = copy
        end
        view.trees = {}
        for index, tree in ipairs(data.trees) do
            local copy = {}
            for key, value in pairs(tree) do
                copy[key] = value
            end
            copy.spent = spentByTree[tree.id] or 0
            view.trees[index] = copy
        end
        view.balance = max(0, (data.earned or 0) - spent)
        return view
    end

    function Shop:RefreshPresets()
        local presets = shop.presets
        if not presets then
            bar:Hide()
            return
        end
        shop.presetSlot = shop.presetSlot or presets.active
        for slot, button in pairs(bar.slots) do
            if slot == shop.presetSlot then
                button:LockHighlight()
            else
                button:UnlockHighlight()
            end
            if slot == presets.active then
                button:SetTextColor(1, 0.82, 0)
                button:SetHighlightTextColor(1, 0.82, 0)
            elseif presets.points[slot] > 0 then
                button:SetTextColor(0.6, 0.49, 0)
                button:SetHighlightTextColor(1, 1, 1)
            else
                button:SetTextColor(0.5, 0.5, 0.5)
                button:SetHighlightTextColor(1, 1, 1)
            end
        end
        if presets.active ~= shop.presetSlot then
            bar.activate:Enable()
        else
            bar.activate:Disable()
        end
        bar:Show()
    end
end

shop.panels = {}

function Shop:Balance()
    local shop = self.frame
    if VB.shop.currency == "shards" or VB.shop.currency == "points" then
        return VB.shop.balance
    end
    return GetMoney()
end

function Shop:FormatPoints(count)
    local shop = self.frame
    return "|cff80d0ff" .. (count == 1 and L("hoa.addon.1_talent_point_2", count) or L("hoa.addon.1_talent_points", count)) .. "|r"
end

function Shop:FormatShards(count)
    local shop = self.frame
    return "|cffc080ff" .. (count == 1 and L("hoa.addon.1_darkmoon_ticket", count) or L("hoa.addon.1_darkmoon_tickets", count)) .. "|r"
end

function Shop:FormatCost(amount)
    local shop = self.frame
    if VB.shop.currency == "shards" then
        return self:FormatShards(amount)
    elseif VB.shop.currency == "points" then
        return self:FormatPoints(amount)
    end
    return FormatGold(amount)
end

function Shop:TreeSpent(treeId)
    local shop = self.frame
    local spent = 0
    for _, other in pairs(VB.shop.nodes) do
        if other.tree == treeId then
            spent = spent + other.rank
        end
    end
    return spent
end

function Shop:TreeName(treeId)
    local shop = self.frame
    for _, tree in ipairs(VB.shop.trees) do
        if tree.id == treeId then
            return tree.name
        end
    end
    return ""
end

function Shop:MissingRequirement(node)
    local shop = self.frame
    if node.locked then
        if node.questDescription ~= "" then
            local what = gsub(node.questDescription, "%.$", "")
            what = strlower(strsub(what, 1, 1)) .. strsub(what, 2)
            return L("hoa.addon.requires_the_quest_1_2", node.quest, what)
        end
        return L("hoa.addon.requires_the_quest_1", node.quest)
    end
    if node.rankLock and node.rankLock ~= "" and node.rank < node.maxRank then
        return node.rankLock
    end
    local gate = VB.shop.gates and VB.shop.gates[node.row]
    if gate and gate.above < gate.need then
        return L("hoa.addon.requires_1_darkmoon_tickets_spent_in_the_rows_above", gate.need)
    end
    local perRow = VB.shop.pointsPerRow or 0
    if perRow > 0 and node.row > 1 and self:TreeSpent(node.tree) < (node.row - 1) * perRow then
        return L("hoa.addon.requires_1_points_in_2", (node.row - 1) * perRow, self:TreeName(node.tree))
    end
    local required = VB.shop.nodes[node.requiredId]
    if not required or node.requiredRank < 1 or required.rank >= node.requiredRank then
        return nil
    end
    if required.maxRank <= 1 then
        return L("hoa.addon.requires_1", required.name)
    end
    return L(node.requiredRank == 1 and "hoa.addon.requires_1_rank_in_2" or "hoa.addon.requires_1_ranks_in_2", node.requiredRank, required.name)
end

function VB.IsEndless(node)
    return node.maxRank >= VB.ENDLESS_RANKS
end
VB.ENDLESS_RANKS = 255

function Shop:DescribeRanks(node, ranks)
    local shop = self.frame
    local perRank = tonumber(node.valuePerRank)
    if not perRank or perRank == 0 then
        return nil
    end
    local text, out, start, value = node.description, "", 1, nil
    while true do
        local first, last = strfind(text, "%d[%d%.]*", start)
        if not first then
            break
        end
        if strsub(text, last, last) == "." then
            last = last - 1
        end
        local number = strsub(text, first, last)
        out = out .. strsub(text, start, first - 1)
        if tonumber(number) == perRank then
            out = out .. format("%g", perRank * ranks)
            if not value then
                local sign, unit = strsub(text, first - 1, first - 1), strsub(text, last + 1, last + 1)
                value = ((sign == "+" or sign == "-") and sign or "") .. format("%g", perRank * ranks) .. (unit == "%" and unit or "")
            end
        else
            out = out .. number
        end
        start = last + 1
    end
    if not value then
        return nil
    end
    return out .. strsub(text, start), value
end

function Shop:RefundBlocker(node)
    local shop = self.frame
    local perRow = VB.shop.pointsPerRow or 0
    for _, other in pairs(VB.shop.nodes) do
        if other ~= node and other.rank > 0 then
            if other.requiredId == node.id and node.rank - 1 < other.requiredRank then
                return L("hoa.addon.refund_1_first_it_depends_on_this_one", other.name)
            end
            local gate = VB.shop.gates and VB.shop.gates[other.row]
            if gate and node.maxRank ~= VB.ENDLESS_RANKS and other.row > node.row and gate.above - node.refund < gate.need then
                return L("hoa.addon.refund_1_first_it_needs_the_tickets_you_spent_here", other.name)
            end
            if perRow > 0 and other.tree == node.tree and other.row > node.row then
                local above = 0
                for _, placed in pairs(VB.shop.nodes) do
                    if placed.tree == other.tree and placed.row < other.row then
                        above = above + placed.rank
                    end
                end
                if above - 1 < (other.row - 1) * perRow then
                    return L("hoa.addon.refund_1_first_it_needs_the_points_you_spent_in_2", other.name, self:TreeName(node.tree))
                end
            end
        end
    end
    return nil
end

function Shop:ShowNodeTooltip(button)
    local shop = self.frame
    local node = button.node
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine(node.name, 1, 1, 1)
    if node.toggle then
        GameTooltip:AddLine(L["hoa.addon.dark_fortune"], 1, 1, 1)
    else
        GameTooltip:AddLine(VB.IsEndless(node) and L("hoa.addon.rank_1", node.rank) or L("hoa.addon.rank_1_2_2", node.rank, node.maxRank), 1, 1, 1)
    end

    local missing = self:MissingRequirement(node)
    if missing and node.rank < node.maxRank then
        GameTooltip:AddLine(missing, 1, 0.1, 0.1, 1)
    end
    local nextRank, nextValue = nil, nil
    if node.maxRank > 1 then
        nextRank, nextValue = self:DescribeRanks(node, node.rank + 1)
    end
    if nextRank then
        if node.rank > 0 then
            GameTooltip:AddLine(self:DescribeRanks(node, node.rank), 1, 0.82, 0, 1)
            if VB.IsEndless(node) then
                GameTooltip:AddLine(L("hoa.addon.next_rank_cff20ff20_1_r", nextRank), 1, 1, 1, 1)
            elseif node.rank < node.maxRank then
                GameTooltip:AddLine(L("hoa.addon.next_rank_cff20ff20_1_r", nextValue), 1, 1, 1)
            end
        else
            GameTooltip:AddLine(nextRank, 1, 0.82, 0, 1)
        end
    elseif node.maxRank > 1 then
        GameTooltip:AddLine(L("hoa.addon.each_rank_1", node.description), 1, 0.82, 0, 1)
    else
        GameTooltip:AddLine(node.description, 1, 0.82, 0, 1)
    end
    if node.description and string.find(node.description, L["hoa.addon.valor"], 1, true) then
        GameTooltip:AddLine(L["hoa.addon.valor_is_spent_on_chests_and_shops_during_a_run_resets_when_"], 0.6, 0.6, 0.6, 1)
    end

    GameTooltip:AddLine(" ")
    if VB.shop.coopGuest and node.toggle then
        if node.rank > 0 then
            GameTooltip:AddLine(node.enabled and L["hoa.addon.enabled"] or L["hoa.addon.disabled"], 0.6, 0.6, 0.6)
        end
        GameTooltip:AddLine(L["hoa.addon.in_co_op_the_host_s_dark_fortunes_count_for_everyone"], 0.6, 0.6, 0.6, 1)
        GameTooltip:Show()
        return
    end
    if node.rank < node.maxRank then
        GameTooltip:AddLine(L("hoa.addon.cost_1", self:FormatCost(node.cost)), 1, 1, 1)
        if self:Balance() < node.cost then
            GameTooltip:AddLine(L("hoa.addon.you_have_1", self:FormatCost(self:Balance())), 1, 0.1, 0.1)
        elseif not missing then
            GameTooltip:AddLine(L["hoa.addon.click_to_learn"], 0.1, 1, 0.1)
        end
    elseif node.toggle then
        if node.enabled then
            GameTooltip:AddLine(L["hoa.addon.enabled"], 0.1, 1, 0.1)
            GameTooltip:AddLine(L["hoa.addon.click_to_disable"], 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(L["hoa.addon.disabled"], 0.6, 0.6, 0.6)
            GameTooltip:AddLine(L["hoa.addon.click_to_enable"], 0.7, 0.7, 0.7)
        end
    else
        GameTooltip:AddLine(L["hoa.addon.fully_learned"], 1, 0.82, 0)
    end
    if node.rank > 0 then
        local blocker = self:RefundBlocker(node)
        if blocker then
            GameTooltip:AddLine(blocker, 0.6, 0.6, 0.6, 1)
        elseif node.refund > 0 then
            GameTooltip:AddLine(L("hoa.addon.right_click_to_refund_1", self:FormatCost(node.refund)), 0.7, 0.7, 0.7)
        else
            GameTooltip:AddLine(L["hoa.addon.right_click_to_refund"], 0.7, 0.7, 0.7)
        end
    end
    GameTooltip:Show()
end

function Shop:NodeOnClick()
    local shop = self.frame
    local node = this.node
    if VB.shopBusy or (VB.shop.coopGuest and node.toggle) then
        return
    end

    if arg1 == "RightButton" then
        if node.rank < 1 then
            return
        end
        local blocker = self:RefundBlocker(node)
        if blocker then
            Notice(blocker)
            return
        end
        VB.shopBusy = GetTime()
        Command("unlearn " .. node.id)
        return
    end

    local command
    if node.toggle and node.rank > 0 then
        command = "toggle " .. node.id
    elseif node.rank < node.maxRank then
        local missing = self:MissingRequirement(node)
        if missing then
            Notice(missing)
            return
        end
        if self:Balance() < node.cost then
            Notice(L("hoa.addon.you_need_1", self:FormatCost(node.cost)))
            return
        end
        command = "learn " .. node.id
    else
        return
    end

    VB.shopBusy = GetTime()
    Command(command)
end

function Shop:CreateNodeButton(panel, index)
    local shop = self.frame
    local name = panel.name .. "Node" .. index
    local button = CreateFrame("Button", name, panel)
    button:SetWidth(SHOP_NODE_SIZE)
    button:SetHeight(SHOP_NODE_SIZE)
    button:SetHighlightTexture("Interface\\Buttons\\ButtonHilight-Square", "ADD")
    VanillaBonkTalents.StyleButton(button)

    UI.Hover(button, function() self:ShowNodeTooltip(this) end)
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetScript("OnClick", function() Shop:NodeOnClick() end)

    panel.buttons[index] = button
    return button
end

function Shop:SetNode(button, node)
    local shop = self.frame
    button.node = node
    button:ClearAllPoints()
    button:SetPoint("TOPLEFT", button:GetParent(), "TOPLEFT",
        treeLayout.left + (node.column - 1) * treeLayout.column, -(TREE_OFFSET_Y + (node.row - 1) * TREE_SPACING))
    local missing = self:MissingRequirement(node)
    local which, text, colour = "locked", VB.IsEndless(node) and tostring(node.rank) or (node.rank .. "/" .. node.maxRank), nil
    if node.toggle and node.rank > 0 then
        which = node.enabled and "on" or "off"
        text = node.enabled and L["hoa.addon.on"] or L["hoa.addon.off_2"]
        colour = node.enabled and { 0.1, 1, 0.1 } or { 0.8, 0.8, 0.8 }
    elseif not missing and node.rank >= node.maxRank then
        which = "max"
    elseif not missing and self:Balance() >= node.cost then
        which = node.rank > 0 and "part" or "open"
    elseif not missing and node.rank > 0 then
        which = "max"
    end
    if VB.shop.coopGuest and node.toggle then
        which = "locked"
        colour = colour and { 0.5, 0.5, 0.5 }
    end
    VanillaBonkTalents.StyleNode(button, node.toggle, which, node.icon ~= "" and node.icon or "INV_Misc_QuestionMark", text, colour)
    button:Show()

    if GameTooltip:IsOwned(button) then
        self:ShowNodeTooltip(button)
    end
end

function Shop:CreateTreePanel(index)
    local shop = self.frame
    local panel = CreateFrame("Frame", "VanillaBonkShopTree" .. index, shop)
    panel.name = "VanillaBonkShopTree" .. index
    panel.buttons = {}
    panel.branches = {}
    panel.arrows = {}

    panel.art = {}
    for _, piece in ipairs({ "TopLeft", "TopRight", "BottomLeft", "BottomRight" }) do
        panel.art[piece] = panel:CreateTexture(nil, "BACKGROUND")
    end

    panel.edge = CreateFrame("Frame", nil, panel)
    panel.edge:SetAllPoints(panel)
    panel.edge:SetBackdrop({ edgeFile = "Interface\\Buttons\\WHITE8X8", edgeSize = 1 })
    panel.edge:SetBackdropBorderColor(0, 0, 0, 1)

    panel.band = panel:CreateTexture(nil, "BORDER")
    panel.band:SetPoint("TOPLEFT", panel, "TOPLEFT", 1, -1)
    panel.band:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -1, -1)
    panel.band:SetHeight(26)
    VanillaBonkUI.Shade(panel.band, 0, 0.75)

    panel.header = panel:CreateFontString(nil, "OVERLAY")
    SetFont(panel.header, 13, "")
    panel.header:SetShadowColor(0, 0, 0, 1)
    panel.header:SetShadowOffset(1, -1)
    panel.header:SetPoint("TOPLEFT", panel, "TOPLEFT", 10, -7)
    panel.header:SetTextColor(1, 0.82, 0)

    panel.spent = panel:CreateFontString(nil, "OVERLAY")
    SetFont(panel.spent, 11, "")
    panel.spent:SetShadowColor(0, 0, 0, 1)
    panel.spent:SetShadowOffset(1, -1)
    panel.spent:SetPoint("TOPRIGHT", panel, "TOPRIGHT", -10, -8)

    shop.panels[index] = panel
    return panel
end

function Shop:LayoutArt(panel, background, height)
    local shop = self.frame
    local width = treeLayout.width
    local scale = width / 256
    local topHeight, bottomHeight = 256 * scale, 128 * scale
    local base = "Interface\\TalentFrame\\" .. background .. "-"
    local art = panel.art

    local top = min(height, topHeight)
    local bottom = min(height - top, bottomHeight)
    art.TopLeft:SetTexture(base .. "TopLeft")
    art.TopLeft:SetWidth(width)
    art.TopLeft:SetHeight(top)
    art.TopLeft:SetTexCoord(0, 1, 0, top / topHeight)
    art.TopLeft:ClearAllPoints()
    art.TopLeft:SetPoint("TOPLEFT", panel, "TOPLEFT", 0, 0)
    art.TopLeft:Show()
    if bottom > 0 then
        art.BottomLeft:SetTexture(base .. "BottomLeft")
        art.BottomLeft:SetWidth(width)
        art.BottomLeft:SetHeight(bottom)
        art.BottomLeft:SetTexCoord(0, 1, 0, bottom / bottomHeight)
        art.BottomLeft:ClearAllPoints()
        art.BottomLeft:SetPoint("TOPLEFT", art.TopLeft, "BOTTOMLEFT", 0, 0)
        art.BottomLeft:Show()
    else
        art.BottomLeft:Hide()
    end
    art.TopRight:Hide()
    art.BottomRight:Hide()
end

function Shop:DrawTree(panel, tree)
    local shop = self.frame
    local nodes = VB.shop.nodes
    for _, list in ipairs({ panel.buttons, panel.branches }) do
        for _, region in ipairs(list) do
            region:Hide()
        end
    end

    local count, spent = 0, 0
    for _, node in pairs(nodes) do
        if node.tree == tree.id then
            count = count + 1
            self:SetNode(panel.buttons[count] or self:CreateNodeButton(panel, count), node)
            spent = spent + node.rank
        end
    end
    panel.header:SetText(tree.name)
    if tree.tickets then
        panel.spent:SetText(tree.tickets == 1 and L("hoa.addon.1_ticket_spent", tree.tickets) or L("hoa.addon.1_tickets_spent", tree.tickets))
    else
        panel.spent:SetText(spent == 1 and L("hoa.addon.1_point_spent", spent) or L("hoa.addon.1_points_spent", spent))
    end

    local height = panel:GetHeight()
    local function Centre(node)
        return treeLayout.left + (node.column - 1) * treeLayout.column + SHOP_NODE_HALF,
            height - TREE_OFFSET_Y - (node.row - 1) * TREE_SPACING - SHOP_NODE_HALF
    end
    local lines, treeRows = 0, 0
    for _, node in pairs(nodes) do
        if node.tree == tree.id then
            treeRows = max(treeRows, node.row)
        end
        local required = nodes[node.requiredId]
        if node.tree == tree.id and required and required.tree == tree.id then
            local sx, sy = Centre(required)
            local ex, ey = Centre(node)
            local kind = self:MissingRequirement(node) and "dark" or node.rank > 0 and "lit" or "open"
            lines = lines + 1
            VanillaBonkTalents.ShopLine(panel, panel.branches, lines, sx, sy, ex, ey, kind)
        end
    end

    VanillaBonkTalents.HideShopGates(panel.arrows)
    local gates = VB.shop.gates
    if gates then
        local count = 0
        for row = 2, min(table.getn(gates), treeRows) do
            if gates[row].need > gates[row - 1].need then
                count = count + 1
                local lit = gates[row].above >= gates[row].need
                local text = lit and L("hoa.addon.unlocked_at_1_tickets_spent", gates[row].need) or L("hoa.addon.requires_1_tickets_spent", gates[row].need)
                VanillaBonkTalents.ShopGate(panel, panel.arrows, count, -(TREE_OFFSET_Y + (row - 1.5) * TREE_SPACING + SHOP_NODE_HALF), text, lit)
            end
        end
    end
end

function Shop:UpdateShopTabs(data)
    local shop = self.frame
    shop.tab = nil
    UI.Tabs(shop, {}, nil)
end

function Shop:Refresh()
    local shop = self.frame
    local data = VB.shop
    local previewSlot = self:PreviewSlot(data)
    if previewSlot then
        data = self:PreviewData(data, previewSlot)
    end
    if VanillaBonkTalents then
        VanillaBonkTalents.muted = previewSlot ~= nil
    end
    self:UpdateShopTabs(data)
    TREE_SPACING = data.gates and 84 or 63
    local rows = TREE_MIN_ROWS
    for _, node in pairs(data.nodes) do
        rows = max(rows, node.row)
    end
    local height = TREE_OFFSET_Y * 2 + (rows - 1) * TREE_SPACING + 37

    for _, panel in ipairs(shop.panels) do
        panel:Hide()
    end
    if VanillaBonkTalents and VanillaBonkTalents.Wants(data) then
        local freeWidth, freeHeight = VanillaBonkTalents.Show(shop, data, TREE_TOP)
        height = freeHeight
        VanillaBonkUI.SetWindowSize(shop, freeWidth, TREE_TOP + height + SHOP_FOOTER + 9)
    else
        if VanillaBonkTalents then
            VanillaBonkTalents.Hide()
        end
        local count = table.getn(data.trees)
        treeLayout = count >= 4 and TREE_LAYOUTS.narrow or TREE_LAYOUTS.wide
        local width = treeLayout.width
        for index, tree in ipairs(data.trees) do
            local panel = shop.panels[index] or self:CreateTreePanel(index)
            panel:ClearAllPoints()
            panel:SetPoint("TOPLEFT", shop, "TOPLEFT", 20 + (index - 1) * (width + TREE_GAP), -TREE_TOP)
            panel:SetWidth(width)
            panel:SetHeight(height)
            self:LayoutArt(panel, tree.background, height)
            self:DrawTree(panel, tree)
            panel:Show()
        end

        count = max(count, 1)
        VanillaBonkUI.SetWindowSize(shop, max(360, 30 + count * width + (count - 1) * TREE_GAP), TREE_TOP + height + SHOP_FOOTER + 9)
    end
    shop.title:SetText((data.className and (data.className .. " ") or "") .. (SHOP_TITLES[data.kind] or ""))
    shop.header:SetText(data.npc)
    shop.hint:SetText(data.inspect and L["hoa.addon.talents_can_only_be_changed_at_the_inn"] or
        data.coopGuest and L["hoa.addon.click_a_fortune_to_buy_it_right_click_to_refund_it_in_co_op_"] or
        previewSlot and L("hoa.addon.preset_1_click_activate_to_use_these_talents", previewSlot) or SHOP_HINTS[data.kind] or "")
    if VanillaBonkTalents then
        VanillaBonkTalents.readOnly = data.inspect or previewSlot ~= nil
    end
    if data.currency == "shards" then
        shop.gold:SetText(self:FormatShards(data.balance))
    elseif data.currency == "points" then
        local level = L("hoa.addon.cffffffffmastery_1_2_r", data.level, data.maxLevel)
        if data.xpNext > 0 then
            level = level .. " |cff9d9d9d(" .. data.xp .. "/" .. data.xpNext .. ")|r"
        end
        shop.gold:SetText(level .. "   " .. self:FormatPoints(data.balance))
    else
        shop.gold:SetText(FormatGold(GetMoney()))
    end
    shop.kind = data.kind
    local refund = not data.inspect and not data.coopGuest and not previewSlot and SHOP_REFUNDS[data.kind]
    if refund then
        shop.respec:SetText(refund.label)
        shop.respec:Show()
    else
        shop.respec:Hide()
    end
    shop.presets = not data.inspect and data.presets or nil
    self:RefreshPresets()
end

shop:SetScript("OnShow", function()
    PlaySound("TalentScreenOpen")
    VanillaBonkUI.SetPortrait(shop)
end)

shop:SetScript("OnHide", function()
    PlaySound("TalentScreenClose")
    VB.shopBusy = nil
    shop.presetSlot = nil
    GossipWindowHidden(shop)
end)

shop:SetScript("OnUpdate", function()
    if VB.shopBusy and GetTime() - VB.shopBusy > 3 then
        VB.shopBusy = nil
    end
end)

function Shop:ApplyShop(f)
    VB.shopIncoming = { kind = f[2], open = f[3] == "1", npc = f[4] or "", currency = f[5] or "gold", balance = tonumber(f[6]) or 0,
        trees = {}, nodes = {} }
    if f[2] == MASTERY_SHOP then
        local data = VB.shopIncoming
        data.level = tonumber(f[7]) or 0
        data.xp = tonumber(f[8]) or 0
        data.xpNext = tonumber(f[9]) or 0
        data.maxLevel = tonumber(f[10]) or 0
        data.earned = tonumber(f[11]) or 0
        data.fromQuests = tonumber(f[12]) or 0
        data.className = f[13]
        data.pointsPerRow = tonumber(f[14]) or 0
        data.inspect = f[15] == "1"
    elseif f[2] == FORTUNE_SHOP and f[7] and f[7] ~= "" then
        local data = VB.shopIncoming
        data.gates = {}
        for need, above in string.gfind(f[7], "(%d+):(%d+)") do
            tinsert(data.gates, { need = tonumber(need), above = tonumber(above) })
        end
    end
    if f[2] == FORTUNE_SHOP then
        VB.shopIncoming.coopGuest = f[8] == "1"
    end
end

function Shop:ApplyTree(f)
    if VB.shopIncoming then
        local tree = { id = f[2], name = f[3] or "", background = f[4] or "MageFire" }
        if VB.shopIncoming.kind == FORTUNE_SHOP then
            tree.tickets = tonumber(f[5])
        end
        if VB.shopIncoming.kind == MASTERY_SHOP and VanillaBonkTalents then
            VanillaBonkTalents.ParseTree(tree, f)
        end
        tinsert(VB.shopIncoming.trees, tree)
    end
end

function Shop:ApplyPresets(f)
    if VB.shopIncoming then
        VB.shopIncoming.presets = { active = tonumber(f[2]) or 0, points = { tonumber(f[3]) or 0, tonumber(f[4]) or 0, tonumber(f[5]) or 0 },
            ranks = { {}, {}, {} } }
    end
end

function Shop:ApplyPresetRanks(f)
    local presets = VB.shopIncoming and VB.shopIncoming.presets
    local ranks = presets and presets.ranks[tonumber(f[2])]
    if not ranks then
        return
    end
    for id, rank in string.gfind(f[3] or "", "(%d+):(%d+)") do
        ranks[id] = tonumber(rank)
    end
end

function Shop:ApplyNode(f)
    if not VB.shopIncoming then
        return
    end
    VB.shopIncoming.nodes[f[3]] = {
        tree = f[2],
        id = f[3],
        row = tonumber(f[4]) or 1,
        column = tonumber(f[5]) or 1,
        icon = f[6] or "",
        rank = tonumber(f[7]) or 0,
        maxRank = tonumber(f[8]) or 1,
        cost = tonumber(f[9]) or 0,
        requiredId = f[10],
        requiredRank = tonumber(f[11]) or 0,
        toggle = f[12] == "1",
        enabled = f[13] == "1",
        name = f[14] or "",
        description = f[15] or "",
        locked = f[16] == "1",
        quest = f[17] or "",
        valuePerRank = f[18] or "",
        refund = tonumber(f[19]) or 0,
        questDescription = f[20] or "",
        rankLock = VB.shopIncoming.kind ~= MASTERY_SHOP and f[21] or "",
    }
    if VB.shopIncoming.kind == MASTERY_SHOP and VanillaBonkTalents then
        VanillaBonkTalents.ParseNode(VB.shopIncoming.nodes[f[3]], f)
    end
end

function Shop:Changes(before, after)
    local shop = self.frame
    local changes = {}
    for id, node in pairs(after.nodes) do
        local old = before.nodes[id]
        if old and node.rank > old.rank then
            changes.learned = true
        elseif old and node.rank < old.rank then
            changes.refunded = true
        elseif old and node.enabled ~= old.enabled then
            changes.switched = node.enabled and "on" or "off"
        end
    end
    return changes
end

function Shop:PlayShopChangeSound(before, after)
    local shop = self.frame
    local changes = self:Changes(before, after)
    if changes.learned then
        PlaySoundFile("Sound\\Interface\\uSpellIconDrop.wav")
    elseif changes.refunded and after.kind == MASTERY_SHOP then
        PlaySound("igMainMenuOptionCheckBoxOff")
    elseif changes.refunded then
        PlaySound("LOOTWINDOWCOINSOUND")
    elseif changes.switched == "on" then
        PlaySound("igMainMenuOptionCheckBoxOn")
    elseif changes.switched == "off" then
        PlaySound("igMainMenuOptionCheckBoxOff")
    end
end

function Shop:PlayPurchaseSound()
    local shop = self.frame
    local money = GetMoney()
    local spent = VB.lastMoney and money < VB.lastMoney
    VB.lastMoney = money
    if not spent or VB.inRun then
        return
    end
    if shop:IsShown() then
        return
    end
    PlaySound("LOOTWINDOWCOINSOUND")
end

function Shop:EndShop()
    local incoming = VB.shopIncoming
    VB.shopIncoming = nil
    if not incoming then
        return
    end

    VB.shopBusy = nil
    if incoming.inspect then
        shop.tab = nil
        VB.shop = incoming
        self:Refresh()
        shop:Show()
    elseif incoming.open then
        shop.tab = nil
        VB.shop = incoming
        ReplaceNextGossip(shop, incoming.npc, function() Shop:Refresh() end)
    elseif shop:IsShown() and VB.shop and VB.shop.kind == incoming.kind then
        local before = VB.shop
        VB.shop = incoming
        self:Refresh()
        self:PlayShopChangeSound(before, incoming)
    end
end

function Shop:CloseShop()
    VB.shopBusy = nil
    shop:Hide()
end


VB.shopFrame = Shop.frame
VB.RefreshShop = function() Shop:Refresh() end
VB.PlayPurchaseSound = function() Shop:PlayPurchaseSound() end

handlers["shop"] = function(f) Shop:ApplyShop(f) end
handlers["tree"] = function(f) Shop:ApplyTree(f) end
handlers["presets"] = function(f) Shop:ApplyPresets(f) end
handlers["presetranks"] = function(f) Shop:ApplyPresetRanks(f) end
handlers["node"] = function(f) Shop:ApplyNode(f) end
handlers["shopend"] = function() Shop:EndShop() end
handlers["shopclose"] = function() Shop:CloseShop() end
