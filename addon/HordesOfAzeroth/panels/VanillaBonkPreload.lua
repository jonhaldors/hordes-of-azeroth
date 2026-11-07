local L = VanillaBonkL
local UI = VanillaBonkUI

local MISSILES = {
    "Spells\\Frostbolt.mdx",
    "Spells\\Fireball_Missile_Low.mdx",
    "Spells\\Fireball_Missile_High.mdx",
    "Spells\\PyroBlast_Missile.mdx",
    "Spells\\Arcane_Missile_Lvl1.mdx",
    "Spells\\ArcaneShot_Missile.mdx",
    "Spells\\MultiShot_Missile.mdx",
    "Spells\\PoisonShot_Missile.mdx",
    "Spells\\ArcaneVolley_Missile.mdx",
    "spells\\missile_axe_copper.mdx",
    "Spells\\LightningBolt_Missile.mdx",
    "Spells\\DeathCoil_Missile.mdx",
    "spells\\wrath_missile.mdx",
    "spells\\holy_hammer_missile.mdx",
    "Spells\\GooBolt_Missile_Low.mdx",
}

local PRELOAD_SHOWN_SECONDS = 3

local holder = CreateFrame("Frame", nil, UIParent)
holder:SetWidth(1)
holder:SetHeight(1)
holder:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", 0, 0)
holder:SetFrameStrata("BACKGROUND")

local function Preload(path)
    local model = CreateFrame("Model", nil, holder)
    model:SetAllPoints(holder)
    model:SetModel(path)
end

local loaded = false
UI.Module("preload"):OnEnterWorld(function()
    if loaded then
        return
    end
    loaded = true
    local ok, err = pcall(function()
        for i = 1, table.getn(MISSILES) do
            Preload(MISSILES[i])
        end
    end)
    if not ok then
        DEFAULT_CHAT_FRAME:AddMessage(L("hoa.addon.hordes_of_azeroth_missile_models_were_not_preloaded_1", tostring(err)))
    end
    holder.shownFor = 0
    holder:SetScript("OnUpdate", function()
        holder.shownFor = holder.shownFor + arg1
        if holder.shownFor >= PRELOAD_SHOWN_SECONDS then
            holder:SetScript("OnUpdate", nil)
            holder:Hide()
        end
    end)
end)
