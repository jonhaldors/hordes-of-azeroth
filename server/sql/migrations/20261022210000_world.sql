DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022210000');

DELETE FROM `bonk_keyword` WHERE `id` = 14;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(14, 'Agony', 'Spell_Shadow_CurseOfSargeras', 14868, 30, 0.04, 1000, 12000, 0,
 'Each stack deals Shadow damage every sec, and the damage grows every sec it stays on the enemy, up to 4 times as much. One curse per enemy.');

DELETE FROM `creature_template` WHERE `entry` IN (900142, 900143, 900144);
DROP TEMPORARY TABLE IF EXISTS `bonk_warlock_pet`;
CREATE TEMPORARY TABLE `bonk_warlock_pet` SELECT * FROM `creature_template` WHERE `entry` = 900134;
UPDATE `bonk_warlock_pet` SET `entry` = 900142, `name` = 'Voidwalker', `display_id1` = 1132, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
UPDATE `bonk_warlock_pet` SET `entry` = 900143, `name` = 'Succubus', `display_id1` = 4162, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
UPDATE `bonk_warlock_pet` SET `entry` = 900144, `name` = 'Felhunter', `display_id1` = 850, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
DROP TEMPORARY TABLE `bonk_warlock_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` IN (13, 14, 15);
DELETE FROM `bonk_pet_family` WHERE `id` IN (13, 14, 15);
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(13, 'Voidwalker', 900142, 0.8, 2000, 0, 0, ''),
(14, 'Succubus', 900143, 0.9, 1500, 8, 1, ''),
(15, 'Felhunter', 900144, 0.8, 1500, 0, 0, '');
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(14, 7814, 4, 3000, 2, 1, 8, 0, 'Succubus: Lash of Pain, every enemy in front of her within 8 yd, 2 bites worth, 1 Shadow Vulnerability'),
(15, 17253, 0, 2500, 1.5, 0, 0, 0, 'Felhunter: bite, 1.5 bites worth; it also interrupts a casting prey');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 901 AND 909;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 901 AND 909;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(901, 'Voidwalker', 'Spell_Shadow_SummonVoidWalker', 'Summons a Voidwalker. Each enemy that dies near it is consumed and it grows; after 5 it bursts in a void nova, dealing Shadow damage to every enemy around it, and shrinks back.',
    697, 7, 3000, 0, 1.2, 256, 0, 0, 0, 0, 0, 0, 20, 1, 2000, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(902, 'Succubus', 'Spell_Shadow_SummonSuccubus', 'Summons a Succubus whose Lash of Pain strikes all enemies in front of her and applies Shadow Vulnerability.',
    712, 7, 3000, 0, 1.2, 256, 0, 0, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 0, 8, 1, 0, 0, 0),
(903, 'Felhunter', 'Spell_Shadow_SummonFelHunter', 'Summons a Felhunter that interrupts the spells of the enemies it bites. Every 10 sec it devours one harmful effect from you.',
    691, 7, 3000, 0, 1.2, 256, 0, 0, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(904, 'Corruption', 'Spell_Shadow_AbominationExplosion', 'Corrupts the 3 nearest enemies that are not corrupted yet, applying 4 stacks of Decay.',
    172, 0, 2000, 30, 0, 256, 0, 256, 0, 0, 0, 0, 117, 0, 0, 3, 0, 0, 1, 0, 0, 0, 13, 4, 0, 0, 0),
(905, 'Curse of Agony', 'Spell_Shadow_CurseOfSargeras', 'Curses the 3 uncursed enemies with the most health, applying 4 stacks of Agony. Agony deals more damage every sec it stays on the enemy.',
    980, 0, 4000, 30, 0, 256, 0, 0, 0, 0, 0, 0, 118, 0, 0, 3, 0, 0, 1, 0, 0, 0, 14, 4, 0, 0, 0),
(906, 'Drain Life', 'Spell_Shadow_LifeDrain02', 'Tentacles of shadow latch onto up to 3 enemies within 20 yards, dealing Shadow damage every sec and healing you for 0.3% of your maximum health per enemy drained. It keeps draining while you move.',
    689, 0, 1000, 20, 0.25, 256, 0, 0, 0, 0.3, 0, 0, 119, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(907, 'Shadow Bolt', 'Spell_Shadow_ShadowBolt', 'Fires a bolt of shadow at the nearest enemy. Nightfall: an enemy that dies with one of your afflictions on it fires a free Shadow Bolt, at most 3 a sec.',
    686, 0, 2500, 30, 1.6, 256, 256, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0),
(908, 'Immolate', 'Spell_Fire_Immolation', 'Fel fire strikes the 2 nearest enemies and applies 5 stacks of Burning.',
    348, 0, 3000, 30, 1.0, 256, 0, 0, 0, 0, 0, 0, 0, 0, 0, 2, 0, 0, 1, 0, 0, 0, 3, 5, 0, 0, 0),
(909, 'Hellfire', 'Spell_Fire_Incinerate', 'Fel fire burns every enemy within 10 yards every sec, and burns you for 1% of your maximum health, never below 35% of your health.',
    5857, 1, 1000, 10, 0.25, 256, 0, 0, 0, 0, 0, 0, 120, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
