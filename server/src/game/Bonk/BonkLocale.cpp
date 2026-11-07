#include "BonkLocale.h"
#include "Config/Config.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"
#include "Policies/SingletonImp.h"

#include <cstdio>
#include <cstring>
#include <fstream>
#include <memory>
#include <zlib.h>

INSTANTIATE_SINGLETON_1(BonkLocale);

namespace
{
    struct BonkFieldSource
    {
        BonkTextField field;
        char const* table;
        char const* column;
        char const* key;
        char const* subKey;
    };

    BonkFieldSource const FIELD_SOURCES[] =
    {
        { BONK_FIELD_GLYPH_NAME,                 "bonk_glyph",          "name",        "id",        nullptr  },
        { BONK_FIELD_GLYPH_DESCRIPTION,          "bonk_glyph",          "description", "id",        nullptr  },
        { BONK_FIELD_GLYPH_DRAWBACK,             "bonk_glyph",          "drawback",    "id",        nullptr  },
        { BONK_FIELD_WEAPON_NAME,                "bonk_weapon",         "name",        "id",        nullptr  },
        { BONK_FIELD_WEAPON_DESCRIPTION,         "bonk_weapon",         "description", "id",        nullptr  },
        { BONK_FIELD_CARD_NAME,                  "bonk_card",           "name",        "id",        nullptr  },
        { BONK_FIELD_CARD_DESCRIPTION,           "bonk_card",           "description", "id",        nullptr  },
        { BONK_FIELD_KEYWORD_NAME,               "bonk_keyword",        "name",        "id",        nullptr  },
        { BONK_FIELD_KEYWORD_DESCRIPTION,        "bonk_keyword",        "description", "id",        nullptr  },
        { BONK_FIELD_MAP_NAME,                   "bonk_map",            "name",        "id",        nullptr  },
        { BONK_FIELD_MAP_SUMMARY,                "bonk_map",            "summary",     "id",        nullptr  },
        { BONK_FIELD_MAP_DESCRIPTION,            "bonk_map",            "description", "id",        nullptr  },
        { BONK_FIELD_TIER_NAME,                  "bonk_tier",           "name",        "id",        nullptr  },
        { BONK_FIELD_TIER_DESCRIPTION,           "bonk_tier",           "description", "id",        nullptr  },
        { BONK_FIELD_TIER_DETAILS,               "bonk_tier",           "details",     "id",        nullptr  },
        { BONK_FIELD_MASTERY_NAME,               "bonk_mastery",        "name",        "id",        nullptr  },
        { BONK_FIELD_MASTERY_DESCRIPTION,        "bonk_mastery",        "description", "id",        nullptr  },
        { BONK_FIELD_MASTERY_TREE_NAME,          "bonk_mastery_tree",   "name",        "id",        nullptr  },
        { BONK_FIELD_PASSIVE_NAME,               "bonk_passive",        "name",        "id",        nullptr  },
        { BONK_FIELD_PASSIVE_DESCRIPTION,        "bonk_passive",        "description", "id",        nullptr  },
        { BONK_FIELD_PET_FAMILY_NAME,            "bonk_pet_family",     "name",        "id",        nullptr  },
        { BONK_FIELD_PET_FAMILY_DESCRIPTION,     "bonk_pet_family",     "description", "id",        nullptr  },
        { BONK_FIELD_QUEST_NAME,                 "bonk_quest",          "name",        "id",        nullptr  },
        { BONK_FIELD_QUEST_DESCRIPTION,          "bonk_quest",          "description", "id",        nullptr  },
        { BONK_FIELD_TALENT_NAME,                "bonk_talent",         "name",        "id",        nullptr  },
        { BONK_FIELD_TALENT_DESCRIPTION,         "bonk_talent",         "description", "id",        nullptr  },
        { BONK_FIELD_UPGRADE_NAME,               "bonk_upgrade",        "name",        "id",        nullptr  },
        { BONK_FIELD_UPGRADE_DESCRIPTION,        "bonk_upgrade",        "description", "id",        nullptr  },
        { BONK_FIELD_ARCHETYPE_NAME,             "bonk_archetype",      "name",        "id",        nullptr  },
        { BONK_FIELD_HIDDEN_NAME,                "bonk_hidden",         "name",        "id",        nullptr  },
        { BONK_FIELD_HIDDEN_YELL,                "bonk_hidden",         "yell",        "id",        nullptr  },
        { BONK_FIELD_HIDDEN_FOUND_TEXT,          "bonk_hidden",         "found_text",  "id",        nullptr  },
        { BONK_FIELD_SHOP_TREE_NAME,             "bonk_shop_tree",      "name",        "id",        nullptr  },
        { BONK_FIELD_TITLE_NAME,                 "bonk_title",          "name",        "id",        nullptr  },
        { BONK_FIELD_TITLE_PATTERN,              "bonk_title",          "pattern",     "id",        nullptr  },
        { BONK_FIELD_WAVE_NAME,                  "bonk_wave",           "name",        "start_sec", nullptr  },
    };

    uint32 const BONK_FIRST_OWN_ENTRY = 900000;

    struct BonkNameSource
    {
        char const* table;
        char const* column;
        char const* localeTable;
    };

    BonkNameSource const NAME_SOURCES[] =
    {
        { "item_template",     "name",    "locales_item"     },
        { "creature_template", "name",    "locales_creature" },
        { "creature_template", "subname", "locales_creature" },
        { "broadcast_text",   "male_text",   "locales_broadcast_text" },
        { "broadcast_text",   "female_text", "locales_broadcast_text" },
    };

    std::string KeyColumns(BonkFieldSource const& source)
    {
        std::string columns = std::string("`") + source.key + "`";
        if (source.subKey)
            columns += std::string(", `") + source.subKey + "`";
        return columns;
    }

    uint32 ReadKey(BonkFieldSource const& source, Field const* fields)
    {
        return source.subKey ? BonkTextKey(fields[0].GetUInt32(), fields[1].GetUInt8()) : fields[0].GetUInt32();
    }

    bool ReadLocale(std::string const& name, char const* table, uint32 id, LocaleConstant& locale)
    {
        if (BonkLocale::ParseLocale(name, locale) && locale != LOCALE_enUS)
            return true;

        sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `%s`: row %u has locale '%s', which is English or unknown, skipped.", table, id, name.c_str());
        return false;
    }

    std::string JsonString(std::string const& text)
    {
        std::string json = "\"";
        for (char c : text)
        {
            switch (c)
            {
                case '"':  json += "\\\""; break;
                case '\\': json += "\\\\"; break;
                case '\n': json += "\\n";  break;
                case '\r': json += "\\r";  break;
                case '\t': json += "\\t";  break;
                default:
                    if (uint8(c) < 0x20)
                    {
                        char escaped[8];
                        std::snprintf(escaped, sizeof(escaped), "\\u%04x", uint32(uint8(c)));
                        json += escaped;
                    }
                    else
                        json += c;
                    break;
            }
        }
        return json + "\"";
    }

    char const* TranslationStatus(std::string const& current, std::string const& outdated)
    {
        if (!current.empty())
            return "translated";
        return outdated.empty() ? "missing" : "outdated";
    }
}

void BonkLocale::Load()
{
    LoadStrings();
    LoadFields();
}

void BonkLocale::LoadStrings()
{
    m_strings.clear();

    for (BonkStringText const& text : GetBonkStringTexts())
    {
        StringTexts& texts = m_strings[text.id];
        if (!texts.current[LOCALE_enUS].empty())
            sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "Bonk: string %u is defined twice in BonkStrings.cpp; the later text is used.", uint32(text.id));
        texts.current[LOCALE_enUS] = text.english;
        texts.hash = SourceHash(texts.current[LOCALE_enUS]);
    }

    uint32 translated = 0;
    uint32 outdated = 0;
    if (std::unique_ptr<QueryResult> result{ WorldDatabase.Query("SELECT `entry`, `locale`, `source_hash`, `content` FROM `bonk_string_locale`") })
    {
        do
        {
            Field* fields = result->Fetch();
            uint32 const entry = fields[0].GetUInt32();
            auto const itr = m_strings.find(entry);
            if (itr == m_strings.end())
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_string_locale`: entry %u is not a Bonk string, skipped.", entry);
                continue;
            }

            LocaleConstant locale;
            if (!ReadLocale(fields[1].GetCppString(), "bonk_string_locale", entry, locale))
                continue;

            StringTexts& texts = itr->second;
            if (fields[2].GetUInt32() != texts.hash)
            {
                sLog.Out(LOG_DBERROR, LOG_LVL_MINIMAL, "Table `bonk_string_locale`: entry %u (%s) was translated from different English text, showing English until it is updated.",
                    entry, localeNames[locale]);
                texts.outdated[locale] = fields[3].GetCppString();
                ++outdated;
                continue;
            }

            texts.current[locale] = fields[3].GetCppString();
            ++translated;
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk strings, %u translations, %u out of date", uint32(m_strings.size()), translated, outdated);
}

void BonkLocale::LoadFields()
{
    for (auto& texts : m_fields)
        texts.clear();

    uint32 count = 0;
    for (BonkFieldSource const& source : FIELD_SOURCES)
    {
        std::string const table = std::string(source.table) + "_locale";
        std::unique_ptr<QueryResult> result(WorldDatabase.PQuery(
            "SELECT %s, `locale`, `%s` FROM `%s` WHERE `%s` <> ''", KeyColumns(source).c_str(), source.column, table.c_str(), source.column));
        if (!result)
            continue;

        uint32 const keys = source.subKey ? 2 : 1;
        do
        {
            Field* fields = result->Fetch();
            LocaleConstant locale;
            if (!ReadLocale(fields[keys].GetCppString(), table.c_str(), fields[0].GetUInt32(), locale))
                continue;

            m_fields[source.field][ReadKey(source, fields)][locale] = fields[keys + 1].GetCppString();
            ++count;
        } while (result->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u Bonk text translations", count);
}

std::string BonkLocale::GetString(BonkString id, LocaleConstant locale, std::vector<std::string> const& args) const
{
    auto const itr = m_strings.find(id);
    if (itr == m_strings.end())
    {
        sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "Bonk: string %u has no English text in BonkStrings.cpp.", uint32(id));
        return "<bonk_string " + std::to_string(uint32(id)) + ">";
    }

    LocalizedText const& current = itr->second.current;
    bool const translated = locale < MAX_LOCALE && !current[locale].empty();
    return Substitute(translated ? current[locale] : current[LOCALE_enUS], args);
}

std::string BonkLocale::Localize(BonkTextField field, uint32 id, std::string const& english, LocaleConstant locale) const
{
    if (field >= MAX_BONK_TEXT_FIELD || locale == LOCALE_enUS || locale >= MAX_LOCALE)
        return english;

    auto const itr = m_fields[field].find(id);
    if (itr == m_fields[field].end() || itr->second[locale].empty())
        return english;
    return itr->second[locale];
}

std::string BonkLocale::JoinList(std::vector<std::string> const& items, BonkString last, LocaleConstant locale) const
{
    std::string text = items.empty() ? std::string() : items.front();
    for (size_t i = 1; i < items.size(); ++i)
        text = GetString(i + 1 == items.size() ? last : BONK_STRING_LIST_ITEM, locale, { text, items[i] });
    return text;
}

bool BonkLocale::Export(LocaleConstant locale, std::string& path) const
{
    std::string directory = sConfig.GetStringDefault("LogsDir", "");
    if (!directory.empty() && directory.back() != '/' && directory.back() != '\\')
        directory += '/';
    path = directory + "bonk-strings-" + localeNames[locale] + ".json";

    std::ofstream file(path, std::ios::out | std::ios::binary | std::ios::trunc);
    if (!file)
        return false;

    file << "{\n  \"locale\": " << JsonString(localeNames[locale]) << ",\n  \"strings\": [";
    char const* separator = "\n";
    for (BonkStringText const& text : GetBonkStringTexts())
    {
        auto const itr = m_strings.find(text.id);
        if (itr == m_strings.end())
            continue;

        StringTexts const& texts = itr->second;
        std::string const& current = texts.current[locale];
        std::string const& outdated = texts.outdated[locale];
        file << separator << "    { \"id\": " << uint32(text.id) << ", \"hash\": " << texts.hash
             << ", \"english\": " << JsonString(texts.current[LOCALE_enUS])
             << ", \"translation\": " << JsonString(current.empty() ? outdated : current)
             << ", \"status\": \"" << TranslationStatus(current, outdated) << "\" }";
        separator = ",\n";
    }

    file << "\n  ],\n  \"fields\": [";
    separator = "\n";
    for (BonkFieldSource const& source : FIELD_SOURCES)
    {
        std::string const keyColumns = KeyColumns(source);
        std::unique_ptr<QueryResult> result(WorldDatabase.PQuery(
            "SELECT %s, `%s` FROM `%s` WHERE `%s` <> '' ORDER BY %s", keyColumns.c_str(), source.column, source.table, source.column, keyColumns.c_str()));
        if (!result)
            continue;

        uint32 const keys = source.subKey ? 2 : 1;
        do
        {
            Field* fields = result->Fetch();
            auto const itr = m_fields[source.field].find(ReadKey(source, fields));
            std::string const translation = itr == m_fields[source.field].end() ? "" : itr->second[locale];
            file << separator << "    { \"table\": " << JsonString(source.table) << ", \"column\": " << JsonString(source.column)
                 << ", " << JsonString(source.key) << ": " << fields[0].GetUInt32();
            if (source.subKey)
                file << ", " << JsonString(source.subKey) << ": " << fields[1].GetUInt32();
            file << ", \"english\": " << JsonString(fields[keys].GetCppString())
                 << ", \"translation\": " << JsonString(translation)
                 << ", \"status\": \"" << TranslationStatus(translation, "") << "\" }";
            separator = ",\n";
        } while (result->NextRow());
    }

    for (BonkNameSource const& source : NAME_SOURCES)
    {
        std::string const translated = locale == LOCALE_enUS ? std::string("''") :
            "IFNULL(l.`" + std::string(source.column) + "_loc" + std::to_string(int(locale)) + "`, '')";
        std::unique_ptr<QueryResult> result(WorldDatabase.PQuery(
            "SELECT t.`entry`, t.`%s`, %s FROM `%s` t LEFT JOIN `%s` l ON l.`entry` = t.`entry` WHERE t.`entry` >= %u AND t.`%s` <> '' ORDER BY t.`entry`",
            source.column, translated.c_str(), source.table, source.localeTable, BONK_FIRST_OWN_ENTRY, source.column));
        if (!result)
            continue;

        do
        {
            Field* fields = result->Fetch();
            std::string const translation = fields[2].GetCppString();
            file << separator << "    { \"table\": " << JsonString(source.table) << ", \"column\": " << JsonString(source.column)
                 << ", \"entry\": " << fields[0].GetUInt32() << ", \"english\": " << JsonString(fields[1].GetCppString())
                 << ", \"translation\": " << JsonString(translation) << ", \"status\": \"" << TranslationStatus(translation, "") << "\" }";
            separator = ",\n";
        } while (result->NextRow());
    }

    file << "\n  ]\n}\n";
    return bool(file);
}

bool BonkLocale::ParseLocale(std::string const& name, LocaleConstant& locale)
{
    for (LocaleNameStr const* itr = &fullLocaleNameList[0]; itr->name; ++itr)
        if (name.size() == std::strlen(itr->name) && StringStartsWithCaseInsensitive(name, itr->name))
        {
            locale = itr->locale;
            return true;
        }
    return false;
}

std::string BonkLocale::ListLocales()
{
    std::string names;
    for (char const* name : localeNames)
        names += (names.empty() ? "" : ", ") + std::string(name);
    return names;
}

namespace
{
    size_t SentenceEnd(std::string const& text, size_t pos, size_t& next)
    {
        size_t const point = text.find(". ", pos);
        size_t const fullStop = text.find("\xE3\x80\x82", pos);
        if (fullStop != std::string::npos && (point == std::string::npos || fullStop < point))
        {
            next = fullStop + 3;
            return next;
        }
        if (point == std::string::npos)
            return std::string::npos;
        next = point + 2;
        return point + 1;
    }
}

std::vector<std::string> BonkLocale::SplitSentences(std::string const& text)
{
    std::vector<std::string> sentences;
    size_t pos = 0;
    while (pos < text.size())
    {
        size_t next = 0;
        size_t const end = SentenceEnd(text, pos, next);
        if (end == std::string::npos)
        {
            sentences.push_back(text.substr(pos));
            break;
        }
        sentences.push_back(text.substr(pos, end - pos));
        pos = next;
    }
    return sentences;
}

std::string BonkLocale::AfterFirstSentence(std::string const& text)
{
    size_t next = 0;
    if (SentenceEnd(text, 0, next) == std::string::npos || next >= text.size())
        return text;
    return text.substr(next);
}

uint32 BonkLocale::SourceHash(std::string const& text)
{
    return uint32(crc32(0L, reinterpret_cast<Bytef const*>(text.data()), uInt(text.size())));
}

std::string BonkLocale::Substitute(std::string const& pattern, std::vector<std::string> const& args)
{
    std::string text;
    text.reserve(pattern.size());
    for (std::size_t i = 0; i < pattern.size(); ++i)
    {
        bool const placeholder = pattern[i] == '{' && i + 2 < pattern.size() && pattern[i + 2] == '}' &&
            pattern[i + 1] >= '1' && pattern[i + 1] <= '9';
        if (!placeholder)
        {
            text += pattern[i];
            continue;
        }

        std::size_t const index = std::size_t(pattern[i + 1] - '1');
        if (index < args.size())
            text += args[index];
        i += 2;
    }
    return text;
}
