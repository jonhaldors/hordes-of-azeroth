DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016130000');

ALTER TABLE `bonk_card` ADD COLUMN `in_chests` TINYINT UNSIGNED NOT NULL DEFAULT 1 AFTER `max_copies`;

CREATE TABLE IF NOT EXISTS `bonk_item_card` (
    `entry` INT UNSIGNED NOT NULL COMMENT 'item_template',
    `card_id` INT UNSIGNED NOT NULL COMMENT 'bonk_card held while the item is worn',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk: worn items that give a card (legendary effects)';

DELETE FROM `bonk_card` WHERE `id` BETWEEN 101 AND 108;
INSERT INTO `bonk_card` (`id`, `name`, `icon`, `description`, `rarity`, `stat1`, `stat1_value`, `stat2`, `stat2_value`, `effect`, `value1`, `value2`, `value3`, `cooldown_ms`, `max_copies`, `in_chests`) VALUES
(101, 'Thunderfury, Blessed Blade of the Windseeker', 'INV_Sword_39',
      'Your hits have a 6% chance to call Chain Lightning on the target and the 4 enemies nearest it, each struck for 150% of the hit.',
      4, 255, 0, 255, 0, 14, 6, 1.5, 5, 0, 0, 0),
(102, 'Corrupted Ashbringer', 'INV_Sword_62',
      'Your hits have a 5% chance to unleash shadow, dealing 200% of the hit to enemies within 8 yards of the target and healing you for a tenth of it.',
      4, 255, 0, 255, 0, 22, 5, 2, 8, 0, 0, 0),
(103, 'Sulfuras, Hand of Ragnaros', 'INV_Hammer_Unique_Sulfuras',
      'Your hits have a 6% chance to erupt in flame, dealing 200% of the hit to enemies within 8 yards of the target.',
      4, 255, 0, 255, 0, 12, 6, 2, 8, 0, 0, 0),
(104, 'Rhok''delar, Longbow of the Ancient Keepers', 'INV_Weapon_Bow_13',
      'Your spells have a 10% chance to go off again.',
      4, 255, 0, 255, 0, 13, 10, 0, 0, 0, 0, 0),
(105, 'Atiesh, Greatstaff of the Guardian', 'INV_Staff_Medivh',
      '+1 Count and +15% Area.',
      4, 2, 1, 10, 15, 0, 0, 0, 0, 0, 0, 0),
(106, 'Kingsfall', 'INV_Weapon_ShortBlade_29',
      'Your critical strikes have a 50% chance to heal 1% of your maximum health (at most 3% a second).',
      4, 255, 0, 255, 0, 5, 50, 1, 3, 0, 0, 0),
(107, 'Empyrean Demolisher', 'INV_Mace_09',
      'Your spells have a 6% chance to go off again.',
      4, 255, 0, 255, 0, 13, 6, 0, 0, 0, 0, 0),
(108, 'Eye of Sulfuras', 'INV_Jewelry_Necklace_15',
      '+25% damage to elites, mini-bosses and bosses.',
      4, 255, 0, 255, 0, 18, 25, 0, 0, 0, 0, 0);

DROP TEMPORARY TABLE IF EXISTS `bonk_legend_src`;
CREATE TEMPORARY TABLE `bonk_legend_src` (
    `entry` INT UNSIGNED, `source` INT UNSIGNED, `name` VARCHAR(100), `classes` INT,
    `dmg_min` FLOAT, `dmg_max` FLOAT, `power` FLOAT, `crit` FLOAT, `card` INT UNSIGNED
);
INSERT INTO `bonk_legend_src` VALUES
(900420, 19019, 'Thunderfury, Blessed Blade of the Windseeker', 395,  2, 5, 7,  0, 101),
(900421, 22691, 'Corrupted Ashbringer',                         3,    4, 8, 14, 0, 102),
(900422, 17182, 'Sulfuras, Hand of Ragnaros',                   1090, 4, 8, 14, 0, 103),
(900423, 18713, 'Rhok''delar, Longbow of the Ancient Keepers',  4,    2, 5, 14, 0, 104),
(900424, 22589, 'Atiesh, Greatstaff of the Guardian',           1424, 4, 8, 14, 0, 105),
(900425, 22802, 'Kingsfall',                                    392,  2, 4, 7,  0, 106),
(900426, 17112, 'Empyrean Demolisher',                          82,   2, 5, 7,  0, 107),
(900427, 18404, 'Eye of Sulfuras',                              1503, 0, 0, 0,  3, 108);

DROP TEMPORARY TABLE IF EXISTS `bonk_legend_items`;
CREATE TEMPORARY TABLE `bonk_legend_items` SELECT `t`.* FROM `item_template` `t`
    JOIN `bonk_legend_src` `s` ON `s`.`source` = `t`.`entry`
    WHERE `t`.`patch` = (SELECT MAX(`t2`.`patch`) FROM `item_template` `t2` WHERE `t2`.`entry` = `t`.`entry`);
UPDATE `bonk_legend_items` `i` JOIN `bonk_legend_src` `s` ON `s`.`source` = `i`.`entry` JOIN `bonk_card` `c` ON `c`.`id` = `s`.`card` SET
    `i`.`name` = `s`.`name`,
    `i`.`allowable_class` = `s`.`classes`,
    `i`.`dmg_min1` = `s`.`dmg_min`, `i`.`dmg_max1` = `s`.`dmg_max`,
    `i`.`description` = CONCAT(`c`.`description`, ' Run gear: go home through the portal to keep it.'),
    `i`.`entry` = `s`.`entry`;
UPDATE `bonk_legend_items` SET
    `patch` = 0, `flags` = 0, `quality` = 5,
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

DELETE FROM `item_template` WHERE `entry` BETWEEN 900420 AND 900427 OR `entry` BETWEEN 901420 AND 901427;
INSERT INTO `item_template` SELECT * FROM `bonk_legend_items`;
UPDATE `bonk_legend_items` `i` JOIN `bonk_legend_src` `s` ON `s`.`entry` = `i`.`entry` JOIN `bonk_card` `c` ON `c`.`id` = `s`.`card`
    SET `i`.`entry` = `i`.`entry` + 1000, `i`.`description` = `c`.`description`;
INSERT INTO `item_template` SELECT * FROM `bonk_legend_items`;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900420 AND 900427 OR `entry` BETWEEN 901420 AND 901427;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry`, `power`, 0, 0, 0, `crit`, 0, 0, 0, 0, 0, 0, 0 FROM `bonk_legend_src`;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`)
    SELECT `entry` + 1000, `power`, 0, 0, 0, `crit`, 0, 0, 0, 0, 0, 0, 0 FROM `bonk_legend_src`;

DELETE FROM `bonk_gear` WHERE `entry` BETWEEN 900420 AND 900427;
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`) SELECT `entry`, 5, `entry` + 1000 FROM `bonk_legend_src`;

DELETE FROM `bonk_item_card` WHERE `entry` BETWEEN 900420 AND 900427 OR `entry` BETWEEN 901420 AND 901427;
INSERT INTO `bonk_item_card` (`entry`, `card_id`) SELECT `entry`, `card` FROM `bonk_legend_src`;
INSERT INTO `bonk_item_card` (`entry`, `card_id`) SELECT `entry` + 1000, `card` FROM `bonk_legend_src`;

DROP TEMPORARY TABLE IF EXISTS `bonk_legend_src`;
DROP TEMPORARY TABLE IF EXISTS `bonk_legend_items`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
