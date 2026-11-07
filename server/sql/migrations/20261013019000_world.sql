DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013019000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013019000');

DELETE FROM `creature_display_info_addon` WHERE `display_id` BETWEEN 18002 AND 18011;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
SELECT d.`id`, a.`build`, a.`bounding_radius`, a.`combat_reach`, a.`speed_walk`, a.`speed_run`, a.`gender`, a.`display_id_other_gender`
FROM `creature_display_info_addon` a
JOIN (SELECT 18002 AS `id` UNION SELECT 18003 UNION SELECT 18004 UNION SELECT 18005 UNION SELECT 18006
      UNION SELECT 18007 UNION SELECT 18008 UNION SELECT 18009 UNION SELECT 18010 UNION SELECT 18011) d
WHERE a.`display_id` = 16587;

DROP TEMPORARY TABLE IF EXISTS `bonk_projectile_template`;
CREATE TEMPORARY TABLE `bonk_projectile_template` SELECT * FROM `creature_template` WHERE `entry` = 900111;
UPDATE `bonk_projectile_template` SET `entry` = 900113, `name` = 'Projectile', `inhabit_type` = 7;
DELETE FROM `creature_template` WHERE `entry` = 900113;
INSERT INTO `creature_template` SELECT * FROM `bonk_projectile_template`;
DROP TEMPORARY TABLE `bonk_projectile_template`;

CREATE TABLE IF NOT EXISTS `bonk_projectile` (
    `spell_id`   INT UNSIGNED NOT NULL COMMENT 'the spell a weapon casts',
    `display_id` INT UNSIGNED NOT NULL COMMENT 'creature display wearing its missile model',
    `speed`      FLOAT        NOT NULL DEFAULT 20 COMMENT 'yards a second',
    `radius`     FLOAT        NOT NULL DEFAULT 1 COMMENT 'yards from its path an enemy is hit, before its own size',
    `scale`      FLOAT        NOT NULL DEFAULT 1 COMMENT 'size of the model',
    `comment`    VARCHAR(64)  NOT NULL DEFAULT '',
    PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk projectiles: spells that fly as moving objects';

DELETE FROM `bonk_projectile`;
INSERT INTO `bonk_projectile` (`spell_id`, `display_id`, `speed`, `radius`, `scale`, `comment`) VALUES
(  116, 18002, 28, 1.0, 1.0, 'Frostbolt'),
(  133, 18003, 24, 1.0, 1.0, 'Fireball'),
(11366, 18004, 24, 1.5, 1.0, 'Pyroblast'),
( 2948, 18005, 30, 0.8, 1.0, 'Scorch: a small fire bolt (Scorch has no missile)'),
( 7268, 18006, 20, 0.8, 1.0, 'Arcane Missile'),
(  686, 18007, 20, 1.0, 1.0, 'Shadow Bolt'),
( 3044, 18008, 40, 0.8, 1.0, 'Arcane Shot'),
(19434, 18008, 40, 1.0, 1.0, 'Aimed Shot'),
( 2643, 18009, 30, 0.7, 1.0, 'Multi-Shot: one arrow per enemy it would hit, in a fan'),
( 1978, 18010, 40, 0.7, 1.0, 'Serpent Sting'),
(16075, 18011, 20, 1.0, 1.0, 'Throw Axe: Heroic Throw');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
