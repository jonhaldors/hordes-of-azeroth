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
    GameTooltip:SetText(L["hoa.addon.determination"], 1, 1, 1)
    GameTooltip:AddLine(L("hoa.addon.1_damage_and_1_less_damage_taken", state.percent), 1, 0.82, 0, 1)
    GameTooltip:AddLine(L["hoa.addon.grows_each_time_you_die_ends_when_you_clear_normal"], 0.6, 0.6, 0.6, 1)
    GameTooltip:Show()
end)
frame:SetScript("OnLeave", function()
    GameTooltip:Hide()
end)

local DETERMINATION_SPELL = HOA_AURA_IDS.determination

local function Refresh()
    local stacks = UI.AuraStacks(DETERMINATION_SPELL, "HELPFUL")
    state.stacks = stacks
    if stacks > 0 then
        count:SetText(stacks > 1 and tostring(stacks) or "")
        frame:Show()
    else
        frame:Hide()
    end
end

UI.Module("determination"):Listen({
    UNIT_AURA = function(unit)
        if unit == "player" then
            Refresh()
        end
    end,
})

UI.ListenHoa({
    HOA_AURA_PERCENT = function(spellId, percent)
        if tonumber(spellId) == DETERMINATION_SPELL then
            state.percent = format("%g%%", tonumber(percent) or 0)
            Refresh()
        end
    end,
})
