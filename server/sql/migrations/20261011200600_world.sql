DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011200600');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011200600');

CREATE TABLE IF NOT EXISTS `bonk_upgrade` (
    `id`             INT UNSIGNED     NOT NULL,
    `name`           VARCHAR(64)      NOT NULL,
    `description`    VARCHAR(128)     NOT NULL DEFAULT '' COMMENT 'what one rank does',
    `effect`         TINYINT UNSIGNED NOT NULL COMMENT 'as bonk_passive: 0 might, 1 cooldown, 2 amount, 3 move speed, 4 max health, 5 recovery, 6 greed, 7 growth',
    `value_per_rank` FLOAT            NOT NULL,
    `max_rank`       TINYINT UNSIGNED NOT NULL DEFAULT 5,
    `cost`           INT UNSIGNED     NOT NULL COMMENT 'copper for the first rank',
    `cost_growth`    FLOAT            NOT NULL DEFAULT 1 COMMENT 'each rank owned makes the next cost this share of cost more',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk permanent upgrades';

DELETE FROM `bonk_upgrade`;
INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`) VALUES
(1, 'Might',      '+5% damage',                       0, 5,   5,  6000, 1.0),
(2, 'Haste',      'weapons fire 4% faster',           1, 4,   5,  6000, 1.0),
(3, 'Vitality',   '+10% maximum health',              4, 10,  5,  4000, 1.0),
(4, 'Recovery',   'regain 0.2% health every second',  5, 0.2, 3,  5000, 1.0),
(5, 'Swiftness',  '+5% movement speed',               3, 5,   3,  4000, 1.0),
(6, 'Greed',      '+10% gold',                        6, 10,  5,  5000, 1.0),
(7, 'Growth',     '+5% experience',                   7, 5,   5,  4000, 1.0),
(8, 'Duplicator', '+1 projectile for bolt weapons',   2, 1,   1, 50000, 0.0);

CREATE TABLE IF NOT EXISTS `bonk_talent` (
    `id`             INT UNSIGNED     NOT NULL,
    `name`           VARCHAR(64)      NOT NULL,
    `description`    VARCHAR(128)     NOT NULL DEFAULT '',
    `effect`         TINYINT UNSIGNED NOT NULL COMMENT 'toggles: 0 enemy health %, 1 enemy damage %, 2 enemies per wave %, 3 elites %; perks: 4 rerolls, 5 banishes, 6 revives, 7 starting coins',
    `value_per_rank` FLOAT            NOT NULL,
    `gold_bonus`     FLOAT            NOT NULL DEFAULT 0 COMMENT 'toggles: + gold while switched on, %',
    `max_rank`       TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'toggles always have one rank',
    `cost`           INT UNSIGNED     NOT NULL COMMENT 'copper for the first rank',
    `cost_growth`    FLOAT            NOT NULL DEFAULT 1,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk run unlocks';

DELETE FROM `bonk_talent`;
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`) VALUES
(1, 'Hardened Foes',   '+50% enemy health, +25% gold',          0,  50, 25, 1, 20000, 0.0),
(2, 'Brutal Foes',     '+50% enemy damage, +25% gold',          1,  50, 25, 1, 20000, 0.0),
(3, 'Swarming',        '+50% enemies per wave, +20% gold',      2,  50, 20, 1, 20000, 0.0),
(4, 'Champions',       'twice as many elites, +15% gold',       3, 100, 15, 1, 15000, 0.0),
(5, 'Second Thoughts', 'reroll an upgrade choice once per run', 4,   1,  0, 3, 10000, 1.0),
(6, 'Banishment',      'banish an upgrade once per run',        5,   1,  0, 3, 10000, 1.0),
(7, 'Second Wind',     'revive once per run at half health',    6,   1,  0, 1, 50000, 0.0),
(8, 'Pocket Change',   '+25 coins at the start of a run',       7,  25,  0, 4,  5000, 0.5);

CREATE TABLE IF NOT EXISTS `bonk_item_power` (
    `entry` INT UNSIGNED NOT NULL COMMENT 'item_template',
    `power` FLOAT        NOT NULL COMMENT 'extra auto-weapon damage while worn, %',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk gear power';

DELETE FROM `item_template` WHERE `entry` BETWEEN 900101 AND 900112;
INSERT INTO `item_template` (`entry`, `patch`, `class`, `subclass`, `name`, `description`, `display_id`, `quality`, `buy_count`, `buy_price`, `sell_price`,
    `inventory_type`, `allowable_class`, `allowable_race`, `item_level`, `required_level`, `stackable`, `stat_type1`, `stat_value1`, `armor`,
    `bonding`, `material`, `max_durability`) VALUES
(900101, 0, 4, 0, 'Scrapper\'s Pendant',  'Power +3%: your weapons deal 3% more damage.',   6494, 2, 1,  3000, 0,  2, -1, -1, 10, 0, 1, 7,  3,  0, 1, 0, 0),
(900102, 0, 4, 0, 'Veteran\'s Medallion', 'Power +6%: your weapons deal 6% more damage.',  23716, 3, 1, 15000, 0,  2, -1, -1, 30, 0, 1, 7,  6,  0, 1, 0, 0),
(900103, 0, 4, 0, 'Champion\'s Talisman', 'Power +10%: your weapons deal 10% more damage.',  4841, 4, 1, 50000, 0,  2, -1, -1, 50, 0, 1, 7, 10,  0, 1, 0, 0),
(900104, 0, 4, 0, 'Scrapper\'s Band',     'Power +2%: your weapons deal 2% more damage.',    224, 2, 1,  2500, 0, 11, -1, -1, 10, 0, 1, 7,  2,  0, 1, 0, 0),
(900105, 0, 4, 0, 'Veteran\'s Signet',    'Power +4%: your weapons deal 4% more damage.',  26537, 3, 1, 12000, 0, 11, -1, -1, 30, 0, 1, 7,  4,  0, 1, 0, 0),
(900106, 0, 4, 0, 'Champion\'s Loop',     'Power +7%: your weapons deal 7% more damage.',   9840, 4, 1, 40000, 0, 11, -1, -1, 50, 0, 1, 7,  7,  0, 1, 0, 0),
(900107, 0, 4, 0, 'Lucky Charm',          'Power +4%: your weapons deal 4% more damage.',   8232, 2, 1,  3000, 0, 12, -1, -1, 10, 0, 1, 0,  0,  0, 1, 0, 0),
(900108, 0, 4, 0, 'Battle Token',         'Power +8%: your weapons deal 8% more damage.',   6337, 3, 1, 15000, 0, 12, -1, -1, 30, 0, 1, 0,  0,  0, 1, 0, 0),
(900109, 0, 4, 0, 'Idol of Fury',         'Power +12%: your weapons deal 12% more damage.',24776, 4, 1, 50000, 0, 12, -1, -1, 50, 0, 1, 0,  0,  0, 1, 0, 0),
(900110, 0, 4, 1, 'Scrapper\'s Cape',     'Power +1%: your weapons deal 1% more damage.',  23014, 2, 1,  2500, 0, 16, -1, -1, 10, 0, 1, 7,  2,  8, 1, 7, 0),
(900111, 0, 4, 1, 'Veteran\'s Cloak',     'Power +2%: your weapons deal 2% more damage.',  29824, 3, 1, 12000, 0, 16, -1, -1, 30, 0, 1, 7,  4, 18, 1, 7, 0),
(900112, 0, 4, 1, 'Champion\'s Mantle',   'Power +4%: your weapons deal 4% more damage.',  29827, 4, 1, 40000, 0, 16, -1, -1, 50, 0, 1, 7,  7, 30, 1, 7, 0);

DELETE FROM `bonk_item_power`;
INSERT INTO `bonk_item_power` (`entry`, `power`) VALUES
(900101, 3), (900102, 6), (900103, 10),
(900104, 2), (900105, 4), (900106, 7),
(900107, 4), (900108, 8), (900109, 12),
(900110, 1), (900111, 2), (900112, 4);

DELETE FROM `creature_template` WHERE `entry` IN (900002, 900003, 900004);
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900002, 0, 'Nix Sparkwrench',    'Upgrades', 60, 60, 35, 1,  7028, 1, 1, 7, 1, 1, 262, 'npc_bonk_quartermaster'),
(900003, 0, 'Lorelai Moonwhisper', 'Talents', 60, 60, 35, 1, 12033, 1, 1, 7, 1, 1, 262, 'npc_bonk_talents'),
(900004, 0, 'Durgan Ironbelly',   'Gear',     60, 60, 35, 4,  5037, 1, 1, 7, 1, 1, 262, '');

DELETE FROM `creature` WHERE `guid` IN (900002, 900003, 900004);
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900002, 900002, 1, 16219.0, 16262.5, 13.440, 5.6309, 120, 120, 0, 0),
(900003, 900003, 1, 16232.5, 16262.5, 13.638, 3.8593, 120, 120, 0, 0),
(900004, 900004, 1, 16214.0, 16258.5, 14.354, 6.1608, 120, 120, 0, 0);

DELETE FROM `npc_vendor` WHERE `entry` = 900004;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`) VALUES
(900004,  1, 900101), (900004,  2, 900104), (900004,  3, 900107), (900004,  4, 900110),
(900004,  5, 900102), (900004,  6, 900105), (900004,  7, 900108), (900004,  8, 900111),
(900004,  9, 900103), (900004, 10, 900106), (900004, 11, 900109), (900004, 12, 900112);

DELETE FROM `broadcast_text` WHERE `entry` IN (900003, 900004);
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900003, 'Gold you bring back buys strength that lasts. Every rank you learn here comes with you into every run.',
         'Gold you bring back buys strength that lasts. Every rank you learn here comes with you into every run.'),
(900004, 'Learn a trick or two for the road, or invite more danger for more gold. Click a challenge you know to switch it on or off.',
         'Learn a trick or two for the road, or invite more danger for more gold. Click a challenge you know to switch it on or off.');

DELETE FROM `npc_text` WHERE `ID` IN (900003, 900004);
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES
(900003, 900003, 1),
(900004, 900004, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
