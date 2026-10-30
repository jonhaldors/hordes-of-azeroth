local SANDBOX_AT = 4
local SETUP_AT = 8
local SETUP_GAP = 1
local BUILD_GAP = 1.2
local BUILD_SECONDS = BenchBuildSeconds or 45
local FALLBACK_QUIT_DELAY = 15

local steps = {}

local function at(seconds, action)
    table.insert(steps, { t = seconds, f = action, order = table.getn(steps) })
end

local function sandbox(verb)
    local text = ".bonk sandbox"
    if verb then
        text = text .. " " .. verb
    end
    SendChatMessage(text, "SAY")
end

local function mark(text)
    SendChatMessage(text, "WHISPER", nil, UnitName("player"))
end

local function scheduleBuild(build, start)
    at(start, function() sandbox("clear") end)
    at(start + 0.5, function() sandbox("forget 0") end)
    for i = 1, table.getn(build.steps) do
        local verb = build.steps[i]
        at(start + 1 + i * BUILD_GAP, function() sandbox(verb) end)
    end
    local ready = start + 1.5 + (table.getn(build.steps) + 1) * BUILD_GAP
    at(ready, function() sandbox("heal") end)
    at(ready + 1.5, function() sandbox(BenchDummies and ((BenchDummyVerb or "dummies") .. " " .. BenchDummies) or BenchPack or "pack 150") end)
    at(ready + 2.7, function() mark("window pack " .. build.name) end)
    if BenchAfterPack then
        for i = 1, table.getn(BenchAfterPack) do
            local fireAt = ready + 1.5 + BenchAfterPack[i][1]
            local command = BenchAfterPack[i][2]
            if fireAt < start + BUILD_SECONDS - 1 then
                at(fireAt, function()
                    if string.sub(command, 1, 5) == "/run " then
                        RunScript(string.sub(command, 6))
                    else
                        SendChatMessage(command, "SAY")
                    end
                end)
            end
        end
    end
    if BenchWaveEvery and not BenchDummies then
        for wave = ready + 1.5 + BenchWaveEvery, start + BUILD_SECONDS - 1, BenchWaveEvery do
            at(wave, function() sandbox(BenchPack or "pack 150") end)
        end
    end
end

local function scheduleAll()
    at(1, function() mark("bench start") end)
    at(SANDBOX_AT, function() sandbox() end)
    local t = SETUP_AT
    for i = 1, table.getn(BenchSetup) do
        local verb = BenchSetup[i]
        at(t, function() sandbox(verb) end)
        t = t + SETUP_GAP
    end
    t = t + SETUP_GAP
    for b = 1, table.getn(BenchBuilds) do
        scheduleBuild(BenchBuilds[b], t)
        t = t + BUILD_SECONDS
    end
    at(t, function()
        mark("bench done")
        sandbox("clear")
    end)
    at(t + 1, function() sandbox("forget 0") end)
    at(t + FALLBACK_QUIT_DELAY, function() ForceQuit() end)
    if BenchVitalsEvery then
        for probe = SETUP_AT + table.getn(BenchSetup) * SETUP_GAP + 1, t, BenchVitalsEvery do
            at(probe, function() sandbox("vitals") end)
        end
    end
    if BenchCrowdProbeEvery then
        for probe = SETUP_AT, t, BenchCrowdProbeEvery do
            at(probe, function() SendChatMessage(".bonk crowd", "SAY") end)
        end
    end
end

scheduleAll()
table.sort(steps, function(a, b)
    if a.t ~= b.t then
        return a.t < b.t
    end
    return a.order < b.order
end)

local frame = CreateFrame("Frame")
local started, index = nil, 1
frame:RegisterEvent("PLAYER_ENTERING_WORLD")
frame:RegisterEvent("CHAT_MSG_SYSTEM")
frame:SetScript("OnEvent", function()
    if event == "CHAT_MSG_SYSTEM" then
        if BenchCrowdProbeEvery and string.find(arg1, "enemies walk in the crowd", 1, true) then
            mark(arg1)
        end
        return
    end
    VanillaBonkPlateGuideDone = true
    LoggingChat(1)
    if not started then
        started = GetTime()
    end
end)
frame:SetScript("OnUpdate", function()
    if not started then
        return
    end
    local elapsed = GetTime() - started
    while steps[index] and steps[index].t <= elapsed do
        local step = steps[index]
        index = index + 1
        pcall(step.f)
    end
end)
