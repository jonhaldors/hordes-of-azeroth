local UI = VanillaBonkUI

local RUN_MASTER = 900001
local RUN_MASTER_NAME = "Gizzik Bonkwhistle"
local RUN_MASTER_TARGETS = { { entry = RUN_MASTER, name = RUN_MASTER_NAME } }
local INNKEEPER_TARGETS = { { entry = UI.INNKEEPER_ENTRY, name = UI.INNKEEPER_NAME } }
local UPSTAIRS_TARGETS = {
    { entry = 900002, name = "Nix Sparkwrench" },
    { entry = 900008, name = "Theron Ashveil" },
}
local STAIRS_FOOT = { x = 16248.695, y = 16313.784, z = 20.844 }
local DECK_SPOT = { x = 16256.1, y = 16312.2, z = 20.865 }
local QUARTERMASTER = 900150
local QUARTERMASTER_NAME = "Varrok Steelbrand"
local QUARTERMASTER_TARGETS = { { entry = QUARTERMASTER, name = QUARTERMASTER_NAME } }
local QUARTERMASTER_CHECK = 1
local WAYPOINT_REACH = 3
local UPSTAIRS_RISE = 3
local ARROW = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\TutorialArrow"
local START_DELAY = 2
local DASHED_DELAY = 1
local TALK_RANGE = 6
local BOB_SPEED = 6
local BOB_HEIGHT = 7
local DASH_ARROW_SIZE = 40
local GUIDE_ARROW_SIZE = 56
local CALLOUT_WIDTH = 320
local CONTROLLER_TIP_WIDTH = 380
local CONTROLLER_ART_WIDTH = 220
local GUIDE_WIDTH = 430
local GUIDE_PLATE_COLUMN = 150
local GUIDE_ROW_GAP = 14
local PAD_BUTTON_NAMES = {
    xbox = { dash = "RT", interact = "X", menu = "Menu" },
    ps = { dash = "R2", interact = "Square", menu = "Options" },
    deck = { dash = "R2", interact = "X", menu = "Menu" },
}
local PLATE_KINDS = {
    { kind = 0, name = "Normal", text = "Regular enemies." },
    { kind = 5, name = "Bruiser", text = "A big enemy with four times the health that hits twice as hard." },
    { kind = 6, name = "Veteran", text = "A stronger version of a regular enemy, with more health and harder hits.",
        note = "Only appears on Heroic and Mythic." },
    { kind = 1, name = "Elite", text = "Named, with special powers called affixes. The Spellbook Keeper in town lists what each one does.",
        sample = "Kolkar Pack Runner" },
    { kind = 0, name = "Your debuffs", text = "Shown under an enemy's bar with their stacks. On a boss's bar, each icon wipes away as its time runs out unless you hit the boss again.",
        debuffs = { { 3, 12 }, { 4, 5 } } },
    { kind = 0, name = "You", text = "Your own health, shown over your character. A bright cyan glow on it is your Shield.", own = true },
}
local OWN_BAR_COLOR = { 0.24, 0.70, 0.28 }
local CURRENCY_WIDTH = 400
local CURRENCY_ICON_SIZE = 32
local CURRENCIES = {
    { icon = "INV_Misc_Coin_02", name = "Gold", color = { 1, 0.82, 0 },
        text = "Buys gear and upgrades at the Inn. You keep it between runs." },
    { icon = "INV_Misc_Ticket_Darkmoon_01", name = "Darkmoon Tickets", color = { 0.75, 0.5, 1 },
        text = "Spent at the Darkmoon vendors. You keep them between runs." },
    { icon = "INV_Misc_Coin_04", name = "Valor", color = { 1, 0.91, 0.45 },
        text = "Spent during a run to open chests and buy from shops. Resets every run, it's not kept." },
}

local tutorial = CreateFrame("Frame")
local step
local inRun = false
local inWorld = false
local waited = 0
local dashedAt
local lastCharges
local waypointReached

local function DialogBackdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

local function RotateTexture(texture, angle)
    local c, s = math.cos(angle), math.sin(angle)
    local function Corner(x, y)
        return 0.5 + x * c + y * s, 0.5 + x * s - y * c
    end
    local ulx, uly = Corner(-0.5, 0.5)
    local llx, lly = Corner(-0.5, -0.5)
    local urx, ury = Corner(0.5, 0.5)
    local lrx, lry = Corner(0.5, -0.5)
    texture:SetTexCoord(ulx, uly, llx, lly, urx, ury, lrx, lry)
end

local function Arrow(size)
    local arrow = CreateFrame("Frame", nil, UIParent)
    arrow:SetFrameStrata("DIALOG")
    arrow:SetWidth(size)
    arrow:SetHeight(size)
    arrow.texture = arrow:CreateTexture(nil, "ARTWORK")
    arrow.texture:SetTexture(ARROW)
    arrow.texture:SetAllPoints(arrow)
    arrow:Hide()
    return arrow
end

local function Bob()
    return BOB_HEIGHT * (1 + math.sin(GetTime() * BOB_SPEED)) / 2
end

local function PadStyle()
    local controller = VanillaBonkController
    if not controller or not controller.kind then
        return nil
    end
    return controller.Style()
end

local function PadButton(action, style)
    local names = PAD_BUTTON_NAMES[style or PadStyle() or "xbox"] or PAD_BUTTON_NAMES.xbox
    return "|cffffffff" .. names[action] .. "|r"
end

local function HasControllerSupport()
    return HoAController_GetConnected ~= nil
end

local function Title(box, size)
    box.title = UI.Text(box, size or 15)
    box.title:SetTextColor(1, 0.82, 0)
    box.title:SetPoint("TOP", box, "TOP", 0, -22)
end

local function Callout()
    local box = CreateFrame("Frame", nil, UIParent)
    box:SetFrameStrata("DIALOG")
    box:SetWidth(CALLOUT_WIDTH)
    DialogBackdrop(box)
    Title(box)
    box.body = UI.Text(box, 12)
    box.body:SetWidth(CALLOUT_WIDTH - 52)
    box.body:SetJustifyH("CENTER")
    box.body:SetPoint("TOP", box.title, "BOTTOM", 0, -10)
    box.close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
    box.close:SetPoint("TOPRIGHT", box, "TOPRIGHT", -6, -6)
    box.close:SetScript("OnClick", function() tutorial:Close() end)
    box:Hide()
    return box
end

local function FitCallout(box, extra)
    box:SetHeight(22 + box.title:GetHeight() + 10 + box.body:GetHeight() + 22 + (extra or 0))
end

local function SetBody(box, text, extra)
    if box.body:GetText() ~= text then
        box.body:SetText(text)
        FitCallout(box, extra)
    end
end

local function BuildControllerTip()
    local box = CreateFrame("Frame", "VanillaBonkControllerTip", UIParent)
    box:SetFrameStrata("DIALOG")
    box:SetWidth(CONTROLLER_TIP_WIDTH)
    box:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    box:EnableMouse(true)
    DialogBackdrop(box)
    Title(box)
    box.title:SetText("Playing with a controller?")
    box.art = box:CreateTexture(nil, "ARTWORK")
    box.art:SetWidth(CONTROLLER_ART_WIDTH)
    box.art:SetPoint("TOP", box.title, "BOTTOM", 0, -10)
    box.body = UI.Text(box, 12)
    box.body:SetWidth(CONTROLLER_TIP_WIDTH - 52)
    box.body:SetJustifyH("CENTER")
    box.body:SetPoint("TOP", box.art, "BOTTOM", 0, -10)
    box.hint = UI.Text(box, 12)
    box.hint:SetWidth(CONTROLLER_TIP_WIDTH - 52)
    box.hint:SetTextColor(1, 0.82, 0)
    box.hint:SetPoint("TOP", box.body, "BOTTOM", 0, -8)
    box.settings = UI.Button(box, 150, "Controller settings", function() tutorial:OpenControllerSettings() end)
    box.settings:SetPoint("BOTTOMRIGHT", box, "BOTTOM", -4, 18)
    box.next = UI.Button(box, 96, "Next", function() box:Hide() end)
    box.next:SetPoint("BOTTOMLEFT", box, "BOTTOM", 4, 18)
    UI.NavPrompt(box, box.next, box.settings)
    box:SetScript("OnHide", function()
        if this:IsShown() then
            return
        end
        if step == "controller" then
            tutorial:ControllerTipSeen()
        end
    end)
    box:Hide()
    tinsert(UISpecialFrames, "VanillaBonkControllerTip")
    return box
end

local controllerTip = BuildControllerTip()

local function CurrencyRow(box, currency, anchor)
    local icon = box:CreateTexture(nil, "ARTWORK")
    icon:SetWidth(CURRENCY_ICON_SIZE)
    icon:SetHeight(CURRENCY_ICON_SIZE)
    icon:SetTexture(UI.ICON_PATH .. currency.icon)
    icon:SetPoint("TOPLEFT", anchor, "BOTTOMLEFT", 0, -GUIDE_ROW_GAP)
    local name = UI.Text(box, 13)
    name:SetTextColor(currency.color[1], currency.color[2], currency.color[3])
    name:SetText(currency.name)
    name:SetPoint("TOPLEFT", icon, "TOPRIGHT", 10, 0)
    local text = UI.Text(box, 12)
    text:SetWidth(CURRENCY_WIDTH - 52 - CURRENCY_ICON_SIZE - 10)
    text:SetJustifyH("LEFT")
    text:SetText(currency.text)
    text:SetPoint("TOPLEFT", name, "BOTTOMLEFT", 0, -3)
    return icon, math.max(CURRENCY_ICON_SIZE, name:GetHeight() + 3 + text:GetHeight())
end

local function BuildCurrencyTip()
    local box = CreateFrame("Frame", "VanillaBonkCurrencyTip", UIParent)
    box:SetFrameStrata("DIALOG")
    box:SetWidth(CURRENCY_WIDTH)
    box:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    box:EnableMouse(true)
    DialogBackdrop(box)
    Title(box)
    box.title:SetText("Your currencies")
    local top = CreateFrame("Frame", nil, box)
    top:SetWidth(1)
    top:SetHeight(1)
    top:SetPoint("TOPLEFT", box, "TOPLEFT", 26, -22 - box.title:GetHeight())
    local height = 22 + box.title:GetHeight()
    local anchor = top
    for _, currency in ipairs(CURRENCIES) do
        local rowHeight
        anchor, rowHeight = CurrencyRow(box, currency, anchor)
        if rowHeight > CURRENCY_ICON_SIZE then
            local spacer = CreateFrame("Frame", nil, box)
            spacer:SetWidth(1)
            spacer:SetHeight(rowHeight)
            spacer:SetPoint("TOPLEFT", anchor, "TOPLEFT", 0, 0)
            anchor = spacer
        end
        height = height + GUIDE_ROW_GAP + rowHeight
    end
    box.next = UI.Button(box, 96, "Next", function() tutorial:ShowInnkeeper() end)
    box.next:SetPoint("BOTTOM", box, "BOTTOM", 0, 18)
    UI.NavPrompt(box, box.next)
    box:SetHeight(height + 16 + 22 + 18)
    box:Hide()
    return box
end

local currencyTip = BuildCurrencyTip()

local dashBox = Callout()
local dashArrow = Arrow(DASH_ARROW_SIZE)
RotateTexture(dashArrow.texture, math.pi)
dashBox.next = UI.Button(dashBox, 96, "Next", function() tutorial:ShowCurrencies() end)
dashBox.next:SetPoint("BOTTOM", dashBox, "BOTTOM", 0, 18)
UI.NavPrompt(dashBox, dashBox.next)

local guideBox = Callout()
guideBox:SetPoint("TOP", UIParent, "TOP", 0, -128)
guideBox.hint = UI.Text(guideBox, 12)
guideBox.hint:SetWidth(CALLOUT_WIDTH - 52)
guideBox.hint:SetTextColor(1, 0.82, 0)
guideBox.hint:SetPoint("TOP", guideBox.body, "BOTTOM", 0, -8)
local guideArrow = Arrow(GUIDE_ARROW_SIZE)
guideArrow.distance = UI.Text(guideArrow, 12, UI.NUMBER_FONT, "OUTLINE")
guideArrow.distance:SetPoint("TOP", guideArrow, "BOTTOM", 0, -2)

local function IsBlink()
    return UI.DashButton.icon == UI.DashButton.blinkIcon
end

local function DashText()
    local verb = IsBlink() and "teleport" or "dash"
    local safety = "You can't be hurt while you " .. verb .. ", so use it to get out of trouble."
    if PadStyle() then
        return "Pull " .. PadButton("dash") .. " to " .. verb .. " a short way in the direction you're moving. " .. safety .. "\n\nTry it now!"
    end
    local key = UI.DashKeyText and UI.DashKeyText() or ""
    if key == "" then
        return "Your hero can " .. verb .. " a short way in the direction you're moving. Give it a key under Key Bindings, at the top of the list."
    end
    return "Press |cffffffff" .. key .. "|r to " .. verb .. " a short way in the direction you're moving. " .. safety
        .. "\n\nTry it now! You can change the key under Key Bindings."
end

local function ControllerTipText()
    return "Hordes of Azeroth supports Xbox and PlayStation controllers. Plug one in and press any button to play with it. There is nothing to set up."
        .. "\n\nThe Controller page in the pause menu shows what every button does. You can also change the camera speed, the stick deadzone and the button prompts there."
end

local function ControllerTipHint()
    local style = PadStyle()
    if style then
        return "Press " .. PadButton("menu", style) .. " to open the pause menu."
    end
    return "Press |cffffffffEscape|r to open the pause menu."
end

local function FitControllerTip()
    local box = controllerTip
    box:SetHeight(22 + box.title:GetHeight() + 10 + box.art:GetHeight() + 10 + box.body:GetHeight()
        + 8 + box.hint:GetHeight() + 16 + 22 + 18)
end

local function RefreshControllerTip()
    local panel = VanillaBonkControllerPanel
    local style = VanillaBonkController and VanillaBonkController.Style() or "xbox"
    local art = panel and panel.ART and (panel.ART[style] or panel.ART.xbox)
    if art then
        controllerTip.art:SetTexture(art.file)
        controllerTip.art:SetTexCoord(0, 1, 0, art.height / 512)
        controllerTip.art:SetHeight(CONTROLLER_ART_WIDTH * art.height / 512)
        controllerTip.art:Show()
    else
        controllerTip.art:SetHeight(1)
        controllerTip.art:Hide()
    end
    controllerTip.style = style
    controllerTip.pad = PadStyle()
    controllerTip.hint:SetText(ControllerTipHint())
    FitControllerTip()
end

local function HideCallouts()
    controllerTip:Hide()
    currencyTip:Hide()
    dashBox:Hide()
    dashArrow:Hide()
    guideBox:Hide()
    guideArrow:Hide()
end

local function EndLesson()
    step = nil
    waited = 0
    HideCallouts()
end

local quartermasterSeenAt, quartermasterHere = 0, false

local function QuartermasterHere()
    if VanillaBonkQuartermasterTip or not ClosestUnitPosition then
        return false
    end
    if GetTime() - quartermasterSeenAt >= QUARTERMASTER_CHECK then
        quartermasterSeenAt = GetTime()
        quartermasterHere = ClosestUnitPosition(QUARTERMASTER) ~= nil
    end
    return quartermasterHere
end

local function CompleteIntro()
    if not VanillaBonkTutorialDone and not VanillaBonkVendorTip then
        VanillaBonkVendorTip = "waiting"
    end
    if not VanillaBonkTutorialDone and not VanillaBonkDeckTip then
        VanillaBonkDeckTip = "waiting"
    end
    VanillaBonkTutorialDone = true
    VanillaBonkControllerTipDone = true
    VanillaBonkInnkeeperTip = true
end

local function NextLesson()
    if not VanillaBonkControllerTipDone and HasControllerSupport() then
        return "controller"
    end
    if not VanillaBonkTutorialDone then
        return "dash"
    end
    if not VanillaBonkInnkeeperTip then
        return "innkeeper"
    end
    if VanillaBonkDeckTip == "ready" then
        return "deck"
    end
    if VanillaBonkVendorTip == "ready" then
        return "vendors"
    end
    if QuartermasterHere() then
        return "quartermaster"
    end
end

local function AllDone()
    return VanillaBonkControllerTipDone and VanillaBonkTutorialDone and VanillaBonkInnkeeperTip and VanillaBonkVendorTip ~= "waiting" and VanillaBonkVendorTip ~= "ready"
        and VanillaBonkDeckTip ~= "waiting" and VanillaBonkDeckTip ~= "ready" and VanillaBonkQuartermasterTip
end

function tutorial:ShowControllerTip()
    step = "controller"
    RefreshControllerTip()
    controllerTip:Show()
end

function tutorial:OpenControllerSettings()
    step = "controllerpanel"
    controllerTip:Hide()
    VanillaBonkControllerTipDone = true
    if VanillaBonkControllerPanel then
        VanillaBonkControllerPanel:Show()
    end
end

function tutorial:ControllerTipSeen()
    VanillaBonkControllerTipDone = true
    if VanillaBonkTutorialDone then
        EndLesson()
    else
        self:ShowDash()
    end
end

function tutorial:ShowDash()
    step = "dash"
    dashedAt = nil
    controllerTip:Hide()
    dashBox.title:SetText(IsBlink() and "Blink" or "Dash")
    dashBox.body:SetText("")
    SetBody(dashBox, DashText(), 30)
    dashArrow:ClearAllPoints()
    dashArrow:SetPoint("BOTTOM", UI.DashButton, "TOP", 0, 4)
    dashBox:ClearAllPoints()
    dashBox:SetPoint("BOTTOM", UI.DashButton, "TOP", 0, DASH_ARROW_SIZE + BOB_HEIGHT + 6)
    dashBox:Show()
    dashArrow:Show()
end

local function ShowGuide(title, body)
    guideBox.title:SetText(title)
    guideBox.body:SetText(body)
    guideBox.hint:SetText(" ")
    FitCallout(guideBox, guideBox.hint:GetHeight() + 8)
    guideBox:Show()
end

function tutorial:ShowCurrencies()
    step = "currencies"
    dashBox:Hide()
    dashArrow:Hide()
    currencyTip:Show()
end

function tutorial:ShowInnkeeper()
    step = "innkeeper"
    dashBox:Hide()
    dashArrow:Hide()
    currencyTip:Hide()
    ShowGuide("Make yourself at home", "Talk to " .. UI.INNKEEPER_NAME .. ", the Innkeeper. He keeps your settings: "
        .. "the interact key and what it works on, chests that open by themselves, where your health bar sits and more.")
end

function tutorial:InnkeeperSeen()
    VanillaBonkInnkeeperTip = true
    if VanillaBonkTutorialDone then
        EndLesson()
    else
        self:ShowRunMaster()
    end
end

function tutorial:ShowRunMaster()
    step = "runmaster"
    dashBox:Hide()
    dashArrow:Hide()
    currencyTip:Hide()
    ShowGuide("Start a run", "Talk to " .. RUN_MASTER_NAME .. ", the Run Master. He lets you pick a map and starts your first run.")
end

function tutorial:ShowVendors()
    step = "vendors"
    waypointReached = false
    ShowGuide("Spend your gold", "The gold you bring back is yours to keep. Upstairs, Nix Sparkwrench sells upgrades that last through every run, "
        .. "and Theron Ashveil, the Talent Trainer, is where you spend your talent points.")
end

function tutorial:ShowDeck()
    step = "deck"
    waypointReached = false
    ShowGuide("The Darkmoon Deck", "The Darkmoon Deck table at the foot of the stairs shows every Darkmoon Card and Glyph you own. "
        .. "Ban the ones you don't want to see in your runs.")
end

function tutorial:ShowQuartermaster()
    step = "quartermaster"
    waypointReached = false
    ShowGuide("The Mythic Quartermaster", QUARTERMASTER_NAME .. " has arrived at the Inn. He sells Mythic tier gear for your class, "
        .. "two tiers below your best Mythic floor cleared, and never below Tier 1.")
end

local function MarkStepSeen()
    if step == "vendors" then
        VanillaBonkVendorTip = true
    elseif step == "deck" then
        VanillaBonkDeckTip = true
    elseif step == "quartermaster" then
        VanillaBonkQuartermasterTip = true
    else
        return false
    end
    return true
end

function tutorial:Close()
    if not MarkStepSeen() then
        VanillaBonkTutorialDone = true
        VanillaBonkControllerTipDone = true
        VanillaBonkInnkeeperTip = true
        VanillaBonkVendorTip = true
    end
    EndLesson()
end

local function PlayerPlace()
    if not UnitPosition or not GetPlayerFacing then
        return
    end
    local playerY, playerX, playerZ = UnitPosition("player")
    local facing = GetCameraFacing and GetCameraFacing() or GetPlayerFacing()
    if not playerX or not facing then
        return
    end
    return playerX, playerY, playerZ, facing
end

local function IsPastWaypoint(point)
    local playerX, playerY, playerZ = PlayerPlace()
    if not playerX then
        return true
    end
    if playerZ and playerZ > point.z + UPSTAIRS_RISE then
        return true
    end
    local dx, dy = point.x - playerX, point.y - playerY
    return dx * dx + dy * dy <= WAYPOINT_REACH * WAYPOINT_REACH
end

local function WaypointBearing(point)
    local playerX, playerY, _, facing = PlayerPlace()
    if not playerX then
        return
    end
    local dx, dy = point.x - playerX, point.y - playerY
    return math.atan2(dy, dx) - facing, math.sqrt(dx * dx + dy * dy)
end

local function Bearing(targets)
    if not ClosestUnitPosition then
        return
    end
    local playerX, playerY, _, facing = PlayerPlace()
    if not playerX then
        return
    end
    local bestX, bestY, bestDistance, bestTarget
    for _, target in ipairs(targets) do
        local x, y, distance = ClosestUnitPosition(target.entry)
        if x and (not bestDistance or distance < bestDistance) then
            bestX, bestY, bestDistance, bestTarget = x, y, distance, target
        end
    end
    if not bestX then
        return
    end
    return math.atan2(bestY - playerY, bestX - playerX) - facing, bestDistance, bestTarget
end

local function IsAtCamp()
    if not ClosestUnitPosition then
        return true
    end
    return ClosestUnitPosition(RUN_MASTER) ~= nil
end

local function SetHint(text)
    if guideBox.hint:GetText() ~= text then
        guideBox.hint:SetText(text)
    end
end

local function TalkHint(name)
    if PadStyle() then
        return "Press " .. PadButton("interact") .. " to talk to " .. name .. "."
    end
    return "Right-click " .. name .. " to talk."
end

local GUIDES = {
    innkeeper = {
        targets = INNKEEPER_TARGETS,
        far = "Follow the arrow to find him.",
        lost = "Look for " .. UI.INNKEEPER_NAME .. " <Innkeeper> at the Inn.",
    },
    runmaster = {
        targets = RUN_MASTER_TARGETS,
        far = "Follow the arrow to find him.",
        lost = "Look for " .. RUN_MASTER_NAME .. " <Run Master> at the Inn.",
    },
    deck = {
        spot = DECK_SPOT,
        spotName = "the Darkmoon Deck table",
        far = "Follow the arrow to the Darkmoon Deck.",
    },
    quartermaster = {
        targets = QUARTERMASTER_TARGETS,
        far = "Follow the arrow to find him.",
        lost = "Look for " .. QUARTERMASTER_NAME .. " <Mythic Quartermaster> at the Inn.",
    },
    vendors = {
        targets = UPSTAIRS_TARGETS,
        waypoint = STAIRS_FOOT,
        toWaypoint = "Follow the arrow to the stairs.",
        far = "Follow the arrow up the stairs.",
        lost = "Look for them on the top floor of the Inn.",
    },
}

local function PointArrow(angle, distance)
    RotateTexture(guideArrow.texture, angle)
    local bob = Bob()
    guideArrow:ClearAllPoints()
    guideArrow:SetPoint("TOP", guideBox, "BOTTOM", -math.sin(angle) * bob, -8 + math.cos(angle) * bob - BOB_HEIGHT / 2)
    guideArrow.distance:SetText(floor(distance + 0.5) .. " yd")
    guideArrow:Show()
end

local function UpdateWaypoint(guide)
    if not guide.waypoint or waypointReached then
        return false
    end
    if IsPastWaypoint(guide.waypoint) then
        waypointReached = true
        return false
    end
    local angle, distance = WaypointBearing(guide.waypoint)
    if not angle then
        return false
    end
    SetHint(guide.toWaypoint)
    PointArrow(angle, distance)
    return true
end

local function OpenHint(name)
    if PadStyle() then
        return "Press " .. PadButton("interact") .. " to open " .. name .. "."
    end
    return "Right-click " .. name .. " to open it."
end

local function UpdateSpot(guide)
    local angle, distance = WaypointBearing(guide.spot)
    if not angle then
        guideArrow:Hide()
        SetHint(OpenHint(guide.spotName))
        return
    end
    if distance <= TALK_RANGE then
        SetHint(OpenHint(guide.spotName))
    else
        SetHint(guide.far)
    end
    PointArrow(angle, distance)
end

local function UpdateGuide(guide)
    if guide.spot then
        UpdateSpot(guide)
        return
    end
    if UpdateWaypoint(guide) then
        return
    end
    local angle, distance, target = Bearing(guide.targets)
    if not angle then
        guideArrow:Hide()
        SetHint(guide.lost)
        return
    end
    if distance <= TALK_RANGE then
        SetHint(TalkHint(target.name))
    else
        SetHint(guide.far)
    end
    PointArrow(angle, distance)
end

local function IsArenaOpen()
    local arena = getglobal("VanillaBonkArena")
    return arena and arena:IsVisible()
end

local function IsSummaryOpen()
    local summary = getglobal("VanillaBonkSummary")
    return summary and summary:IsVisible()
end

local function IsDeckOpen()
    local deck = getglobal("VanillaBonkDeckFrame")
    return deck and deck:IsVisible()
end

local function ReadyToStart()
    return inWorld and not inRun and UI.DashButton:IsVisible() and IsAtCamp() and not IsSummaryOpen() and not IsDeckOpen()
end

local LESSONS = {
    controller = function() tutorial:ShowControllerTip() end,
    dash = function() tutorial:ShowDash() end,
    innkeeper = function() tutorial:ShowInnkeeper() end,
    vendors = function() tutorial:ShowVendors() end,
    deck = function() tutorial:ShowDeck() end,
    quartermaster = function() tutorial:ShowQuartermaster() end,
}

local function WaitForLesson(elapsed)
    local lesson = NextLesson()
    if not lesson or not ReadyToStart() then
        waited = 0
        return
    end
    waited = waited + elapsed
    if waited >= START_DELAY then
        LESSONS[lesson]()
    end
end

local function UpdateControllerTip()
    local style = VanillaBonkController and VanillaBonkController.Style() or "xbox"
    if controllerTip.style ~= style or controllerTip.pad ~= PadStyle() then
        RefreshControllerTip()
    end
end

tutorial:SetScript("OnUpdate", function()
    if not step then
        if AllDone() then
            this:Hide()
            return
        end
        WaitForLesson(arg1)
        return
    end
    if inRun or IsArenaOpen() then
        if not MarkStepSeen() then
            CompleteIntro()
        end
        EndLesson()
        return
    end
    if step == "controller" then
        UpdateControllerTip()
    elseif step == "controllerpanel" then
        if not (VanillaBonkControllerPanel and VanillaBonkControllerPanel:IsVisible()) then
            this:ControllerTipSeen()
        end
    elseif step == "innkeeperopen" then
        if not (VanillaBonkInnkeeper and VanillaBonkInnkeeper:IsVisible()) then
            this:InnkeeperSeen()
        end
    elseif step == "dash" then
        SetBody(dashBox, DashText(), 30)
        dashArrow:SetPoint("BOTTOM", UI.DashButton, "TOP", 0, 4 + Bob())
        if dashedAt and GetTime() - dashedAt >= DASHED_DELAY then
            this:ShowCurrencies()
        end
    elseif GUIDES[step] then
        UpdateGuide(GUIDES[step])
    end
end)

local function IsUpstairsVendor(name)
    for _, target in ipairs(UPSTAIRS_TARGETS) do
        if target.name == name then
            return true
        end
    end
    return false
end

tutorial:RegisterEvent("PLAYER_ENTERING_WORLD")
tutorial:RegisterEvent("PLAYER_LEAVING_WORLD")
tutorial:RegisterEvent("GOSSIP_SHOW")
tutorial:RegisterEvent("MERCHANT_SHOW")
tutorial:SetScript("OnEvent", function()
    if event == "PLAYER_ENTERING_WORLD" then
        inWorld = true
    elseif event == "PLAYER_LEAVING_WORLD" then
        inWorld = false
    elseif event == "GOSSIP_SHOW" and UnitName("npc") == UI.INNKEEPER_NAME then
        if step == "innkeeper" then
            step = "innkeeperopen"
            HideCallouts()
        else
            VanillaBonkInnkeeperTip = true
        end
    elseif (event == "GOSSIP_SHOW" or event == "MERCHANT_SHOW") and UnitName("npc") == QUARTERMASTER_NAME then
        VanillaBonkQuartermasterTip = true
        if step == "quartermaster" then
            EndLesson()
        end
    elseif event == "GOSSIP_SHOW" and IsUpstairsVendor(UnitName("npc")) then
        if VanillaBonkVendorTip == "waiting" or VanillaBonkVendorTip == "ready" then
            VanillaBonkVendorTip = true
        end
        if step == "vendors" then
            EndLesson()
        end
    end
end)

local gearTip = {}
local GEAR_TIP_WIDTH = 270
local GEAR_TIPS = {
    Heroic = { title = "Heroic gear",
        body = "Durgan now sells Heroic gear as well. It is a lot stronger than Normal gear, so look here before you spend your gold." },
    Mythic = { title = "Mythic gear",
        body = "Durgan now sells Mythic gear, the strongest he has. Look here before you spend your gold." },
}

local function BuildGearTip()
    local box = CreateFrame("Frame", nil, UIParent)
    box:SetFrameStrata("FULLSCREEN_DIALOG")
    box:SetWidth(GEAR_TIP_WIDTH)
    DialogBackdrop(box)
    Title(box)
    box.body = UI.Text(box, 12)
    box.body:SetWidth(GEAR_TIP_WIDTH - 52)
    box.body:SetJustifyH("CENTER")
    box.body:SetPoint("TOP", box.title, "BOTTOM", 0, -10)
    box.hint = UI.Text(box, 12)
    box.hint:SetTextColor(1, 0.82, 0)
    box.hint:SetPoint("TOP", box.body, "BOTTOM", 0, -8)
    box.close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
    box.close:SetPoint("TOPRIGHT", box, "TOPRIGHT", -6, -6)
    box.close:SetScript("OnClick", function() gearTip.Seen() end)
    box.done = UI.Button(box, 96, "Got it", function() gearTip.Seen() end)
    box.done:SetPoint("BOTTOM", box, "BOTTOM", 0, 18)
    UI.NavPrompt(box, box.done)
    box.arrow = Arrow(DASH_ARROW_SIZE)
    box.arrow:SetFrameStrata("FULLSCREEN_DIALOG")
    box:Hide()
    return box
end

local function UnseenGearTab()
    for _, entry in ipairs(UI.vendorTierTabs or {}) do
        local name = entry.name
        if entry.tab:IsVisible() and not entry.tab.active and GEAR_TIPS[name] and not (VanillaBonkGearTabTips and VanillaBonkGearTabTips[name]) then
            return entry.tab, name
        end
    end
end

function gearTip.Seen()
    if gearTip.name then
        VanillaBonkGearTabTips = VanillaBonkGearTabTips or {}
        VanillaBonkGearTabTips[gearTip.name] = true
    end
    gearTip.Hide()
end

function gearTip.Hide()
    gearTip.tab, gearTip.name = nil, nil
    if gearTip.box then
        gearTip.box:Hide()
        gearTip.box.arrow:Hide()
    end
end

function gearTip.Show(tab, name)
    gearTip.box = gearTip.box or BuildGearTip()
    local box, tip = gearTip.box, GEAR_TIPS[name]
    gearTip.tab, gearTip.name = tab, name
    box.title:SetText(tip.title)
    box.body:SetText(tip.body)
    box.hint:SetText("Click the " .. name .. " tab.")
    box:SetHeight(22 + box.title:GetHeight() + 10 + box.body:GetHeight() + 8 + box.hint:GetHeight() + 16 + 22 + 18)
    box.arrow:ClearAllPoints()
    box.arrow:SetPoint("TOP", tab, "BOTTOM", 0, -2)
    box:ClearAllPoints()
    box:SetPoint("TOP", tab, "BOTTOM", 0, -(DASH_ARROW_SIZE + BOB_HEIGHT + 4))
    box:Show()
    box.arrow:Show()
end

function gearTip.Update()
    if gearTip.tab then
        if not gearTip.tab:IsVisible() then
            gearTip.Hide()
        elseif gearTip.tab.active then
            gearTip.Seen()
        else
            gearTip.box.arrow:SetPoint("TOP", gearTip.tab, "BOTTOM", 0, -2 - Bob())
        end
        return
    end
    local tab, name = UnseenGearTab()
    if tab then
        gearTip.Show(tab, name)
    end
end

gearTip.watcher = CreateFrame("Frame")
gearTip.watcher:Hide()
gearTip.watcher:SetScript("OnUpdate", function() gearTip.Update() end)
gearTip.watcher:RegisterEvent("MERCHANT_SHOW")
gearTip.watcher:RegisterEvent("MERCHANT_CLOSED")
gearTip.watcher:SetScript("OnEvent", function()
    if event == "MERCHANT_SHOW" then
        this:Show()
    elseif event == "MERCHANT_CLOSED" then
        this:Hide()
        gearTip.Hide()
    end
end)

local plateGuide

local function PlateKeyText()
    local key = GetBindingKey("NAMEPLATES")
    if not key or key == "" then
        return "Turn enemy health bars on and off under Key Bindings."
    end
    return "Hit |cffffd100" .. key .. "|r to toggle enemy health bars."
end

local function SampleDebuffs(entries)
    local list = {}
    for _, pair in ipairs(entries) do
        local keyword = UI.Keyword(pair[1])
        if keyword then
            tinsert(list, { keyword = keyword, stacks = pair[2] })
        end
    end
    return list
end

local function BuildPlateGuide()
    local box = CreateFrame("Frame", "VanillaBonkPlateGuide", UIParent)
    box:SetFrameStrata("FULLSCREEN_DIALOG")
    box:SetWidth(GUIDE_WIDTH)
    box:SetPoint("CENTER", UIParent, "CENTER", 0, 40)
    box:EnableMouse(true)
    DialogBackdrop(box)
    box.title = UI.Text(box, 15)
    box.title:SetTextColor(1, 0.82, 0)
    box.title:SetPoint("TOP", box, "TOP", 0, -22)
    box.title:SetText("Health bars")
    box.hint = UI.Text(box, 12)
    box.hint:SetPoint("TOP", box.title, "BOTTOM", 0, -10)
    box.close = CreateFrame("Button", nil, box, "UIPanelCloseButton")
    box.close:SetPoint("TOPRIGHT", box, "TOPRIGHT", -6, -6)
    box.close:SetScript("OnClick", function() plateGuide.Close() end)
    box.done = UI.Button(box, 96, "Got it", function() plateGuide.Close() end)
    box.done:SetPoint("BOTTOM", box, "BOTTOM", 0, 18)
    UI.NavPrompt(box, box.done)

    local textLeft = 22 + GUIDE_PLATE_COLUMN + 12
    local textWidth = GUIDE_WIDTH - textLeft - 26
    box.rows = {}
    local previous
    for _, entry in ipairs(PLATE_KINDS) do
        local row = CreateFrame("Frame", nil, box)
        row:SetWidth(GUIDE_WIDTH - 44)
        row.name = UI.Text(row, 13)
        row.name:SetPoint("TOPLEFT", row, "TOPLEFT", textLeft - 22, 0)
        row.name:SetText(entry.name)
        row.text = UI.Text(row, 12)
        row.text:SetTextColor(1, 0.82, 0)
        row.text:SetWidth(textWidth)
        row.text:SetJustifyH("LEFT")
        row.text:SetPoint("TOPLEFT", row.name, "BOTTOMLEFT", 0, -3)
        row.text:SetText(entry.text)
        local bottom = row.text
        if entry.note then
            row.note = UI.Text(row, 12)
            row.note:SetTextColor(1, 0.43, 0.39)
            row.note:SetWidth(textWidth)
            row.note:SetJustifyH("LEFT")
            row.note:SetPoint("TOPLEFT", row.text, "BOTTOMLEFT", 0, 0)
            row.note:SetText(entry.note)
            bottom = row.note
        end
        local textHeight = row.name:GetHeight() + 3 + row.text:GetHeight() + (row.note and row.note:GetHeight() or 0)
        row:SetHeight(max(textHeight, entry.icons and 52 or entry.sample and 34 or 22))
        local plate = UI.SamplePlate(row, entry.kind, entry.sample, entry.icons, nil, entry.debuffs and SampleDebuffs(entry.debuffs))
        if entry.own then
            plate:SetStatusBarColor(OWN_BAR_COLOR[1], OWN_BAR_COLOR[2], OWN_BAR_COLOR[3])
        end
        plate:SetPoint("CENTER", row, "LEFT", GUIDE_PLATE_COLUMN / 2, entry.icons and -16 or entry.sample and -8 or entry.debuffs and 6 or 0)
        if previous then
            row:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -GUIDE_ROW_GAP)
        else
            row:SetPoint("TOPLEFT", box.hint, "BOTTOM", -(GUIDE_WIDTH - 44) / 2, -22)
        end
        tinsert(box.rows, row)
        previous = row
    end
    box.selfBar = UI.Text(box, 12)
    box.selfBar:SetWidth(GUIDE_WIDTH - 44)
    box.selfBar:SetPoint("TOPLEFT", previous, "BOTTOMLEFT", 0, -GUIDE_ROW_GAP - 6)
    box.selfBar:SetText("Prefer the classic unit frame in the top left? Under Interface Options, Your Health Bar, you can show your health there instead, or in both places.")
    box:Hide()
    return box
end

plateGuide = {}

function plateGuide.Close()
    VanillaBonkPlateGuideDone = true
    if not plateGuide.box or not plateGuide.box:IsShown() then
        return
    end
    plateGuide.box:Hide()
    if not (VanillaBonkMenu and VanillaBonkMenu:IsShown()) then
        SendChatMessage(".bonk menu 0", "SAY")
    end
end

function plateGuide.Show()
    if VanillaBonkPlateGuideDone then
        return
    end
    plateGuide.box = plateGuide.box or BuildPlateGuide()
    local box = plateGuide.box
    box.hint:SetText(PlateKeyText())
    local height = 22 + box.title:GetHeight() + 10 + box.hint:GetHeight() + 22
    for _, row in ipairs(box.rows) do
        height = height + row:GetHeight() + GUIDE_ROW_GAP
    end
    height = height + 6 + box.selfBar:GetHeight() + GUIDE_ROW_GAP
    box:SetHeight(height + 22 + 18)
    box:Show()
    SendChatMessage(".bonk menu 1", "SAY")
end

function UI.ResetTutorial()
    VanillaBonkTutorialDone = nil
    VanillaBonkControllerTipDone = nil
    VanillaBonkVendorTip = nil
    VanillaBonkGearTabTips = nil
    VanillaBonkPlateGuideDone = nil
    VanillaBonkHearthTipDone = nil
    VanillaBonkInnkeeperTip = nil
    VanillaBonkDeckTip = nil
    VanillaBonkQuartermasterTip = nil
    EndLesson()
    if not inRun then
        tutorial:Show()
    end
end

local function EnterRun()
    if not inRun then
        plateGuide.Show()
    end
    inRun = true
end

UI.Listen({
    cdx = function(f)
        if f[4] ~= "1" then
            return
        end
        VanillaBonkDeckTip = true
        if step == "deck" then
            EndLesson()
        end
    end,
    start = EnterRun,
    state = EnterRun,
    ["end"] = function()
        if inRun and VanillaBonkVendorTip == "waiting" then
            VanillaBonkVendorTip = "ready"
        end
        if inRun and VanillaBonkDeckTip == "waiting" then
            VanillaBonkDeckTip = "ready"
        end
        inRun = false
        if not AllDone() then
            tutorial:Show()
        end
    end,
    dash = function(f)
        local charges = tonumber(f[2]) or 0
        if step == "dash" and lastCharges and charges < lastCharges and not dashedAt then
            dashedAt = GetTime()
        end
        lastCharges = charges
    end,
})
