local L = VanillaBonkL
local UI = VanillaBonkUI

local OPEN_STEP = 0.3
local STUCK_STEPS = 12

local openAll = CreateFrame("Button", "VanillaBonkOpenAll", InboxFrame, "UIPanelButtonTemplate")
openAll:SetWidth(90)
openAll:SetHeight(22)
openAll:SetPoint("CENTER", InboxFrame, "BOTTOMLEFT", 167, 100)
openAll:SetText(L["hoa.addon.open_all"])

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

UI.Module("mail"):Listen({
    UI_ERROR_MESSAGE = function(message)
        if runner:IsShown() and message == ERR_INV_FULL then
            runner:Hide()
        end
    end,
    MAIL_INBOX_UPDATE = function()
        if not runner:IsShown() then
            RefreshButton()
        end
    end,
    MAIL_SHOW = function()
        if not runner:IsShown() then
            RefreshButton()
        end
    end,
}, runner)

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
