RegisterCVar("hoaLanguage", "enUS");

BonkGlueLocale = { tables = {} };

local function SavedLanguage()
	local language = GetCVar("hoaLanguage");
	if ( not language or language == "" ) then
		return "enUS";
	end
	return language;
end

BonkGlueLocale.language = SavedLanguage();

local function WithoutNote(text)
	local _, last = string.find(text, "::", 1, true);
	if ( last ) then
		return string.sub(text, last + 1);
	end
	return text;
end

function BonkGlueLocale.Text(language, text)
	local strings = BonkGlueLocale.tables[language];
	return strings and strings[text] or WithoutNote(text);
end

local function Fill(text, values)
	return (string.gsub(text, "{(%d)}", function(index)
		local value = values[tonumber(index)];
		if ( value == nil ) then
			return "";
		end
		return tostring(value);
	end));
end

BonkGlueL = setmetatable({}, {
	__index = function(_, text)
		return BonkGlueLocale.Text(BonkGlueLocale.language, text);
	end,
	__call = function(_, text, a, b, c, d, e, f, g, h, i)
		return Fill(BonkGlueLocale.Text(BonkGlueLocale.language, text), { a, b, c, d, e, f, g, h, i });
	end,
});

function BonkGlueLocale.Register(language, strings)
	BonkGlueLocale.tables[language] = strings;
end
