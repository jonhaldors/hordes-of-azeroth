#ifndef MANGOS_BONKAURA_H
#define MANGOS_BONKAURA_H

#include "Common.h"
#include "Policies/Singleton.h"

#include <array>
#include <string>
#include <unordered_map>
#include <vector>

enum BonkAuraDynamic : uint8
{
    BONK_AURA_DYNAMIC_NONE          = 0,
    BONK_AURA_DYNAMIC_SHIELD_ABSORB = 1,
    BONK_AURA_DYNAMIC_WOUNDS_CUT    = 2,
    BONK_AURA_DYNAMIC_STACK_PERCENT = 3,
    BONK_AURA_DYNAMIC_CARD_TOTAL    = 4,
};

struct BonkAuraEntry
{
    uint32 id = 0;
    std::string key;
    std::string icon;
    uint8 stackMax = 0;
    uint16 durationIndex = 28;
    bool visible = true;
    BonkAuraDynamic dynamic = BONK_AURA_DYNAMIC_NONE;
    std::string sourceKind;
    uint32 sourceId = 0;
};

class BonkAura
{
    public:
        void Load();

        BonkAuraEntry const* Get(uint32 id) const;
        std::vector<BonkAuraEntry> const& All() const { return m_entries; }

        std::string Name(BonkAuraEntry const& entry, LocaleConstant locale) const;
        std::string Description(BonkAuraEntry const& entry, LocaleConstant locale) const;
        std::string Format(BonkAuraEntry const& entry, LocaleConstant locale, std::vector<std::string> const& args = {}) const;

    private:
        typedef std::array<std::string, MAX_LOCALE> LocalizedText;

        std::string Localized(std::unordered_map<uint32, LocalizedText> const& texts, uint32 id, LocaleConstant locale) const;

        std::vector<BonkAuraEntry> m_entries;
        std::unordered_map<uint32, size_t> m_byId;
        std::unordered_map<uint32, LocalizedText> m_names;
        std::unordered_map<uint32, LocalizedText> m_descriptions;
        std::unordered_map<uint32, LocalizedText> m_templates;
};

#define sBonkAura MaNGOS::Singleton<BonkAura>::Instance()

#endif
