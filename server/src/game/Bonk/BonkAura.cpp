#include "BonkAura.h"
#include "BonkLocale.h"
#include "Database/DatabaseEnv.h"
#include "Log.h"
#include "Policies/SingletonImp.h"

#include <memory>

INSTANTIATE_SINGLETON_1(BonkAura);

void BonkAura::Load()
{
    m_entries.clear();
    m_byId.clear();
    m_names.clear();
    m_descriptions.clear();
    m_templates.clear();

    std::unique_ptr<QueryResult> result(WorldDatabase.Query(
        "SELECT `entry`, `key`, `icon`, `name`, `description`, `stack_max`, `duration_index`, `visible`, "
        "`dynamic_kind`, `dynamic_template`, `source_kind`, `source_id` FROM `hoa_aura` ORDER BY `entry`"));
    if (!result || result->GetRowCount() == 0)
    {
        sLog.Out(LOG_BASIC, LOG_LVL_ERROR, "HoA auras: `hoa_aura` is empty; apply server/sql/content/*.sql");
        return;
    }

    do
    {
        Field* fields = result->Fetch();
        BonkAuraEntry entry;
        entry.id = fields[0].GetUInt32();
        entry.key = fields[1].GetCppString();
        entry.icon = fields[2].GetCppString();
        entry.stackMax = uint8(fields[5].GetUInt32());
        entry.durationIndex = uint16(fields[6].GetUInt32());
        entry.visible = fields[7].GetUInt32() != 0;
        uint32 const dynamic = fields[8].GetUInt32();
        entry.dynamic = dynamic <= BONK_AURA_DYNAMIC_CARD_TOTAL ? BonkAuraDynamic(dynamic) : BONK_AURA_DYNAMIC_NONE;
        entry.sourceKind = fields[10].GetCppString();
        entry.sourceId = fields[11].IsNULL() ? 0 : fields[11].GetUInt32();

        m_byId[entry.id] = m_entries.size();
        m_names[entry.id][LOCALE_enUS] = fields[3].GetCppString();
        m_descriptions[entry.id][LOCALE_enUS] = fields[4].GetCppString();
        m_templates[entry.id][LOCALE_enUS] = fields[9].GetCppString();
        m_entries.push_back(entry);
    } while (result->NextRow());

    std::unique_ptr<QueryResult> localeResult(WorldDatabase.Query(
        "SELECT `entry`, `locale`, `name`, `description`, `dynamic_template` FROM `hoa_aura_locale`"));
    uint32 translated = 0;
    if (localeResult && localeResult->GetRowCount() > 0)
    {
        do
        {
            Field* fields = localeResult->Fetch();
            uint32 const id = fields[0].GetUInt32();
            if (!m_byId.count(id))
                continue;
            LocaleConstant locale;
            if (!BonkLocale::ParseLocale(fields[1].GetCppString(), locale) || locale == LOCALE_enUS)
                continue;
            std::string const name = fields[2].GetCppString();
            std::string const description = fields[3].GetCppString();
            std::string const text = fields[4].GetCppString();
            if (!name.empty())
                m_names[id][locale] = name;
            if (!description.empty())
                m_descriptions[id][locale] = description;
            if (!text.empty())
                m_templates[id][locale] = text;
            ++translated;
        } while (localeResult->NextRow());
    }

    sLog.Out(LOG_BASIC, LOG_LVL_MINIMAL, ">> Loaded %u HoA auras (%u translations)", uint32(m_entries.size()), translated);
}

BonkAuraEntry const* BonkAura::Get(uint32 id) const
{
    auto const itr = m_byId.find(id);
    return itr == m_byId.end() ? nullptr : &m_entries[itr->second];
}

std::string BonkAura::Localized(std::unordered_map<uint32, LocalizedText> const& texts, uint32 id, LocaleConstant locale) const
{
    auto const itr = texts.find(id);
    if (itr == texts.end())
        return "";
    if (locale < MAX_LOCALE && !itr->second[locale].empty())
        return itr->second[locale];
    return itr->second[LOCALE_enUS];
}

std::string BonkAura::Name(BonkAuraEntry const& entry, LocaleConstant locale) const
{
    return Localized(m_names, entry.id, locale);
}

std::string BonkAura::Description(BonkAuraEntry const& entry, LocaleConstant locale) const
{
    return Localized(m_descriptions, entry.id, locale);
}

std::string BonkAura::Format(BonkAuraEntry const& entry, LocaleConstant locale, std::vector<std::string> const& args) const
{
    std::string const pattern = Localized(m_templates, entry.id, locale);
    return pattern.empty() ? "" : BonkLocale::Substitute(pattern, args);
}
