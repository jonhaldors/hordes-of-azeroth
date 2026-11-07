-- The transmog probe: listen for every HOA_MOG_* message the client's plugin fires, then report
-- whether the addon's window answered. Runs in the live UI VM via WOW_PROBE_LUA.
local f = CreateFrame("Frame")
local seen = {}
for _, name in ipairs({ "HOA_MOG_BEGIN", "HOA_MOG_SLOT", "HOA_MOG_LOOK", "HOA_MOG_OUTFIT", "HOA_MOG_END" }) do
    f:RegisterEvent(name)
end
f:SetScript("OnEvent", function()
    seen[event] = (seen[event] or 0) + 1
    if event == "HOA_MOG_BEGIN" or event == "HOA_MOG_END" then
        ProbeLog("mog " .. event)
    end
end)
local elapsed, checked = 0, false
f:SetScript("OnUpdate", function()
    if checked then
        return
    end
    elapsed = elapsed + (arg1 or 0)
    if elapsed < 25 then
        return
    end
    checked = true
    local counts = {}
    for name, count in pairs(seen) do
        tinsert(counts, name .. "=" .. count)
    end
    table.sort(counts)
    ProbeLog("mog counts: " .. table.concat(counts, ", "))
    ProbeLog("mog window exists: " .. tostring(VanillaBonkTransmog ~= nil))
    ProbeLog("mog window shown: " .. tostring(VanillaBonkTransmog and VanillaBonkTransmog:IsShown()))
end)
ProbeLog("mog probe installed")