DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016570000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016570000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (228, 229, 230, 231);
DELETE FROM `bonk_weapon` WHERE `id` IN (228, 229, 230, 231);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(228, 'Stampede', 'Ability_Mount_WhiteDireWolf', 'Summons your cat to fight for you. It claws, bites, dashes and pounces by itself; its Claw applies Bleed. Every 20 sec, 3 spectral beasts charge through the largest group of enemies, hitting every enemy they pass.', 883, 7, 3000, 0, 1.2, 4, 0, 201, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 2048, 0, 0, 0, 0),
(229, 'Plague Beast', 'Ability_Creature_Disease_02', 'Summons an undead beast to fight for you. It claws, bites, dashes and pounces by itself; its Claw applies 2 stacks of Poison. A plague cloud surrounds it and applies 1 stack of Poison to enemies within 5 yards every 1 sec.', 883, 7, 3000, 0, 1.2, 4, 0, 201, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 4096, 5, 1, 0, 0),
(230, 'Howl of the Pack Leader', 'Ability_Druid_ChallangingRoar', 'A spirit wolf fights for you. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec. Each howl also calls a Boar, a Bear or a Wyvern for 8 sec. The Boar charges through the largest group of enemies, the Bear mauls enemies around it and leaves them bleeding, and the Wyvern''s screech makes all your pets deal 20% more damage.', 19574, 7, 15000, 0, 0.6, 4, 0, 211, 0, 6000, 0, 21, 900115, 1500, 1, 0, 0, 1, 0, 0, 8192, 0, 0, 0, 0),
(231, 'Feeding Frenzy', 'Ability_Druid_Rake', 'A spirit wolf fights for you. Every 15 sec it howls, and your other pets deal double damage to all enemies in front for 6 sec. Each kill your pets make during the frenzy extends it by 0.5 sec, up to 10 sec remaining.', 19574, 7, 15000, 0, 0.6, 4, 0, 211, 0, 6000, 0, 21, 900115, 1500, 1, 0, 0, 1, 0, 0, 16384, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(228, 3, 8), (228, 7, 15), (228, 8, 10),
(229, 3, 8), (229, 7, 15), (229, 8, 10), (229, 9, 1),
(230, 3, 8), (230, 5, 15), (230, 7, 15), (230, 11, 15),
(231, 3, 8), (231, 5, 15), (231, 7, 15), (231, 11, 15);

DELETE FROM `creature_template` WHERE `entry` IN (900118, 900119, 900120, 900121, 900122);
DROP TEMPORARY TABLE IF EXISTS `bonk_beast`;
CREATE TEMPORARY TABLE `bonk_beast` AS SELECT * FROM `creature_template` WHERE `entry` = 900114;
UPDATE `bonk_beast` SET `entry` = 900118, `name` = 'Spectral Beast', `display_id1` = 2446, `display_scale1` = 1, `pet_family` = 0;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
UPDATE `bonk_beast` SET `entry` = 900119, `name` = 'Plague Beast', `display_id1` = 6121, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
UPDATE `bonk_beast` SET `entry` = 900120, `name` = 'Boar', `display_id1` = 3035, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
UPDATE `bonk_beast` SET `entry` = 900121, `name` = 'Bear', `display_id1` = 820, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
UPDATE `bonk_beast` SET `entry` = 900122, `name` = 'Wyvern', `display_id1` = 295, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
DROP TEMPORARY TABLE `bonk_beast`;

ALTER TABLE `bonk_mastery` MODIFY `effect` tinyint(3) unsigned NOT NULL COMMENT '0 passive, 1 spell damage, 2 school damage, 3 spell cooldown, 4 spell targets, 5 start spell, 6 shatter, 7 opener, 8 execute, 9 clearcasting, 10 soul siphon, 11 spell slow';

UPDATE `bonk_mastery` SET `max_rank` = 3, `value_per_rank` = 1, `description` = 'Increases the number of beasts summoned by Call Pet by 1.' WHERE `id` = 30108;

DELETE FROM `bonk_mastery` WHERE `id` IN (30210, 30310);
INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`) VALUES
(30210, 3, 302, 3, 1, 'Spell_Nature_Slow', 'Concussive Barrage', 'Arcane Shot slows normal enemies it hits by 30% for 2 sec.', 1, 0, 0, 11, 7, 30),
(30310, 3, 303, 3, 1, 'Ability_Creature_Poison_03', 'Noxious Stings', '+5% Poison damage.', 3, 0, 0, 0, 19, 5);

DELETE FROM `bonk_passive` WHERE `id` = 21;
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`, `excludes`) VALUES
(21, 'Toxicology', 'Trade_BrewPoison', '+10% Poison damage. Offered only while one of your spells applies Poison.', 19, 10, 5, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
