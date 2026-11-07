#include "BonkRun.h"
#include "BonkMastery.h"
#include "BonkPlayer.h"
#include "BonkRunStats.h"
#include "Creature.h"
#include "HoaProtocol.h"
#include "Map.h"
#include "Player.h"
#include "SpellAuras.h"
#include "SpellMgr.h"
#include "Utilities/Random.h"
#include "WorldSession.h"

#include <algorithm>
#include <set>

namespace
{
    uint32 const BONK_WEAPON_MOONFIRE         = 1002;
    uint32 const BONK_WEAPON_HURRICANE        = 1003;
    uint32 const BONK_WEAPON_RAKE             = 1004;
    uint32 const BONK_WEAPON_SHRED            = 1005;
    uint32 const BONK_WEAPON_SWIPE            = 1006;
    uint32 const BONK_WEAPON_FRENZIED_REGENERATION = 1007;
    uint32 const BONK_WEAPON_REJUVENATION     = 1008;
    uint32 const BONK_WEAPON_FORCE_OF_NATURE  = 1009;
    uint32 const BONK_WEAPON_ENTANGLING_ROOTS = 1010;
    uint32 const BONK_WEAPON_TRANQUILITY      = 1011;
    uint32 const BONK_WEAPON_THORNS           = 1012;
    uint32 const BONK_WEAPON_SHAPESHIFT       = 1013;

    uint32 const BONK_SHAPESHIFT_COOLDOWN_MS  = 500;
    float const BONK_MOONFIRE_IMPACT_SHARE    = 0.4f;
    float const BONK_FORM_SPLASH_RADIUS       = 5.0f;
    uint32 const BONK_STARFALL_EVERY_MS       = 3000;
    float const BONK_STARFALL_SHARE           = 1.5f;
    float const BONK_STARFALL_RANGE           = 30.0f;
    size_t const BONK_STARFALL_STARS          = 3;
    size_t const BONK_ALIGNMENT_EXTRA_STARS   = 2;
    float const BONK_PRIMAL_FURY_BEAR_TAKEN   = 0.8f;
    float const BONK_HEART_OF_THE_WILD_PER_TREE = 0.15f;
    float const BONK_HEART_OF_THE_WILD_ATTACK = 0.65f;
    uint32 const BONK_SPELL_STARFALL_LOOK     = 2912;
    float const BONK_CAT_MOVE_SPEED           = 15.0f;
    uint32 const BONK_CAT_CRIT_BLEED          = 1;
    float const BONK_BRAWLER_PER_ENEMY        = 0.08f;
    float const BONK_BRAWLER_RADIUS           = 8.0f;
    uint32 const BONK_BRAWLER_MAX_ENEMIES     = 8;
    uint32 const BONK_ROAR_EVERY_MS           = 6000;
    uint32 const BONK_ROAR_MS                 = 4000;
    float const BONK_ROAR_RADIUS              = 10.0f;
    float const BONK_ROAR_REDUCTION           = 25.0f;
    uint32 const BONK_KIT_ROAR_CAST           = 3372;
    uint32 const BONK_KIT_ROAR_IMPACT         = 693;
    size_t const BONK_ROAR_LOOKS              = 6;
    float const BONK_TREE_REJUVENATION_PACE   = 0.67f;
    uint32 const BONK_THORNS_MOONFIRE         = 2;
    uint32 const BONK_BLOOM_HASTE_MS          = 3000;
    uint32 const BONK_TREE_EXTRA_TREANTS      = 1;
    uint32 const BONK_KIT_SHAPESHIFT_SMOKE    = 3610;
    uint32 const BONK_KIT_TREANT_SPROUT       = 7504;
    uint32 const BONK_KIT_NATURE_CAST         = 3291;
    uint32 const BONK_KIT_ARCANE_CAST         = 730;
    uint32 const BONK_DRUID_MOTION_GAP_MS     = 500;
    uint32 const BONK_CLAW_LOOK_GAP_MS        = 500;
    uint32 const BONK_KIT_CLAW_IMPACT         = 220;
    uint32 const BONK_KIT_MAUL_IMPACT         = 290;
    uint32 const BONK_KIT_STILL_RAKE          = 7410;
    uint32 const BONK_KIT_STILL_CLAW          = 7411;
    uint32 const BONK_KIT_STILL_SWIPE         = 7413;
    uint32 const BONK_KIT_STILL_MAUL          = 7414;
    uint32 const BONK_SPELL_CLAW_LOOK         = 1082;
    uint32 const BONK_SPELL_RAKE_LOOK         = 1822;
    uint32 const BONK_SPELL_SHRED_LOOK        = 5221;
    uint32 const BONK_SPELL_SWIPE_LOOK        = 779;
    uint32 const BONK_SPELL_MAUL_LOOK         = 6807;
    uint32 const BONK_SHAPESHIFT_SMOKE_DELAY_MS = 100;
    float const BONK_RIGHT_FORM_BONUS         = 1.3f;
    float const BONK_SPIRIT_SHARE             = 0.25f;
    float const BONK_BEAR_DAMAGE              = 0.8f;

    struct FormAttack
    {
        uint32 spellId;
        uint32 creditSpellId;
        float share;
        float cooldownScale;
        uint32 targets;
        float range;
        uint32 bleedStacks;
        float healPerHit;
        float splashShare;
        char const* name;
    };

    FormAttack const BONK_FORM_ATTACKS[] =
    {
        { 0,    0,     0.0f, 1.0f,  0, 0.0f,  0, 0.0f,  0.0f, "caster" },
        { 5176, 5176,  1.5f, 1.0f,  1, 30.0f, 0, 0.0f,  0.45f, "moonkin" },
        { 1082, 1082,  1.4f, 0.67f, 1, 10.0f, 1, 0.0f,  0.4f, "cat" },
        { 6807, 6807,  1.8f, 1.0f,  1, 10.0f, 0, 0.0f,  0.1f, "bear" },
        { 5570, 16689, 0.8f, 1.0f,  3, 20.0f, 0, 0.3f,  0.2f, "tree" },
    };

    uint32 const BONK_SPELL_FRENZIED_REGEN    = 22842;
    uint32 const BONK_SPELL_THORNS            = 467;
    uint32 const BONK_SPELL_BLOOM_LASH        = 5570;
    uint32 const BONK_SPELL_HURRICANE_LOOK    = 16914;
    uint32 const BONK_SPELL_TREANT_ROOTS      = 339;
    float const BONK_TREANT_ROOT_RADIUS       = 5.0f;

    uint32 const BONK_DISPLAY_MOONKIN_ALLIANCE = 15374;
    uint32 const BONK_DISPLAY_MOONKIN_HORDE   = 15375;
    uint32 const BONK_DISPLAY_CAT_ALLIANCE    = 892;
    uint32 const BONK_DISPLAY_CAT_HORDE       = 8571;
    uint32 const BONK_DISPLAY_BEAR_ALLIANCE   = 2281;
    uint32 const BONK_DISPLAY_BEAR_HORDE      = 2289;
    uint32 const BONK_DISPLAY_TREE            = 864;


    float const BONK_BEAR_TAKEN               = 0.65f;

    float const BONK_SHRED_MAX_STACKS         = 30.0f;
    float const BONK_FRENZIED_REGEN_MAX_ENEMIES = 5.0f;
    float const BONK_SURVIVAL_HEALTH          = 35.0f;
    uint32 const BONK_DRUID_LOOK_GAP_MS       = 3000;
    uint32 const BONK_ROOT_MS                 = 2000;
    uint32 const BONK_TRANQUILITY_PULSES      = 4;
    uint32 const BONK_TRANQUILITY_PULSE_MS    = 1000;
    uint32 const BONK_KIT_TRANQUILITY_PULSE   = 7415;
    uint32 const BONK_THORNS_PER_SEC          = 5;
    uint32 const BONK_HURRICANE_MS            = 4000;
    int32 const BONK_HURRICANE_PULSE_MS       = 1000;
    size_t const BONK_HURRICANE_ALIVE         = 2;
    size_t const BONK_SWIPE_LOOKS             = 4;
    float const BONK_SWIPE_PER_BLEED          = 0.1f;
    float const BONK_SWIPE_MAX_BLEEDS         = 10.0f;
    float const BONK_DRUID_AWARE_RANGE        = 30.0f;
    int32 const BONK_DRUID_POLL_MS            = 250;
    uint32 const BONK_DRUID_IDLE_MS           = 1000;


    FormAttack const& GetFormAttack(BonkRun::BonkDruidForm form)
    {
        return BONK_FORM_ATTACKS[size_t(form)];
    }
}

bool BonkRun::IsDruidAnimal() const
{
    return m_druidForm == BonkDruidForm::Cat || m_druidForm == BonkDruidForm::Bear;
}

void BonkRun::PlayDruidMotion(uint32 spellId)
{
    if (!IsDruidHero() || !m_player->IsAlive() || m_totalMs - m_druidMotionMs < BONK_DRUID_MOTION_GAP_MS)
        return;
    m_druidMotionMs = m_totalMs;
    if (IsDruidAnimal())
        return;
    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(spellId);
    bool const arcane = spellInfo && spellInfo->School == SPELL_SCHOOL_ARCANE;
    m_player->SendPlaySpellVisualKit(arcane ? BONK_KIT_ARCANE_CAST : BONK_KIT_NATURE_CAST);
}

uint32 BonkRun::GetClawImpactKit(uint32 spellId) const
{
    switch (spellId)
    {
        case BONK_SPELL_CLAW_LOOK:
        case BONK_SPELL_RAKE_LOOK:
        case BONK_SPELL_SHRED_LOOK:
        case BONK_SPELL_SWIPE_LOOK:
            return BONK_KIT_CLAW_IMPACT;
        case BONK_SPELL_MAUL_LOOK:
            return BONK_KIT_MAUL_IMPACT;
        default:
            return 0;
    }
}

uint32 BonkRun::GetStillClawKit(uint32 spellId) const
{
    switch (spellId)
    {
        case BONK_SPELL_RAKE_LOOK:
        case BONK_SPELL_SHRED_LOOK:
            return BONK_KIT_STILL_RAKE;
        case BONK_SPELL_CLAW_LOOK:
            return BONK_KIT_STILL_CLAW;
        case BONK_SPELL_SWIPE_LOOK:
            return BONK_KIT_STILL_SWIPE;
        case BONK_SPELL_MAUL_LOOK:
            return BONK_KIT_STILL_MAUL;
        default:
            return 0;
    }
}

void BonkRun::ShowDruidStrike(SpellEntry const* look, Creature* target)
{
    if (!look || !target)
        return;
    uint32 const impact = GetClawImpactKit(look->Id);
    if (!impact)
    {
        ShowStrike(m_player, look, target);
        return;
    }
    bool const clawReady = !m_druidClawLookMs || m_totalMs - m_druidClawLookMs >= BONK_CLAW_LOOK_GAP_MS;
    if (clawReady)
        m_druidClawLookMs = m_totalMs;
    if (clawReady && IsDruidAnimal())
    {
        ShowStrike(m_player, look, target);
        return;
    }
    if (clawReady)
        m_player->SendPlaySpellVisualKit(GetStillClawKit(look->Id));
    target->SendPlaySpellVisualKit(impact);
}

void BonkRun::OnDruidStrike(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target)
{
    if (!(owned.weapon.classMask & (1 << (CLASS_DRUID - 1))))
        return;
    PlayDruidMotion(owned.weapon.spellId);
    OnStarfireStrike(owned, spellInfo, target);
}

bool BonkRun::IsDruidHero() const
{
    return m_player->GetClass() == CLASS_DRUID;
}

void BonkRun::ResetDruidState()
{
    m_druidLookMs.clear();
    m_thornsTimes.clear();
    m_tranquilityPulsesLeft = 0;
    m_tranquilityPulseMs = 0;
    m_tranquilityWeapon = 0;
    m_druidForm = BonkDruidForm::None;
    m_shapeshiftReadyMs = 0;
    m_shapeshiftSmokeAtMs = 0;
    m_druidMotionMs = 0;
    m_druidClawLookMs = 0;
    m_sentDruidForm.clear();
    m_sentDruidSlots.clear();
    m_starfallReadyMs = 0;
    m_roarReadyMs = 0;
    m_tranquilityPulse = 0;
    m_formCycleMs = m_formCycleAtMs = 0;
    ResetDruidEvolutions();
    if (IsDruidHero() && m_player->GetBonkPlayer()->IsAddonReady())
    {
        WorldPacket data(SMSG_HOA_MESSAGE);
        HoAWriteDruidForm(data, "caster");
        m_player->GetSession()->SendPacket(&data);
    }
    if (IsDruidHero() && m_player->GetDisplayId() != m_player->GetNativeDisplayId())
        m_player->SetDisplayId(m_player->GetNativeDisplayId());
}

bool BonkRun::FireDruidSpell(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    switch (owned.weapon.behavior)
    {
        case BONK_BEHAVIOR_MOONFIRE:         CastMoonfire(owned, spellInfo); break;
        case BONK_BEHAVIOR_HURRICANE:        CallHurricane(owned); break;
        case BONK_BEHAVIOR_RAKE:             RakeEnemies(owned, spellInfo); break;
        case BONK_BEHAVIOR_SHRED:            ShredEnemy(owned, spellInfo); break;
        case BONK_BEHAVIOR_SWIPE:            SwipeAround(owned, spellInfo); break;
        case BONK_BEHAVIOR_FRENZIED_REGENERATION: RegenerateFrenzied(owned); break;
        case BONK_BEHAVIOR_REJUVENATION:     BloomRejuvenation(owned, spellInfo); break;
        case BONK_BEHAVIOR_ENTANGLING_ROOTS: EntangleEnemies(owned, spellInfo); break;
        case BONK_BEHAVIOR_TRANQUILITY:      StartTranquility(owned); break;
        case BONK_BEHAVIOR_THORNS:           owned.timer = BONK_DRUID_IDLE_MS; break;
        case BONK_BEHAVIOR_SHAPESHIFT:       FireFormAttack(owned); break;
        default:                             return false;
    }
    return true;
}

std::vector<Creature*> BonkRun::GetDruidTargets(float range) const
{
    std::vector<Creature*> mobs;
    for (Creature* mob : GetMobsInRange(range))
        if (SurvivesBoltsInFlight(mob) && m_player->IsWithinLOSInMap(mob))
            mobs.push_back(mob);
    return mobs;
}

bool BonkRun::IsDruidNear() const
{
    return !GetMobsInRange(BONK_DRUID_AWARE_RANGE).empty();
}

bool BonkRun::TakeDruidLookSlot(uint32 weaponId)
{
    uint32& lastMs = m_druidLookMs[weaponId];
    if (lastMs && m_totalMs - lastMs < BONK_DRUID_LOOK_GAP_MS)
        return false;
    lastMs = m_totalMs;
    return true;
}

float BonkRun::HealDruid(OwnedWeapon const& owned, float percent)
{
    if (!m_player->IsAlive() || percent <= 0.0f)
        return 0.0f;
    SupportScope scope(*this, WeaponSupport(owned));
    float const scaled = percent * GetDruidFormScale(owned);
    uint32 const heal = ReduceHealing(std::max(1u, uint32(m_player->GetMaxHealth() * scaled / 100.0f)));
    uint32 const missing = m_player->GetMaxHealth() - m_player->GetHealth();
    HealHero(heal, owned.weapon.spellId);
    return heal > missing ? float(heal - missing) / float(heal) : 0.0f;
}

BonkRun::OwnedWeapon BonkRun::ScaleForForm(OwnedWeapon const& owned) const
{
    OwnedWeapon scaled = owned;
    scaled.damageBonus = ((1.0f + owned.damageBonus / 100.0f) * GetDruidFormScale(owned) - 1.0f) * 100.0f;
    return scaled;
}

BonkRun::BonkDruidForm BonkRun::GetDruidSpellForm(uint32 rootId) const
{
    switch (rootId)
    {
        case BONK_WEAPON_STARFIRE:
        case BONK_WEAPON_MOONFIRE:
        case BONK_WEAPON_HURRICANE:
            return BonkDruidForm::Moonkin;
        case BONK_WEAPON_RAKE:
        case BONK_WEAPON_SHRED:
            return BonkDruidForm::Cat;
        case BONK_WEAPON_SWIPE:
        case BONK_WEAPON_FRENZIED_REGENERATION:
        case BONK_WEAPON_THORNS:
            return BonkDruidForm::Bear;
        case BONK_WEAPON_REJUVENATION:
        case BONK_WEAPON_FORCE_OF_NATURE:
        case BONK_WEAPON_ENTANGLING_ROOTS:
        case BONK_WEAPON_TRANQUILITY:
            return BonkDruidForm::Tree;
        default:
            return BonkDruidForm::None;
    }
}

float BonkRun::GetDruidFormScale(OwnedWeapon const& owned) const
{
    if (!IsDruidHero() || !(owned.weapon.classMask & (1 << (CLASS_DRUID - 1))))
        return 1.0f;
    if (m_druidForm == BonkDruidForm::None && !IsHeartOfTheWild())
        return 1.0f;
    uint32 const root = GetRootWeapon(owned.weapon);
    if (root == BONK_WEAPON_SHAPESHIFT)
        return 1.0f;
    if (IsHeartOfTheWild())
        return GetHeartOfTheWildScale();
    if (GetDruidSpellForm(root) == m_druidForm)
        return BONK_RIGHT_FORM_BONUS;
    return m_druidForm == BonkDruidForm::Bear ? BONK_BEAR_DAMAGE : 1.0f;
}

BonkRun::FormTooltip BonkRun::GetFormTooltip(BonkDruidForm form) const
{
    float const share = GetFormAttack(form).share * (IsHeartOfTheWild() ? BONK_HEART_OF_THE_WILD_ATTACK : 1.0f);
    float const range = GetFormAttack(form).range;
    switch (form)
    {
        case BonkDruidForm::Moonkin: return { "Moonkin Form", "Nature", share, range };
        case BonkDruidForm::Cat:     return { "Cat Form", "Physical", share, range };
        case BonkDruidForm::Bear:    return { "Bear Form", "Physical", share, range };
        case BonkDruidForm::Tree:    return { "Tree of Life", "Nature", share, range };
        default:                     return { "", "", 0.0f, 0.0f };
    }
}

BonkRun::BonkDruidForm BonkRun::GetAttackForm() const
{
    return IsHeartOfTheWild() ? BonkDruidForm::Moonkin : m_druidForm;
}

float BonkRun::GetHeartOfTheWildScale() const
{
    std::set<uint32> trees;
    for (OwnedWeapon const& owned : m_weapons)
        if (owned.weapon.classMask & (1 << (CLASS_DRUID - 1)))
            if (uint32 const spec = BonkMastery::GetSpec(owned.weapon.id))
                trees.insert(spec);
    return 1.0f + BONK_HEART_OF_THE_WILD_PER_TREE * float(trees.size());
}

bool BonkRun::IsHeartOfTheWild() const
{
    return m_mastery.Has(BONK_CAPSTONE_HEART_OF_THE_WILD);
}

bool BonkRun::IsWildShapeshift(OwnedWeapon const& owned) const
{
    return owned.weapon.id == BONK_WEAPON_SHAPESHIFT && IsHeartOfTheWild();
}

void BonkRun::FireFormAttack(OwnedWeapon& owned)
{
    FormAttack const& attack = GetFormAttack(GetAttackForm());
    SpellEntry const* look = sSpellMgr.GetSpellEntry(attack.spellId);
    std::vector<Creature*> mobs;
    if (look)
        mobs = GetDruidTargets(attack.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = int32(GetWeaponCooldown(owned) * attack.cooldownScale);
    PlayDruidMotion(attack.spellId);
    mobs.resize(std::min<size_t>(mobs.size(), attack.targets + GetSpellCount(owned)));
    float const damage = GetWeaponDamage(owned) * attack.share * (IsHeartOfTheWild() ? BONK_HEART_OF_THE_WILD_ATTACK : 1.0f);
    std::set<ObjectGuid> splashed;
    for (Creature* mob : mobs)
        splashed.insert(mob->GetObjectGuid());
    uint32 const weaponId = owned.weapon.id;
    auto land = [this, weaponId, look, attack, damage](Creature* mob, std::set<ObjectGuid>& splashed)
    {
        OwnedWeapon* landing = FindOwned(weaponId);
        if (!landing)
            return;
        HitAsDruid(*landing, look, mob, damage, attack.creditSpellId);
        if (attack.splashShare > 0.0f)
            for (Creature* neighbor : GetMobsInRange(BONK_FORM_SPLASH_RADIUS * GetWeaponArea(*landing), mob))
                if (splashed.insert(neighbor->GetObjectGuid()).second)
                    DealShamanHit(look, attack.creditSpellId, neighbor, damage * attack.splashShare);
        if (attack.bleedStacks && mob->IsAlive())
            ApplyWeaponKeyword(*landing, mob, BONK_KEYWORD_BLEED, attack.bleedStacks);
    };
    for (Creature* mob : mobs)
    {
        if (look->speed > 0.0f)
        {
            LaunchBolt(m_player, look, mob, damage, [land, splashed](Creature* struck) mutable { land(struck, splashed); });
            continue;
        }
        ShowDruidStrike(look, mob);
        land(mob, splashed);
    }
    if (attack.healPerHit > 0.0f)
        HealDruid(owned, attack.healPerHit * mobs.size());
}

void BonkRun::ShapeshiftTo(uint32 form)
{
    if (form >= size_t(BonkDruidForm::Moonkin) && form <= size_t(BonkDruidForm::Tree))
        Shapeshift(BONK_FORM_ATTACKS[form].name);
}

void BonkRun::Shapeshift(char const* formName)
{
    if (m_state != STATE_RUNNING || !IsDruidHero() || !m_player->IsAlive() || !FindOwnedByRoot(BONK_WEAPON_SHAPESHIFT) || IsHeartOfTheWild())
        return;
    BonkDruidForm next = BonkDruidForm(size_t(m_druidForm) % size_t(BonkDruidForm::Tree) + 1);
    if (formName && *formName)
    {
        bool found = false;
        for (size_t form = size_t(BonkDruidForm::Moonkin); form <= size_t(BonkDruidForm::Tree); ++form)
            if (!strcmp(formName, BONK_FORM_ATTACKS[form].name))
            {
                next = BonkDruidForm(form);
                found = true;
            }
        if (!found)
            return;
    }
    else if (m_totalMs < m_shapeshiftReadyMs)
        return;
    m_shapeshiftReadyMs = m_totalMs + BONK_SHAPESHIFT_COOLDOWN_MS;
    BonkDruidForm const previous = m_druidForm;
    m_druidForm = next;
    UpdateDruidForm();
    ApplyPassives();
    if (previous != next)
        OnDruidShift(previous, next);
    m_shapeshiftSmokeAtMs = m_totalMs + BONK_SHAPESHIFT_SMOKE_DELAY_MS;
    if (OwnedWeapon* shapeshift = FindOwnedByRoot(BONK_WEAPON_SHAPESHIFT))
        shapeshift->timer = std::min(shapeshift->timer, BONK_DRUID_POLL_MS);
}

void BonkRun::HitAsDruid(OwnedWeapon const& owned, SpellEntry const* spellInfo, Creature* target, float damage, uint32 creditSpellId)
{
    uint32 const credit = creditSpellId ? creditSpellId : owned.weapon.spellId;
    bool crit = DealShamanHit(spellInfo, credit, target, damage);
    float const twice = GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_HIT_TWICE);
    if (twice > 0.0f && target->IsAlive() && roll_chance_f(twice))
        crit |= DealShamanHit(spellInfo, credit, target, damage);
    bool const clawsBleed = m_druidForm == BonkDruidForm::Cat;
    if (crit && clawsBleed && target->IsAlive())
        ApplyWeaponKeyword(owned, target, BONK_KEYWORD_BLEED, BONK_CAT_CRIT_BLEED);
}

float BonkRun::GetBrawlerScale() const
{
    if (m_druidForm != BonkDruidForm::Bear)
        return 1.0f;
    size_t const crowd = std::min<size_t>(GetMobsInRange(BONK_BRAWLER_RADIUS).size(), BONK_BRAWLER_MAX_ENEMIES);
    return 1.0f + BONK_BRAWLER_PER_ENEMY * float(crowd);
}

void BonkRun::DropStarfall()
{
    OwnedWeapon const* shapeshift = FindOwnedByRoot(BONK_WEAPON_SHAPESHIFT);
    bool const aligned = m_mastery.Has(BONK_CAPSTONE_CELESTIAL_ALIGNMENT);
    bool const formFalls = m_druidForm == BonkDruidForm::Moonkin || (aligned && m_druidForm != BonkDruidForm::None);
    if (!formFalls || !shapeshift || !m_player->IsAlive() || m_totalMs < m_starfallReadyMs)
        return;
    if (CallStarfall(*shapeshift, BONK_STARFALL_STARS + (aligned ? BONK_ALIGNMENT_EXTRA_STARS : 0)))
        m_starfallReadyMs = m_totalMs + BONK_STARFALL_EVERY_MS;
}

size_t BonkRun::CallStarfall(OwnedWeapon const& shapeshift, size_t stars)
{
    std::vector<Creature*> moonfired;
    for (Creature* mob : GetDruidTargets(BONK_STARFALL_RANGE))
        if (GetKeywordStacks(mob, BONK_KEYWORD_MOONFIRE))
            moonfired.push_back(mob);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_STARFALL_LOOK);
    float const damage = GetWeaponDamage(shapeshift) * BONK_STARFALL_SHARE;
    size_t fallen = 0;
    for (; fallen < stars && !moonfired.empty(); ++fallen)
    {
        size_t const pick = urand(0, uint32(moonfired.size() - 1));
        Creature* target = moonfired[pick];
        moonfired.erase(moonfired.begin() + pick);
        ShowStrike(m_player, look, target);
        DealShamanHit(look, shapeshift.weapon.spellId, target, damage);
    }
    return fallen;
}

uint32 BonkRun::GetSpiritAttackMs(OwnedWeapon const& shapeshift, BonkDruidForm form) const
{
    return uint32(GetWeaponCooldown(shapeshift) * GetFormAttack(form).cooldownScale);
}

void BonkRun::StrikeAsSpirit(OwnedWeapon const& shapeshift, Creature* spirit, BonkDruidForm form)
{
    FormAttack const& attack = GetFormAttack(form);
    SpellEntry const* look = sSpellMgr.GetSpellEntry(attack.spellId);
    if (!look)
        return;
    std::vector<Creature*> mobs = GetMobsInRange(attack.range * GetWeaponArea(shapeshift), spirit);
    mobs.erase(std::remove_if(mobs.begin(), mobs.end(), [this, spirit](Creature* mob) { return !SurvivesBoltsInFlight(mob) || !spirit->IsWithinLOSInMap(mob); }), mobs.end());
    mobs.resize(std::min<size_t>(mobs.size(), attack.targets + GetSpellCount(shapeshift)));
    float const damage = GetWeaponDamage(shapeshift) * attack.share * BONK_SPIRIT_SHARE;
    std::set<ObjectGuid> splashed;
    for (Creature* mob : mobs)
        splashed.insert(mob->GetObjectGuid());
    uint32 const weaponId = shapeshift.weapon.id;
    for (Creature* mob : mobs)
        LaunchBolt(spirit, look, mob, damage, [this, weaponId, look, attack, damage, splashed](Creature* struck) mutable
        {
            OwnedWeapon* landing = FindOwned(weaponId);
            if (!landing)
                return;
            DealShamanHit(look, attack.creditSpellId, struck, damage);
            if (attack.splashShare > 0.0f)
                for (Creature* neighbor : GetMobsInRange(BONK_FORM_SPLASH_RADIUS * GetWeaponArea(*landing), struck))
                    if (splashed.insert(neighbor->GetObjectGuid()).second)
                        DealShamanHit(look, attack.creditSpellId, neighbor, damage * attack.splashShare);
            if (attack.bleedStacks && struck->IsAlive())
                ApplyWeaponKeyword(*landing, struck, BONK_KEYWORD_BLEED, attack.bleedStacks);
        });
}

void BonkRun::RoarAsBear()
{
    OwnedWeapon const* shapeshift = FindOwnedByRoot(BONK_WEAPON_SHAPESHIFT);
    if (m_druidForm != BonkDruidForm::Bear || !shapeshift || !m_player->IsAlive() || m_totalMs < m_roarReadyMs)
        return;
    std::vector<Creature*> const mobs = GetMobsInRange(BONK_ROAR_RADIUS * GetWeaponArea(*shapeshift));
    if (mobs.empty())
        return;
    m_roarReadyMs = m_totalMs + BONK_ROAR_EVERY_MS;
    m_player->SendPlaySpellVisualKit(BONK_KIT_ROAR_CAST);
    size_t shown = 0;
    for (Creature* mob : mobs)
    {
        ApplyTimedAuraTo(mob, BONK_SPELL_DEMORALIZING_ROAR, BONK_ROAR_MS, ADD_AURA_NEGATIVE);
        ApplyWeaponKeyword(*shapeshift, mob, BONK_KEYWORD_DAZED, 1);
        if (shown++ < BONK_ROAR_LOOKS)
            mob->SendPlaySpellVisualKit(BONK_KIT_ROAR_IMPACT);
    }
}

float BonkRun::GetDruidRoarReduction(Creature const* mob) const
{
    return mob->GetSpellAuraHolder(BONK_SPELL_DEMORALIZING_ROAR, m_player->GetObjectGuid()) ? BONK_ROAR_REDUCTION : 0.0f;
}

float BonkRun::GetDruidMoveSpeed() const
{
    if (!IsDruidHero())
        return 0.0f;
    bool const furious = m_druidForm == BonkDruidForm::Bear && m_mastery.Has(BONK_CAPSTONE_PRIMAL_FURY);
    return m_druidForm == BonkDruidForm::Cat || furious ? BONK_CAT_MOVE_SPEED : 0.0f;
}

uint32 BonkRun::GetDruidExtraPets(OwnedWeapon const& owned) const
{
    if (GetDruidPetFamily(owned) != BONK_PET_FAMILY_TREANT)
        return 0;
    uint32 const grove = uint32(m_mastery.Special(BONK_SPECIAL_GROVE_GUARDIANS));
    return grove + (m_druidForm == BonkDruidForm::Tree ? BONK_TREE_EXTRA_TREANTS : 0);
}

bool BonkRun::IsShapeshift(OwnedWeapon const& owned)
{
    return owned.weapon.behavior == BONK_BEHAVIOR_SHAPESHIFT;
}

std::string BonkRun::DescribeShapeshiftDamage() const
{
    std::string text = "nature";
    for (size_t form = size_t(BonkDruidForm::Moonkin); form <= size_t(BonkDruidForm::Tree); ++form)
    {
        BonkRunStats::Spell const stats = BonkStats::GetSpellStats(m_player->GetObjectGuid(), BONK_FORM_ATTACKS[form].creditSpellId);
        if (stats.damage)
            text += std::string("/") + BONK_FORM_ATTACKS[form].name + ":" + std::to_string(stats.damage);
    }
    return text;
}

std::string BonkRun::DescribeDruidSlots() const
{
    std::string line = "druidslots";
    for (OwnedWeapon const& owned : m_weapons)
    {
        float const scale = GetDruidFormScale(owned);
        line += scale > 1.0f ? "~g" : scale < 1.0f ? "~r" : "~n";
    }
    return line;
}

void BonkRun::CastMoonfire(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> const mobs = GetMobsInRange(GetStrikeRange(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    std::vector<Creature*> struck = mobs;
    std::stable_partition(struck.begin(), struck.end(), [this](Creature* mob) { return !GetKeywordStacks(mob, BONK_KEYWORD_MOONFIRE); });
    struck.resize(std::min<size_t>(struck.size(), GetWeaponTargets(owned)));
    float const impact = GetWeaponDamage(owned) * BONK_MOONFIRE_IMPACT_SHARE;
    for (Creature* mob : struck)
        HitAsDruid(owned, spellInfo, mob, impact);
    AddWarlockStacks(ScaleForForm(owned), spellInfo, mobs, BONK_KEYWORD_MOONFIRE, false);
    OnMoonfireStrikes(owned, struck);
}

void BonkRun::CallHurricane(OwnedWeapon& owned)
{
    float x, y, z;
    if (!FindLargestGroup(GetStrikeRange(owned), x, y, z))
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    StartKeywordCloud(owned, x, y, z);
}

bool BonkRun::GetDruidCloudKind(OwnedWeapon const& owned, KeywordCloudKind& kind) const
{
    if (GetDruidEvolvedCloudKind(owned, kind))
        return true;
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_HURRICANE)
        return false;
    kind.lifeMs = BONK_HURRICANE_MS + uint32(m_mastery.Special(BONK_SPECIAL_IMPROVED_HURRICANE) * IN_MILLISECONDS);
    kind.pulseEveryMs = BONK_HURRICANE_PULSE_MS;
    kind.stacks = owned.weapon.applyStacks;
    kind.maxAlive = BONK_HURRICANE_ALIVE;
    kind.lookSpellId = BONK_SPELL_HURRICANE_LOOK;
    return true;
}

void BonkRun::OnDruidCloudPulse(OwnedWeapon const& owned, KeywordCloud const& cloud)
{
    OnDruidEvolvedCloudPulse(owned, cloud);
    if (GetRootWeapon(owned.weapon) != BONK_WEAPON_HURRICANE)
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : GetMobsNear(cloud.x, cloud.y, cloud.radius))
        DealShamanHit(look, owned.weapon.spellId, mob, damage);
}

void BonkRun::RakeEnemies(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetDruidTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    PickRakeTargets(owned, mobs);
    uint32 const stacks = owned.weapon.applyStacks + uint32(GetSpellUpgrade(owned, BONK_SPELL_UPGRADE_STACKS));
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
    {
        ShowDruidStrike(spellInfo, mob);
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage);
        if (mob->IsAlive())
            ApplyWeaponKeyword(ScaleForForm(owned), mob, BONK_KEYWORD_BLEED, stacks);
    }
    OnRakeDone(owned, mobs.size());
}

void BonkRun::ShredEnemy(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetDruidTargets(owned.weapon.range * GetWeaponArea(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    std::stable_sort(mobs.begin(), mobs.end(), [this](Creature* a, Creature* b)
    {
        return GetKeywordStacks(a, BONK_KEYWORD_BLEED) > GetKeywordStacks(b, BONK_KEYWORD_BLEED);
    });
    size_t const wanted = std::min<size_t>(mobs.size(), GetWeaponTargets(owned));
    std::vector<Creature*> queue(mobs.begin() + wanted, mobs.end());
    mobs.resize(wanted);
    for (Creature* mob : mobs)
    {
        ShowDruidStrike(spellInfo, mob);
        HitAsDruid(owned, spellInfo, mob, GetShredDamage(owned, mob));
        OnShredHit(owned, spellInfo, mob, queue);
    }
}

float BonkRun::GetShredDamage(OwnedWeapon const& owned, Creature* mob) const
{
    float const bleeds = std::min(float(GetKeywordStacks(mob, BONK_KEYWORD_BLEED)), BONK_SHRED_MAX_STACKS);
    return GetWeaponDamage(owned) * (1.0f + owned.weapon.usesPct * bleeds / 100.0f);
}

void BonkRun::SwipeAround(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> const mobs = GetMobsInRange(GetWeaponRadius(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned) * GetBrawlerScale();
    size_t shown = 0;
    for (Creature* mob : mobs)
    {
        if (shown++ < BONK_SWIPE_LOOKS)
            ShowDruidStrike(spellInfo, mob);
        DealShamanHit(spellInfo, owned.weapon.spellId, mob, damage * GetSwipeBleedScale(mob));
    }
    OnSwipe(owned, mobs);
}

float BonkRun::GetSwipeBleedScale(Creature* mob) const
{
    float const bleeds = std::min(float(GetKeywordStacks(mob, BONK_KEYWORD_BLEED)), BONK_SWIPE_MAX_BLEEDS);
    return 1.0f + BONK_SWIPE_PER_BLEED * bleeds;
}

float BonkRun::GetFrenziedRegenerationHeal(OwnedWeapon const& owned) const
{
    return owned.weapon.healPct * (1.0f + owned.damageBonus / 100.0f);
}

void BonkRun::RegenerateFrenzied(OwnedWeapon& owned)
{
    owned.timer = GetWeaponCooldown(owned);
    if (!m_player->IsAlive())
        return;
    size_t const nearby = GetMobsInRange(GetWeaponRadius(owned)).size();
    if (!nearby)
        return;
    float const enemies = std::min(float(nearby), BONK_FRENZIED_REGEN_MAX_ENEMIES + m_mastery.Special(BONK_SPECIAL_IMPROVED_FRENZIED));
    OnFrenziedTick(owned, GetFrenziedRegenerationHeal(owned) * enemies);
    if (m_player->GetHealth() >= m_player->GetMaxHealth())
        return;
    float const fittest = m_player->GetHealthPercent() < BONK_SURVIVAL_HEALTH ? 1.0f + m_mastery.Special(BONK_SPECIAL_SURVIVAL_OF_THE_FITTEST) : 1.0f;
    HealDruid(owned, GetFrenziedRegenerationHeal(owned) * enemies * fittest);
    if (TakeDruidLookSlot(owned.weapon.id))
        if (SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_FRENZIED_REGEN))
            ShowStrike(m_player, look, m_player);
}

void BonkRun::BloomRejuvenation(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    float const pace = m_druidForm == BonkDruidForm::Tree ? BONK_TREE_REJUVENATION_PACE : 1.0f;
    owned.timer = int32(GetWeaponCooldown(owned) * pace);
    if (!m_player->IsAlive() || BloomEfflorescence(owned))
        return;
    OnRejuvenationTick(owned, spellInfo);
    if (TakeDruidLookSlot(owned.weapon.id))
        ShowStrike(m_player, spellInfo, m_player);
    if (HealDruid(owned, owned.weapon.healPct) > 0.0f)
        ApplyTimedAura(BONK_SPELL_LIFEBLOOM_HASTE, BONK_BLOOM_HASTE_MS);

    std::vector<Creature*> mobs = GetDruidTargets(owned.weapon.range * GetWeaponArea(owned));
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    SpellEntry const* lash = sSpellMgr.GetSpellEntry(BONK_SPELL_BLOOM_LASH);
    if (!mobs.empty())
        PlayDruidMotion(owned.weapon.spellId);
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
    {
        ShowStrike(m_player, lash, mob);
        HitAsDruid(owned, spellInfo, mob, damage);
    }
}

void BonkRun::EntangleEnemies(OwnedWeapon& owned, SpellEntry const* spellInfo)
{
    std::vector<Creature*> mobs = GetDruidTargets(GetStrikeRange(owned));
    if (mobs.empty())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    mobs.resize(std::min<size_t>(mobs.size(), GetWeaponTargets(owned)));
    float const damage = GetWeaponDamage(owned);
    for (Creature* mob : mobs)
    {
        ShowDruidStrike(spellInfo, mob);
        HitAsDruid(owned, spellInfo, mob, damage);
        int32 durationMs = int32(BONK_ROOT_MS + m_mastery.Special(BONK_SPECIAL_DEEP_ROOTS) * IN_MILLISECONDS);
        if (mob->IsAlive() && LimitRoot(mob, durationMs))
        {
            HoldMob(mob, spellInfo, SPELL_AURA_MOD_ROOT, durationMs);
            OnDruidRooted(owned, spellInfo, mob, true);
        }
    }
}

void BonkRun::StartTranquility(OwnedWeapon& owned)
{
    if (!IsDruidNear() || !m_player->IsAlive())
    {
        owned.timer = BONK_DRUID_POLL_MS;
        return;
    }
    owned.timer = GetWeaponCooldown(owned);
    PlayDruidMotion(owned.weapon.spellId);
    m_tranquilityWeapon = owned.weapon.id;
    m_tranquilityPulsesLeft = std::max(1u, uint32(BONK_TRANQUILITY_PULSES * GetWeaponDurationScale(owned) + 0.5f)) +
        uint32(m_mastery.Special(BONK_SPECIAL_INNER_PEACE));
    m_tranquilityPulseMs = 0;
    m_tranquilityPulse = 0;
}

void BonkRun::PulseTranquility(uint32 diff)
{
    if (!m_tranquilityPulsesLeft)
        return;
    OwnedWeapon* owned = FindOwned(m_tranquilityWeapon);
    if (!owned || !m_player->IsAlive())
    {
        m_tranquilityPulsesLeft = 0;
        return;
    }
    if (m_tranquilityPulseMs > diff)
    {
        m_tranquilityPulseMs -= diff;
        return;
    }
    m_tranquilityPulseMs = BONK_TRANQUILITY_PULSE_MS;
    --m_tranquilityPulsesLeft;

    SpellEntry const* spellInfo = sSpellMgr.GetSpellEntry(owned->weapon.spellId);
    m_player->SendPlaySpellVisualKit(BONK_KIT_TRANQUILITY_PULSE);
    float const flourish = m_tranquilityPulsesLeft ? 1.0f : 1.0f + m_mastery.Special(BONK_SPECIAL_FLOURISH);
    float const damage = GetWeaponDamage(*owned) * flourish;
    for (Creature* mob : GetMobsInRange(GetTranquilityReach(*owned)))
        DealShamanHit(spellInfo, owned->weapon.spellId, mob, damage);
    ++m_tranquilityPulse;
    OnTranquilityHeal(*owned, HealDruid(*owned, owned->weapon.healPct));
}

void BonkRun::OnDruidStruck(Creature* attacker)
{
    if (!attacker || !attacker->IsAlive() || IsPeriodicHit())
        return;
    OwnedWeapon const* thorns = FindOwnedByBehavior(BONK_BEHAVIOR_THORNS);
    if (!thorns || !TakeRateSlot(m_thornsTimes, BONK_THORNS_PER_SEC))
        return;
    SpellEntry const* look = sSpellMgr.GetSpellEntry(BONK_SPELL_THORNS);
    if (!look)
        look = sSpellMgr.GetSpellEntry(thorns->weapon.spellId);
    HitAsDruid(*thorns, look, attacker, GetWeaponDamage(*thorns));
    OnThornsStrike(*thorns, look, attacker);
    if (attacker->IsAlive())
        ApplyDruidMoonfire(*thorns, attacker, BONK_THORNS_MOONFIRE);
}

uint32 BonkRun::ApplyDruidDamageTaken(uint32 damage) const
{
    if (m_druidForm != BonkDruidForm::Bear)
        return damage;
    float const furious = m_mastery.Has(BONK_CAPSTONE_PRIMAL_FURY) ? BONK_PRIMAL_FURY_BEAR_TAKEN : 1.0f;
    return std::max(1u, uint32(damage * BONK_BEAR_TAKEN * furious));
}

uint32 BonkRun::GetDruidPetFamily(OwnedWeapon const& owned) const
{
    if (!(owned.weapon.classMask & (1 << (CLASS_DRUID - 1))))
        return 0;
    return IsAncientOfWar(owned) ? BONK_PET_FAMILY_ANCIENT : BONK_PET_FAMILY_TREANT;
}

uint32 BonkRun::GetDruidSummonKit(OwnedWeapon const& owned) const
{
    return GetDruidPetFamily(owned) ? BONK_KIT_TREANT_SPROUT : 0;
}

uint32 BonkRun::GetDruidFormDisplay(BonkDruidForm form) const
{
    bool const alliance = Player::TeamForRace(m_player->GetRace()) == ALLIANCE;
    switch (form)
    {
        case BonkDruidForm::Moonkin: return alliance ? BONK_DISPLAY_MOONKIN_ALLIANCE : BONK_DISPLAY_MOONKIN_HORDE;
        case BonkDruidForm::Cat:     return alliance ? BONK_DISPLAY_CAT_ALLIANCE : BONK_DISPLAY_CAT_HORDE;
        case BonkDruidForm::Bear:    return alliance ? BONK_DISPLAY_BEAR_ALLIANCE : BONK_DISPLAY_BEAR_HORDE;
        case BonkDruidForm::Tree:    return BONK_DISPLAY_TREE;
        default:                     return m_player->GetNativeDisplayId();
    }
}

void BonkRun::UpdateDruidForm()
{
    if (!IsDruidHero() || !m_player->IsAlive())
        return;
    bool const shifts = FindOwnedByRoot(BONK_WEAPON_SHAPESHIFT) != nullptr && !IsHeartOfTheWild();
    if (!shifts)
        m_druidForm = BonkDruidForm::None;
    else if (m_druidForm == BonkDruidForm::None)
        m_druidForm = BonkDruidForm::Moonkin;
    std::string const form = GetFormAttack(m_druidForm).name;
    std::string const sent = std::string("druidform~") + form;
    if (sent != m_sentDruidForm)
    {
        m_sentDruidForm = sent;
        if (m_player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDruidForm(data, form);
            m_player->GetSession()->SendPacket(&data);
        }
    }
    std::string const slots = DescribeDruidSlots();
    if (slots != m_sentDruidSlots)
    {
        m_sentDruidSlots = slots;
        if (m_player->GetBonkPlayer()->IsAddonReady())
        {
            WorldPacket data(SMSG_HOA_MESSAGE);
            HoAWriteDruidSlots(data, slots.size() > 11 ? slots.substr(11) : "");
            m_player->GetSession()->SendPacket(&data);
        }
    }
    uint32 const display = GetDruidFormDisplay(m_druidForm);
    if (m_player->GetDisplayId() != display)
        m_player->SetDisplayId(display);
}

void BonkRun::OnDruidPetStrike(OwnedWeapon const& owned, Creature* pet, Creature* prey)
{
    if (GetDruidPetFamily(owned) != BONK_PET_FAMILY_TREANT || !prey)
        return;
    SpellEntry const* roots = sSpellMgr.GetSpellEntry(BONK_SPELL_TREANT_ROOTS);
    if (!roots)
        return;
    std::vector<Creature*> mobs = GetMobsNear(prey->GetPositionX(), prey->GetPositionY(), BONK_TREANT_ROOT_RADIUS * GetSummonReach(owned));
    if (std::find(mobs.begin(), mobs.end(), prey) == mobs.end())
        mobs.push_back(prey);
    for (Creature* mob : mobs)
    {
        int32 durationMs = int32(BONK_ROOT_MS);
        if (mob->IsAlive() && pet->IsWithinLOSInMap(mob) && LimitRoot(mob, durationMs))
            HoldMob(mob, roots, SPELL_AURA_MOD_ROOT, durationMs);
    }
    PlantMushroom(owned, prey);
}

void BonkRun::CycleSandboxForm()
{
    if (!m_formCycleMs || int32(m_formCycleAtMs - m_totalMs) > 0)
        return;
    m_formCycleAtMs = m_totalMs + m_formCycleMs;
    Shapeshift(nullptr);
}

void BonkRun::UpdateDruid(uint32 diff)
{
    if (m_shapeshiftSmokeAtMs && m_totalMs >= m_shapeshiftSmokeAtMs)
    {
        m_shapeshiftSmokeAtMs = 0;
        m_player->SendPlaySpellVisualKit(BONK_KIT_SHAPESHIFT_SMOKE);
    }
    UpdateDruidForm();
    CycleSandboxForm();
    PulseTranquility(diff);
    DropStarfall();
    RoarAsBear();
    UpdateDruidEvolutions();
}
