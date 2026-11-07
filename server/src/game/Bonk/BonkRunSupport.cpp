#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkPlayer.h"
#include "Player.h"

#include <algorithm>

namespace
{
    char const BONK_SUPPORT_OTHER_ICON[] = "INV_Misc_QuestionMark";

    std::string CleanField(std::string text)
    {
        std::replace_if(text.begin(), text.end(), [](char c) { return c == ',' || c == '~'; }, ' ');
        return text;
    }
}

BonkRun::SupportCredit& BonkRun::GetSupportCredit(BonkSupportSource const& source)
{
    std::string const name = source.name.empty() ? GetString(BONK_STRING_SUPPORT_OTHER) : source.name;
    auto itr = m_supportCredits.find(name);
    if (itr == m_supportCredits.end())
    {
        SupportCredit credit;
        credit.order = uint32(m_supportCredits.size());
        itr = m_supportCredits.emplace(name, credit).first;
    }
    itr->second.icon = source.name.empty() || source.icon.empty() ? BONK_SUPPORT_OTHER_ICON : source.icon;
    return itr->second;
}

void BonkRun::CreditHealing(uint32 amount)
{
    if (amount)
        GetSupportCredit(m_supportSource).healed += amount;
}

void BonkRun::CreditAbsorb(BonkSupportSource const& source, uint32 amount)
{
    if (amount)
        GetSupportCredit(source).absorbed += amount;
}

void BonkRun::AddSpellShield(uint32 amount)
{
    uint32 const cap = GetSpellShieldCap();
    uint32 const before = m_spellShield;
    m_spellShield = std::min(m_spellShield + amount, cap);
    if (m_spellShield > before)
        m_spellShieldParts.emplace_back(m_supportSource, m_spellShield - before);
}

uint32 BonkRun::AbsorbSpellShield(uint32 damage)
{
    uint32 const absorbed = std::min(m_spellShield, damage);
    m_spellShield -= absorbed;
    uint32 left = absorbed;
    while (left && !m_spellShieldParts.empty())
    {
        auto& part = m_spellShieldParts.front();
        uint32 const taken = std::min(part.second, left);
        CreditAbsorb(part.first, taken);
        part.second -= taken;
        left -= taken;
        if (!part.second)
            m_spellShieldParts.pop_front();
    }
    if (left)
        CreditAbsorb(BonkSupportSource(), left);
    if (!m_spellShield)
        m_spellShieldParts.clear();
    return absorbed;
}

std::string BonkRun::DescribeSupport() const
{
    std::vector<std::pair<std::string, SupportCredit const*>> credits;
    for (auto const& itr : m_supportCredits)
        credits.emplace_back(itr.first, &itr.second);
    std::sort(credits.begin(), credits.end(), [](auto const& a, auto const& b) { return a.second->order < b.second->order; });
    std::string text;
    for (auto const& credit : credits)
        text += CleanField(credit.second->icon) + ":" + std::to_string(credit.second->healed) + ":" + std::to_string(credit.second->absorbed) + ":" +
            CleanField(credit.first) + ",";
    return text;
}

BonkSupportSource BonkRun::WeaponSupport(OwnedWeapon const& owned) const
{
    return { owned.weapon.icon, Localize(BONK_FIELD_WEAPON_NAME, owned.weapon.id, owned.weapon.name) };
}

BonkSupportSource BonkRun::SpellSupport(uint32 spellId) const
{
    if (spellId)
        for (OwnedWeapon const& owned : m_weapons)
            if (owned.weapon.spellId == spellId || owned.weapon.altSpellId == spellId)
                return WeaponSupport(owned);
    return {};
}

BonkSupportSource BonkRun::PassiveSupport(BonkPassiveEffect effect) const
{
    for (auto const& itr : m_passiveRanks)
        if (BonkPassive const* passive = sBonkMgr.GetPassive(itr.first))
            if (passive->effect == effect)
                return { passive->icon, Localize(BONK_FIELD_PASSIVE_NAME, passive->id, passive->name) };
    return {};
}

BonkSupportSource BonkRun::CardSupport(BonkCardEffect effect) const
{
    if (BonkCard const* card = m_cardByEffect[effect])
        return { card->icon, Localize(BONK_FIELD_CARD_NAME, card->id, card->name) };
    return {};
}

BonkSupportSource BonkRun::TalentSupport(BonkMasteryEffect effect) const
{
    for (auto const& itr : m_player->GetBonkPlayer()->GetMasteryRanks())
        if (BonkMasteryNode const* node = itr.second ? sBonkMastery.GetNode(itr.first) : nullptr)
            if (node->effect == effect)
                return { node->icon, Localize(BONK_FIELD_MASTERY_NAME, node->id, node->name) };
    return {};
}

BonkSupportSource BonkRun::CapstoneSupport(BonkCapstone capstone) const
{
    for (auto const& itr : m_player->GetBonkPlayer()->GetMasteryRanks())
        if (BonkMasteryNode const* node = itr.second ? sBonkMastery.GetNode(itr.first) : nullptr)
            if (node->effect == BONK_MASTERY_CAPSTONE && node->target == uint32(capstone))
                return { node->icon, Localize(BONK_FIELD_MASTERY_NAME, node->id, node->name) };
    return {};
}
