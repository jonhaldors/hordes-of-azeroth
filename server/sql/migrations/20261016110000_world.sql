DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016110000');

DELETE FROM `gameobject_template` WHERE `entry` = 900040;
DROP TEMPORARY TABLE IF EXISTS `bonk_loot_go`;
CREATE TEMPORARY TABLE `bonk_loot_go` SELECT * FROM `gameobject_template` WHERE `entry` = 900007;
UPDATE `bonk_loot_go` SET `entry` = 900040, `name` = 'Loot', `displayId` = 6484, `size` = 1.2;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_loot_go`;
DROP TEMPORARY TABLE IF EXISTS `bonk_loot_go`;

CREATE TABLE IF NOT EXISTS `bonk_gear` (
    `entry` INT UNSIGNED NOT NULL COMMENT 'item_template: the run copy',
    `quality` TINYINT UNSIGNED NOT NULL COMMENT '2 green, 3 blue, 4 epic, 5 legendary',
    `keep_entry` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'the permanent copy an extraction mails; 0: not extractable',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk: gear that drops in runs (BonkRunGear.cpp)';

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_spec`;
CREATE TEMPORARY TABLE `bonk_gear_spec` (
    `spec` INT NOT NULL,
    `class` INT NOT NULL,
    `subclass` INT NOT NULL,
    `inv` VARCHAR(16) NOT NULL,
    `classes` INT NOT NULL,
    `kind` VARCHAR(8) NOT NULL,
    `weight` FLOAT NOT NULL,
    `dmg_min` FLOAT NOT NULL,
    `dmg_max` FLOAT NOT NULL
);
INSERT INTO `bonk_gear_spec` VALUES
(1,  4, 1, '1',    400, 'armor', 1.0,  0, 0),
(2,  4, 1, '3',    400, 'armor', 0.75, 0, 0),
(3,  4, 1, '5,20', 400, 'armor', 1.0,  0, 0),
(4,  4, 1, '6',    400, 'armor', 0.75, 0, 0),
(5,  4, 1, '7',    400, 'armor', 1.0,  0, 0),
(6,  4, 1, '8',    400, 'armor', 0.75, 0, 0),
(7,  4, 1, '9',    400, 'armor', 0.5,  0, 0),
(8,  4, 1, '10',   400, 'armor', 0.75, 0, 0),
(9,  4, 2, '1',    1100, 'armor', 1.0,  0, 0),
(10, 4, 2, '3',    1100, 'armor', 0.75, 0, 0),
(11, 4, 2, '5,20', 1100, 'armor', 1.0,  0, 0),
(12, 4, 2, '6',    1100, 'armor', 0.75, 0, 0),
(13, 4, 2, '7',    1100, 'armor', 1.0,  0, 0),
(14, 4, 2, '8',    1100, 'armor', 0.75, 0, 0),
(15, 4, 2, '9',    1100, 'armor', 0.5,  0, 0),
(16, 4, 2, '10',   1100, 'armor', 0.75, 0, 0),
(17, 4, 3, '1',    3, 'armor', 1.0,  0, 0),
(18, 4, 3, '3',    3, 'armor', 0.75, 0, 0),
(19, 4, 3, '5,20', 3, 'armor', 1.0,  0, 0),
(20, 4, 3, '6',    3, 'armor', 0.75, 0, 0),
(21, 4, 3, '7',    3, 'armor', 1.0,  0, 0),
(22, 4, 3, '8',    3, 'armor', 0.75, 0, 0),
(23, 4, 3, '9',    3, 'armor', 0.5,  0, 0),
(24, 4, 3, '10',   3, 'armor', 0.75, 0, 0),
(25, 4, 0, '2',  1503, 'neck',   0.5, 0, 0),
(26, 4, 1, '16', 1503, 'back',   0.5, 0, 0),
(27, 4, 0, '11', 1503, 'finger', 0.5, 0, 0),
(28, 2, 7,  '13,21', 1,    'one',    1, 2, 5),
(29, 4, 6,  '14',    65,   'shield', 1, 0, 0),
(30, 2, 4,  '13,21', 80,   'one',    1, 2, 5),
(31, 2, 5,  '17',    2,    'two',    1, 4, 8),
(32, 2, 15, '13',    8,    'one',    1, 2, 4),
(33, 2, 2,  '15',    4,    'two',    1, 2, 5),
(34, 2, 10, '17',    1408, 'two',    1, 4, 8),
(35, 4, 0,  '23',    16,   'held',   1, 0, 0);

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_pick`;
CREATE TEMPORARY TABLE `bonk_gear_pick` SELECT `s`.`spec`, `q`.`quality`, `s`.`classes`, `s`.`kind`, `s`.`weight`, `s`.`dmg_min`, `s`.`dmg_max`,
    (SELECT MIN(`t`.`entry`) FROM `item_template` `t`
        WHERE `t`.`class` = `s`.`class` AND `t`.`subclass` = `s`.`subclass` AND FIND_IN_SET(`t`.`inventory_type`, `s`.`inv`)
          AND `t`.`quality` = `q`.`quality` AND `t`.`entry` < 900000
          AND `t`.`name` NOT LIKE '%Test%' AND `t`.`name` NOT LIKE '%Deprecated%' AND `t`.`name` NOT LIKE '%Monster%'
          AND ((`q`.`quality` = 2 AND `t`.`required_level` BETWEEN 25 AND 40) OR (`q`.`quality` = 3 AND `t`.`required_level` BETWEEN 45 AND 58)
            OR (`q`.`quality` = 4 AND `t`.`item_level` >= 66))) AS `source`,
    CAST(0 AS UNSIGNED) AS `entry`
    FROM `bonk_gear_spec` `s` CROSS JOIN (SELECT 2 AS `quality` UNION ALL SELECT 3 UNION ALL SELECT 4) `q`;
DELETE FROM `bonk_gear_pick` WHERE `source` IS NULL;

SET @bonk_gear_row := 0;
UPDATE `bonk_gear_pick` SET `entry` = 900300 + (@bonk_gear_row := @bonk_gear_row + 1) - 1 ORDER BY `spec`, `quality`;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_items`;
CREATE TEMPORARY TABLE `bonk_gear_items` SELECT `t`.* FROM `item_template` `t`
    JOIN `bonk_gear_pick` `p` ON `p`.`source` = `t`.`entry`
    WHERE `t`.`patch` = (SELECT MAX(`t2`.`patch`) FROM `item_template` `t2` WHERE `t2`.`entry` = `t`.`entry`);

UPDATE `bonk_gear_items` `i` JOIN `bonk_gear_pick` `p` ON `p`.`source` = `i`.`entry` SET
    `i`.`allowable_class` = `p`.`classes`,
    `i`.`dmg_min1` = IF(`p`.`dmg_max` > 0, `p`.`dmg_min`, 0),
    `i`.`dmg_max1` = IF(`p`.`dmg_max` > 0, `p`.`dmg_max`, 0),
    `i`.`entry` = `p`.`entry`;

UPDATE `bonk_gear_items` SET
    `patch` = 0, `flags` = 0,
    `description` = IF(`quality` >= 4, 'Run gear: go home through the portal to keep it.', 'Run gear: worn until the run ends, then sold for gold.'),
    `buy_price` = 0, `sell_price` = 0, `allowable_race` = -1, `required_level` = 0, `bonding` = 1,
    `stat_type1` = 0, `stat_value1` = 0, `stat_type2` = 0, `stat_value2` = 0, `stat_type3` = 0, `stat_value3` = 0,
    `stat_type4` = 0, `stat_value4` = 0, `stat_type5` = 0, `stat_value5` = 0, `stat_type6` = 0, `stat_value6` = 0,
    `stat_type7` = 0, `stat_value7` = 0, `stat_type8` = 0, `stat_value8` = 0, `stat_type9` = 0, `stat_value9` = 0,
    `stat_type10` = 0, `stat_value10` = 0,
    `dmg_min2` = 0, `dmg_max2` = 0, `armor` = 0, `block` = 0,
    `holy_res` = 0, `fire_res` = 0, `nature_res` = 0, `frost_res` = 0, `shadow_res` = 0, `arcane_res` = 0,
    `spellid_1` = 0, `spelltrigger_1` = 0, `spellid_2` = 0, `spelltrigger_2` = 0, `spellid_3` = 0, `spelltrigger_3` = 0,
    `spellid_4` = 0, `spelltrigger_4` = 0, `spellid_5` = 0, `spelltrigger_5` = 0,
    `start_quest` = 0, `page_text` = 0, `lock_id` = 0, `random_property` = 0, `set_id` = 0, `max_durability` = 0, `disenchant_id` = 0;

DELETE FROM `item_template` WHERE `entry` BETWEEN 900300 AND 900499 OR `entry` BETWEEN 901300 AND 901499;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_items`;
UPDATE `bonk_gear_items` SET `entry` = `entry` + 1000, `description` = '' WHERE `quality` >= 4;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_items` WHERE `entry` >= 901300;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900300 AND 900499 OR `entry` BETWEEN 901300 AND 901499;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_stat`;
CREATE TEMPORARY TABLE `bonk_gear_stat` SELECT `entry`, `quality`,
    ROUND(4 * CASE `kind`
        WHEN 'armor' THEN `p` * `weight`
        WHEN 'one' THEN `p` * 1.2
        WHEN 'two' THEN `p` * 2
        WHEN 'held' THEN `p` * 0.8
        ELSE 0 END) / 4 AS `power`,
    ROUND(4 * CASE `kind`
        WHEN 'armor' THEN `a` * `weight`
        WHEN 'back' THEN `a` * 0.5
        WHEN 'shield' THEN `a` * 1.5
        ELSE 0 END) / 4 AS `armor`,
    ROUND(4 * IF(`kind` = 'back', `j` * 0.5, 0)) / 4 AS `dodge`,
    ROUND(4 * CASE `kind` WHEN 'neck' THEN `j` WHEN 'held' THEN `j` * 0.5 ELSE 0 END) / 4 AS `crit`,
    IF(`kind` = 'shield', `s`, 0) AS `shield`,
    ROUND(4 * IF(`kind` = 'finger', `j` * 1.25, 0)) / 4 AS `haste`
    FROM (SELECT `entry`, `quality`, `kind`, `weight`,
            CASE `quality` WHEN 2 THEN 2 WHEN 3 THEN 3.5 ELSE 5 END AS `p`,
            CASE `quality` WHEN 2 THEN 1 WHEN 3 THEN 1.75 ELSE 2.5 END AS `a`,
            CASE `quality` WHEN 2 THEN 1 WHEN 3 THEN 1.5 ELSE 2 END AS `j`,
            CASE `quality` WHEN 2 THEN 0 WHEN 3 THEN 2 ELSE 4 END AS `s`
          FROM `bonk_gear_pick`) `b`;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry`, `power`, `armor`, `dodge`, 0, `crit`, 0, `shield`, `haste`, 0, 0, 0, 0 FROM `bonk_gear_stat`;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry` + 1000, `power`, `armor`, `dodge`, 0, `crit`, 0, `shield`, `haste`, 0, 0, 0, 0 FROM `bonk_gear_stat` WHERE `quality` >= 4;

DELETE FROM `bonk_gear`;
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`)
    SELECT `entry`, `quality`, IF(`quality` >= 4, `entry` + 1000, 0) FROM `bonk_gear_pick`;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_spec`;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_pick`;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_items`;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_stat`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
