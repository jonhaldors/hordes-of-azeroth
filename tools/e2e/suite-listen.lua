-- The suite listener: count every HOA_* message and chat line the client sees, reporting a
-- snapshot every 20 seconds so a long command run shows its own timeline. Runs in the live UI VM
-- via WOW_PROBE_LUA.
local f = CreateFrame("Frame")
local seen = {}
local chat = {}
local events = {
    "HOA_HELLO", "HOA_INCOMPATIBLE", "HOA_STATS", "HOA_WALLET", "HOA_TIER", "HOA_TIER_INFO",
    "HOA_AURA_PERCENT", "HOA_AURA_VALUE", "HOA_MOG_BEGIN", "HOA_MOG_SLOT", "HOA_MOG_LOOK",
    "HOA_MOG_OUTFIT", "HOA_MOG_END", "HOA_ARENA", "HOA_RUN_START", "HOA_RUN_END", "HOA_RUN_STATE",
    "HOA_CODEX", "HOA_DASH", "HOA_GLYPH_*",
}
for _, name in ipairs({ "CHAT_MSG_SYSTEM", "CHAT_MSG_SAY", "CHAT_MSG_WHISPER" }) do
    f:RegisterEvent(name)
end
for _, name in ipairs(events) do
    f:RegisterEvent(name)
end
f:SetScript("OnEvent", function()
    if strsub(event, 1, 4) == "CHAT" then
        tinsert(chat, tostring(arg1))
        if table.getn(chat) <= 60 then
            ProbeLog("chat " .. event .. ": " .. tostring(arg1))
        end
        return
    end
    seen[event] = (seen[event] or 0) + 1
end)
local elapsed, next_report = 0, 20
f:SetScript("OnUpdate", function()
    elapsed = elapsed + (arg1 or 0)
    if elapsed < next_report then
        return
    end
    next_report = next_report + 20
    local counts = {}
    for name, count in pairs(seen) do
        tinsert(counts, name .. "=" .. count)
    end
    table.sort(counts)
    ProbeLog("snapshot " .. math.floor(elapsed) .. "s: " .. table.concat(counts, ", "))
end)
ProbeLog("suite listener installed")
