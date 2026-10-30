RegisterCVar("hoaLanguage", "enUS")

VanillaBonkLocale = { tables = {} }

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
    return strings and strings[text] or WithoutNote(text)
end

function VanillaBonkLocale.English(text)
    local strings = VanillaBonkLocale.tables[VanillaBonkLocale.language]
    if not strings then
        return text
    end
    if not VanillaBonkLocale.reverse then
        VanillaBonkLocale.reverse = {}
        for english, translated in pairs(strings) do
            VanillaBonkLocale.reverse[translated] = WithoutNote(english)
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
    dialog.button1 = VanillaBonkLocale.Text(language, "Reload")
    dialog.button2 = VanillaBonkLocale.Text(language, "Later")
    StaticPopup_Show("VANILLABONK_LANGUAGE", VanillaBonkLocale.Text(language, "Reload the interface to show it in the new language?"))
end
