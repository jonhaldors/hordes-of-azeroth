DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015280000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015280000');

DROP TEMPORARY TABLE IF EXISTS `bonk_starter_src`;
CREATE TEMPORARY TABLE `bonk_starter_src` (
    `entry` INT UNSIGNED NOT NULL,
    `source` INT UNSIGNED NOT NULL,
    `classes` INT NOT NULL,
    `dmg_min` FLOAT NOT NULL,
    `dmg_max` FLOAT NOT NULL
);
INSERT INTO `bonk_starter_src` VALUES
(900201, 14133, 400,  0, 0),
(900202, 14125, 400,  0, 0),
(900203, 14129, 400,  0, 0),
(900204, 14124, 400,  0, 0),
(900205, 6584,  1100, 0, 0),
(900206, 6587,  1100, 0, 0),
(900207, 6582,  1100, 0, 0),
(900208, 6586,  1100, 0, 0),
(900209, 9783,  3,    0, 0),
(900210, 9789,  3,    0, 0),
(900211, 9784,  3,    0, 0),
(900212, 9787,  3,    0, 0),
(900213, 15210, 1,    2, 5),
(900214, 9790,  1,    0, 0),
(900215, 4777,  2,    4, 8),
(900216, 2079,  64,   2, 5),
(900217, 14729, 64,   0, 0),
(900218, 3222,  8,    2, 4),
(900219, 11304, 4,    2, 5),
(900220, 1933,  128,  4, 8),
(900221, 3227,  256,  4, 8),
(900222, 1539,  1024, 4, 8),
(900223, 789,   16,   2, 5),
(900224, 15926, 16,   0, 0),
(900225, 4500,  -1,   0, 0),
(900226, 2512,  4,    0, 0);

DROP TEMPORARY TABLE IF EXISTS `bonk_starter_items`;
CREATE TEMPORARY TABLE `bonk_starter_items` SELECT `t`.* FROM `item_template` `t`
    JOIN `bonk_starter_src` `s` ON `s`.`source` = `t`.`entry`
    WHERE `t`.`patch` = (SELECT MAX(`t2`.`patch`) FROM `item_template` `t2` WHERE `t2`.`entry` = `t`.`entry`);

UPDATE `bonk_starter_items` `i` JOIN `bonk_starter_src` `s` ON `s`.`source` = `i`.`entry` SET
    `i`.`dmg_min1` = IF(`s`.`dmg_max` > 0, `s`.`dmg_min`, `i`.`dmg_min1`),
    `i`.`dmg_max1` = IF(`s`.`dmg_max` > 0, `s`.`dmg_max`, `i`.`dmg_max1`),
    `i`.`allowable_class` = `s`.`classes`,
    `i`.`entry` = `s`.`entry`;

UPDATE `bonk_starter_items` SET
    `patch` = 0, `quality` = 2, `flags` = 0, `description` = '',
    `buy_price` = 0, `sell_price` = 0, `allowable_race` = -1,
    `item_level` = 5, `required_level` = 0, `bonding` = 1,
    `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0,
    `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0,
    `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0,
    `stat_type10` = 0, `stat_value10` = 0,
    `dmg_min2` = 0, `dmg_max2` = 0,
    `armor` = 0, `block` = 0,
    `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0, `arcane_res` = 0,
    `spellid_1` = 0, `spelltrigger_1` = 0, `spellid_2` = 0, `spelltrigger_2` = 0, `spellid_3` = 0, `spelltrigger_3` = 0,
    `spellid_4` = 0, `spelltrigger_4` = 0, `spellid_5` = 0, `spelltrigger_5` = 0,
    `start_quest` = 0, `random_property` = 0, `set_id` = 0, `max_durability` = 0, `disenchant_id` = 0;

UPDATE `bonk_starter_items` SET `name` = 'Darkmoon Satchel', `container_slots` = 24 WHERE `entry` = 900225;
UPDATE `bonk_starter_items` SET `name` = 'Darkmoon Arrow' WHERE `entry` = 900226;

DELETE FROM `item_template` WHERE `entry` BETWEEN 900201 AND 900226;
INSERT INTO `item_template` SELECT * FROM `bonk_starter_items`;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900201 AND 900225;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`) VALUES
(900201, 1,   1,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900202, 1,   0.75, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900203, 0,   0.5,  0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900204, 0.5, 0,    0, 0, 0.5, 0, 0, 0, 0, 0, 0, 0),
(900205, 1,   1,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900206, 1,   0.75, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900207, 0,   0.5,  0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900208, 0.5, 0,    0, 0, 0.5, 0, 0, 0, 0, 0, 0, 0),
(900209, 1,   1,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900210, 1,   0.75, 0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900211, 0,   0.5,  0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900212, 0.5, 0,    0, 0, 0.5, 0, 0, 0, 0, 0, 0, 0),
(900213, 2,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900214, 0,   1.5,  0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900215, 4,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900216, 2,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900217, 0,   1.5,  0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900218, 2,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900219, 4,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900220, 4,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900221, 4,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900222, 4,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900223, 2,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0),
(900224, 2,   0,    0, 0, 0,   0, 0, 0, 0, 0, 0, 0);

DROP TEMPORARY TABLE IF EXISTS `bonk_starter_kit`;
CREATE TEMPORARY TABLE `bonk_starter_kit` (`class` TINYINT UNSIGNED, `item` INT UNSIGNED, `amount` TINYINT UNSIGNED);
INSERT INTO `bonk_starter_kit` VALUES
(1, 900209, 1), (1, 900210, 1), (1, 900211, 1), (1, 900212, 1), (1, 900213, 1), (1, 900214, 1),
(2, 900209, 1), (2, 900210, 1), (2, 900211, 1), (2, 900212, 1), (2, 900215, 1),
(3, 900205, 1), (3, 900206, 1), (3, 900207, 1), (3, 900208, 1), (3, 900219, 1), (3, 900226, 200),
(4, 900205, 1), (4, 900206, 1), (4, 900207, 1), (4, 900208, 1), (4, 900218, 2),
(5, 900201, 1), (5, 900202, 1), (5, 900203, 1), (5, 900204, 1), (5, 900223, 1), (5, 900224, 1),
(7, 900205, 1), (7, 900206, 1), (7, 900207, 1), (7, 900208, 1), (7, 900216, 1), (7, 900217, 1),
(8, 900201, 1), (8, 900202, 1), (8, 900203, 1), (8, 900204, 1), (8, 900220, 1),
(9, 900201, 1), (9, 900202, 1), (9, 900203, 1), (9, 900204, 1), (9, 900221, 1),
(11, 900205, 1), (11, 900206, 1), (11, 900207, 1), (11, 900208, 1), (11, 900222, 1),
(1, 900225, 4), (2, 900225, 4), (3, 900225, 4), (4, 900225, 4), (5, 900225, 4),
(7, 900225, 4), (8, 900225, 4), (9, 900225, 4), (11, 900225, 4);

DELETE FROM `playercreateinfo_item`;
INSERT INTO `playercreateinfo_item` (`race`, `class`, `itemid`, `amount`)
    SELECT `p`.`race`, `p`.`class`, `k`.`item`, `k`.`amount` FROM `playercreateinfo` `p` JOIN `bonk_starter_kit` `k` ON `k`.`class` = `p`.`class`;

INSERT IGNORE INTO `playercreateinfo_spell` (`race`, `class`, `spell`, `build_min`, `build_max`, `note`) VALUES
(3, 1, 201, 0, 5875, 'One-Handed Swords (Vanilla Bonk starter sword)'),
(6, 1, 201, 0, 5875, 'One-Handed Swords (Vanilla Bonk starter sword)'),
(8, 1, 201, 0, 5875, 'One-Handed Swords (Vanilla Bonk starter sword)'),
(3, 3, 264, 0, 5875, 'Bows (Vanilla Bonk starter bow)'),
(6, 3, 264, 0, 5875, 'Bows (Vanilla Bonk starter bow)'),
(1, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(2, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(3, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(4, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(5, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(7, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(8, 4, 674, 0, 5875, 'Dual Wield (Vanilla Bonk starter daggers)'),
(1, 9, 227, 0, 5875, 'Staves (Vanilla Bonk starter staff)'),
(2, 9, 227, 0, 5875, 'Staves (Vanilla Bonk starter staff)'),
(5, 9, 227, 0, 5875, 'Staves (Vanilla Bonk starter staff)'),
(7, 9, 227, 0, 5875, 'Staves (Vanilla Bonk starter staff)');

DELETE FROM `creature_template` WHERE `entry` = 900009;
DROP TEMPORARY TABLE IF EXISTS `bonk_banker`;
CREATE TEMPORARY TABLE `bonk_banker` SELECT * FROM `creature_template` WHERE `entry` = 900004;
UPDATE `bonk_banker` SET `entry` = 900009, `name` = 'Bixi Vaultbolt', `subname` = 'Banker', `npc_flags` = 256, `display_id1` = 7346, `gossip_menu_id` = 0;
INSERT INTO `creature_template` SELECT * FROM `bonk_banker`;

DELETE FROM `creature` WHERE `guid` = 900009;
DROP TEMPORARY TABLE IF EXISTS `bonk_banker_spawn`;
CREATE TEMPORARY TABLE `bonk_banker_spawn` SELECT * FROM `creature` WHERE `guid` = 900004;
UPDATE `bonk_banker_spawn` SET `guid` = 900009, `id` = 900009, `position_x` = 16223.0, `position_y` = 16271.8, `position_z` = 13.0, `orientation` = 4.8;
INSERT INTO `creature` SELECT * FROM `bonk_banker_spawn`;

DELETE FROM `bonk_hidden_gameobject` WHERE `guid` = 230922;

DROP TEMPORARY TABLE IF EXISTS `bonk_starter_src`;
DROP TEMPORARY TABLE IF EXISTS `bonk_starter_items`;
DROP TEMPORARY TABLE IF EXISTS `bonk_starter_kit`;
DROP TEMPORARY TABLE IF EXISTS `bonk_banker`;
DROP TEMPORARY TABLE IF EXISTS `bonk_banker_spawn`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
