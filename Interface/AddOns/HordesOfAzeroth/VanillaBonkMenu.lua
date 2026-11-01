local L = VanillaBonkL
local UI = VanillaBonkUI

local CARD_WIDTH = 220
local CARD_HEIGHT = 304
local CARD_GAP = 20
local CARD_Y = 20
local STONE_BORDER = { edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 24 }
local BUTTON_WIDTH = 176
local SPELL_SIZE = 40
local PASSIVE_SIZE = 30
local CARD_SLOT_SIZE = 26
local DIFFICULTY_COLORS = { [L["Normal"]] = "40ff40", [L["Heroic"]] = "ffd100", [L["Mythic"]] = "ff4d4d" }

local run = { inRun = false, stage = 1, difficulty = "", elapsed = 0, spells = {}, passives = {} }

local function Command(text)
    SendChatMessage(".bonk " .. text, "SAY")
end

local menu = CreateFrame("Frame", "VanillaBonkMenu", UIParent)
menu:SetAllPoints(UIParent)
menu:SetFrameStrata("FULLSCREEN_DIALOG")
menu:EnableMouse(true)
menu:Hide()

menu.dim = menu:CreateTexture(nil, "BACKGROUND")
menu.dim:SetTexture("Interface\\AddOns\\HordesOfAzeroth\\Textures\\OfferVignette")
menu.dim:SetPoint("TOPLEFT", WorldFrame, "TOPLEFT", -2, 2)
menu.dim:SetPoint("BOTTOMRIGHT", WorldFrame, "BOTTOMRIGHT", 2, -2)
menu.dim:SetVertexColor(0, 0, 0, 1)
menu.shade = menu:CreateTexture(nil, "BACKGROUND")
menu.shade:SetTexture(UI.FLAT)
menu.shade:SetAllPoints(menu.dim)
menu.shade:SetVertexColor(0, 0, 0, 0.25)

menu.title = menu:CreateFontString(nil, "OVERLAY")
menu.title:SetFont(UI.TITLE_FONT, 46, "OUTLINE")
menu.title:SetPoint("CENTER", menu, "CENTER", 0, 230)
menu.title:SetTextColor(1, 0.82, 0)

menu.subtitle = UI.Text(menu, 13)
menu.subtitle:SetPoint("CENTER", menu, "CENTER", 0, 186)
menu.subtitle:SetTextColor(0.9, 0.83, 0.64)

for side = 1, 2 do
    local line = menu:CreateTexture(nil, "ARTWORK")
    line:SetTexture(UI.FLAT)
    line:SetWidth(60)
    line:SetHeight(1)
    if side == 1 then
        line:SetPoint("RIGHT", menu.subtitle, "LEFT", -12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.7)
    else
        line:SetPoint("LEFT", menu.subtitle, "RIGHT", 12, 0)
        line:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.7, 1, 0.82, 0, 0)
    end
end

menu.hint = UI.Text(menu, 11)
menu.hint:SetPoint("CENTER", menu, "CENTER", 0, CARD_Y - CARD_HEIGHT / 2 - 22)
menu.hint:SetTextColor(0.78, 0.78, 0.78)
menu.hint:SetText(L["Press Escape to resume."])

local function Card(art)
    local card = CreateFrame("Frame", nil, menu)
    card:SetWidth(CARD_WIDTH)
    card:SetHeight(CARD_HEIGHT)
    card:SetBackdrop(STONE_BORDER)
    card.art = card:CreateTexture(nil, "BACKGROUND")
    card.art:SetPoint("TOPLEFT", card, "TOPLEFT", 9, -9)
    card.art:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -9, 9)
    card.art:SetTexture("Interface\\TalentFrame\\" .. art .. "-TopLeft")
    UI.TalentArtCoords(card.art, CARD_WIDTH - 18, CARD_HEIGHT - 18)
    card.shade = card:CreateTexture(nil, "BORDER")
    card.shade:SetAllPoints(card.art)
    UI.Shade(card.shade, 0.95, 0.4)
    card.line = CreateFrame("Frame", nil, card)
    card.line:SetPoint("TOPLEFT", card, "TOPLEFT", 8, -8)
    card.line:SetPoint("BOTTOMRIGHT", card, "BOTTOMRIGHT", -8, 8)
    card.line:SetBackdrop({ edgeFile = UI.FLAT, edgeSize = 1 })
    card.line:SetBackdropBorderColor(0.85, 0.75, 0.5, 0.35)
    return card
end

local function Heading(card, text)
    card.heading = UI.Text(card, 15)
    card.heading:SetPoint("TOP", card, "TOP", 0, -24)
    card.heading:SetTextColor(1, 0.82, 0)
    card.heading:SetText(text)
    for side = 1, 2 do
        local half = card:CreateTexture(nil, "ARTWORK")
        half:SetTexture(UI.FLAT)
        half:SetHeight(1)
        half:SetWidth((CARD_WIDTH - 48) / 2)
        if side == 1 then
            half:SetPoint("TOPRIGHT", card.heading, "BOTTOM", 0, -9)
            half:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0, 1, 0.82, 0, 0.75)
        else
            half:SetPoint("TOPLEFT", card.heading, "BOTTOM", 0, -9)
            half:SetGradientAlpha("HORIZONTAL", 1, 0.82, 0, 0.75, 1, 0.82, 0, 0)
        end
    end
end

local runCard = Card("PaladinHoly")
Heading(runCard, L["This Run"])
runCard.rows = {}

local function StatRow(index, label, icon)
    local row = {}
    row.icon = runCard:CreateTexture(nil, "ARTWORK")
    row.icon:SetTexture(UI.ICON_PATH .. icon)
    row.icon:SetTexCoord(0.07, 0.93, 0.07, 0.93)
    row.icon:SetWidth(20)
    row.icon:SetHeight(20)
    row.icon:SetPoint("TOPLEFT", runCard, "TOPLEFT", 26, -64 - (index - 1) * 28)
    row.label = UI.Text(runCard, 12)
    row.label:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
    row.label:SetText(label)
    row.value = UI.Text(runCard, 14, UI.NUMBER_FONT)
    row.value:SetPoint("RIGHT", runCard, "TOPRIGHT", -26, -74 - (index - 1) * 28)
    runCard.rows[index] = row
    return row
end

local levelRow = StatRow(1, L["Level"], "Spell_Nature_TimeStop")
local killsRow = StatRow(2, L["Kills"], "INV_Misc_Bone_HumanSkull_01")
local valorRow = StatRow(3, L["Valor"], "INV_Misc_Coin_04")
local ticketsRow = StatRow(4, L["Tickets"], "INV_Misc_Ticket_Darkmoon_01")
local goldRow = StatRow(5, L["Gold"], "INV_Misc_Coin_02")

local menuCard = Card("MageFire")

local confirm

local function Button(text, height, onClick)
    local button = UI.Button(menuCard, BUTTON_WIDTH, text, onClick)
    button:SetHeight(height or 22)
    return button
end

local function Close()
    confirm:Hide()
    menu:Hide()
end

local function Panel(frame)
    return function()
        PlaySound("igMainMenuOption")
        Close()
        ShowUIPanel(frame)
    end
end

function UI.ShowClientSettings(page)
    if not BenillaOptionsFrame or not BenillaOptionsFrame_SelectCategory then
        return false
    end
    ShowUIPanel(BenillaOptionsFrame)
    BenillaOptionsFrame_SelectCategory(page)
    return true
end

local function VideoSettings()
    PlaySound("igMainMenuOption")
    Close()
    if not UI.ShowClientSettings("Graphics") then
        ShowUIPanel(OptionsFrame)
    end
end

menuCard.resume = Button(L["Resume"], 28, function()
    PlaySound("igMainMenuContinue")
    Close()
end)
menuCard.endRun = Button(L["|cffff5a4aEnd Run|r"], 22, function()
    PlaySound("igMainMenuOption")
    confirm:Show()
end)
menuCard.video = Button(L["Video"], 22, VideoSettings)
menuCard.sound = Button(L["Sound"], 22, Panel(SoundOptionsFrame))
menuCard.interface = Button(L["Interface"], 22, Panel(UIOptionsFrame))
menuCard.bindings = Button(L["Key Bindings"], 22, function()
    PlaySound("igMainMenuOption")
    Close()
    VanillaBonkUI.ShowBindings(VanillaBonkController.kind ~= nil)
end)
menuCard.controller = Button(L["Controller"], 22, function()
    PlaySound("igMainMenuOption")
    Close()
    VanillaBonkControllerPanel:Show()
end)
menuCard.logout = Button(L["Logout"], 22, function()
    PlaySound("igMainMenuLogout")
    Close()
    Logout()
end)
menuCard.quit = Button(L["Exit Game"], 22, function()
    PlaySound("igMainMenuQuit")
    Close()
    Quit()
end)

local function LayoutButtons()
    local order = { menuCard.resume, menuCard.endRun, false, menuCard.video, menuCard.sound, menuCard.interface,
        menuCard.bindings, menuCard.controller, false, menuCard.logout, menuCard.quit }
    local y = -22
    for _, button in ipairs(order) do
        if not button then
            y = y - 8
        elseif button == menuCard.endRun and not run.inRun then
            button:Hide()
        else
            button:ClearAllPoints()
            button:SetPoint("TOP", menuCard, "TOP", 0, y)
            button:Show()
            y = y - button:GetHeight() - 4
        end
    end
    local leaving = StaticPopup_Visible("CAMP") or StaticPopup_Visible("QUIT")
    for _, button in ipairs({ menuCard.logout, menuCard.quit }) do
        if leaving then
            button:Disable()
        else
            button:Enable()
        end
    end
end

local buildCard = Card("MageFrost")
Heading(buildCard, L["Your Build"])
buildCard.spells = {}
buildCard.passives = {}
buildCard.passiveLabel = UI.Text(buildCard, 11)
buildCard.passiveLabel:SetTextColor(0.62, 0.62, 0.62)
buildCard.passiveLabel:SetText(L["Passives"])
buildCard.cards = {}
buildCard.cardLabel = UI.Text(buildCard, 11)
buildCard.cardLabel:SetTextColor(0.62, 0.62, 0.62)
buildCard.cardLabel:SetText(L["Darkmoon Cards"])
buildCard.empty = UI.Text(buildCard, 12)
buildCard.empty:SetPoint("TOP", buildCard, "TOP", 0, -80)
buildCard.empty:SetTextColor(0.62, 0.62, 0.62)
buildCard.empty:SetText(L["Nothing learned yet"])

local function BuildSlot(list, index, size)
    local slot = list[index]
    if not slot then
        slot = UI.Slot(buildCard, size)
        slot.rank = UI.Text(slot, size >= 40 and 13 or 11, UI.NUMBER_FONT, "OUTLINE")
        slot.rank:SetPoint("BOTTOMRIGHT", slot, "BOTTOMRIGHT", -1, 2)
        slot.index = index
        slot.isPassive = list == buildCard.passives
        slot.isCard = list == buildCard.cards
        slot.navTooltip = true
        slot:SetScript("OnEnter", function()
            if this.isCard then
                UI.DarkmoonCardTooltip(this, this.index)
            elseif this.isPassive then
                VanillaBonk_PassiveTooltip(this, this.index)
            else
                VanillaBonk_SpellTooltip(this, this.index)
            end
        end)
        slot:SetScript("OnLeave", function()
            GameTooltip:Hide()
        end)
        list[index] = slot
    end
    return slot
end

local function PlaceSlots(list, entries, size, gap, top, perRow)
    perRow = perRow or 3
    local count = getn(entries)
    for index, entry in ipairs(entries) do
        local slot = BuildSlot(list, index, size)
        local row = floor((index - 1) / perRow)
        local column = mod(index - 1, perRow)
        local inRow = min(perRow, count - row * perRow)
        local x = (column - (inRow - 1) / 2) * (size + gap)
        slot:ClearAllPoints()
        slot:SetPoint("TOP", buildCard, "TOP", x, top - row * (size + gap))
        slot.icon:SetTexture(UI.ICON_PATH .. entry.icon)
        slot.rank:SetText(entry.rank)
        slot.frame:SetVertexColor(entry.r or 1, entry.g or 1, entry.b or 1)
        slot:Show()
    end
    for index = count + 1, getn(list) do
        list[index]:Hide()
    end
    local rows = ceil(count / perRow)
    return top - rows * size - max(0, rows - 1) * gap
end

local function HeldCardEntries()
    local entries = {}
    for _, card in ipairs(UI.HeldDarkmoonCards and UI.HeldDarkmoonCards() or {}) do
        local color = UI.RARITY[card.rarity] or UI.RARITY[0]
        tinsert(entries, {
            icon = card.icon ~= "" and card.icon or "INV_Misc_QuestionMark",
            rank = card.copies > 1 and card.copies or "",
            r = color.r, g = color.g, b = color.b,
        })
    end
    return entries
end

local function RefreshBuild()
    local bottom = PlaceSlots(buildCard.spells, run.spells, SPELL_SIZE, 14, -66)
    if getn(run.passives) > 0 then
        buildCard.passiveLabel:ClearAllPoints()
        buildCard.passiveLabel:SetPoint("TOP", buildCard, "TOP", 0, bottom - 12)
        buildCard.passiveLabel:Show()
        bottom = PlaceSlots(buildCard.passives, run.passives, PASSIVE_SIZE, 18, bottom - 34)
    else
        buildCard.passiveLabel:Hide()
        PlaceSlots(buildCard.passives, run.passives, PASSIVE_SIZE, 18, 0)
    end
    local cards = HeldCardEntries()
    if getn(cards) > 0 then
        buildCard.cardLabel:ClearAllPoints()
        buildCard.cardLabel:SetPoint("TOP", buildCard, "TOP", 0, bottom - 12)
        buildCard.cardLabel:Show()
        bottom = PlaceSlots(buildCard.cards, cards, CARD_SLOT_SIZE, 10, bottom - 32, 6)
    else
        buildCard.cardLabel:Hide()
        PlaceSlots(buildCard.cards, cards, CARD_SLOT_SIZE, 10, 0, 6)
    end
    if getn(run.spells) + getn(run.passives) + getn(cards) == 0 then
        buildCard.empty:Show()
    else
        buildCard.empty:Hide()
    end
    local height = max(CARD_HEIGHT, 24 - bottom)
    buildCard:SetHeight(height)
    UI.TalentArtCoords(buildCard.art, CARD_WIDTH - 18, height - 18)
end

confirm = CreateFrame("Frame", nil, menu)
confirm:SetAllPoints(menu)
confirm:SetFrameLevel(menu:GetFrameLevel() + 20)
confirm:EnableMouse(true)
confirm.shroud = confirm:CreateTexture(nil, "BACKGROUND")
confirm.shroud:SetTexture(UI.FLAT)
confirm.shroud:SetAllPoints(menu.dim)
confirm.shroud:SetVertexColor(0, 0, 0, 0.45)
confirm:Hide()

confirm.box = CreateFrame("Frame", nil, confirm)
confirm.box:SetWidth(360)
confirm.box:SetHeight(130)
confirm.box:SetPoint("CENTER", menu, "CENTER", 0, 70)
confirm.box:SetBackdrop({
    bgFile = UI.FLAT, edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border", edgeSize = 32, tileSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
confirm.box:SetBackdropColor(0, 0, 0, 0.95)
confirm.question = UI.Text(confirm.box, 14)
confirm.question:SetPoint("TOP", confirm.box, "TOP", 0, -24)
confirm.question:SetText(L["End this run?"])
confirm.text = UI.Text(confirm.box, 12)
confirm.text:SetPoint("TOP", confirm.question, "BOTTOM", 0, -6)
confirm.text:SetWidth(310)
confirm.text:SetTextColor(1, 0.82, 0)
confirm.text:SetText(L["You keep the gold and Darkmoon Tickets earned so far. Loot outside your Extraction Vault is lost."])
confirm.yes = UI.Button(confirm.box, 120, L["|cffff5a4aEnd Run|r"], function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    Command(confirm.command or "stop")
    Close()
end)
confirm.yes:SetPoint("BOTTOMRIGHT", confirm.box, "BOTTOM", -6, 18)
confirm.no = UI.Button(confirm.box, 120, L["Cancel"], function()
    PlaySound("igMainMenuOptionCheckBoxOff")
    if confirm.command then
        Close()
    else
        confirm:Hide()
    end
end)

local function SetConfirm(question, text, command)
    confirm.question:SetText(question)
    confirm.text:SetText(text)
    confirm.command = command
end

local function SetEndRunConfirm()
    SetConfirm(L["End this run?"], L["You keep the gold and Darkmoon Tickets earned so far. Loot outside your Extraction Vault is lost."])
end
confirm.no:SetPoint("BOTTOMLEFT", confirm.box, "BOTTOM", 6, 18)

local function Refresh()
    if run.inRun then
        menu.title:SetText(L["Paused"])
        local difficulty = run.difficulty ~= "" and ("  |cff9d9d9d·|r  |cff" .. (DIFFICULTY_COLORS[run.difficulty] or "ffffff") .. run.difficulty .. "|r") or ""
        menu.subtitle:SetText("|cffffd100" .. L["Floor "] .. run.stage .. "|r" .. difficulty .. "  |cff9d9d9d·|r  |cffffffff" .. UI.FormatTime(run.elapsed) .. "|r")
        levelRow.value:SetText(run.level or "-")
        killsRow.value:SetText(run.kills or 0)
        valorRow.value:SetText("|cffffe873" .. (run.valor or 0) .. "|r")
        ticketsRow.value:SetText("|cffd6b0ff" .. (run.shards or 0) .. "|r")
        goldRow.value:SetText(UI.FormatGold(run.gold or 0))
        RefreshBuild()
        runCard:ClearAllPoints()
        runCard:SetPoint("CENTER", menu, "CENTER", -(CARD_WIDTH + CARD_GAP), CARD_Y)
        menuCard:ClearAllPoints()
        menuCard:SetPoint("CENTER", menu, "CENTER", 0, CARD_Y)
        buildCard:ClearAllPoints()
        buildCard:SetPoint("TOP", menu, "CENTER", CARD_WIDTH + CARD_GAP, CARD_Y + CARD_HEIGHT / 2)
        runCard:Show()
        buildCard:Show()
    else
        menu.title:SetText(L["Game Menu"])
        menu.subtitle:SetText(L["Inn"])
        runCard:Hide()
        buildCard:Hide()
        menuCard:ClearAllPoints()
        menuCard:SetPoint("CENTER", menu, "CENTER", 0, CARD_Y)
    end
    LayoutButtons()
end

local paused = false

function UI.MenuPaused()
    return paused and run.inRun
end

local function StillOpen()
    if menu:IsShown() or StaticPopup_Visible("CAMP") or StaticPopup_Visible("QUIT") then
        return true
    end
    for _, name in ipairs({ "VanillaBonkPlateGuide", "VanillaBonkHearthTip" }) do
        local guide = getglobal(name)
        if guide and guide:IsShown() then
            return true
        end
    end
    for _, frame in ipairs({ OptionsFrame, SoundOptionsFrame, UIOptionsFrame, KeyBindingFrame, BenillaOptionsFrame }) do
        if frame and frame:IsShown() then
            return true
        end
    end
    return false
end

local watch = CreateFrame("Frame")
watch:Hide()
watch:SetScript("OnUpdate", function()
    this.elapsed = (this.elapsed or 0) + arg1
    if this.elapsed < 0.1 then
        return
    end
    this.elapsed = 0
    if not StillOpen() then
        paused = false
        Command("menu 0")
        this:Hide()
    end
end)

local function Open()
    if menu:IsShown() then
        return
    end
    if GameMenuFrame:IsShown() then
        HideUIPanel(GameMenuFrame)
    end
    confirm:Hide()
    SetEndRunConfirm()
    Refresh()
    menu:Show()
    if not paused then
        paused = true
        Command("menu 1")
        watch:Show()
    end
end

menu:SetScript("OnShow", function()
    PlaySound("igMainMenuOpen")
end)

function ToggleGameMenu(clicked)
    if confirm:IsShown() and confirm.command then
        PlaySound("igMainMenuQuit")
        Close()
        return
    end
    if confirm:IsShown() then
        confirm:Hide()
        return
    end
    if menu:IsShown() then
        PlaySound("igMainMenuQuit")
        Close()
        return
    end
    if not clicked then
        if StaticPopup_EscapePressed() then
            return
        end
        if OptionsFrame:IsVisible() then
            OptionsFrameCancel:Click()
            return
        end
        if BenillaOptionsFrame and BenillaOptionsFrame:IsVisible() then
            BenillaOptionsFrameCloseButton:Click()
            return
        end
        if CloseMenus() or SpellStopCasting() or SpellStopTargeting() or CloseAllWindows() then
            return
        end
    else
        CloseMenus()
        CloseAllWindows()
    end
    Open()
end

local StockShowUIPanel = ShowUIPanel
function ShowUIPanel(frame, force)
    if frame and frame == GameMenuFrame then
        Open()
        return
    end
    return StockShowUIPanel(frame, force)
end

local handlers = {}

handlers["start"] = function(f)
    run.inRun = true
    run.difficulty = f[3] or ""
    run.stage = tonumber(f[5] or "") or 1
    run.floors = f[8] == "1"
    run.elapsed = 0
    run.level, run.kills, run.gold, run.valor, run.shards = nil, 0, 0, 0, 0
end

handlers["state"] = function(f)
    run.inRun = true
    run.elapsed = tonumber(f[2] or "") or run.elapsed
    run.kills = tonumber(f[4] or "") or 0
    run.gold = tonumber(f[5] or "") or 0
    run.level = tonumber(f[6] or "") or run.level
    run.valor = tonumber(f[8] or "") or 0
    run.stage = tonumber(f[10] or "") or run.stage
    run.shards = tonumber(f[12] or "") or 0
    if menu:IsShown() then
        Refresh()
    end
end

handlers["loadout"] = function(f)
    run.spells, run.passives = {}, {}
    for _, item in ipairs(UI.Split(f[2] or "", ",")) do
        if item ~= "" then
            local parts = UI.Split(item, ":")
            local entry = { icon = (parts[2] and parts[2] ~= "") and parts[2] or "INV_Misc_QuestionMark", rank = tonumber(parts[3] or "") or 1 }
            if parts[1] == "p" then
                tinsert(run.passives, entry)
            else
                tinsert(run.spells, entry)
            end
        end
    end
    if menu:IsShown() then
        Refresh()
    end
end

handlers["end"] = function()
    run.inRun = false
    run.spells, run.passives = {}, {}
    if menu:IsShown() then
        Refresh()
    end
end

handlers["portalhome"] = function(f)
    Open()
    local text = L["This ends your run. Gear in your Extraction Vault waits in your mailbox; everything else you found is sold for gold."]
    if f[2] == "1" then
        text = L["This ends your run. Your Extraction Vault is empty, so everything you found will be sold for gold."]
    end
    SetConfirm(L["Return to the Inn?"], text, "home")
    confirm:Show()
end

UI.Listen(handlers)
