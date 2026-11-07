#include "BonkRun.h"
#include "BonkLocale.h"
#include "BonkMgr.h"
#include "Creature.h"
#include "Map.h"
#include "Player.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"

#include <cmath>
#include <cstring>
#include <string>

namespace
{
    float const BONK_DAMAGE_SPREAD = 0.07f;
    float const BONK_PET_SWING_SPREAD = 0.1f;
    uint32 const BONK_PET_NO_SWING_MS = 60000;
    uint32 const BONK_PET_MIN_ATTACK_MS = 300;
    uint32 const BONK_RANK_FULL_DAMAGE_RANKS = 20;

    bool IsStackStrengthSpell(BonkWeapon const& weapon)
    {
        return weapon.behavior == BONK_BEHAVIOR_CORRUPTION || weapon.behavior == BONK_BEHAVIOR_CURSE_OF_AGONY;
    }

    std::string GetSchoolName(SpellEntry const* spellInfo, LocaleConstant locale)
    {
        switch (spellInfo ? spellInfo->School : SPELL_SCHOOL_NORMAL)
        {
            case SPELL_SCHOOL_HOLY:   return sBonkLocale.GetString(BONK_STRING_SCHOOL_HOLY, locale);
            case SPELL_SCHOOL_FIRE:   return sBonkLocale.GetString(BONK_STRING_SCHOOL_FIRE, locale);
            case SPELL_SCHOOL_NATURE: return sBonkLocale.GetString(BONK_STRING_SCHOOL_NATURE, locale);
            case SPELL_SCHOOL_FROST:  return sBonkLocale.GetString(BONK_STRING_SCHOOL_FROST, locale);
            case SPELL_SCHOOL_SHADOW: return sBonkLocale.GetString(BONK_STRING_SCHOOL_SHADOW, locale);
            case SPELL_SCHOOL_ARCANE: return sBonkLocale.GetString(BONK_STRING_SCHOOL_ARCANE, locale);
            default:                  return sBonkLocale.GetString(BONK_STRING_SCHOOL_PHYSICAL, locale);
        }
    }

    std::string DescribeRange(float hit, float spread, LocaleConstant locale)
    {
        uint32 const low = uint32(std::max(1.0f, std::floor(hit * (1.0f - spread))));
        uint32 const high = uint32(std::max(1.0f, std::ceil(hit * (1.0f + spread))));
        return low == high ? std::to_string(low) : sBonkLocale.GetString(BONK_STRING_RANGE, locale, { std::to_string(low), std::to_string(high) });
    }

    bool IsTickingKeyword(BonkKeyword keyword)
    {
        return keyword == BONK_KEYWORD_BURNING || keyword == BONK_KEYWORD_BLEED || keyword == BONK_KEYWORD_POISON ||
            keyword == BONK_KEYWORD_DECAY || keyword == BONK_KEYWORD_AGONY || keyword == BONK_KEYWORD_MOONFIRE;
    }

    std::string FormatNumber(float value, char const* format)
    {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), format, value);
        return buffer;
    }

    std::string ShownNumber(float value)
    {
        return std::to_string(uint32(std::max(1.0f, std::round(value))));
    }

    std::string ShownTick(float value)
    {
        return value < 10.0f ? FormatNumber(value, "%.1f") : ShownNumber(value);
    }

    std::string ShownSeconds(float ms, LocaleConstant locale)
    {
        float const seconds = ms / 1000.0f;
        return sBonkLocale.GetString(BONK_STRING_SECONDS_SHORT, locale, { FormatNumber(seconds, seconds < 1.0f ? "%.2f" : "%.1f") });
    }

    std::string ShownPercent(float value, bool signed_)
    {
        return (signed_ && value >= 0.0f ? "+" : "") + FormatNumber(std::round(value * 10.0f) / 10.0f, "%g") + "%";
    }

    std::string CapitalizeFirst(std::string text)
    {
        if (!text.empty())
            text[0] = char(toupper(static_cast<unsigned char>(text[0])));
        return text;
    }

    std::string GetIntervalLabel(BonkWeapon const& weapon, LocaleConstant locale)
    {
        if (weapon.behavior == BONK_BEHAVIOR_DEEP_WOUNDS || weapon.IsRevenge())
            return sBonkLocale.GetString(BONK_STRING_INTERVAL_CAN_OCCUR, locale);
        if (weapon.behavior == BONK_BEHAVIOR_BLOOD_AURA)
            return sBonkLocale.GetString(BONK_STRING_INTERVAL_PULSES, locale);
        return sBonkLocale.GetString(BONK_STRING_INTERVAL_CASTS, locale);
    }

    BonkStatChange SplitUpgradeText(BonkWeapon const& weapon, BonkSpellUpgrade upgrade, float before, float after, LocaleConstant locale)
    {
        std::string const now = DescribeBonkSpellUpgrade(weapon, upgrade, before, locale);
        std::string const next = DescribeBonkSpellUpgrade(weapon, upgrade, after, locale);
        size_t const nowSpace = now.find(' ');
        size_t const nextSpace = next.find(' ');
        if (nowSpace == std::string::npos || nextSpace == std::string::npos)
            return {};
        return { CapitalizeFirst(next.substr(nextSpace + 1)), now.substr(0, nowSpace), next.substr(0, nextSpace) };
    }

    float const BONK_SHOWN_BETTER = 1.001f;
    char const* const BONK_DAMAGE_VERBS[] = { "dealing ", "deals ", "deal ", "for ", "take ", "takes " };
    char const* const BONK_DAMAGE_ADJECTIVES[] = { "", "heavy ", "massive ", "extra " };
    char const* const BONK_TARGET_NOUNS[] = { "enem", "random", "nearest", "strongest", "target", "pack", "spirit" };

    std::string MarkNumber(std::string const& text, bool)
    {
        return "|cffffffff" + text + "|r";
    }

    std::string MarkRange(float hit, float spread, bool better, LocaleConstant locale)
    {
        uint32 const low = uint32(std::max(1.0f, std::floor(hit * (1.0f - spread))));
        uint32 const high = uint32(std::max(1.0f, std::ceil(hit * (1.0f + spread))));
        if (low == high)
            return MarkNumber(std::to_string(low), better);
        return sBonkLocale.GetString(BONK_STRING_RANGE, locale, { MarkNumber(std::to_string(low), better), MarkNumber(std::to_string(high), better) });
    }

    std::string TrimNumber(float value)
    {
        return FormatNumber(std::round(value * 10.0f) / 10.0f, "%g");
    }

    bool IsWordEdge(std::string const& text, size_t at)
    {
        if (at >= text.size())
            return true;
        bool const decimal = text[at] == '.' && at + 1 < text.size() && isdigit(static_cast<unsigned char>(text[at + 1]));
        return !isalnum(static_cast<unsigned char>(text[at])) && !decimal;
    }

    bool IsWordStart(std::string const& text, size_t at)
    {
        return at == 0 || !isalnum(static_cast<unsigned char>(text[at - 1]));
    }

    bool MarkNumberFollowedBy(std::string& text, std::string const& number, std::string const& follow, std::string const& marked)
    {
        std::string const needle = number + follow;
        for (size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + 1))
            if (IsWordStart(text, at))
            {
                text.replace(at, number.size(), marked);
                return true;
            }
        return false;
    }

    bool ReplaceAtWordStart(std::string& text, std::string const& needle, std::string const& replacement)
    {
        for (size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + 1))
            if (IsWordStart(text, at))
            {
                text.replace(at, needle.size(), replacement);
                return true;
            }
        return false;
    }

    bool MarkNumberAfter(std::string& text, std::string const& lead, std::string const& number, std::string const& marked)
    {
        std::string const needle = lead + number;
        for (size_t at = text.find(needle); at != std::string::npos; at = text.find(needle, at + 1))
            if (IsWordEdge(text, at + needle.size()))
            {
                text.replace(at + lead.size(), number.size(), marked);
                return true;
            }
        return false;
    }

    bool MarkTargetCount(std::string& text, std::string const& number, std::string const& marked)
    {
        for (size_t at = text.find(number); at != std::string::npos; at = text.find(number, at + 1))
        {
            size_t const after = at + number.size();
            if (!IsWordStart(text, at) || after >= text.size() || text[after] != ' ')
                continue;
            for (char const* noun : BONK_TARGET_NOUNS)
                if (text.compare(after + 1, strlen(noun), noun) == 0)
                {
                    text.replace(at, number.size(), marked);
                    return true;
                }
        }
        return false;
    }

    bool InsertDamageRange(std::string& text, std::string const& school, std::string const& range)
    {
        size_t best = std::string::npos;
        size_t bestLength = 0;
        std::string bestVerb;
        for (char const* verb : BONK_DAMAGE_VERBS)
            for (char const* adjective : BONK_DAMAGE_ADJECTIVES)
                for (std::string const& noun : { school + " damage", std::string("damage") })
                {
                    std::string const needle = std::string(verb) + adjective + noun;
                    size_t const at = text.find(needle);
                    if (at != std::string::npos && IsWordStart(text, at) && (best == std::string::npos || at < best))
                    {
                        best = at;
                        bestLength = needle.size();
                        bestVerb = verb;
                    }
                }
        if (best == std::string::npos)
            return false;
        text.replace(best, bestLength, bestVerb + range + " " + school + " damage");
        return true;
    }
}

float BonkRun::GetShownSpread(OwnedWeapon const& owned) const
{
    return owned.weapon.behavior == BONK_BEHAVIOR_PET ? BONK_PET_SWING_SPREAD : BONK_DAMAGE_SPREAD;
}

uint32 BonkRun::GetPetAttackMs(OwnedWeapon const& owned, bool* pulses) const
{
    if (pulses)
        *pulses = false;
    BonkPetFamily const* family = owned.weapon.behavior == BONK_BEHAVIOR_PET ? GetPetFamily(owned) : nullptr;
    if (!family)
        return 0;

    uint32 baseMs = family->attackMs < BONK_PET_NO_SWING_MS ? family->attackMs : 0;
    if (!baseMs)
        for (BonkPetAbility const& ability : family->abilities)
        {
            bool const pulse = ability.kind == BONK_PET_ABILITY_PULSE;
            if (!pulse && ability.kind != BONK_PET_ABILITY_STRIKE && ability.kind != BONK_PET_ABILITY_CONE)
                continue;
            if (!baseMs || ability.cooldownMs < baseMs)
            {
                baseMs = ability.cooldownMs;
                if (pulses)
                    *pulses = pulse;
            }
        }
    if (!baseMs)
        return 0;

    float const pace = GetWeaponCooldown(owned) / float(std::max(1u, owned.weapon.cooldownMs));
    return std::max(BONK_PET_MIN_ATTACK_MS, uint32(baseMs * pace));
}

std::string BonkRun::GetPetAttackLabel(OwnedWeapon const& owned) const
{
    bool pulses = false;
    GetPetAttackMs(owned, &pulses);
    return GetString(pulses ? BONK_STRING_INTERVAL_PULSES : BONK_STRING_INTERVAL_ATTACKS);
}

float BonkRun::RollDamageSpread() const
{
    return frand(1.0f - BONK_DAMAGE_SPREAD, 1.0f + BONK_DAMAGE_SPREAD);
}

void BonkRun::AddRankGains(OwnedWeapon& owned, Offer const& offer) const
{
    bool const damageCounts = RankDamageCounts(owned);
    uint8 const count = GetRankUpgradeCount(&owned, offer.rarity);
    float const scale = GetRankDamageScale(offer.newLevel);
    owned.damageBonus += GetRankDamage(&owned, offer.rarity) * scale;
    for (uint8 i = 0; i < count; ++i)
    {
        float const step = owned.weapon.GetUpgradeStep(offer.upgrades[i]);
        if (step > 0.0f)
            owned.upgrades[offer.upgrades[i]] += step;
        else if (damageCounts)
            owned.damageBonus += BONK_RANK_SPARE_DAMAGE * scale;
    }
}

bool BonkRun::RankDamageCounts(OwnedWeapon const& owned) const
{
    if (owned.weapon.damageFraction > 0.0f || owned.weapon.healPct > 0.0f)
        return true;
    if (IsTickingKeyword(owned.weapon.applies) && owned.weapon.applyStacks)
        return true;
    float const BONK_STRENGTH_PROBE_BONUS = 100.0f;
    float upgrades[MAX_BONK_SPELL_UPGRADE] = {};
    GetSpellUpgrades(&owned, upgrades);
    WeaponStrength strength, stronger;
    if (!GetWeaponStrength(owned.weapon, owned.damageBonus, upgrades, strength))
        return false;
    GetWeaponStrength(owned.weapon, owned.damageBonus + BONK_STRENGTH_PROBE_BONUS, upgrades, stronger);
    return stronger.value - strength.value >= 0.05f;
}

float BonkRun::GetRankDamageScale(uint32 rank)
{
    return rank > BONK_RANK_FULL_DAMAGE_RANKS ? float(BONK_RANK_FULL_DAMAGE_RANKS) / float(rank) : 1.0f;
}

float BonkRun::GetRankDamage(OwnedWeapon const* owned, BonkRarity rarity) const
{
    return !owned || RankDamageCounts(*owned) ? BONK_RANK_DAMAGE[rarity] : 0.0f;
}

uint8 BonkRun::GetRankUpgradeCount(OwnedWeapon const* owned, BonkRarity rarity) const
{
    uint8 const count = !owned || RankDamageCounts(*owned) ? BONK_RANK_UPGRADES[rarity] : BONK_DAMAGELESS_RANK_UPGRADES[rarity];
    return std::min(count, BONK_MAX_RANK_UPGRADES);
}

bool BonkRun::IsWindowSpell(BonkWeapon const& weapon) const
{
    bool const window = weapon.behavior == BONK_BEHAVIOR_BLADE_FLURRY || weapon.behavior == BONK_BEHAVIOR_SHADOW_DANCE ||
        weapon.behavior == BONK_BEHAVIOR_EVASION;
    return window && weapon.durationMs > 0;
}

float BonkRun::GetWindowLengthMs(OwnedWeapon const& owned) const
{
    float const lengthMs = owned.weapon.durationMs * GetWeaponDurationScale(owned);
    if (!IsWindowSpell(owned.weapon))
        return lengthMs;
    return std::min(lengthMs, GetWeaponCooldown(owned) * BONK_WINDOW_MAX_UPTIME);
}

bool BonkRun::DurationGrowsWindow(OwnedWeapon const& owned, float const* rolled, BonkSpellUpgrade upgrade, float step) const
{
    if (upgrade != BONK_SPELL_UPGRADE_DURATION || !IsWindowSpell(owned.weapon))
        return true;
    OwnedWeapon before = owned;
    for (uint8 index = 0; index < MAX_BONK_SPELL_UPGRADE; ++index)
        before.upgrades[index] += rolled[index];
    OwnedWeapon after = before;
    after.upgrades[upgrade] += step;
    return GetWindowLengthMs(after) > GetWindowLengthMs(before) + 1.0f;
}

float BonkRun::GetShownHit(OwnedWeapon const& owned, float extraPower) const
{
    if (owned.weapon.damageFraction <= 0.0f || IsStackStrengthSpell(owned.weapon))
        return 0.0f;

    if (owned.weapon.behavior == BONK_BEHAVIOR_PET)
    {
        BonkPetFamily const* family = GetPetFamily(owned);
        if (!family)
            return 0.0f;
        float const minionScale = 1.0f + GetPackPowerShare();
        return GetPetBiteDamage(owned, *family) * GetPetSwingFactor(owned) * GetDamageMultiplier(nullptr, nullptr, minionScale, extraPower) *
            (1.0f + GetSpecDamage(owned.weapon.id) / 100.0f);
    }

    return GetWeaponDamage(owned) * GetDamageMultiplier(sSpellMgr.GetSpellEntry(owned.weapon.spellId), nullptr, 1.0f, extraPower);
}

float BonkRun::GetPetSwingFactor(OwnedWeapon const& owned) const
{
    if (owned.pets.empty())
        return 1.0f;
    for (OwnedWeapon const& held : m_weapons)
    {
        if (held.pets.empty() || held.pets.front() != owned.pets.front())
            continue;
        BonkPetFamily const* family = GetPetFamily(held);
        Creature const* pet = family ? m_player->GetMap()->GetCreature(held.pets.front()) : nullptr;
        float const bite = family ? GetPetBiteDamage(held, *family) : 0.0f;
        if (!pet || bite <= 0.0f)
            return 1.0f;
        float const swing = (pet->GetFloatValue(UNIT_FIELD_MINDAMAGE) + pet->GetFloatValue(UNIT_FIELD_MAXDAMAGE)) / 2.0f;
        float const frenzy = IsPetFrenzied() ? GetFrenzyDamage() : 1.0f;
        return swing > 0.0f ? swing / (bite * frenzy) : 1.0f;
    }
    return 1.0f;
}

float BonkRun::GetShownTick(OwnedWeapon const& owned, float extraPower) const
{
    if (!IsTickingKeyword(owned.weapon.applies) || !owned.weapon.applyStacks)
        return 0.0f;
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(owned.weapon.applies);
    if (!info)
        return 0.0f;
    float const scale = 1.0f + (owned.damageBonus + GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_PET_DAMAGE)) / 100.0f;
    float const strength = IsStackStrengthSpell(owned.weapon) ? std::max(1.0f, owned.weapon.damageFraction) : 1.0f;
    float const points = GetDotTickDamage(*info) * scale * strength;
    return points * GetDamageMultiplier(sSpellMgr.GetSpellEntry(info->spellId), nullptr, 1.0f, extraPower);
}

std::string BonkRun::DescribeShownRange(OwnedWeapon const& owned, float extraPower) const
{
    if (float const hit = GetShownHit(owned, extraPower))
        return DescribeRange(hit, GetShownSpread(owned), GetLocale());
    if (float const tick = GetShownTick(owned, extraPower))
        return GetString(BONK_STRING_TICK_PER_STACK, { ShownTick(tick) });
    return "";
}

std::string BonkRun::DescribeShownDamage(OwnedWeapon const& owned) const
{
    std::string text;
    if (float const hit = GetShownHit(owned, 0.0f))
    {
        if (owned.weapon.behavior == BONK_BEHAVIOR_PET)
            text = GetString(BONK_STRING_PET_ATTACKS_DEAL, { DescribeRange(hit, BONK_PET_SWING_SPREAD, GetLocale()) });
        else
            text = GetString(BONK_STRING_SCHOOL_DAMAGE, { DescribeRange(hit, BONK_DAMAGE_SPREAD, GetLocale()),
                GetSchoolName(sSpellMgr.GetSpellEntry(owned.weapon.spellId), GetLocale()) });
    }
    if (float const tick = GetShownTick(owned, 0.0f))
        if (BonkKeywordInfo const* info = sBonkMgr.GetKeyword(owned.weapon.applies))
        {
            std::string const ticks = GetString(BONK_STRING_SCHOOL_DAMAGE_TICK_PER_STACK, { ShownTick(tick),
                GetSchoolName(sSpellMgr.GetSpellEntry(info->spellId), GetLocale()), Localize(BONK_FIELD_KEYWORD_NAME, uint32(info->id), info->name) });
            text = text.empty() ? ticks : GetString(BONK_STRING_LIST_ITEM, { text, ticks });
        }
    return text;
}

void BonkRun::DescribeOfferDamage(Offer const& offer, std::string& before, std::string& after, std::string& label) const
{
    before.clear();
    after.clear();
    label.clear();
    if (offer.isCard)
        return;

    if (!offer.isWeapon)
        return;

    BonkWeapon const* weapon = sBonkMgr.GetWeapon(offer.id);
    if (!weapon)
        return;

    if (offer.step == BONK_STEP_NEW)
    {
        OwnedWeapon fresh;
        fresh.weapon = *weapon;
        after = DescribeShownRange(fresh);
        return;
    }

    OwnedWeapon const* owned = FindOwned(offer.id);
    if (!owned)
        return;
    OwnedWeapon next = *owned;
    if (offer.step == BONK_STEP_EVOLVE)
    {
        BonkWeapon const* evolved = sBonkMgr.GetWeapon(offer.evolveTo);
        if (!evolved)
            return;
        next.weapon = *evolved;
    }
    else if (offer.step == BONK_STEP_RANK && offer.rarity < BONK_RARITY_LEGENDARY)
        AddRankGains(next, offer);
    else
        return;

    before = DescribeShownRange(*owned);
    after = DescribeShownRange(next);
    if (before == after)
        before.clear();
}

void BonkRun::AddCurvedTotal(BonkPassiveEffect effect, float gain, std::vector<BonkStatChange>& stats) const
{
    float const ceiling = effect == BONK_PASSIVE_HASTE ? BONK_MAX_HASTE : effect == BONK_PASSIVE_AREA ? BONK_MAX_AREA : 0.0f;
    if (ceiling <= 0.0f)
        return;
    float const raw = GetPassiveTotal(effect);
    float const before = CurveStat(raw, ceiling);
    float const after = CurveStat(raw + gain, ceiling);
    bool const fine = std::lround(before) == std::lround(after);
    auto percent = [fine](float value)
    {
        char text[16];
        snprintf(text, sizeof(text), fine ? "%.1f%%" : "%.0f%%", value);
        return std::string(text);
    };
    stats.push_back({ GetString(effect == BONK_PASSIVE_HASTE ? BONK_STRING_TOTAL_HASTE : BONK_STRING_TOTAL_AREA), percent(before), percent(after) });
}

void BonkRun::DescribeOfferStats(Offer const& offer, std::vector<BonkStatChange>& stats) const
{
    stats.clear();
    if (offer.isCard)
        return;

    if (!offer.isWeapon)
    {
        if (BonkPassive const* passive = sBonkMgr.GetPassive(offer.id))
        {
            sBonkMgr.DescribePassiveStats(*passive, offer.newLevel, stats, GetLocale());
            if (!stats.empty())
                AddCurvedTotal(BonkPassiveEffect(passive->effect), passive->valuePerRank * passive->RankWeight(offer.newLevel), stats);
        }
        return;
    }

    if (offer.newLevel <= 1)
        return;

    if (offer.step != BONK_STEP_RANK || offer.rarity >= BONK_RARITY_LEGENDARY)
        return;
    OwnedWeapon const* owned = FindOwned(offer.id);
    if (!owned)
        return;
    OwnedWeapon next = *owned;
    AddRankGains(next, offer);

    AddDamageStats(*owned, next, stats);
    bool const hasDamage = !stats.empty();

    float now[MAX_BONK_SPELL_UPGRADE] = {};
    float after[MAX_BONK_SPELL_UPGRADE] = {};
    GetSpellUpgrades(owned, now);
    GetSpellUpgrades(&next, after);
    WeaponStrength before, strength;
    if (GetWeaponStrength(owned->weapon, owned->damageBonus, now, before) &&
        GetWeaponStrength(next.weapon, next.damageBonus, after, strength) && std::fabs(strength.value - before.value) >= 0.05f)
    {
        bool const signed_ = strength.folded == BONK_SPELL_UPGRADE_MARK || strength.folded == BONK_SPELL_UPGRADE_SLOWED;
        stats.push_back({ GetString(strength.label), ShownPercent(before.value, signed_), ShownPercent(strength.value, signed_) });
    }

    AddUpgradeStats(*owned, next, hasDamage, stats);
}

void BonkRun::AddDamageStats(OwnedWeapon const& owned, OwnedWeapon const& next, std::vector<BonkStatChange>& stats) const
{
    float const hit = GetShownHit(next, 0.0f);
    if (hit > 0.0f)
        stats.push_back({ GetString(BONK_STRING_STAT_DAMAGE), ShownNumber(GetShownHit(owned, 0.0f)), ShownNumber(hit) });

    float const tick = GetShownTick(next, 0.0f);
    if (tick <= 0.0f)
        return;
    std::string const tickBefore = ShownTick(GetShownTick(owned, 0.0f));
    std::string const tickAfter = ShownTick(tick);
    if (tickBefore == tickAfter)
        return;
    if (BonkKeywordInfo const* info = sBonkMgr.GetKeyword(next.weapon.applies))
        stats.push_back({ GetString(BONK_STRING_KEYWORD_DAMAGE_PER_STACK, { Localize(BONK_FIELD_KEYWORD_NAME, uint32(info->id), info->name) }),
            tickBefore, tickAfter });
}

void BonkRun::AddUpgradeStats(OwnedWeapon const& owned, OwnedWeapon const& next, bool hasDamage, std::vector<BonkStatChange>& stats) const
{
    float now[MAX_BONK_SPELL_UPGRADE] = {};
    float after[MAX_BONK_SPELL_UPGRADE] = {};
    GetSpellUpgrades(&owned, now);
    GetSpellUpgrades(&next, after);
    WeaponStrength strength;
    bool const strengthens = GetWeaponStrength(next.weapon, next.damageBonus, after, strength);
    BonkWeapon const& weapon = next.weapon;

    for (uint8 index = BONK_SPELL_UPGRADE_NONE + 1; index < MAX_BONK_SPELL_UPGRADE; ++index)
    {
        BonkSpellUpgrade const upgrade = BonkSpellUpgrade(index);
        if (after[upgrade] - now[upgrade] < 0.001f)
            continue;
        if (strengthens && upgrade == strength.folded)
            continue;
        if (upgrade == BONK_SPELL_UPGRADE_PET_DAMAGE && hasDamage)
            continue;

        switch (upgrade)
        {
            case BONK_SPELL_UPGRADE_HASTE:
                if (weapon.behavior == BONK_BEHAVIOR_PET)
                {
                    if (uint32 const attackMs = GetPetAttackMs(owned))
                        stats.push_back({ GetPetAttackLabel(owned), ShownSeconds(float(attackMs), GetLocale()), ShownSeconds(float(GetPetAttackMs(next)), GetLocale()) });
                }
                else
                    stats.push_back({ GetIntervalLabel(weapon, GetLocale()), ShownSeconds(float(GetWeaponCooldown(owned)), GetLocale()),
                        ShownSeconds(float(GetWeaponCooldown(next)), GetLocale()) });
                break;
            case BONK_SPELL_UPGRADE_DURATION:
                if (weapon.durationMs > 0)
                {
                    BonkStatChange stat = SplitUpgradeText(weapon, upgrade, now[upgrade], after[upgrade], GetLocale());
                    stats.push_back({ stat.label, ShownSeconds(GetWindowLengthMs(owned), GetLocale()), ShownSeconds(GetWindowLengthMs(next), GetLocale()) });
                }
                else
                    stats.push_back(SplitUpgradeText(weapon, upgrade, now[upgrade], after[upgrade], GetLocale()));
                break;
            case BONK_SPELL_UPGRADE_STACKS:
            {
                BonkKeywordInfo const* info = sBonkMgr.GetKeyword(weapon.applies);
                uint32 const base = std::max<uint32>(1, weapon.applyStacks);
                std::string const effect = info ? Localize(BONK_FIELD_KEYWORD_NAME, uint32(info->id), info->name) : GetString(BONK_STRING_STACKS_EFFECT);
                stats.push_back({ GetString(BONK_STRING_KEYWORD_STACKS_PER_HIT, { effect }), std::to_string(base + uint32(now[upgrade])),
                    std::to_string(base + uint32(after[upgrade])) });
                break;
            }
            case BONK_SPELL_UPGRADE_ECHO:
                stats.push_back({ GetString(BONK_STRING_EXTRA_CASTS), FormatNumber(now[upgrade], "%g"), FormatNumber(after[upgrade], "%g") });
                break;
            case BONK_SPELL_UPGRADE_TARGETS:
                stats.push_back({ GetString(BONK_STRING_ENEMIES_AFFECTED), std::to_string(weapon.baseTargets + uint32(now[upgrade])),
                    std::to_string(weapon.baseTargets + uint32(after[upgrade])) });
                break;
            case BONK_SPELL_UPGRADE_REACH:
                stats.push_back({ GetString(BONK_STRING_STAT_RANGE), GetString(BONK_STRING_YARDS, { FormatNumber(weapon.range * GetWeaponArea(owned), "%.1f") }),
                    GetString(BONK_STRING_YARDS, { FormatNumber(weapon.range * GetWeaponArea(next), "%.1f") }) });
                break;
            case BONK_SPELL_UPGRADE_DEPLOY:
                stats.push_back({ GetString(BONK_STRING_DEPLOY_RANGE), GetString(BONK_STRING_YARDS, { "+" + FormatNumber(now[upgrade], "%g") }),
                    GetString(BONK_STRING_YARDS, { "+" + FormatNumber(after[upgrade], "%g") }) });
                break;
            default:
            {
                BonkStatChange stat = SplitUpgradeText(weapon, upgrade, now[upgrade], after[upgrade], GetLocale());
                if (!stat.label.empty())
                    stats.push_back(stat);
                break;
            }
        }
    }
}

std::string BonkRun::GetShownSchool(OwnedWeapon const& owned) const
{
    std::string school = GetBonkMagicSchoolName(owned.weapon.spellId, GetLocale());
    if (!school.empty() || owned.weapon.behavior != BONK_BEHAVIOR_PET)
        return school;
    BonkPetFamily const* family = GetPetFamily(owned);
    if (!family)
        return school;
    for (BonkPetAbility const& ability : family->abilities)
    {
        school = GetBonkMagicSchoolName(ability.spellId, GetLocale());
        if (!school.empty())
            return school;
    }
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(family->applies);
    return info ? GetBonkMagicSchoolName(info->spellId, GetLocale()) : school;
}

std::string BonkRun::DescribeFormRanges(OwnedWeapon const& owned, OwnedWeapon const& fresh, std::string text) const
{
    float const hit = GetShownHit(owned, 0.0f);
    if (hit <= 0.0f)
        return text;
    bool const better = hit > GetShownHit(fresh, 0.0f) * BONK_SHOWN_BETTER;
    for (size_t form = size_t(BonkDruidForm::Moonkin); form <= size_t(BonkDruidForm::Tree); ++form)
    {
        if (IsHeartOfTheWild() && BonkDruidForm(form) != GetAttackForm())
            continue;
        FormTooltip const shown = GetFormTooltip(BonkDruidForm(form));
        std::string const label = std::string(shown.label) + ":";
        size_t const start = text.find(label);
        if (start == std::string::npos)
            continue;
        size_t const end = text.find(BONK_LINE_BREAK, start);
        std::string const needle = std::string("for ") + shown.school + " damage";
        size_t const at = text.find(needle, start);
        if (at != std::string::npos && (end == std::string::npos || at < end))
            text.replace(at, needle.size(), "for " + MarkRange(hit * shown.share, GetShownSpread(owned), better, LOCALE_enUS) + " " + shown.school + " damage");
        text.replace(start, label.size(), std::string(shown.label) + " (" + TrimNumber(shown.range * GetWeaponArea(owned)) + " yd range):");
    }
    return text;
}

std::string BonkRun::DescribeLiveSpell(OwnedWeapon const& owned, std::string text) const
{
    BonkWeapon const& weapon = owned.weapon;
    OwnedWeapon fresh = owned;
    fresh.rank = 1;
    fresh.damageBonus = 0.0f;
    fresh.rarities.clear();
    for (float& upgrade : fresh.upgrades)
        upgrade = 0.0f;

    bool const pet = weapon.behavior == BONK_BEHAVIOR_PET;
    if (IsShapeshift(owned))
        text = DescribeFormRanges(owned, fresh, text);
    else if (float const hit = GetShownHit(owned, 0.0f))
    {
        std::string const range = MarkRange(hit, GetShownSpread(owned), hit > GetShownHit(fresh, 0.0f) * BONK_SHOWN_BETTER, GetLocale());
        std::string const school = GetSchoolName(sSpellMgr.GetSpellEntry(weapon.spellId), GetLocale());
        if (pet)
            text += " " + GetString(BONK_STRING_PET_ATTACKS_DEAL_SENTENCE, { range });
        else if (!InsertDamageRange(text, school, range))
            text += " " + GetString(BONK_STRING_SCHOOL_DAMAGE_SENTENCE, { range, school });
    }

    BonkKeyword keyword = weapon.applies;
    uint32 baseStacks = weapon.applyStacks;
    if (pet && keyword == BONK_KEYWORD_NONE)
        if (BonkPetFamily const* family = GetPetFamily(owned))
        {
            keyword = family->applies;
            baseStacks = family->applyStacks;
        }
    BonkKeywordInfo const* info = sBonkMgr.GetKeyword(keyword);
    if (info && baseStacks)
    {
        uint32 const stacks = std::min<uint32>(baseStacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS)), std::max<uint32>(baseStacks, info->maxStacks));
        std::string marked = MarkNumber(std::to_string(stacks), stacks > baseStacks);
        if (baseStacks != 1 || stacks == 1 || !ReplaceAtWordStart(text, "1 stack ", marked + " stacks "))
            MarkNumberFollowedBy(text, std::to_string(baseStacks), " stack", marked);
    }
    std::string keywordLine;
    if (float const tick = GetShownTick(owned, 0.0f))
        if (info)
        {
            bool const better = tick > GetShownTick(fresh, 0.0f) * BONK_SHOWN_BETTER;
            std::vector<std::string> args = { Localize(BONK_FIELD_KEYWORD_NAME, uint32(info->id), info->name), MarkNumber(ShownNumber(tick), better),
                GetSchoolName(sSpellMgr.GetSpellEntry(info->spellId), GetLocale()) };
            if (keyword == BONK_KEYWORD_AGONY)
            {
                float const peakSeconds = GetAgonyPeakTicks() * info->tickMs / GetHasteRate() / 1000.0f;
                args.push_back(MarkNumber(ShownNumber(tick * GetAgonyPeakScale()), better));
                args.push_back(MarkNumber(TrimNumber(peakSeconds), GetHasteRate() > BONK_SHOWN_BETTER));
            }
            keywordLine = "|n|n" + GetString(keyword == BONK_KEYWORD_AGONY ? BONK_STRING_KEYWORD_TICK_LINE_RISING : BONK_STRING_KEYWORD_TICK_LINE, args);
        }

    if (weapon.durationMs)
    {
        float const scale = GetWindowLengthMs(owned) / weapon.durationMs;
        std::string const base = TrimNumber(weapon.durationMs / 1000.0f);
        std::string const marked = MarkNumber(TrimNumber(weapon.durationMs * scale / 1000.0f), scale > BONK_SHOWN_BETTER);
        if (!MarkNumberAfter(text, "for ", base, marked))
            MarkNumberAfter(text, "lasts ", base, marked);
    }

    if (weapon.HasFlag(BONK_WEAPON_FLAG_AOE))
    {
        float const area = GetWeaponArea(owned);
        float const radius = weapon.radius > 0.0f ? weapon.radius : weapon.range;
        std::string const base = TrimNumber(radius);
        if (area > BONK_SHOWN_BETTER && radius > 0.0f)
            MarkNumberAfter(text, "within ", base, MarkNumber(TrimNumber(radius * area), true));
    }

    uint32 const targets = GetWeaponTargets(owned);
    if (weapon.HasTargets() && targets > 1)
    {
        std::string const marked = MarkNumber(std::to_string(targets), targets > weapon.baseTargets);
        if (weapon.baseTargets <= 1 || !MarkTargetCount(text, std::to_string(weapon.baseTargets), marked))
        {
            std::string sentence = weapon.DescribeTargets(targets, GetLocale());
            MarkNumberFollowedBy(sentence, std::to_string(targets), " ", marked);
            text += " " + sentence;
        }
    }
    return text + keywordLine;
}

std::string BonkRun::DescribeSpellHeader(OwnedWeapon const& owned, uint32 intervalMs, bool& better) const
{
    BonkWeapon const& weapon = owned.weapon;
    better = !weapon.IsBlink() && GetWeaponCooldown(owned) < weapon.cooldownMs;
    auto seconds = [this](uint32 ms) { return GetString(BONK_STRING_SECONDS_SHORT, { TrimNumber(ms / 1000.0f) }); };
    if (weapon.behavior == BONK_BEHAVIOR_ROLLING_THUNDER || weapon.IsSeal())
        return "";
    if (weapon.behavior == BONK_BEHAVIOR_PET)
    {
        bool pulses = false;
        uint32 const attackMs = GetPetAttackMs(owned, &pulses);
        return attackMs ? GetString(pulses ? BONK_STRING_HEADER_PULSES_EVERY : BONK_STRING_HEADER_ATTACKS_EVERY, { seconds(attackMs) }) : "";
    }
    if (weapon.IsBlink())
        return GetString(BONK_STRING_HEADER_COOLDOWN, { seconds(intervalMs) });
    if (weapon.behavior == BONK_BEHAVIOR_DEEP_WOUNDS)
        return GetString(BONK_STRING_HEADER_ONCE_EVERY_PER_ENEMY, { seconds(intervalMs) });
    if (weapon.IsRevenge())
        return GetString(BONK_STRING_HEADER_ONCE_EVERY, { seconds(intervalMs) });
    if (weapon.behavior == BONK_BEHAVIOR_BLOOD_AURA)
        return GetString(BONK_STRING_HEADER_PULSES_EVERY, { seconds(intervalMs) });
    return GetString(BONK_STRING_HEADER_COOLDOWN, { seconds(intervalMs) });
}
