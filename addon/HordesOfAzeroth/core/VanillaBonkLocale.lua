RegisterCVar("hoaLanguage", "enUS")

VanillaBonkLocale = { tables = {}, keys = {}, english = {} }

local function SavedLanguage()
    local language = GetCVar("hoaLanguage")
    if not language or language == "" then
        return "enUS"
    end
    return language
end

VanillaBonkLocale.language = SavedLanguage()

local function WithoutNote(text)
    local _, last = string.find(text, "::", 1, true)
    if last then
        return string.sub(text, last + 1)
    end
    return text
end

function VanillaBonkLocale.Text(language, text)
    local strings = VanillaBonkLocale.tables[language]
    local message_id = VanillaBonkLocale.keys[text]
    local translated = message_id and strings and strings[message_id]
    local english = VanillaBonkLocale.english[message_id or text]
    return translated or (strings and strings[text]) or english or WithoutNote(text)
end

function VanillaBonkLocale.English(text)
    local strings = VanillaBonkLocale.tables[VanillaBonkLocale.language]
    if not strings then
        return text
    end
    if not VanillaBonkLocale.reverse then
        VanillaBonkLocale.reverse = {}
        for message_id, translated in pairs(strings) do
            VanillaBonkLocale.reverse[translated] = VanillaBonkLocale.english[message_id] or message_id
        end
    end
    return VanillaBonkLocale.reverse[text] or text
end

local function Fill(text, values)
    return (string.gsub(text, "{(%d)}", function(index)
        local value = values[tonumber(index)]
        return value == nil and "" or tostring(value)
    end))
end

VanillaBonkL = setmetatable({}, {
    __index = function(_, text)
        return VanillaBonkLocale.Text(VanillaBonkLocale.language, text)
    end,
    __call = function(_, text, a, b, c, d, e, f, g, h, i)
        return Fill(VanillaBonkLocale.Text(VanillaBonkLocale.language, text), { a, b, c, d, e, f, g, h, i })
    end,
})

function VanillaBonkLocale.Register(language, strings)
    VanillaBonkLocale.tables[language] = strings
    VanillaBonkLocale.reverse = nil
end

function VanillaBonkLocale.RegisterLanguages(tables)
    for language, strings in pairs(tables) do
        VanillaBonkLocale.tables[language] = strings
    end
    VanillaBonkLocale.reverse = nil
end

function VanillaBonkLocale.RegisterKeys(keys)
    VanillaBonkLocale.keys = keys
end

function VanillaBonkLocale.RegisterEnglish(english)
    VanillaBonkLocale.english = english
    VanillaBonkLocale.reverse = nil
end

StaticPopupDialogs["VANILLABONK_LANGUAGE"] = {
    text = "%s",
    OnAccept = function()
        ReloadUI()
    end,
    timeout = 0,
    whileDead = 1,
}

function VanillaBonkLocale.Changed(language)
    if language == VanillaBonkLocale.language then
        StaticPopup_Hide("VANILLABONK_LANGUAGE")
        return
    end
    local dialog = StaticPopupDialogs["VANILLABONK_LANGUAGE"]
    dialog.button1 = VanillaBonkLocale.Text(language, "hoa.addon.reload")
    dialog.button2 = VanillaBonkLocale.Text(language, "hoa.addon.later")
    StaticPopup_Show("VANILLABONK_LANGUAGE", VanillaBonkLocale.Text(language, "hoa.addon.reload_the_interface_to_show_it_in_the_new_language"))
end
