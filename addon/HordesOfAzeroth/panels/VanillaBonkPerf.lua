local L = VanillaBonkL
local UI = VanillaBonkUI
local SAMPLE_SECONDS = 1
local MINUTE_SECONDS = 60
local SLOW_FPS = 30
local HITCH_MS = 100
local DIP_FPS = 100
local DIP_MS = 50
local DIP_REPORT_GAP = 5
local KEEP_SLOW = 300
local KEEP_MINUTES = 180
local SHOW_MINUTES = 5

local probe = CreateFrame("Frame")
local sampleTime, sampleFrames, sampleWorst = 0, 0, 0
local lastMemory
local lastDipReport = 0

local minute = { seconds = 0, frames = 0, time = 0, minFps = 999, worst = 0, plates = 0, garbage = 0, slow = 0 }

local function Trim(list, keep)
    while getn(list) > keep do
        tremove(list, 1)
    end
end

local function CountPlates()
    local count = 0
    local children = { WorldFrame:GetChildren() }
    for _, frame in ipairs(children) do
        if frame.vbStyled and frame:IsVisible() then
            count = count + 1
        end
    end
    return count
end

local function ResetMinute()
    minute.seconds, minute.frames, minute.time = 0, 0, 0
    minute.minFps, minute.worst, minute.plates, minute.garbage, minute.slow = 999, 0, 0, 0, 0
end

local function CloseMinute()
    if not VanillaBonkPerfLog or minute.time <= 0 then
        return
    end
    tinsert(VanillaBonkPerfLog.minutes, format("%s %s: fps avg %d min %d, worst frame %d ms, slow seconds %d, plates max %d, Lua garbage %d KB/s",
        date("%H:%M"), GetRealZoneText() or "?", floor(minute.frames / minute.time + 0.5), minute.minFps, floor(minute.worst * 1000 + 0.5),
        minute.slow, minute.plates, floor(minute.garbage / minute.time + 0.5)))
    Trim(VanillaBonkPerfLog.minutes, KEEP_MINUTES)
    ResetMinute()
end

local function Sample()
    local fps = floor(sampleFrames / sampleTime + 0.5)
    local worstMs = floor(sampleWorst * 1000 + 0.5)
    local memory = gcinfo()
    local garbage, collected = 0, false
    if lastMemory then
        if memory >= lastMemory then
            garbage = memory - lastMemory
        else
            collected = true
        end
    end
    lastMemory = memory
    local plates = CountPlates()

    minute.seconds = minute.seconds + 1
    minute.frames = minute.frames + sampleFrames
    minute.time = minute.time + sampleTime
    minute.minFps = min(minute.minFps, fps)
    minute.worst = max(minute.worst, sampleWorst)
    minute.plates = max(minute.plates, plates)
    minute.garbage = minute.garbage + garbage

    local slow = fps < SLOW_FPS or worstMs >= HITCH_MS
    if VanillaBonkPerfLog and (slow or fps < DIP_FPS or worstMs >= DIP_MS) then
        if slow then
            minute.slow = minute.slow + 1
        end
        tinsert(VanillaBonkPerfLog.slow, format("%s %s fps %d, worst frame %d ms, plates %d, Lua %d KB +%d KB%s, %s",
            date("%H:%M:%S"), slow and "slow" or "dip", fps, worstMs, plates, memory, garbage,
            collected and ", garbage collected" or "", GetRealZoneText() or "?"))
        Trim(VanillaBonkPerfLog.slow, KEEP_SLOW)
        if GetTime() - lastDipReport >= DIP_REPORT_GAP then
            lastDipReport = GetTime()
            SendChatMessage(".bonk perfdip", "SAY")
        end
    end
    if minute.seconds >= MINUTE_SECONDS then
        CloseMinute()
    end
end

probe:SetScript("OnUpdate", function()
    sampleTime = sampleTime + arg1
    sampleFrames = sampleFrames + 1
    if arg1 > sampleWorst then
        sampleWorst = arg1
    end
    if sampleTime >= SAMPLE_SECONDS then
        Sample()
        sampleTime, sampleFrames, sampleWorst = 0, 0, 0
    end
end)

UI.Module("perf"):Listen({
    ADDON_LOADED = function(name)
        if name == "HordesOfAzeroth" then
            if type(VanillaBonkPerfLog) ~= "table" then
                VanillaBonkPerfLog = {}
            end
            VanillaBonkPerfLog.slow = VanillaBonkPerfLog.slow or {}
            VanillaBonkPerfLog.minutes = VanillaBonkPerfLog.minutes or {}
        end
    end,
    PLAYER_LOGOUT = CloseMinute,
}, probe)

SLASH_VANILLABONKPERF1 = "/bonkperf"
SlashCmdList["VANILLABONKPERF"] = function(text)
    if not VanillaBonkPerfLog then
        return
    end
    if text == "reset" then
        VanillaBonkPerfLog.slow = {}
        VanillaBonkPerfLog.minutes = {}
        DEFAULT_CHAT_FRAME:AddMessage(L["hoa.addon.hordes_of_azeroth_performance_log_cleared"])
        return
    end
    local minutes = VanillaBonkPerfLog.minutes
    local first = max(1, getn(minutes) - SHOW_MINUTES + 1)
    for index = first, getn(minutes) do
        DEFAULT_CHAT_FRAME:AddMessage(minutes[index])
    end
    DEFAULT_CHAT_FRAME:AddMessage(format(L["hoa.addon.hordes_of_azeroth_d_slow_seconds_logged_type_bonkperf_reset_"], getn(VanillaBonkPerfLog.slow)))
end
