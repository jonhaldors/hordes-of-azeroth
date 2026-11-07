#include "BonkPlayer.h"
#include "BonkLocale.h"
#include "BonkMastery.h"
#include "BonkMgr.h"
#include "BonkQuests.h"
#include "Database/DatabaseEnv.h"
#include "HoaProtocol.h"
#include "Player.h"
#include "WorldSession.h"

#include <algorithm>

namespace
{
    bool IsDefaultStarter(BonkWeapon const& weapon, uint32 classMask)
    {
        return (weapon.starterClassMask & classMask) != 0;
    }

    std::string DescribeStarterUnlock(BonkPlayer const* bonk, BonkMasteryNode const& node)
    {
        if (BonkMasteryTree const* tree = sBonkMastery.GetTree(node.tree))
            return bonk->GetString(BONK_STRING_LEARN_IN_TALENTS_TO_UNLOCK, { bonk->Localize(BONK_FIELD_MASTERY_NAME, node.id, node.name),
                bonk->Localize(BONK_FIELD_MASTERY_TREE_NAME, tree->id, tree->name) });
        return bonk->GetString(BONK_STRING_LEARN_TO_UNLOCK, { bonk->Localize(BONK_FIELD_MASTERY_NAME, node.id, node.name) });
    }

    std::string DescribeSpellUnlock(BonkPlayer const* bonk, uint32 weaponId)
    {
        if (BonkQuest const* quest = sBonkQuests.GetUnlockingQuest(BONK_REWARD_WEAPON, weaponId))
            return bonk->GetString(BONK_STRING_FINISH_QUEST_FIRST, { bonk->Localize(BONK_FIELD_QUEST_NAME, quest->id, quest->name) });
        return bonk->GetString(BONK_STRING_UNLOCK_IT_FIRST);
    }
}

void BonkPlayer::LoadStarter()
{
    m_starterChoice = 0;
    std::unique_ptr<QueryResult> result(CharacterDatabase.PQuery("SELECT `weapon` FROM `bonk_account_starter` WHERE `account` = %u AND `class` = %u",
        m_player->GetBonkPlayer()->GetCharacterAccount(), uint32(m_player->GetClass())));
    if (result)
        m_starterChoice = result->Fetch()[0].GetUInt32();
}

std::vector<BonkPlayer::StarterOption> BonkPlayer::GetStarterOptions() const
{
    uint32 const classMask = m_player->GetClassMask();
    uint32 const account = m_player->GetBonkPlayer()->GetProgressAccount();
    std::vector<StarterOption> options;
    for (auto const& itr : sBonkMgr.GetWeapons())
    {
        BonkWeapon const& weapon = itr.second;
        if (!((weapon.starterClassMask | weapon.starterOptionMask) & classMask))
            continue;

        StarterOption option;
        option.weapon = &weapon;
        option.unlocked = true;
        if (!IsDefaultStarter(weapon, classMask))
            if (BonkMasteryNode const* node = sBonkMastery.FindStarterUnlock(m_player->GetClass(), weapon.id))
                if (!GetMasteryRank(node->id))
                {
                    option.unlocked = false;
                    option.hint = DescribeStarterUnlock(this, *node);
                }
        if (option.unlocked && sBonkQuests.IsLocked(account, BONK_REWARD_WEAPON, weapon.id))
        {
            option.unlocked = false;
            option.hint = DescribeSpellUnlock(this, weapon.id);
        }
        options.push_back(option);
    }

    std::stable_sort(options.begin(), options.end(), [classMask](StarterOption const& a, StarterOption const& b)
    {
        bool const defaultA = IsDefaultStarter(*a.weapon, classMask);
        bool const defaultB = IsDefaultStarter(*b.weapon, classMask);
        if (defaultA != defaultB)
            return defaultA;
        return a.weapon->id < b.weapon->id;
    });
    return options;
}

BonkWeapon const* BonkPlayer::GetStarterWeapon() const
{
    std::vector<StarterOption> const options = GetStarterOptions();
    for (StarterOption const& option : options)
        if (option.unlocked && option.weapon->id == m_starterChoice)
            return option.weapon;
    return options.empty() ? nullptr : options.front().weapon;
}

bool BonkPlayer::ChooseStarter(uint32 weaponId, std::string& error)
{
    for (StarterOption const& option : GetStarterOptions())
    {
        if (option.weapon->id != weaponId)
            continue;
        if (!option.unlocked)
        {
            error = option.hint;
            return false;
        }
        m_starterChoice = weaponId;
        CharacterDatabase.PExecute("REPLACE INTO `bonk_account_starter` (`account`, `class`, `weapon`) VALUES (%u, %u, %u)",
            m_player->GetBonkPlayer()->GetCharacterAccount(), uint32(m_player->GetClass()), weaponId);
        SendStarters();
        return true;
    }
    error = GetString(BONK_STRING_NOT_A_STARTER_SPELL);
    return false;
}

void BonkPlayer::SendStarters() const
{
    if (!m_addonReady)
        return;
    BonkWeapon const* chosen = GetStarterWeapon();
    for (StarterOption const& option : GetStarterOptions())
    {
        BonkWeapon const& weapon = *option.weapon;
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteStarter(data, weapon.id, weapon.icon, Localize(BONK_FIELD_WEAPON_NAME, weapon.id, weapon.name), option.unlocked,
            &weapon == chosen, option.hint, Localize(BONK_FIELD_WEAPON_DESCRIPTION, weapon.id, weapon.description));
        m_player->GetSession()->SendPacket(&data);
    }
    WorldPacket end(SMSG_HOA_MESSAGE);
    HoAWriteStarterEnd(end);
    m_player->GetSession()->SendPacket(&end);
}
