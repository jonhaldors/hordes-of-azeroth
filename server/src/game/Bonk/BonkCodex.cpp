#include "BonkCodex.h"
#include "BonkLocale.h"
#include "BonkMastery.h"
#include "BonkMgr.h"
#include "BonkPlayer.h"
#include "BonkQuests.h"
#include "BonkRun.h"
#include "Creature.h"
#include "CreatureAI.h"
#include "Database/DatabaseEnv.h"
#include "GameObject.h"
#include "HoaProtocol.h"
#include "ObjectMgr.h"
#include "Player.h"
#include "ScriptMgr.h"
#include "ScriptedGossip.h"
#include "WorldSession.h"

#include <string>

namespace
{
    void SendCodex(BonkPlayer* bonk, std::string const& line)
    {
        if (!bonk->IsAddonReady())
            return;
        size_t const split = line.find('~');
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteCodex(data, split == std::string::npos ? line : line.substr(0, split),
            split == std::string::npos ? "" : line.substr(split + 1));
        bonk->GetPlayer()->GetSession()->SendPacket(&data);
    }

    uint32 const BONK_TEXT_SPELLBOOK = 900006;

    std::string Number(float value)
    {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), value >= 10.0f ? "%.0f" : "%.2f", value);
        std::string text = buffer;
        if (text.find('.') != std::string::npos)
        {
            while (text.back() == '0')
                text.pop_back();
            if (text.back() == '.')
                text.pop_back();
        }
        return text;
    }

    std::string ChanceNumber(float value)
    {
        char buffer[32];
        snprintf(buffer, sizeof(buffer), "%.1f", value);
        std::string text = buffer;
        if (text.size() > 2 && text.compare(text.size() - 2, 2, ".0") == 0)
            text.resize(text.size() - 2);
        return text;
    }

    BonkString GetStatGainText(BonkPassiveEffect stat)
    {
        switch (stat)
        {
            case BONK_PASSIVE_POWER:        return BONK_STRING_STAT_GAIN_POWER;
            case BONK_PASSIVE_HASTE:        return BONK_STRING_STAT_GAIN_HASTE;
            case BONK_PASSIVE_MOVE_SPEED:   return BONK_STRING_STAT_GAIN_MOVE_SPEED;
            case BONK_PASSIVE_MAX_HEALTH:   return BONK_STRING_STAT_GAIN_MAX_HEALTH;
            case BONK_PASSIVE_RECOVERY:     return BONK_STRING_STAT_GAIN_RECOVERY;
            case BONK_PASSIVE_GROWTH:       return BONK_STRING_STAT_GAIN_GROWTH;
            case BONK_PASSIVE_AREA:         return BONK_STRING_STAT_GAIN_AREA;
            case BONK_PASSIVE_ARMOR:        return BONK_STRING_STAT_GAIN_ARMOR;
            case BONK_PASSIVE_DODGE:        return BONK_STRING_STAT_GAIN_DODGE;
            case BONK_PASSIVE_CRIT:         return BONK_STRING_STAT_GAIN_CRIT;
            case BONK_PASSIVE_CRIT_DAMAGE:  return BONK_STRING_STAT_GAIN_CRIT_DAMAGE;
            case BONK_PASSIVE_SHIELD:       return BONK_STRING_STAT_GAIN_SHIELD;
            case BONK_PASSIVE_AMOUNT:       return BONK_STRING_STAT_GAIN_COUNT;
            case BONK_PASSIVE_PICKUP:       return BONK_STRING_STAT_GAIN_PICKUP;
            case BONK_PASSIVE_LUCK:         return BONK_STRING_STAT_GAIN_LUCK;
            default:                        return BONK_STRING_STAT_GAIN;
        }
    }

    std::string DescribeStat(BonkPassiveEffect stat, float value, LocaleConstant locale)
    {
        return sBonkLocale.GetString(GetStatGainText(stat), locale, { Number(value) });
    }

    std::string DescribeCardStack(BonkCard const& card, uint32 copies, LocaleConstant locale)
    {
        float const sum = BonkRun::GetCopySum(copies);
        auto text = [locale](BonkString id, float value) { return sBonkLocale.GetString(id, locale, { Number(value) }); };
        auto chance = [&]() { return sBonkLocale.GetString(BONK_STRING_CARD_CHANCE, locale, { ChanceNumber(BonkRun::GetStackedChance(card.values[0], copies)) }); };
        auto cooldown = [&]() { return text(BONK_STRING_CARD_COOLDOWN, card.cooldownMs * BonkRun::GetCopyWeight(copies) / 1000.0f); };
        switch (card.effect)
        {
            case BONK_CARD_HEALTHSTONE:
            case BONK_CARD_HIT_IMMUNE:
            case BONK_CARD_SWIFTNESS:
            case BONK_CARD_MAGNET:
                return cooldown();
            case BONK_CARD_BANDAGE:
            case BONK_CARD_CAMPFIRE:
                return text(BONK_STRING_STAT_GAIN_RECOVERY, card.values[0] * sum);
            case BONK_CARD_JERKY:
                return sBonkLocale.GetString(BONK_STRING_CARD_TURKEY_LEGS, locale, { Number(card.values[0] * sum), Number(card.values[1] * sum) });
            case BONK_CARD_CRIT_HEAL:
                return sBonkLocale.GetString(BONK_STRING_CARD_UP_TO_HEALTH_A_SECOND, locale, { chance(), Number(card.values[2] * sum) });
            case BONK_CARD_OVERHEAL:
                return text(BONK_STRING_CARD_SHIELD_UP_TO, card.values[0] * sum);
            case BONK_CARD_THORNS:
                return text(BONK_STRING_CARD_THORNS, card.values[0] * sum);
            case BONK_CARD_FIRE_BURST:
            case BONK_CARD_CHAIN:
            case BONK_CARD_DEATH_RAY:
            case BONK_CARD_ECHO:
            case BONK_CARD_FREE_CHEST:
            case BONK_CARD_SHADOW_BURST:
                return chance();
            case BONK_CARD_HASTE_BURST:
                return sBonkLocale.GetString(BONK_STRING_CARD_CHANCE_AND_HASTE, locale, { chance(), Number(card.values[1] * sum) });
            case BONK_CARD_KILL_POWER:
            case BONK_CARD_UNHIT_POWER:
                return text(BONK_STRING_CARD_UP_TO_POWER, card.values[1] * sum);
            case BONK_CARD_POWER_SURGE:
                return text(BONK_STRING_STAT_GAIN_POWER, card.values[0] * sum);
            case BONK_CARD_BIG_GAME:
                if (card.values[1] > 0.0f)
                    return sBonkLocale.GetString(BONK_STRING_CARD_DAMAGE_LESS_DAMAGE_TAKEN, locale,
                        { Number(card.values[0] * sum), Number(std::min(BonkRun::GetChampionMaxReduction(), card.values[1] * sum)) });
                return text(BONK_STRING_CARD_DAMAGE, card.values[0] * sum);
            case BONK_CARD_VALOR:
                return text(BONK_STRING_CARD_VALOR, card.values[0] * sum);
            case BONK_CARD_DOT_DAMAGE:
                return text(BONK_STRING_CARD_DOT_DAMAGE, card.values[0] * sum);
            default:
                break;
        }
        std::string stats;
        for (uint8 i = 0; i < 2; ++i)
            if (card.stats[i] < MAX_BONK_PASSIVE_EFFECT)
            {
                float value = card.statValues[i] * BonkRun::GetStatCopySum(card.stats[i], copies);
                float const cap = BonkRun::GetPassiveCap(card.stats[i]);
                if (cap > 0.0f)
                    value = std::min(value, cap);
                std::string const stat = DescribeStat(card.stats[i], value, locale);
                stats = stats.empty() ? stat : sBonkLocale.GetString(BONK_STRING_LIST_ITEM, locale, { stats, stat });
            }
        return stats;
    }

    BonkKeywordInfo const& KeywordOrBlank(BonkKeyword id)
    {
        static BonkKeywordInfo const blank{};
        BonkKeywordInfo const* info = sBonkMgr.GetKeyword(id);
        return info ? *info : blank;
    }

    std::string Seconds(LocaleConstant locale, uint32 ms)
    {
        return sBonkLocale.GetString(BONK_STRING_SECONDS_SHORT, locale, { Number(ms / 1000.0f) });
    }

    class RulesPage
    {
    public:
        RulesPage(BonkPlayer* bonk, BonkString section) : m_bonk(bonk), m_section(bonk->GetString(section)) {}
        RulesPage& Line(BonkString text, std::vector<std::string> const& args = {})
        {
            return Send(std::string(), m_bonk->GetString(text, args));
        }
        RulesPage& Term(BonkString term, BonkString text, std::vector<std::string> const& args = {})
        {
            return Send(m_bonk->GetString(term), m_bonk->GetString(text, args));
        }

    private:
        RulesPage& Send(std::string const& term, std::string const& text)
        {
            SendCodex(m_bonk,"cdxr~" + m_section + "~" + term + "~" + text);
            return *this;
        }

        BonkPlayer* m_bonk;
        std::string m_section;
    };

    void SendStatRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_STATS)
            .Term(BONK_STRING_STAT_POWER, BONK_STRING_RULE_POWER)
            .Term(BONK_STRING_STAT_MAX_HEALTH, BONK_STRING_RULE_MAX_HEALTH)
            .Term(BONK_STRING_STAT_CRIT_CHANCE, BONK_STRING_RULE_CRIT_CHANCE, { Number(BONK_BASE_CRIT) })
            .Term(BONK_STRING_STAT_CRIT_DAMAGE, BONK_STRING_RULE_CRIT_DAMAGE)
            .Term(BONK_STRING_STAT_HASTE, BONK_STRING_RULE_HASTE, { Number(BONK_MAX_HASTE), Number(BONK_MAX_GEAR_HASTE) })
            .Term(BONK_STRING_STAT_AREA, BONK_STRING_RULE_AREA, { Number(BONK_MAX_AREA) })
            .Term(BONK_STRING_STAT_COUNT, BONK_STRING_RULE_COUNT, { Number(BONK_MAX_COUNT) })
            .Term(BONK_STRING_STAT_DODGE, BONK_STRING_RULE_DODGE, { Number(BONK_MAX_DODGE) })
            .Term(BONK_STRING_STAT_ARMOR, BONK_STRING_RULE_ARMOR)
            .Term(BONK_STRING_STAT_SHIELD, BONK_STRING_RULE_SHIELD, { Seconds(bonk->GetLocale(), BONK_SHIELD_REGEN_DELAY_MS) })
            .Term(BONK_STRING_STAT_LEECH, BONK_STRING_RULE_LEECH)
            .Term(BONK_STRING_STAT_HEALTH_REGENERATION, BONK_STRING_RULE_HEALTH_REGENERATION)
            .Term(BONK_STRING_STAT_LUCK, BONK_STRING_RULE_LUCK)
            .Term(BONK_STRING_STAT_PICKUP_RANGE, BONK_STRING_RULE_PICKUP_RANGE)
            .Term(BONK_STRING_STAT_MOVEMENT_SPEED, BONK_STRING_RULE_MOVEMENT_SPEED, { Number(BONK_MAX_MOVE_SPEED) })
            .Term(BONK_STRING_STAT_GOLD, BONK_STRING_RULE_GOLD)
            .Term(BONK_STRING_STAT_EXPERIENCE, BONK_STRING_RULE_EXPERIENCE)
            .Term(BONK_STRING_STAT_DETERMINATION, BONK_STRING_RULE_DETERMINATION,
                { Number(BONK_DETERMINATION_PER_STACK), std::to_string(uint32(BONK_DETERMINATION_MAX_STACKS)) });
    }

    void SendStackingRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_STACKING)
            .Line(BONK_STRING_RULE_STACKING_TOTAL)
            .Line(BONK_STRING_RULE_STACKING_CAPS)
            .Line(BONK_STRING_RULE_STACKING_POWER)
            .Line(BONK_STRING_RULE_STACKING_TARGET)
            .Line(BONK_STRING_RULE_STACKING_COPIES)
            .Line(BONK_STRING_RULE_STACKING_TRINKETS);
    }

    void SendSpellRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_SPELLS)
            .Term(BONK_STRING_TERM_COOLDOWN, BONK_STRING_RULE_COOLDOWN)
            .Term(BONK_STRING_TERM_RANKS, BONK_STRING_RULE_RANKS,
                { Number(BONK_RANK_DAMAGE[0]), Number(BONK_RANK_DAMAGE[1]), Number(BONK_RANK_DAMAGE[2]), Number(BONK_RANK_DAMAGE[3]) })
            .Line(BONK_STRING_RULE_EPIC_UPGRADES)
            .Line(BONK_STRING_RULE_EVOLUTIONS)
            .Line(BONK_STRING_RULE_HIT_SPREAD)
            .Line(BONK_STRING_RULE_SLOTS);
    }

    void SendDotRules(BonkPlayer* bonk)
    {
        BonkKeywordInfo const& burning = KeywordOrBlank(BONK_KEYWORD_BURNING);
        BonkKeywordInfo const& agony = KeywordOrBlank(BONK_KEYWORD_AGONY);
        RulesPage(bonk, BONK_STRING_RULES_DAMAGE_OVER_TIME)
            .Term(BONK_STRING_TERM_BASE_HEALTH, BONK_STRING_RULE_BASE_HEALTH)
            .Line(BONK_STRING_RULE_DOT_STACKS,
                { Number(burning.valuePerStack * 100.0f), Seconds(bonk->GetLocale(), burning.durationMs), std::to_string(uint32(burning.maxStacks)) })
            .Term(BONK_STRING_TERM_AGONY, BONK_STRING_RULE_AGONY,
                { Number(agony.valuePerStack * 100.0f), Seconds(bonk->GetLocale(), agony.durationMs) })
            .Line(BONK_STRING_RULE_DOT_TICK)
            .Line(BONK_STRING_RULE_DOT_CRIT)
            .Line(BONK_STRING_RULE_DOT_REFRESH)
            .Line(BONK_STRING_RULE_DOT_POWER)
            .Line(BONK_STRING_RULE_DOT_SPREAD)
            .Line(BONK_STRING_RULE_DOT_BURST)
            .Line(BONK_STRING_RULE_DOT_BOSSES)
            .Line(BONK_STRING_RULE_DOT_LEECH);
    }

    void SendKeywordRules(BonkPlayer* bonk)
    {
        BonkKeywordInfo const& chill = KeywordOrBlank(BONK_KEYWORD_CHILL);
        BonkKeywordInfo const& frozen = KeywordOrBlank(BONK_KEYWORD_FROZEN);
        BonkKeywordInfo const& staticCharge = KeywordOrBlank(BONK_KEYWORD_STATIC);
        BonkKeywordInfo const& mark = KeywordOrBlank(BONK_KEYWORD_HUNTERS_MARK);
        BonkKeywordInfo const& dazed = KeywordOrBlank(BONK_KEYWORD_DAZED);
        RulesPage(bonk, BONK_STRING_RULES_KEYWORDS)
            .Term(BONK_STRING_TERM_CHILL, BONK_STRING_RULE_CHILL, { Number(chill.valuePerStack), std::to_string(uint32(chill.maxStacks)) })
            .Term(BONK_STRING_TERM_FROZEN, BONK_STRING_RULE_FROZEN, { Seconds(bonk->GetLocale(), frozen.durationMs) })
            .Term(BONK_STRING_TERM_STATIC, BONK_STRING_RULE_STATIC,
                { std::to_string(uint32(staticCharge.maxStacks)), Number(staticCharge.valuePerStack * 100.0f) })
            .Term(BONK_STRING_TERM_HUNTERS_MARK, BONK_STRING_RULE_HUNTERS_MARK, { Number(mark.valuePerStack) })
            .Term(BONK_STRING_TERM_JUDGED, BONK_STRING_RULE_JUDGED)
            .Term(BONK_STRING_TERM_DAZED, BONK_STRING_RULE_DAZED, { Number(dazed.valuePerStack), Seconds(bonk->GetLocale(), dazed.durationMs) })
            .Term(BONK_STRING_TERM_VULNERABILITIES, BONK_STRING_RULE_VULNERABILITIES, {
                Number(KeywordOrBlank(BONK_KEYWORD_FIRE_VULNERABILITY).valuePerStack), Number(KeywordOrBlank(BONK_KEYWORD_SHADOW_VULNERABILITY).valuePerStack),
                Number(KeywordOrBlank(BONK_KEYWORD_NATURE_VULNERABILITY).valuePerStack), Number(KeywordOrBlank(BONK_KEYWORD_SUNDER_ARMOR).valuePerStack) });
    }

    void SendControlRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_CROWD_CONTROL)
            .Line(BONK_STRING_RULE_STUNS)
            .Line(BONK_STRING_RULE_ROOTS)
            .Line(BONK_STRING_RULE_KNOCKBACKS)
            .Line(BONK_STRING_RULE_FEAR);
    }

    void SendSummonRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_SUMMONS)
            .Line(BONK_STRING_RULE_SUMMON_STATS)
            .Line(BONK_STRING_RULE_SUMMON_LIMITS)
            .Line(BONK_STRING_RULE_SUMMON_KEYWORD)
            .Line(BONK_STRING_RULE_SUMMON_COUNT)
            .Line(BONK_STRING_RULE_SUMMON_DURATION);
    }

    void SendProcRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_PROCS)
            .Term(BONK_STRING_TERM_TRINKETS, BONK_STRING_RULE_TRINKETS)
            .Line(BONK_STRING_RULE_PROC_NEXT_HIT)
            .Line(BONK_STRING_RULE_PROC_CHAINS)
            .Line(BONK_STRING_RULE_GLYPH_DAMAGE);
    }

    void SendGearRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_GEAR)
            .Line(BONK_STRING_RULE_GEAR_STATS)
            .Term(BONK_STRING_TERM_GEAR_TIERS, BONK_STRING_RULE_GEAR_TIERS)
            .Line(BONK_STRING_RULE_GEAR_QUALITY)
            .Line(BONK_STRING_RULE_GEAR_ROLLS)
            .Line(BONK_STRING_RULE_TRINKET_TIERS)
            .Term(BONK_STRING_TERM_SCRAP, BONK_STRING_RULE_SCRAP);
    }

    void SendSurvivalRules(BonkPlayer* bonk)
    {
        RulesPage(bonk, BONK_STRING_RULES_SURVIVAL)
            .Line(BONK_STRING_RULE_DAMAGE_ORDER)
            .Line(BONK_STRING_RULE_DASH_IMMUNE)
            .Line(BONK_STRING_RULE_HEALING_ORBS)
            .Line(BONK_STRING_RULE_HEALING_CUTS)
            .Term(BONK_STRING_TERM_REVIVES, BONK_STRING_RULE_REVIVES);
    }

    void SendRules(BonkPlayer* bonk)
    {
        SendStatRules(bonk);
        SendStackingRules(bonk);
        SendSpellRules(bonk);
        SendDotRules(bonk);
        SendKeywordRules(bonk);
        SendControlRules(bonk);
        SendSummonRules(bonk);
        SendProcRules(bonk);
        SendGearRules(bonk);
        SendSurvivalRules(bonk);
    }

    void SendLock(BonkPlayer* bonk, char const* kind, uint32 id, BonkQuestReward type)
    {
        if (BonkQuest const* quest = sBonkQuests.GetUnlockingQuest(type, id))
            SendCodex(bonk,std::string("cdxq~") + kind + "~" + std::to_string(id) + "~" + bonk->Localize(BONK_FIELD_QUEST_NAME, quest->id, quest->name) + "~" +
                bonk->Localize(BONK_FIELD_QUEST_DESCRIPTION, quest->id, quest->description) + "~" +
                std::to_string(sBonkQuests.GetProgress(bonk->GetProgressAccount(), *quest)) + "~" + std::to_string(quest->amount));
    }
}

std::string BonkCodex::DescribeCardTotal(BonkCard const& card, uint32_t copies, LocaleConstant locale)
{
    return DescribeCardStack(card, copies, locale);
}

void BonkCodex::Send(Player* player, std::string const& npc, bool deck)
{
    BonkPlayer* bonk = player->GetBonkPlayer();
    if (!bonk->IsAddonReady())
        return;

    uint32 const account = player->GetBonkPlayer()->GetProgressAccount();
    SendCodex(bonk,"cdx~" + npc + "~" + std::to_string(player->GetClassMask()) + "~" + (deck ? "1" : "0"));

    auto lockState = [account](BonkQuestReward type, uint32 id, uint32& price)
    {
        price = 0;
        return sBonkQuests.IsLocked(account, type, id) ? "1" : "0";
    };

    for (auto const& itr : sBonkMgr.GetWeapons())
    {
        BonkWeapon const& weapon = itr.second;
        std::string const id = std::to_string(weapon.id);
        uint32 price;
        std::string const locked = lockState(BONK_REWARD_WEAPON, weapon.id, price);
        SendCodex(bonk,"cdxw~" + id + "~" + bonk->Localize(BONK_FIELD_WEAPON_NAME, weapon.id, weapon.name) + "~" + weapon.icon + "~" + std::to_string(weapon.classMask) + "~" +
            std::to_string(weapon.starterClassMask | weapon.starterOptionMask) + "~" + std::to_string(weapon.evolvesFrom) + "~" + locked + "~" + std::to_string(price));
        SendCodex(bonk,"cdxwd~" + id + "~" + bonk->Localize(BONK_FIELD_WEAPON_DESCRIPTION, weapon.id, weapon.description) + "~" +
            DescribeBonkWeaponTags(weapon, GetBonkMagicSchoolName(weapon.spellId, bonk->GetLocale()), bonk->GetLocale()) + "~" +
            std::to_string(BonkMastery::GetSpec(weapon.id)));
        if (locked == "1")
            SendLock(bonk, "w", weapon.id, BONK_REWARD_WEAPON);
    }

    for (auto const& itr : sBonkMgr.GetPassives())
    {
        BonkPassive const& passive = itr.second;
        uint32 price;
        std::string const locked = lockState(BONK_REWARD_PASSIVE, passive.id, price);
        SendCodex(bonk,"cdxp~" + std::to_string(passive.id) + "~" + bonk->Localize(BONK_FIELD_PASSIVE_NAME, passive.id, passive.name) + "~" + passive.icon + "~" +
            std::to_string(passive.maxRank) + "~" + locked + "~" + sBonkMgr.DescribePassive(passive, 1, bonk->GetLocale()) + "~" + std::to_string(price));
        if (locked == "1")
            SendLock(bonk, "p", passive.id, BONK_REWARD_PASSIVE);
    }

    for (auto const& itr : sBonkMgr.GetCards())
    {
        BonkCard const& card = itr.second;
        if (!card.inChests)
            continue;
        uint32 price;
        std::string const locked = lockState(BONK_REWARD_CARD, card.id, price);
        std::string const id = std::to_string(card.id);
        SendCodex(bonk,"cdxc~" + id + "~" + bonk->Localize(BONK_FIELD_CARD_NAME, card.id, card.name) + "~" + card.icon + "~" + std::to_string(uint32(card.rarity)) + "~" +
            std::to_string(uint32(card.maxCopies)) + "~" + locked + "~" + std::to_string(price));
        SendCodex(bonk,"cdxcd~" + id + "~" + bonk->Localize(BONK_FIELD_CARD_DESCRIPTION, card.id, card.description));
        std::string const one = DescribeCardStack(card, 1, bonk->GetLocale());
        if (card.maxCopies != 1 && !one.empty())
            SendCodex(bonk,"cdxcs~" + id + "~" + one + "~" + DescribeCardStack(card, 5, bonk->GetLocale()));
        if (locked == "1")
            SendLock(bonk, "c", card.id, BONK_REWARD_CARD);
    }

    bonk->TrimPoolToggles();
    for (BonkQuestReward type : { BONK_REWARD_CARD, BONK_REWARD_GLYPH })
    {
        char const* kind = type == BONK_REWARD_CARD ? "c" : "g";
        SendCodex(bonk,"cdxpool~" + std::string(kind) + "~" + std::to_string(sBonkQuests.CountDisabled(account, type)) + "~" +
            std::to_string(bonk->GetBanSlots(type)));
        for (BonkPlayer::BanSource const& source : bonk->GetBanSources(type))
            SendCodex(bonk,"cdxban~" + std::string(kind) + "~" + (source.earned ? "1" : "0") + "~" + std::to_string(source.tickets) + "~" +
                source.label + "~" + source.detail);
    }
    SendCodex(bonk,"cdxtickets~" + std::to_string(bonk->GetShards()));
    for (auto const& off : sBonkQuests.GetDisabled(account))
    {
        char const* kind = off.first == BONK_REWARD_WEAPON ? "w" : off.first == BONK_REWARD_PASSIVE ? "p" : off.first == BONK_REWARD_CARD ? "c" : "g";
        SendCodex(bonk,"cdxoff~" + std::string(kind) + "~" + std::to_string(off.second));
    }

    for (auto const& itr : sBonkMgr.GetGlyphs())
    {
        uint32 price;
        std::string const locked = lockState(BONK_REWARD_GLYPH, itr.first, price);
        SendCodex(bonk,"cdxg~" + std::to_string(itr.first) + "~" + locked + "~" + std::to_string(price));
        if (locked == "1")
            SendLock(bonk, "g", itr.first, BONK_REWARD_GLYPH);
    }

    for (auto const& itr : sBonkMgr.GetKeywords())
    {
        BonkKeywordInfo const& keyword = itr.second;
        if (!keyword.description.empty())
            SendCodex(bonk,"cdxk~" + std::to_string(uint32(keyword.id)) + "~" + bonk->Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword.id), keyword.name) + "~" +
                keyword.icon + "~" + std::to_string(uint32(keyword.maxStacks)) + "~" + std::to_string(keyword.durationMs) + "~" +
                bonk->Localize(BONK_FIELD_KEYWORD_DESCRIPTION, uint32(keyword.id), keyword.description));
    }

    SendRules(bonk);
    SendCodex(bonk,"cdxend");
}

void BonkCodex::SendTermGlossary(BonkPlayer* bonk)
{
    std::unique_ptr<QueryResult> result(WorldDatabase.Query("SELECT `term`, `words`, `keyword`, `description` FROM `bonk_glossary` ORDER BY `sort`, `term`"));
    if (!result)
        return;
    do
    {
        Field* fields = result->Fetch();
        std::string description = fields[3].GetCppString();
        if (uint32 const keywordId = fields[2].GetUInt32())
            if (BonkKeywordInfo const* keyword = sBonkMgr.GetKeyword(BonkKeyword(keywordId)))
                description = bonk->Localize(BONK_FIELD_KEYWORD_DESCRIPTION, keywordId, keyword->description);
        if (!description.empty())
            SendCodex(bonk,"gls~" + fields[0].GetCppString() + "~" + fields[1].GetCppString() + "~" + description);
    } while (result->NextRow());
}

void BonkCodex::SendKeywordGlossary(BonkPlayer* bonk)
{
    for (auto const& itr : sBonkMgr.GetKeywords())
    {
        BonkKeywordInfo const& keyword = itr.second;
        std::string const id = std::to_string(uint32(keyword.id));
        std::string const name = bonk->Localize(BONK_FIELD_KEYWORD_NAME, uint32(keyword.id), keyword.name);
        if (!keyword.description.empty())
            SendCodex(bonk,"kwd~" + id + "~" + name + "~" + keyword.icon + "~" + bonk->Localize(BONK_FIELD_KEYWORD_DESCRIPTION, uint32(keyword.id), keyword.description));
        SendCodex(bonk,"kwdaura~" + id + "~" + name + "~" + keyword.icon + "~" + std::to_string(keyword.spellId) + "~" +
            std::to_string(uint32(keyword.maxStacks)));
    }
    SendTermGlossary(bonk);
}

namespace
{
    uint32 const BONK_SHELF_BROWSE_MS = 10000;
    uint32 const BONK_SHELF_KNEEL_MS  = 4000;
    uint32 const BONK_SHELF_PONDER_MS = 3000;

    class BonkShelfKeeperAI : public CreatureAI
    {
        public:
            explicit BonkShelfKeeperAI(Creature* creature) : CreatureAI(creature)
            {
                Browse();
            }

            void MoveInLineOfSight(Unit*) override {}
            void AttackStart(Unit*) override {}
            void EnterEvadeMode() override {}

            void UpdateAI(uint32 const diff) override
            {
                if (m_timer > diff)
                {
                    m_timer -= diff;
                    return;
                }
                switch (m_step)
                {
                    case STEP_BROWSE:
                        Kneel();
                        break;
                    case STEP_KNEEL:
                        Ponder();
                        break;
                    default:
                        Browse();
                        break;
                }
            }

        private:
            enum Step
            {
                STEP_BROWSE,
                STEP_KNEEL,
                STEP_PONDER
            };

            void Browse()
            {
                m_creature->SetStandState(UNIT_STAND_STATE_STAND);
                m_creature->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_STATE_USESTANDING_NOSHEATHE);
                m_step = STEP_BROWSE;
                m_timer = BONK_SHELF_BROWSE_MS;
            }

            void Kneel()
            {
                m_creature->SetUInt32Value(UNIT_NPC_EMOTESTATE, EMOTE_ONESHOT_NONE);
                m_creature->SetStandState(UNIT_STAND_STATE_KNEEL);
                m_step = STEP_KNEEL;
                m_timer = BONK_SHELF_KNEEL_MS;
            }

            void Ponder()
            {
                m_creature->SetStandState(UNIT_STAND_STATE_STAND);
                m_creature->HandleEmote(EMOTE_ONESHOT_QUESTION);
                m_step = STEP_PONDER;
                m_timer = BONK_SHELF_PONDER_MS;
            }

            Step m_step = STEP_BROWSE;
            uint32 m_timer = 0;
    };
}

CreatureAI* GetAI_npc_bonk_codex(Creature* creature)
{
    return new BonkShelfKeeperAI(creature);
}

bool GossipHello_npc_bonk_codex(Player* player, Creature* creature)
{
    if (player->GetBonkPlayer()->IsAddonReady())
        player->GetBonkPlayer()->SendNpcName(creature);
    BonkCodex::Send(player, player->GetBonkPlayer()->IsAddonReady() ? player->GetBonkPlayer()->GetLocalName(creature) : "");
    player->SEND_GOSSIP_MENU(BONK_TEXT_SPELLBOOK, creature->GetObjectGuid());
    return true;
}

bool GOHello_go_bonk_deck(Player* player, GameObject* go)
{
    BonkPlayer* bonk = player->GetBonkPlayer();
    if (bonk->GetRun())
        return true;
    bonk->VisitDeck(go);
    BonkCodex::Send(player, go->GetName(), true);
    return true;
}

void AddSC_bonk_codex()
{
    Script* newscript = new Script;
    newscript->Name = "npc_bonk_codex";
    newscript->pGossipHello = &GossipHello_npc_bonk_codex;
    newscript->GetAI = &GetAI_npc_bonk_codex;
    newscript->RegisterSelf();

    newscript = new Script;
    newscript->Name = "go_bonk_deck";
    newscript->pGOHello = &GOHello_go_bonk_deck;
    newscript->RegisterSelf();
}
