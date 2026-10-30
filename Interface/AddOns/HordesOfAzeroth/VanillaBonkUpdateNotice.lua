local L = VanillaBonkL
local UI = VanillaBonkUI

local NOTICE_WIDTH = 440
local BODY_INSET = 52
local BUTTON_GAP = 4

local GEAR_TITLE = L["Gear has changed"]
local GEAR_BODY = L["Gear now climbs by quality. Normal drops white items, Heroic drops white and green, and Mythic drops blue."] .. "\n\n" ..
    L["Epic items drop from Mythic floor 10 and legendaries from floor 20."] .. "\n\n" ..
    L["Your gear has been updated to the new system:"]
local GEAR_CHANGES = L["Mythic tier pieces are now blue, with new looks and names."] .. "\n" ..
    L["Gear stats were rescaled so numbers stay sensible deep into the climb."] .. "\n" ..
    L["Pieces above Tier 20 are now Tier 20, and your best Mythic floor counts as floor 20 at most."] .. "\n" ..
    L["Gold and Darkmoon Tickets come in more slowly."]

local OTHER_DIALOGS = { "VanillaBonkControllerTip", "VanillaBonkCurrencyTip", "VanillaBonkPlateGuide", "StaticPopup1" }

local pendingLegendaries

local function Backdrop(frame)
    frame:SetBackdrop({
        bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
        edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
        tile = true, tileSize = 32, edgeSize = 32,
        insets = { left = 11, right = 12, top = 12, bottom = 11 },
    })
end

local function BuildBox(name)
    local box = CreateFrame("Frame", name, UIParent)
    box:SetFrameStrata("DIALOG")
    box:SetWidth(NOTICE_WIDTH)
    box:SetPoint("CENTER", UIParent, "CENTER", 0, 60)
    box:EnableMouse(true)
    Backdrop(box)
    box.title = UI.Text(box, 15)
    box.title:SetTextColor(1, 0.82, 0)
    box.title:SetPoint("TOP", box, "TOP", 0, -22)
    box.body = UI.Text(box, 12)
    box.body:SetWidth(NOTICE_WIDTH - BODY_INSET)
    box.body:SetJustifyH("LEFT")
    box.body:SetPoint("TOP", box.title, "BOTTOM", 0, -12)
    box:Hide()
    return box
end

local function FitBox(box, last)
    local height = 22 + box.title:GetHeight() + 12 + box.body:GetHeight() + 64
    if last then
        height = height + 8 + last:GetHeight()
    end
    box:SetHeight(height)
end

local legendaryBox = BuildBox("VanillaBonkOldLegendaries")
legendaryBox.title:SetText(L["Your legendaries"])

local function ShowLegendaryPrompt()
    if not pendingLegendaries then
        return
    end
    local count, scrap = pendingLegendaries.count, pendingLegendaries.scrap
    local owned = count == 1 and L["You own 1 legendary item from before the gear update."]
        or L("You own {1} legendary items from before the gear update.", count)
    legendaryBox.body:SetText(owned .. " " .. L["Legendaries are now the rarest drop in the game."] .. "\n\n" ..
        L("Delete them to chase legendaries fresh and receive {1} Scrap, or keep them as they are. You will only be asked once.", scrap))
    legendaryBox.delete:SetText(L("Delete for {1} Scrap", scrap))
    FitBox(legendaryBox)
    legendaryBox:Show()
end

local function Answer(choice)
    pendingLegendaries = nil
    legendaryBox:Hide()
    SendChatMessage(".bonk oldlegendaries " .. choice, "SAY")
end

StaticPopupDialogs["HOA_DELETE_OLD_LEGENDARIES"] = {
    text = L["Delete all your old legendaries? This can't be undone."],
    button1 = YES,
    button2 = NO,
    OnAccept = function()
        Answer("delete")
    end,
    OnCancel = function()
        ShowLegendaryPrompt()
    end,
    timeout = 0,
    whileDead = 1,
}

legendaryBox.delete = UI.Button(legendaryBox, 170, L["Delete"], function()
    legendaryBox:Hide()
    StaticPopup_Show("HOA_DELETE_OLD_LEGENDARIES")
end)
legendaryBox.delete:SetPoint("BOTTOMRIGHT", legendaryBox, "BOTTOM", -BUTTON_GAP, 18)
legendaryBox.keep = UI.Button(legendaryBox, 130, L["Keep them"], function() Answer("keep") end)
legendaryBox.keep:SetPoint("BOTTOMLEFT", legendaryBox, "BOTTOM", BUTTON_GAP, 18)
UI.NavPrompt(legendaryBox, legendaryBox.keep, legendaryBox.delete)

local gearBox = BuildBox("VanillaBonkGearNotice")
gearBox.title:SetText(GEAR_TITLE)
gearBox.body:SetText(GEAR_BODY)
gearBox.changes = UI.Text(gearBox, 12)
gearBox.changes:SetWidth(NOTICE_WIDTH - BODY_INSET - 16)
gearBox.changes:SetJustifyH("LEFT")
gearBox.changes:SetTextColor(1, 0.82, 0)
gearBox.changes:SetPoint("TOP", gearBox.body, "BOTTOM", 8, -8)
gearBox.changes:SetText(GEAR_CHANGES)
gearBox.okay = UI.Button(gearBox, 96, L["Okay"], function() gearBox:Hide() end)
gearBox.okay:SetPoint("BOTTOM", gearBox, "BOTTOM", 0, 18)
UI.NavPrompt(gearBox, gearBox.okay)
gearBox:SetScript("OnHide", function()
    if gearBox.seen then
        return
    end
    gearBox.seen = true
    SendChatMessage(".bonk notice gear", "SAY")
    ShowLegendaryPrompt()
end)
tinsert(UISpecialFrames, "VanillaBonkGearNotice")

local function OtherDialogOpen()
    for _, name in ipairs(OTHER_DIALOGS) do
        local frame = getglobal(name)
        if frame and frame:IsShown() then
            return true
        end
    end
    return false
end

local waiter = CreateFrame("Frame")
waiter:Hide()
waiter:SetScript("OnUpdate", function()
    if OtherDialogOpen() then
        return
    end
    this:Hide()
    if gearBox.wanted and not gearBox.seen then
        FitBox(gearBox, gearBox.changes)
        gearBox:Show()
    else
        ShowLegendaryPrompt()
    end
end)

local handlers = {}

handlers["notice"] = function(f)
    if f[2] ~= "gear" or gearBox.seen then
        return
    end
    gearBox.wanted = true
    waiter:Show()
end

handlers["oldlegendaries"] = function(f)
    pendingLegendaries = { count = tonumber(f[2]) or 0, scrap = tonumber(f[3]) or 0 }
    if pendingLegendaries.count == 0 then
        pendingLegendaries = nil
        return
    end
    if not gearBox.wanted or gearBox.seen then
        waiter:Show()
    end
end

UI.Listen(handlers)
