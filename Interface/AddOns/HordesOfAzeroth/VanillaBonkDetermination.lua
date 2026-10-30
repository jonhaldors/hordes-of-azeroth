local L = VanillaBonkL
local UI = VanillaBonkUI

local ICON = "Interface\\Icons\\Spell_Holy_SealOfMight"
local SIZE = 30

local frame = CreateFrame("Button", "VanillaBonkDetermination", UIParent)
frame:SetWidth(SIZE)
frame:SetHeight(SIZE)
frame:SetPoint("TOPRIGHT", UIParent, "TOPRIGHT", -205, -110)
frame:Hide()

local icon = frame:CreateTexture(nil, "ARTWORK")
icon:SetAllPoints(frame)
icon:SetTexture(ICON)

local count = frame:CreateFontString(nil, "OVERLAY", "NumberFontNormal")
count:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)

local state = { stacks = 0, percent = "0" }

frame:SetScript("OnEnter", function()
    GameTooltip:SetOwner(this, "ANCHOR_BOTTOMLEFT")
    GameTooltip:SetText(L["Determination"], 1, 1, 1)
    GameTooltip:AddLine("+" .. state.percent .. L["% damage and "] .. state.percent .. L["% less damage taken."], 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["Grows each time you die. Ends when you clear Normal."], 0.6, 0.6, 0.6, 1)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local handlers = {}

handlers["determination"] = function(f)
    state.stacks = tonumber(f[2]) or 0
    state.percent = f[3] or "0"
    if state.stacks > 0 then
        count:SetText(state.stacks > 1 and tostring(state.stacks) or "")
        frame:Show()
    else
        frame:Hide()
    end
end

UI.Listen(handlers)
