local UI = VanillaBonkUI

local BATTLE_TRACKS = {
    "Sound\\Music\\Musical Moments\\battle\\battle01.mp3",
    "Sound\\Music\\Musical Moments\\battle\\battle02.mp3",
    "Sound\\Music\\Musical Moments\\battle\\battle03.mp3",
    "Sound\\Music\\Musical Moments\\battle\\battle04.mp3",
    "Sound\\Music\\Musical Moments\\battle\\battle05.mp3",
    "Sound\\Music\\Musical Moments\\battle\\battle06.mp3",
}

local playing = false

local function PlayBossMusic()
    PlayMusic(BATTLE_TRACKS[random(getn(BATTLE_TRACKS))])
    playing = true
end

local function StopBossMusic()
    if playing then
        StopMusic()
        playing = false
    end
end

UI.Listen({
    ["music"] = function(f)
        if f[2] == "boss" then
            PlayBossMusic()
        else
            StopBossMusic()
        end
    end,
    ["start"] = StopBossMusic,
    ["end"] = StopBossMusic,
})
