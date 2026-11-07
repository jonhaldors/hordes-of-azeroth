DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018180000');

DELETE FROM `bonk_keyword` WHERE `id` = 11;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(11, 'Static', 'Spell_Nature_Lightning', 18148, 5, 0.8, 0, 8000, 0,
 'Stacks up to 5 times. At 5 stacks, the enemy is struck by lightning, dealing Nature damage to it and up to 3 enemies within 6 yards, and the stacks reset.');

DELETE FROM `spell_effect_mod` WHERE (`Id` = 18148 AND `EffectIndex` = 0) OR (`Id` = 324 AND `EffectIndex` = 0) OR (`Id` = 8050 AND `EffectIndex` = 1)
    OR (`Id` = 421 AND `EffectIndex` = 0) OR (`Id` = 8078 AND `EffectIndex` IN (1, 2));
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `EffectApplyAuraName`, `Comment`) VALUES
(18148, 0, 4, 'Static: the stack carrier only'),
(324, 0, 4, 'Lightning Shield: the look only, the server zaps');
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `Comment`) VALUES
(8050, 1, 0, 0, 'Flame Shock burns through Burning'),
(8078, 1, 0, 0, 'Thunderstorm: no slow'),
(8078, 2, 0, 0, 'Thunderstorm: no slow');
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `EffectChainTarget`, `Comment`) VALUES
(421, 0, 4, 'Chain Lightning jumps to 3 additional enemies');

DELETE FROM `creature_template` WHERE `entry` BETWEEN 900130 AND 900133;
DROP TEMPORARY TABLE IF EXISTS `bonk_shaman_pet`;
CREATE TEMPORARY TABLE `bonk_shaman_pet` SELECT * FROM `creature_template` WHERE `entry` = 900114;
UPDATE `bonk_shaman_pet` SET `entry` = 900130, `name` = 'Spirit Wolf', `display_id1` = 1236, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_shaman_pet`;
DROP TEMPORARY TABLE `bonk_shaman_pet`;
CREATE TEMPORARY TABLE `bonk_shaman_pet` SELECT * FROM `creature_template` WHERE `entry` = 900128;
UPDATE `bonk_shaman_pet` SET `entry` = 900131, `name` = 'Searing Totem', `display_id1` = 4589, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_shaman_pet`;
UPDATE `bonk_shaman_pet` SET `entry` = 900132, `name` = 'Magma Totem', `display_id1` = 4589;
INSERT INTO `creature_template` SELECT * FROM `bonk_shaman_pet`;
UPDATE `bonk_shaman_pet` SET `entry` = 900133, `name` = 'Healing Stream Totem', `display_id1` = 4587;
INSERT INTO `creature_template` SELECT * FROM `bonk_shaman_pet`;
DROP TEMPORARY TABLE `bonk_shaman_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` BETWEEN 6 AND 9;
DELETE FROM `bonk_pet_family` WHERE `id` BETWEEN 6 AND 9;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(6, 'Spirit Wolf', 900130, 1, 1500, 11, 1, ''),
(7, 'Searing Totem', 900131, 1, 60000, 0, 0, ''),
(8, 'Magma Totem', 900132, 1, 60000, 0, 0, ''),
(9, 'Healing Stream Totem', 900133, 1, 60000, 0, 0, '');
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(7, 3606, 0, 1500, 1, 1, 20, 0, 'Searing Totem: fire bolt from 20 yd, 1 bite worth, 1 Burning'),
(8, 8187, 3, 2000, 1, 1, 8, 6310, 'Magma Totem: fire pulse, 8 yd, 1 bite worth, 1 Burning');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 700 AND 719;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 700 AND 719;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(700, 'Lightning Bolt', 'Spell_Nature_Lightning', 'Hurls a bolt of lightning at the nearest enemy, dealing Nature damage and applying 1 stack of Static.',
    403, 0, 1500, 30, 1.0, 64, 64, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 11, 1, 0, 0, 701),
(701, 'Chain Lightning', 'Spell_Nature_ChainLightning', 'Hurls lightning at the nearest enemy that jumps to 3 additional nearby enemies, applying 1 stack of Static to each.',
    421, 0, 2500, 30, 0.7, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 11, 1, 0, 0, 701),
(702, 'Flame Shock', 'Spell_Fire_FlameShock', 'Shocks the 3 nearest enemies, dealing Fire damage and applying 3 stacks of Burning.',
    8050, 0, 3000, 20, 0.4, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 0, 3, 3, 0, 0, 701),
(703, 'Thunderstorm', 'Spell_Nature_CallStorm', 'Calls a thunderclap around you, dealing Nature damage to all enemies within 10 yards, applying 1 stack of Static and knocking normal enemies back.',
    8078, 1, 4000, 10, 0.6, 64, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 67108872, 11, 1, 0, 0, 701),
(704, 'Windfury Weapon', 'Spell_Nature_Cyclone', 'Swings your weapon at the nearest enemy. Every 3rd swing calls Windfury: 2 extra swings at once that also strike enemies within 4 yards of the target.',
    13446, 0, 1500, 6, 0.6, 64, 0, 64, 0, 0, 0, 0, 78, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 702),
(705, 'Stormstrike', 'Spell_Holy_SealOfMight', 'Strikes up to 3 enemies around you twice, once with your weapon and once with lightning, applying 2 stacks of Static.',
    11976, 0, 3000, 8, 0.6, 64, 0, 0, 0, 0, 0, 0, 79, 0, 0, 3, 0, 0, 1, 0, 0, 0, 11, 2, 0, 0, 702),
(706, 'Maelstrom Weapon', 'Spell_Nature_StormReach', 'Every 5th melee hit hurls a free Lightning Bolt at the nearest enemy, or a free Chain Lightning when you have Chain Lightning. Melee hits are Windfury Weapon swings, Stormstrike and Feral Spirit bites.',
    8246, 7, 500, 30, 1.0, 64, 0, 0, 0, 0, 0, 0, 80, 0, 0, 1, 0, 0, 1, 0, 0, 0, 11, 1, 0, 0, 702),
(707, 'Feral Spirit', 'Spell_Nature_SpiritWolf', 'Summons 2 spirit wolves whose bites apply Static.',
    2645, 7, 3000, 0, 1.2, 64, 0, 0, 0, 0, 0, 0, 20, 1, 1500, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 702),
(708, 'Searing Totem', 'Spell_Fire_SearingTotem', 'Plants a Searing Totem at your feet that hurls fire at an enemy within 20 yards, applying Burning. It is replanted when you move away.',
    3599, 7, 3000, 0, 1.0, 64, 0, 64, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 134217728, 3, 1, 0, 0, 703),
(709, 'Magma Totem', 'Spell_Fire_SelfDestruct', 'Plants a Magma Totem at your feet that pulses fire every 2 seconds, dealing Fire damage and 1 stack of Burning to all enemies within 8 yards of it.',
    8190, 7, 3000, 0, 0.8, 64, 0, 0, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 201326592, 3, 1, 0, 0, 703),
(710, 'Healing Stream Totem', 'INV_Spear_04', 'Plants a Healing Stream Totem at your feet that heals you for 1% of your maximum health every second while you are within 15 yards of it.',
    5394, 7, 3000, 0, 0, 64, 0, 0, 0, 1.0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 134217728, 0, 0, 0, 0, 703),
(711, 'Lightning Shield', 'Spell_Nature_LightningShield', 'Surrounds you with up to 3 lightning charges. When an enemy strikes you, a charge zaps it for Nature damage and applies 1 stack of Static. One charge returns every 3 seconds.',
    324, 7, 3000, 0, 0.8, 64, 0, 0, 0, 0, 0, 0, 81, 0, 0, 1, 0, 0, 1, 0, 0, 0, 11, 1, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(700, 1, 10), (700, 2, 10), (700, 3, 8), (700, 9, 1),
(701, 2, 10), (701, 3, 8), (701, 9, 1),
(702, 3, 8), (702, 5, 15), (702, 9, 1),
(703, 3, 8), (703, 9, 1), (703, 16, 1),
(704, 2, 10), (704, 3, 8),
(705, 2, 10), (705, 3, 8), (705, 9, 1),
(706, 9, 1),
(707, 3, 8), (707, 7, 15), (707, 8, 10),
(708, 3, 8), (708, 7, 15), (708, 8, 10),
(709, 3, 8), (709, 7, 15), (709, 8, 10),
(711, 3, 8), (711, 9, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
