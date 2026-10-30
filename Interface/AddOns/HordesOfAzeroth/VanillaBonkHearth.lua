local UI = VanillaBonkUI

local HEARTH = "VANILLABONK_HEARTH"
local HEARTHSTONE_ITEM = "item:900230:"
local SIZE = 32
local EMPTY_ICON = UI.ICON_PATH .. "INV_Misc_Rune_01"
local PULSE_SPEED = 3
local ARROW = "Interface\\AddOns\\HordesOfAzeroth\\Textures\\TutorialArrow"
local ARROW_SIZE = 40
local BOB_SPEED = 6
local BOB_HEIGHT = 7
local TIP_WIDTH = 340
BINDING_NAME_VANILLABONK_HEARTH = "Use Hearthstone"

local function FindHearthstone()
    for bag = 0, 4 do
        for slot = 1, GetContainerNumSlots(bag) do
            local link = GetContainerItemLink(bag, slot)
            if link and string.find(link, HEARTHSTONE_ITEM, 1, true) then
                return bag, slot
            end
        end
    end
end

function VanillaBonk_UseHearthstone()
    local bag, slot = FindHearthstone()
    if bag then
        UseContainerItem(bag, slot)
    end
end

local button = UI.Slot(UI.HearthDock, SIZE)
button:SetPoint("CENTER", UI.HearthDock, "CENTER", 0, 0)
button:SetFrameLevel(UI.HearthDock:GetFrameLevel() + 2)
button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
button.glow = button:CreateTexture(nil, "OVERLAY")
button.glow:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
button.glow:SetBlendMode("ADD")
button.glow:SetVertexColor(1, 0.82, 0.3)
button.glow:SetWidth(SIZE * 82 / 44)
button.glow:SetHeight(SIZE * 82 / 44)
button.glow:SetPoint("CENTER", button, "CENTER", 0, 0)
button.key = UI.Text(button, 11, UI.NUMBER_FONT, "OUTLINE")
button.key:SetPoint("TOPRIGHT", button, "TOPRIGHT", -2, -3)
button.key:SetTextColor(0.75, 0.75, 0.75)
button.keyGlyph = button:CreateTexture(nil, "OVERLAY")
button.keyGlyph:SetWidth(16)
button.keyGlyph:SetHeight(16)
button.keyGlyph:SetPoint("TOPRIGHT", button, "TOPRIGHT", -1, -1)
button.keyGlyph:Hide()

button:SetScript("OnClick", VanillaBonk_UseHearthstone)
button:SetScript("OnEnter", function()
    local bag, slot = FindHearthstone()
    GameTooltip:SetOwner(this, "ANCHOR_TOPLEFT")
    if not bag then
        GameTooltip:AddDoubleLine("Hearthstone", "Not found yet", 1, 1, 1, 0.5, 0.5, 0.5)
        GameTooltip:AddLine("Elites and mini-bosses sometimes drop one. It lets you escape the run early and takes you back to the Inn with 1 item from your Extraction Vault.", 1, 0.82, 0, 1)
        GameTooltip:Show()
        return
    end
    GameTooltip:SetBagItem(bag, slot)
    local key = UI.BindingText(HEARTH)
    if key ~= "" then
        GameTooltip:AddLine("Hit " .. key .. " to use it.", 0.6, 0.6, 0.6)
    end
    GameTooltip:Show()
end)
button:SetScript("OnLeave", function() GameTooltip:Hide() end)
button:SetScript("OnUpdate", function()
    this.glow:SetAlpha(0.55 + 0.45 * math.sin(GetTime() * PULSE_SPEED))
end)

local tip = CreateFrame("Frame", "VanillaBonkHearthTip", UIParent)
tip:SetFrameStrata("FULLSCREEN_DIALOG")
tip:SetWidth(TIP_WIDTH)
tip:EnableMouse(true)
tip:SetBackdrop({
    bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background",
    edgeFile = "Interface\\DialogFrame\\UI-DialogBox-Border",
    tile = true, tileSize = 32, edgeSize = 32,
    insets = { left = 11, right = 12, top = 12, bottom = 11 },
})
tip.title = UI.Text(tip, 15)
tip.title:SetTextColor(1, 0.82, 0)
tip.title:SetPoint("TOP", tip, "TOP", 0, -22)
tip.title:SetText("You found a Hearthstone!")
tip.body = UI.Text(tip, 12)
tip.body:SetWidth(TIP_WIDTH - 52)
tip.body:SetJustifyH("CENTER")
tip.body:SetPoint("TOP", tip.title, "BOTTOM", 0, -10)
tip.key = UI.Text(tip, 12)
tip.key:SetWidth(TIP_WIDTH - 52)
tip.key:SetTextColor(1, 0.82, 0)
tip.key:SetPoint("TOP", tip.body, "BOTTOM", 0, -10)
tip.close = CreateFrame("Button", nil, tip, "UIPanelCloseButton")
tip.close:SetPoint("TOPRIGHT", tip, "TOPRIGHT", -6, -6)
tip.close:SetScript("OnClick", function() tip:Hide() end)
tip.done = UI.Button(tip, 96, "Got it", function() tip:Hide() end)
tip.done:SetPoint("BOTTOM", tip, "BOTTOM", 0, 18)
UI.NavPrompt(tip, tip.done)
tip:SetPoint("BOTTOMRIGHT", button, "TOPRIGHT", 12, ARROW_SIZE + BOB_HEIGHT + 6)
tip:Hide()
tinsert(UISpecialFrames, "VanillaBonkHearthTip")

tip.arrow = CreateFrame("Frame", nil, tip)
tip.arrow:SetWidth(ARROW_SIZE)
tip.arrow:SetHeight(ARROW_SIZE)
tip.arrow.texture = tip.arrow:CreateTexture(nil, "ARTWORK")
tip.arrow.texture:SetTexture(ARROW)
tip.arrow.texture:SetAllPoints(tip.arrow)
tip.arrow.texture:SetTexCoord(1, 1, 1, 0, 0, 1, 0, 0)

local function KeyLine()
    local key = UI.BindingText(HEARTH)
    if key == "" then
        return "Pick a key for it under Key Bindings, Hordes of Azeroth, Use Hearthstone."
    end
    return "Hit " .. key .. " or click the stone to use it. You can change the key under Key Bindings."
end

tip:SetScript("OnShow", function()
    this.body:SetText("You don't need it to finish a run. It's an emergency exit for when a run turns bad. " ..
        "It opens a ring with an Extraction Vault beside it that holds 1 item. " ..
        "Put your best find in the vault, then be inside the ring when it fills to escape to the Inn. If you're outside, it leaves without you.")
    this.key:SetText(KeyLine())
    this:SetHeight(22 + this.title:GetHeight() + 10 + this.body:GetHeight() + 10 + this.key:GetHeight() + 22 + 30)
    SendChatMessage(".bonk menu 1", "SAY")
end)
tip:SetScript("OnHide", function()
    VanillaBonkHearthTipDone = true
    if not (VanillaBonkMenu and VanillaBonkMenu:IsShown()) then
        SendChatMessage(".bonk menu 0", "SAY")
    end
end)
tip:SetScript("OnUpdate", function()
    local bob = BOB_HEIGHT * (1 + math.sin(GetTime() * BOB_SPEED)) / 2
    this.arrow:ClearAllPoints()
    this.arrow:SetPoint("BOTTOM", button, "TOP", 0, 4 + bob)
end)

local function Refresh()
    local found = FindHearthstone() ~= nil
    if found then
        button.icon:SetTexture(GetContainerItemInfo(FindHearthstone()))
        UI.CropIcon(button.icon)
        button.icon:SetVertexColor(1, 1, 1)
        VanillaBonkController.ShowKey(button.key, button.keyGlyph, VanillaBonkController.ButtonFor("hearth"), UI.BindingText(HEARTH))
        button.glow:Show()
        if not button.found and not VanillaBonkHearthTipDone then
            tip:Show()
        end
    else
        button.icon:SetTexture(EMPTY_ICON)
        UI.CropIcon(button.icon)
        button.icon:SetVertexColor(0.3, 0.3, 0.3)
        button.key:SetText("")
        button.keyGlyph:Hide()
        button.glow:Hide()
        tip:Hide()
    end
    button.found = found
end

UI.RefreshHearthKey = Refresh

local events = CreateFrame("Frame")
events:RegisterEvent("PLAYER_ENTERING_WORLD")
events:RegisterEvent("BAG_UPDATE")
events:RegisterEvent("UPDATE_BINDINGS")
events:SetScript("OnEvent", Refresh)
