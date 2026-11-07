DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012010000');

RENAME TABLE `bonk_item_power` TO `bonk_item_stat`;
ALTER TABLE `bonk_item_stat`
    COMMENT = 'Vanilla Bonk gear stats',
    ADD COLUMN `defense` FLOAT        NOT NULL DEFAULT 0 COMMENT 'less damage taken from enemies in a run, %' AFTER `power`,
    ADD COLUMN `set_id`  INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'bonk_item_set, 0 = none' AFTER `defense`;

CREATE TABLE IF NOT EXISTS `bonk_item_set` (
    `id`   INT UNSIGNED NOT NULL,
    `name` VARCHAR(64)  NOT NULL,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk item sets';

CREATE TABLE IF NOT EXISTS `bonk_item_set_bonus` (
    `set_id`         INT UNSIGNED     NOT NULL,
    `pieces`         TINYINT UNSIGNED NOT NULL COMMENT 'pieces worn to get the bonus',
    `power`          FLOAT            NOT NULL DEFAULT 0,
    `defense`        FLOAT            NOT NULL DEFAULT 0,
    `passive_effect` TINYINT UNSIGNED NOT NULL DEFAULT 255 COMMENT 'bonk_passive effect it adds to, 255 = none',
    `passive_value`  FLOAT            NOT NULL DEFAULT 0,
    `description`    VARCHAR(128)     NOT NULL,
    PRIMARY KEY (`set_id`, `pieces`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk item set bonuses';

UPDATE `item_template` SET `description` = '' WHERE `entry` BETWEEN 900101 AND 900112;

DELETE FROM `item_template` WHERE `entry` BETWEEN 900113 AND 900132;
INSERT INTO `item_template` (`entry`, `patch`, `class`, `subclass`, `name`, `description`, `display_id`, `quality`, `buy_count`, `buy_price`, `sell_price`,
    `inventory_type`, `allowable_class`, `allowable_race`, `item_level`, `required_level`, `stackable`, `stat_type1`, `stat_value1`, `armor`,
    `bonding`, `material`, `max_durability`) VALUES
(900113, 0, 4, 1, 'Recruit\'s Sash',                '', 17121, 2, 1,   3000, 0,  6, -1, -1, 10, 0, 1, 0, 0, 0, 1, 7, 0),
(900114, 0, 4, 1, 'Recruit\'s Sandals',             '',  3036, 2, 1,   3000, 0,  8, -1, -1, 10, 0, 1, 0, 0, 0, 1, 7, 0),
(900115, 0, 4, 1, 'Recruit\'s Bracers',             '', 17009, 2, 1,   3000, 0,  9, -1, -1, 10, 0, 1, 0, 0, 0, 1, 7, 0),
(900116, 0, 4, 1, 'Recruit\'s Gloves',              '', 17061, 2, 1,   3000, 0, 10, -1, -1, 10, 0, 1, 0, 0, 0, 1, 7, 0),
(900117, 0, 4, 1, 'Warden\'s Girdle',               '', 31353, 3, 1,  15000, 0,  6, -1, -1, 30, 0, 1, 0, 0, 0, 1, 7, 0),
(900118, 0, 4, 1, 'Warden\'s Boots',                '', 31354, 3, 1,  15000, 0,  8, -1, -1, 30, 0, 1, 0, 0, 0, 1, 7, 0),
(900119, 0, 4, 1, 'Warden\'s Bracers',              '', 31509, 3, 1,  15000, 0,  9, -1, -1, 30, 0, 1, 0, 0, 0, 1, 7, 0),
(900120, 0, 4, 1, 'Warden\'s Gauntlets',            '', 31507, 3, 1,  15000, 0, 10, -1, -1, 30, 0, 1, 0, 0, 0, 1, 7, 0),
(900121, 0, 4, 1, 'Juggernaut Belt',                '', 31019, 4, 1,  50000, 0,  6, -1, -1, 50, 0, 1, 0, 0, 0, 1, 7, 0),
(900122, 0, 4, 1, 'Juggernaut Sabatons',            '', 31025, 4, 1,  50000, 0,  8, -1, -1, 50, 0, 1, 0, 0, 0, 1, 7, 0),
(900123, 0, 4, 1, 'Juggernaut Bracers',             '', 31020, 4, 1,  50000, 0,  9, -1, -1, 50, 0, 1, 0, 0, 0, 1, 7, 0),
(900124, 0, 4, 1, 'Juggernaut Gauntlets',           '', 31022, 4, 1,  50000, 0, 10, -1, -1, 50, 0, 1, 0, 0, 0, 1, 7, 0),
(900125, 0, 4, 1, 'Helm of the Unbroken',           '', 34215, 4, 1, 150000, 0,  1, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900126, 0, 4, 1, 'Pauldrons of the Unbroken',      '', 34253, 4, 1, 120000, 0,  3, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900127, 0, 4, 1, 'Breastplate of the Unbroken',    '', 33983, 4, 1, 180000, 0,  5, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900128, 0, 4, 1, 'Legplates of the Unbroken',      '', 33986, 4, 1, 150000, 0,  7, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900129, 0, 4, 1, 'Crown of Slaughter',             '', 34369, 4, 1, 150000, 0,  1, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900130, 0, 4, 1, 'Mantle of Slaughter',            '', 34022, 4, 1, 120000, 0,  3, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900131, 0, 4, 1, 'Robes of Slaughter',             '', 34014, 4, 1, 180000, 0, 20, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0),
(900132, 0, 4, 1, 'Leggings of Slaughter',          '', 29857, 4, 1, 150000, 0,  7, -1, -1, 60, 0, 1, 0, 0, 0, 1, 7, 0);

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900113 AND 900132;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `defense`, `set_id`) VALUES
(900113, 0, 2, 0), (900114, 0, 2, 0), (900115, 1, 1, 0), (900116, 2, 0, 0),
(900117, 0, 4, 0), (900118, 0, 4, 0), (900119, 2, 2, 0), (900120, 3, 2, 0),
(900121, 0, 7, 0), (900122, 0, 7, 0), (900123, 3, 4, 0), (900124, 5, 3, 0),
(900125, 0, 6, 1), (900126, 0, 5, 1), (900127, 0, 7, 1), (900128, 0, 6, 1),
(900129, 6, 0, 2), (900130, 5, 0, 2), (900131, 7, 0, 2), (900132, 6, 0, 2);

DELETE FROM `bonk_item_set` WHERE `id` IN (1, 2);
INSERT INTO `bonk_item_set` (`id`, `name`) VALUES
(1, 'Battlegear of the Unbroken'),
(2, 'Regalia of Slaughter');

DELETE FROM `bonk_item_set_bonus` WHERE `set_id` IN (1, 2);
INSERT INTO `bonk_item_set_bonus` (`set_id`, `pieces`, `power`, `defense`, `passive_effect`, `passive_value`, `description`) VALUES
(1, 2, 0,  0,  4, 10, '+10% maximum health.'),
(1, 4, 0, 10,  5,  1, '+10% Defense, and regain 1% health every second.'),
(2, 2, 0,  0,  1,  8, 'Weapons fire 8% faster.'),
(2, 4, 15, 0,  9,  3, '+15% Power, and heal for 3% of the damage your weapons deal.');

DELETE FROM `npc_vendor` WHERE `entry` = 900004;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`) VALUES
(900004,  1, 900101), (900004,  2, 900104), (900004,  3, 900107), (900004,  4, 900110),
(900004,  5, 900113), (900004,  6, 900114), (900004,  7, 900115), (900004,  8, 900116),
(900004,  9, 900102), (900004, 10, 900105), (900004, 11, 900108), (900004, 12, 900111),
(900004, 13, 900117), (900004, 14, 900118), (900004, 15, 900119), (900004, 16, 900120),
(900004, 17, 900103), (900004, 18, 900106), (900004, 19, 900109), (900004, 20, 900112),
(900004, 21, 900121), (900004, 22, 900122), (900004, 23, 900123), (900004, 24, 900124),
(900004, 25, 900125), (900004, 26, 900126), (900004, 27, 900127), (900004, 28, 900128),
(900004, 29, 900129), (900004, 30, 900130), (900004, 31, 900131), (900004, 32, 900132);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
