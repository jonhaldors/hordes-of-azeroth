DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018200000');

DELETE FROM `spell_effect_mod` WHERE (`Id` IN (27567, 28167) AND `EffectIndex` = 0) OR (`Id` = 8056 AND `EffectIndex` = 0);
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `EffectChainTarget`, `Comment`) VALUES
(27567, 0, 4, 'Lightning Overload: the chain jumps to 3 additional enemies');
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `EffectChainTarget`, `EffectMultipleValue`, `Comment`) VALUES
(28167, 0, 20, 0.85, 'Elemental Mastery: jumps on and on, 15% less each jump');
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `Comment`) VALUES
(8056, 0, 0, 0, 'Frost Shock slows through Chill');

DELETE FROM `bonk_pet_family` WHERE `id` = 10;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(10, 'Elemental Spirit', 900130, 1, 1500, 0, 0, '');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 712 AND 735;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 712 AND 735;

DROP TEMPORARY TABLE IF EXISTS `bonk_shaman_evolution`;
CREATE TEMPORARY TABLE `bonk_shaman_evolution` (
    `id` INT UNSIGNED NOT NULL PRIMARY KEY,
    `base` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `icon` VARCHAR(64) NOT NULL,
    `description` VARCHAR(1024) NOT NULL,
    `spell_id` INT UNSIGNED NULL,
    `behavior` INT UNSIGNED NULL,
    `behavior_value` FLOAT NULL,
    `alt_spell_id` INT UNSIGNED NULL,
    `alt_damage` FLOAT NULL,
    `base_targets` INT UNSIGNED NULL,
    `flags` INT UNSIGNED NULL,
    `applies` INT UNSIGNED NULL,
    `apply_stacks` INT UNSIGNED NULL,
    `damage_fraction` FLOAT NULL
);
INSERT INTO `bonk_shaman_evolution` VALUES
(712, 700, 'Lightning Overload', 'Spell_Lightning_LightningBolt01', 'Hurls a bolt of lightning at the nearest enemy, dealing Nature damage and applying 1 stack of Static. A bolt that sets off a Static discharge also hurls a Chain Lightning from that enemy.',
    NULL, NULL, NULL, 27567, 0.7, NULL, NULL, NULL, NULL, NULL),
(713, 700, 'Lava Burst', 'Spell_Fire_Fireball02', 'Hurls molten lava at the enemy with the most stacks of Burning, dealing Fire damage. Always critically strikes Burning enemies.',
    20420, 82, NULL, NULL, NULL, NULL, NULL, 0, 0, 1.4),
(714, 701, 'Elemental Mastery', 'Spell_Nature_WispHeal', 'Hurls lightning at the nearest enemy that keeps jumping to nearby enemies with no limit, applying 1 stack of Static to each. Each jump deals 15% less damage.',
    28167, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(715, 701, 'Forked Lightning', 'Spell_Nature_ChainLightning', 'Hurls 2 Chain Lightnings at the 2 nearest enemies, each jumping to 3 additional nearby enemies and applying 1 stack of Static to each.',
    NULL, NULL, NULL, NULL, NULL, 2, NULL, NULL, NULL, NULL),
(716, 702, 'Frost Shock', 'Spell_Frost_FrostShock', 'Shocks the 3 nearest enemies with frost, dealing Frost damage and applying 3 stacks of Chill.',
    8056, NULL, NULL, NULL, NULL, NULL, NULL, 1, 3, NULL),
(717, 702, 'Lava Surge', 'Spell_Fire_LavaSpawn', 'Shocks the 3 nearest enemies, dealing Fire damage and applying 3 stacks of Burning. When a Burning enemy dies, Lightning Bolt fires at once.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(718, 703, 'Earthquake', 'Spell_Nature_Earthquake', 'Calls a thunderclap around you, dealing Nature damage to all enemies within 10 yards, applying 1 stack of Static and knocking normal enemies back. The ground where you stood shakes for 4 seconds; enemies inside are Dazed and take Nature damage every second.',
    NULL, NULL, 8, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(719, 703, 'Eye of the Storm', 'Spell_Nature_EyeOfTheStorm', 'Calls a thunderclap around you, dealing Nature damage to all enemies within 10 yards, applying 1 stack of Static and knocking normal enemies back. Every Static discharge within 10 yards of you sets off a small thunderclap on that enemy.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(720, 704, 'Flametongue Weapon', 'Spell_Fire_Flametounge', 'Swings your weapon at the nearest enemy. Every swing also deals Fire damage and applies 1 stack of Burning. Every 3rd swing calls Windfury: 2 extra swings that also strike enemies within 4 yards and apply 3 stacks of Burning.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(721, 704, 'Doom Winds', 'Spell_Nature_Cyclone', 'Swings your weapon at the nearest enemy. Every 3rd swing calls Windfury: 2 extra swings that also strike enemies within 4 yards. Every 15 seconds, every swing calls Windfury for 4 seconds.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(722, 705, 'Lava Lash', 'Spell_Fire_Flametounge', 'Strikes up to 3 enemies around you twice, once with your weapon and once with molten lava, applying 2 stacks of Static and 2 stacks of Burning. The lava deals 50% more damage to Burning enemies.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(723, 705, 'Crash Lightning', 'Spell_Nature_Lightning', 'Strikes up to 3 enemies around you twice, once with your weapon and once with lightning, applying 2 stacks of Static. The lightning also strikes all enemies within 8 yards of you, applying 1 stack of Static.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(724, 706, 'Overcharge', 'Spell_Nature_WispSplode', 'Every 5th melee hit hurls a free Lightning Bolt, or a free Chain Lightning when you have Chain Lightning, at the 3 nearest enemies.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(725, 706, 'Static Surge', 'Spell_Nature_Purge', 'Every 5th melee hit hurls a free Lightning Bolt, or a free Chain Lightning when you have Chain Lightning, at the nearest enemy. It applies 5 stacks of Static, so the enemy discharges at once.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(726, 707, 'Elemental Spirits', 'Spell_Nature_GuardianWard', 'Summons 2 spirit wolves that take the forms of fire, frost and lightning. Their bites apply Burning, Chill or Static.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(727, 707, 'Spirit Pack', 'Ability_Hunter_Pet_Wolf', 'Summons 2 spirit wolves whose bites apply Static. Each Windfury calls an extra wolf for 6 seconds.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(728, 708, 'Fire Nova Totem', 'Spell_Fire_SealOfFire', 'Plants a Searing Totem at your feet that hurls fire at an enemy within 20 yards, applying Burning. Every 4 seconds the totem bursts, dealing Fire damage and 3 stacks of Burning to all enemies within 8 yards, and is replanted at your feet.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(729, 708, 'Totem of Wrath', 'Spell_Fire_Immolation', 'Plants a Searing Totem at your feet that hurls fire at an enemy within 20 yards, applying Burning. Enemies within 15 yards of the totem take 15% more Fire damage.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(730, 709, 'Liquid Magma', 'Spell_Fire_Volcano', 'Plants a Magma Totem at your feet that pulses fire every 2 seconds, dealing Fire damage and 1 stack of Burning to all enemies within 8 yards of it. Each pulse also hurls 2 globs of magma at enemies within 20 yards.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(731, 709, 'Earthbind', 'Spell_Nature_EarthBindTotem', 'Plants a Magma Totem at your feet that pulses fire every 2 seconds, dealing Fire damage and 1 stack of Burning to all enemies within 8 yards of it. The pulse also Dazes them.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(732, 710, 'Healing Tide', 'Spell_Nature_HealingWaveGreater', 'Summons a Healing Tide Totem that walks with you and heals you for 1% of your maximum health every second.',
    NULL, NULL, NULL, NULL, NULL, NULL, 0, NULL, NULL, NULL),
(733, 710, 'Healing Rain', 'Spell_Nature_Tranquility', 'Plants a Healing Stream Totem at your feet that heals you for 1% of your maximum health every second while you are within 15 yards of it. Every 3 seconds it rains on enemies within 10 yards, dealing Nature damage.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, 0.6),
(734, 711, 'Earth Shield', 'Spell_Nature_ProtectionformNature', 'Surrounds you with up to 3 lightning charges. When an enemy strikes you, a charge zaps it for Nature damage, applies 1 stack of Static and gives you a Shield of 1% of your maximum health, up to 10%. One charge returns every 3 seconds.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL),
(735, 711, 'Static Shock', 'Spell_Nature_StormReach', 'Surrounds you with up to 3 lightning charges. When an enemy strikes you or your melee hits land, a charge zaps the enemy and all enemies within 4 yards of it for Nature damage and applies 1 stack of Static. One charge returns every 3 seconds.',
    NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL, NULL);

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`)
SELECT `e`.`id`, `e`.`name`, `e`.`icon`, `e`.`description`, COALESCE(`e`.`spell_id`, `b`.`spell_id`), `b`.`target`, `b`.`cooldown_ms`, `b`.`range`,
    COALESCE(`e`.`damage_fraction`, `b`.`damage_fraction`), `b`.`class_mask`, 0, 0,
    `e`.`base`, `b`.`heal_pct`, `b`.`duration_ms`, `b`.`chains`, COALESCE(`e`.`behavior`, `b`.`behavior`), COALESCE(`e`.`behavior_value`, `b`.`behavior_value`), `b`.`tick_ms`,
    COALESCE(`e`.`base_targets`, `b`.`base_targets`), COALESCE(`e`.`alt_spell_id`, `b`.`alt_spell_id`), `b`.`alt_every`, COALESCE(`e`.`alt_damage`, `b`.`alt_damage`), `b`.`base_jumps`, `b`.`kill_below_pct`,
    COALESCE(`e`.`flags`, `b`.`flags`), COALESCE(`e`.`applies`, `b`.`applies`), COALESCE(`e`.`apply_stacks`, `b`.`apply_stacks`), `b`.`uses`, `b`.`uses_pct`, 0
FROM `bonk_shaman_evolution` `e` JOIN `bonk_weapon` `b` ON `b`.`id` = `e`.`base`;

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `e`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_shaman_evolution` `e` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `e`.`base`;

DROP TEMPORARY TABLE `bonk_shaman_evolution`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
