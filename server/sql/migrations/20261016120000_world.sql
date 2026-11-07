DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016120000');

DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_mask`;
CREATE TEMPORARY TABLE `bonk_weapon_mask` (`first` INT UNSIGNED, `classes` INT, `one_hand` TINYINT);
INSERT INTO `bonk_weapon_mask` VALUES
(900381, 395,  1),
(900384, 67,   0),
(900387, 82,   1),
(900390, 1090, 0),
(900393, 392,  1),
(900396, 4,    0),
(900399, 1424, 0),
(900402, 400,  0);
UPDATE `item_template` `i` JOIN `bonk_weapon_mask` `w`
    ON `i`.`entry` BETWEEN `w`.`first` AND `w`.`first` + 2 OR `i`.`entry` = `w`.`first` + 1002
    SET `i`.`allowable_class` = `w`.`classes`;
UPDATE `bonk_item_stat` `s` JOIN `bonk_weapon_mask` `w`
    ON `w`.`one_hand` = 1 AND (`s`.`entry` BETWEEN `w`.`first` AND `w`.`first` + 2 OR `s`.`entry` = `w`.`first` + 1002)
    SET `s`.`power` = CASE WHEN `s`.`entry` = `w`.`first` THEN 2 WHEN `s`.`entry` = `w`.`first` + 1 THEN 3.5 ELSE 5 END;
DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_mask`;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_spec`;
CREATE TEMPORARY TABLE `bonk_gear_spec` (`spec` INT, `class` INT, `subclass` INT, `inv` VARCHAR(16), `classes` INT, `dmg_min` FLOAT, `dmg_max` FLOAT);
INSERT INTO `bonk_gear_spec` VALUES
(1, 2, 8,  '17',    3, 4, 8),
(2, 2, 3,  '15,26', 4, 2, 5),
(3, 2, 18, '15,26', 4, 2, 5);

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_pick`;
CREATE TEMPORARY TABLE `bonk_gear_pick` SELECT `s`.`spec`, `q`.`quality`, `s`.`classes`, `s`.`dmg_min`, `s`.`dmg_max`,
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
UPDATE `bonk_gear_pick` SET `entry` = 900405 + (@bonk_gear_row := @bonk_gear_row + 1) - 1 ORDER BY `spec`, `quality`;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_items`;
CREATE TEMPORARY TABLE `bonk_gear_items` SELECT `t`.* FROM `item_template` `t`
    JOIN `bonk_gear_pick` `p` ON `p`.`source` = `t`.`entry`
    WHERE `t`.`patch` = (SELECT MAX(`t2`.`patch`) FROM `item_template` `t2` WHERE `t2`.`entry` = `t`.`entry`);
UPDATE `bonk_gear_items` `i` JOIN `bonk_gear_pick` `p` ON `p`.`source` = `i`.`entry` SET
    `i`.`allowable_class` = `p`.`classes`, `i`.`dmg_min1` = `p`.`dmg_min`, `i`.`dmg_max1` = `p`.`dmg_max`, `i`.`entry` = `p`.`entry`;
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

DELETE FROM `item_template` WHERE `entry` BETWEEN 900405 AND 900413 OR `entry` BETWEEN 901405 AND 901413;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_items`;
UPDATE `bonk_gear_items` SET `entry` = `entry` + 1000, `description` = '' WHERE `quality` >= 4;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_items` WHERE `entry` >= 901405;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900405 AND 900413 OR `entry` BETWEEN 901405 AND 901413;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry`, CASE `quality` WHEN 2 THEN 4 WHEN 3 THEN 7 ELSE 10 END, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 FROM `bonk_gear_pick`;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry` + 1000, 10, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 FROM `bonk_gear_pick` WHERE `quality` >= 4;

DELETE FROM `bonk_gear` WHERE `entry` BETWEEN 900405 AND 900413;
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`)
    SELECT `entry`, `quality`, IF(`quality` >= 4, `entry` + 1000, 0) FROM `bonk_gear_pick`;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_spec`;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_pick`;
DROP TEMPORARY TABLE IF EXISTS `bonk_gear_items`;

DELETE FROM `item_template` WHERE `entry` = 900227;
DROP TEMPORARY TABLE IF EXISTS `bonk_shot`;
CREATE TEMPORARY TABLE `bonk_shot` SELECT * FROM `item_template` WHERE `entry` = 2516
    AND `patch` = (SELECT MAX(`patch`) FROM `item_template` WHERE `entry` = 2516);
UPDATE `bonk_shot` SET `entry` = 900227, `patch` = 0, `name` = 'Darkmoon Shot', `quality` = 2, `buy_price` = 0, `sell_price` = 0,
    `required_level` = 0, `item_level` = 5, `bonding` = 1, `allowable_class` = 4, `allowable_race` = -1, `description` = '';
INSERT INTO `item_template` SELECT * FROM `bonk_shot`;
DROP TEMPORARY TABLE IF EXISTS `bonk_shot`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
