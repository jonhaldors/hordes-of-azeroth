DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022200000');

DELETE FROM `creature_display_info_addon` WHERE `display_id` = 18900;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
SELECT 18900, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`
FROM `creature_display_info_addon` WHERE `display_id` = 4449;

DELETE FROM `creature_template` WHERE `entry` = 900141;
DROP TEMPORARY TABLE IF EXISTS `bonk_warlock_pet`;
CREATE TEMPORARY TABLE `bonk_warlock_pet` SELECT * FROM `creature_template` WHERE `entry` = 900134;
UPDATE `bonk_warlock_pet` SET `entry` = 900141, `name` = 'Imp', `display_id1` = 18900, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
DROP TEMPORARY TABLE `bonk_warlock_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` = 12;
DELETE FROM `bonk_pet_family` WHERE `id` = 12;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(12, 'Imp', 900141, 1.0, 2000, 3, 1, '');
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(12, 11763, 0, 2000, 2, 1, 30, 0, 'Imp: fel Firebolt from 30 yd, 2 bites worth, 1 Burning');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (900, 910);
DELETE FROM `bonk_weapon` WHERE `id` IN (900, 910);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(900, 'Imp', 'Spell_Shadow_SummonImp', 'Summons an Imp that hurls fel Firebolts at enemies within 30 yards, leaving them burning.',
    688, 7, 3000, 0, 1.2, 256, 0, 256, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 0, 3, 1, 0, 0, 0),
(910, 'Rain of Felfire', 'Spell_Fel_RainOfFelfire', 'Fel fire rains on the largest group of enemies for 4 sec, dealing Fire damage and applying 1 stack of Burning every sec.',
    19717, 3, 5000, 20, 0.3, 256, 0, 0, 0, 0, 4000, 0, 0, 0, 1000, 1, 0, 0, 1, 0, 0, 67108864, 3, 1, 0, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
