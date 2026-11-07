-- The class verification listener: counts HOA_* events and Lua errors per class,
-- reporting the class identity, the weapons that fired, and any chat replies.
-- Runs in the live UI VM via WOW_PROBE_LUA.
local f = CreateFrame("Frame")
local seen = {}
local errors = 0
local chat = {}

-- Track every HOA event so we can see which messages actually arrive.
local all_events = {
    "HOA_HELLO", "HOA_INCOMPATIBLE", "HOA_STATS", "HOA_WALLET", "HOA_TIER", "HOA_TIER_INFO",
    "HOA_AURA_PERCENT", "HOA_AURA_VALUE", "HOA_ARENA", "HOA_RUN_START", "HOA_RUN_END",
    "HOA_RUN_STATE", "HOA_RUN_PAUSED", "HOA_RUN_XP", "HOA_DASH", "HOA_CODEX",
    "HOA_MOG_BEGIN", "HOA_MOG_END", "HOA_SHOP_OPEN", "HOA_CARDS", "HOA_CARD_NOW",
    "HOA_COOP_READY", "HOA_COOP_DOWN", "HOA_COOP_WAIT",
    -- Class-specific auras
    "HOA_RUN_GLYPH_METER", "HOA_RUN_OTHER_METER", "HOA_WAVE_BEAT", "HOA_RUN_SUPPORT",
    "HOA_BOSS_BAR", "HOA_CAPTURE", "HOA_DEATH_EVENTS", "HOA_DEATH_RECAP",
}

for _, name in ipairs(all_events) do
    f:RegisterEvent(name)
end
-- Chat
for _, name in ipairs({ "CHAT_MSG_SYSTEM", "CHAT_MSG_SAY", "CHAT_MSG_WHISPER" }) do
    f:RegisterEvent(name)
end

f:SetScript("OnEvent", function()
    if strsub(event, 1, 4) == "CHAT" then
        tinsert(chat, tostring(arg1))
        if table.getn(chat) <= 30 then
            ProbeLog("chat " .. event .. ": " .. tostring(arg1))
        end
        return
    end
    seen[event] = (seen[event] or 0) + 1
end)

-- Track Lua errors via the error handler
local origHandler = geterrorhandler()
seterrorhandler(function(msg)
    errors = errors + 1
    ProbeLog("LUA-ERROR: " .. tostring(msg))
    origHandler(msg)
end)

local elapsed = 0
f:SetScript("OnUpdate", function()
    elapsed = elapsed + (arg1 or 0)
    if elapsed < 20 then return end
    elapsed = 0

    -- Report class info
    local _, class = UnitClass("player")
    local level = UnitLevel("player")
    ProbeLog("CLASS: " .. tostring(class) .. " level " .. tostring(level))

    -- Report event counts
    local counts = {}
    for name, count in pairs(seen) do
        tinsert(counts, name .. "=" .. count)
    end
    table.sort(counts)
    ProbeLog("EVENTS: " .. table.concat(counts, ", "))

    -- Report weapon state
    local weapons = ""
    if VanillaBonkRun and VanillaBonkRun.weapons then
        for i = 1, table.getn(VanillaBonkRun.weapons or {}) do
            local w = VanillaBonkRun.weapons[i]
            if w and w.weapon then
                weapons = weapons .. w.weapon.id .. " "
            end
        end
    end
    ProbeLog("WEAPONS: " .. weapons)

    -- Report errors
    ProbeLog("ERRORS: " .. tostring(errors))
    if errors > 0 then errors = 0 end
end)
ProbeLog("class-verify installed")
