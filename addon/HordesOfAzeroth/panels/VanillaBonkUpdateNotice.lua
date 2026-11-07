local L = VanillaBonkL
local UI = VanillaBonkUI

local NOTICE_WIDTH = 440
local BODY_INSET = 52

local GEAR_TITLE = L["hoa.addon.gear_has_changed"]
local GEAR_BODY = L["hoa.addon.all_gear_now_has_a_tier_and_a_quality_from_common_to_legenda"] .. " " ..
    L["hoa.addon.higher_levels_drop_higher_tier_gear_and_each_piece_s_quality"] .. "\n\n" ..
    L["hoa.addon.your_gear_has_been_updated_to_the_new_system"]
local GEAR_CHANGES = L["hoa.addon.all_your_old_gear_has_been_converted"] .. "\n" ..
    L["hoa.addon.item_sets_and_their_bonuses_are_gone"] .. "\n" ..
    L["hoa.addon.durgan_now_sells_all_shop_gear_and_upgrades_your_found_gear_"]

local OTHER_DIALOGS = { "VanillaBonkControllerTip", "VanillaBonkCurrencyTip", "VanillaBonkPlateGuide", "StaticPopup1" }

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

local gearBox = BuildBox("VanillaBonkGearNotice")
gearBox.title:SetText(GEAR_TITLE)
gearBox.body:SetText(GEAR_BODY)
gearBox.changes = UI.Text(gearBox, 12)
gearBox.changes:SetWidth(NOTICE_WIDTH - BODY_INSET - 16)
gearBox.changes:SetJustifyH("LEFT")
gearBox.changes:SetTextColor(1, 0.82, 0)
gearBox.changes:SetPoint("TOP", gearBox.body, "BOTTOM", 8, -8)
gearBox.changes:SetText(GEAR_CHANGES)
gearBox.okay = UI.Button(gearBox, 96, L["hoa.addon.okay"], function() gearBox:Hide() end)
gearBox.okay:SetPoint("BOTTOM", gearBox, "BOTTOM", 0, 18)
UI.NavPrompt(gearBox, gearBox.okay)
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
    end
end)
gearBox:SetScript("OnHide", function()
    if not gearBox.seen then
        gearBox.seen = true
        SendChatMessage(".bonk notice gear", "SAY")
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

UI.ListenHoa({
    HOA_NOTICE = function(notice)
        handlers["notice"]({ false, notice.kind })
    end,
})

