local function LinePattern(text)
    if not text then
        return nil
    end
    text = gsub(text, "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1")
    text = gsub(text, "%%%%s", ".+")
    text = gsub(text, "%%%%d", "%%d+")
    return "^" .. text .. "$"
end

local HIDDEN_SYSTEM_LINES = {}
for _, text in ipairs({ ERR_LEARN_SPELL_S, ERR_LEARN_ABILITY_S, ERR_SPELL_UNLEARNED_S, ERR_SKILL_GAINED_S, ERR_SKILL_UP_SI }) do
    local pattern = LinePattern(text)
    if pattern then
        tinsert(HIDDEN_SYSTEM_LINES, pattern)
    end
end

local HIDDEN_CHANNEL_NOTICES = { YOU_JOINED = true, YOU_CHANGED = true, YOU_LEFT = true }

local OriginalChatFrameOnEvent = ChatFrame_OnEvent
function ChatFrame_OnEvent(event)
    if event == "PLAYER_LEVEL_UP" or event == "CHAT_MSG_SKILL" then
        return
    end
    if event == "CHAT_MSG_CHANNEL_NOTICE" and HIDDEN_CHANNEL_NOTICES[arg1] then
        return
    end
    if event == "CHAT_MSG_SYSTEM" and arg1 then
        for _, pattern in ipairs(HIDDEN_SYSTEM_LINES) do
            if strfind(arg1, pattern) then
                return
            end
        end
    end
    OriginalChatFrameOnEvent(event)
end
