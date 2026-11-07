#ifndef MANGOS_BONKLOCALE_H
#define MANGOS_BONKLOCALE_H

#include "BonkStrings.h"
#include "Common.h"
#include "Policies/Singleton.h"

#include <array>
#include <string>
#include <unordered_map>
#include <vector>

enum BonkTextField : uint8
{
    BONK_FIELD_GLYPH_NAME                 = 0,
    BONK_FIELD_GLYPH_DESCRIPTION          = 1,
    BONK_FIELD_GLYPH_DRAWBACK             = 2,
    BONK_FIELD_WEAPON_NAME                = 3,
    BONK_FIELD_WEAPON_DESCRIPTION         = 4,
    BONK_FIELD_CARD_NAME                  = 5,
    BONK_FIELD_CARD_DESCRIPTION           = 6,
    BONK_FIELD_KEYWORD_NAME               = 7,
    BONK_FIELD_KEYWORD_DESCRIPTION        = 8,
    BONK_FIELD_MAP_NAME                   = 9,
    BONK_FIELD_MAP_SUMMARY                = 10,
    BONK_FIELD_MAP_DESCRIPTION            = 11,
    BONK_FIELD_TIER_NAME                  = 12,
    BONK_FIELD_TIER_DESCRIPTION           = 13,
    BONK_FIELD_TIER_DETAILS               = 14,
    BONK_FIELD_MASTERY_NAME               = 15,
    BONK_FIELD_MASTERY_DESCRIPTION        = 16,
    BONK_FIELD_MASTERY_TREE_NAME          = 17,
    BONK_FIELD_PASSIVE_NAME               = 18,
    BONK_FIELD_PASSIVE_DESCRIPTION        = 19,
    BONK_FIELD_PET_FAMILY_NAME            = 20,
    BONK_FIELD_PET_FAMILY_DESCRIPTION     = 21,
    BONK_FIELD_QUEST_NAME                 = 22,
    BONK_FIELD_QUEST_DESCRIPTION          = 23,
    BONK_FIELD_TALENT_NAME                = 24,
    BONK_FIELD_TALENT_DESCRIPTION         = 25,
    BONK_FIELD_UPGRADE_NAME               = 26,
    BONK_FIELD_UPGRADE_DESCRIPTION        = 27,
    BONK_FIELD_ARCHETYPE_NAME             = 28,
    BONK_FIELD_HIDDEN_NAME                = 31,
    BONK_FIELD_HIDDEN_YELL                = 32,
    BONK_FIELD_HIDDEN_FOUND_TEXT          = 33,
    BONK_FIELD_SHOP_TREE_NAME             = 34,
    BONK_FIELD_TITLE_NAME                 = 35,
    BONK_FIELD_TITLE_PATTERN              = 36,
    BONK_FIELD_WAVE_NAME                  = 37,
    MAX_BONK_TEXT_FIELD
};

inline uint32 BonkTextKey(uint32 key, uint8 subKey) { return key << 8 | subKey; }

class BonkLocale
{
    public:
        void Load();

        std::string GetString(BonkString id, LocaleConstant locale, std::vector<std::string> const& args = {}) const;
        std::string Localize(BonkTextField field, uint32 id, std::string const& english, LocaleConstant locale) const;
        std::string JoinList(std::vector<std::string> const& items, BonkString last, LocaleConstant locale) const;
        bool Export(LocaleConstant locale, std::string& path) const;

        static bool ParseLocale(std::string const& name, LocaleConstant& locale);
        static std::string ListLocales();
        static char const* Tag(LocaleConstant locale)
        {
            switch (locale)
            {
                case LOCALE_zhCN: return "zhCN";
                case LOCALE_zhTW: return "zhTW";
                default: return "enUS";
            }
        }
        static std::vector<std::string> SplitSentences(std::string const& text);
        static std::string AfterFirstSentence(std::string const& text);
        static uint32 SourceHash(std::string const& text);
        static std::string Substitute(std::string const& pattern, std::vector<std::string> const& args);

    private:
        typedef std::array<std::string, MAX_LOCALE> LocalizedText;

        struct StringTexts
        {
            uint32 hash = 0;
            LocalizedText current;
            LocalizedText outdated;
        };

        void LoadStrings();
        void LoadFields();

        std::unordered_map<uint32, StringTexts> m_strings;
        std::array<std::unordered_map<uint32, LocalizedText>, MAX_BONK_TEXT_FIELD> m_fields;
};

#define sBonkLocale MaNGOS::Singleton<BonkLocale>::Instance()

#endif
