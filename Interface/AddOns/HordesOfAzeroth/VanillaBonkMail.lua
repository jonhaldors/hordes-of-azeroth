local L = VanillaBonkL

local OPEN_STEP = 0.3
local STUCK_STEPS = 12

local openAll = CreateFrame("Button", "VanillaBonkOpenAll", InboxFrame, "UIPanelButtonTemplate")
openAll:SetWidth(90)
openAll:SetHeight(22)
openAll:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 167, 100)
openAll:SetText(L["Open All"])

local function NextMailAction()
    for index = 1, GetInboxNumItems() do
        local _, _, _, _, money, cod, _, hasItem = GetInboxHeaderInfo(index)
        if (cod or 0) == 0 then
            if (money or 0) > 0 then
                return TakeInboxMoney, index
            end
            if hasItem then
                return TakeInboxItem, index
            end
            return DeleteInboxItem, index
        end
    end
end

local function RefreshButton()
    if GetInboxNumItems() > 0 and NextMailAction() then
        openAll:Enable()
    else
        openAll:Disable()
    end
end

local runner = CreateFrame("Frame")
runner:Hide()
runner:RegisterEvent("UI_ERROR_MESSAGE")
runner:RegisterEvent("MAIL_INBOX_UPDATE")
runner:RegisterEvent("MAIL_SHOW")

runner:SetScript("OnEvent", function()
    if event == "UI_ERROR_MESSAGE" then
        if this:IsShown() and arg1 == ERR_INV_FULL then
            this:Hide()
        end
        return
    end
    if not this:IsShown() then
        RefreshButton()
    end
end)

runner:SetScript("OnUpdate", function()
    this.wait = this.wait - arg1
    if this.wait > 0 then
        return
    end
    this.wait = OPEN_STEP
    if not MailFrame:IsVisible() then
        this:Hide()
        return
    end
    local action, index = NextMailAction()
    if not action then
        this:Hide()
        return
    end
    local step = tostring(action) .. ":" .. index .. ":" .. GetInboxNumItems()
    if step == this.lastStep then
        this.repeats = this.repeats + 1
        if this.repeats > STUCK_STEPS then
            this:Hide()
            return
        end
    else
        this.lastStep = step
        this.repeats = 0
    end
    action(index)
end)

runner:SetScript("OnHide", RefreshButton)

openAll:SetScript("OnClick", function()
    PlaySound("igMainMenuOptionCheckBoxOn")
    this:Disable()
    runner.wait = 0
    runner.repeats = 0
    runner.lastStep = nil
    runner:Show()
end)
