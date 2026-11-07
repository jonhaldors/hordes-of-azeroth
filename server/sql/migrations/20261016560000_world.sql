DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016560000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016560000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (222, 223, 224, 225, 226, 227);
DELETE FROM `bonk_weapon` WHERE `id` IN (222, 223, 224, 225, 226, 227);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(222, 'Venom Bolts', 'Ability_PoisonArrow', 'Stings the nearest enemy and 2 enemies near it, applying 3 stacks of Poison to each. When a poisoned enemy dies, it fires 3 venom arrows at the nearest enemies within 12 yards, each applying 2 stacks of Poison.', 1978, 0, 1200, 30, 0, 4, 0, 38, 0, 0, 0, 30, 3, 0, 1, 0, 0, 1, 2, 0, 0, 5, 3, 0, 0),
(223, 'Venom Cloud', 'Spell_Shadow_PlagueCloud', 'Stings the nearest enemy and 2 enemies near it, applying 3 stacks of Poison to each. When a poisoned enemy dies, it leaves a venom cloud for 2 sec that applies 1 stack of Poison to enemies within 4 yards every 0.5 sec.', 1978, 0, 1200, 30, 0, 4, 0, 38, 0, 0, 0, 31, 4, 0, 1, 0, 0, 1, 2, 0, 0, 5, 3, 0, 0),
(224, 'Cluster Trap', 'INV_Misc_Bomb_02', 'Places a fire trap that goes off when an enemy comes close. It explodes and burns the ground for 4 sec, applying Burning. It also scatters 5 bomblets that each explode a moment later for 40% of its damage to enemies within 3 yards, applying Burning.', 13812, 7, 5000, 6, 0.8, 4, 0, 202, 0, 4000, 0, 19, 900009, 1000, 1, 0, 0, 1, 0, 0, 256, 3, 1, 0, 0),
(225, 'Snake Trap', 'INV_Misc_MonsterFang_01', 'Places a trap that goes off when an enemy comes close. It releases 6 venomous snakes that attack nearby enemies for 8 sec. Each bite applies 2 stacks of Poison. The snakes count as your pets.', 13812, 7, 5000, 6, 0.1, 4, 0, 202, 0, 8000, 0, 19, 900009, 0, 1, 0, 0, 1, 0, 0, 512, 5, 2, 0, 0),
(226, 'Shatter Field', 'Spell_Frost_IceShock', 'Places a frost trap that goes off when an enemy comes close. For 6 sec, normal enemies inside are slowed by 60% and take 5% more damage. When the ice fades, it shatters and deals Frost damage to every enemy inside.', 13810, 7, 7000, 6, 1, 4, 0, 204, 0, 6000, 0, 19, 900010, 0, 1, 0, 0, 1, 0, 0, 1088, 0, 0, 0, 0),
(227, 'Ice Path', 'Spell_Frost_FrostArmor02', 'Ice forms around you and follows you for 6 sec. Normal enemies within 6 yards of you are slowed by 60% and take 5% more damage.', 13810, 7, 7000, 6, 0, 4, 0, 204, 0, 6000, 0, 32, 0, 0, 1, 0, 0, 1, 0, 0, 64, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(222, 3, 8), (222, 5, 15), (222, 9, 1),
(223, 3, 8), (223, 5, 15), (223, 9, 1),
(224, 5, 15), (224, 9, 1), (224, 12, 4),
(225, 5, 15), (225, 9, 1), (225, 12, 4),
(226, 5, 15), (226, 10, 3), (226, 12, 4),
(227, 5, 15), (227, 10, 3);

DELETE FROM `creature_template` WHERE `entry` = 900117;
DROP TEMPORARY TABLE IF EXISTS `bonk_snake`;
CREATE TEMPORARY TABLE `bonk_snake` AS SELECT * FROM `creature_template` WHERE `entry` = 900114;
UPDATE `bonk_snake` SET `entry` = 900117, `name` = 'Venomous Snake', `display_id1` = 1986, `display_scale1` = 1.5, `pet_family` = 0;
INSERT INTO `creature_template` SELECT * FROM `bonk_snake`;
DROP TEMPORARY TABLE `bonk_snake`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
