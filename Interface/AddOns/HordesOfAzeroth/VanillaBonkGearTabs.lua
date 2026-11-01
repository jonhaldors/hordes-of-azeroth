local MERCHANT_SLOTS = 10
local SLOT_SIZE = 37

local function QualityColor(link)
    if not link then
        return nil
    end
    local _, _, hex = strfind(link, "|c%x%x(%x%x%x%x%x%x)")
    if not hex or hex == "ffffff" or hex == "9d9d9d" then
        return nil
    end
    return tonumber(strsub(hex, 1, 2), 16) / 255, tonumber(strsub(hex, 3, 4), 16) / 255, tonumber(strsub(hex, 5, 6), 16) / 255
end

local function QualityBorder(button)
    if not button.quality then
        button.quality = button:CreateTexture(nil, "OVERLAY")
        button.quality:SetTexture("Interface\\Buttons\\UI-ActionButton-Border")
        button.quality:SetBlendMode("ADD")
        button.quality:SetWidth(SLOT_SIZE * 64 / 37)
        button.quality:SetHeight(SLOT_SIZE * 64 / 37)
        button.quality:SetPoint("CENTER", button, "CENTER", 0, 0)
    end
    return button.quality
end

local function RefreshQualities()
    for index = 1, MERCHANT_SLOTS do
        local button = getglobal("MerchantItem" .. index .. "ItemButton")
        local name = getglobal("MerchantItem" .. index .. "Name")
        if button then
            local link
            if button:IsShown() then
                if MerchantFrame.selectedTab == 1 then
                    link = GetMerchantItemLink(button:GetID())
                elseif GetBuybackItemLink then
                    link = GetBuybackItemLink(button:GetID())
                end
            end
            local r, g, b = QualityColor(link)
            local border = QualityBorder(button)
            if r then
                border:SetVertexColor(r, g, b)
                border:Show()
                if name then
                    name:SetTextColor(r, g, b)
                end
            else
                border:Hide()
                if name then
                    name:SetTextColor(1, 1, 1)
                end
            end
        end
    end
end

local BaseMerchantUpdate = MerchantFrame_Update
function MerchantFrame_Update()
    BaseMerchantUpdate()
    RefreshQualities()
end

local events = CreateFrame("Frame")
events:RegisterEvent("MERCHANT_SHOW")
events:RegisterEvent("PLAYER_MONEY")
local lastMoney = GetMoney()
events:SetScript("OnEvent", function()
    local money = GetMoney()
    if event == "PLAYER_MONEY" and money > lastMoney and (MerchantFrame:IsShown() or (VanillaBonkQuartermasterFrame and VanillaBonkQuartermasterFrame:IsShown())) then
        PlaySound("LOOTWINDOWCOINSOUND")
    end
    lastMoney = money
end)
