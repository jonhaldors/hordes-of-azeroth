DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011191000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011191000');

CREATE TABLE IF NOT EXISTS `bonk_tier` (
    `id`                  TINYINT UNSIGNED NOT NULL,
    `key`                 VARCHAR(32)      NOT NULL COMMENT 'name used by .bonk start',
    `name`                VARCHAR(64)      NOT NULL,
    `health_multiplier`   FLOAT            NOT NULL DEFAULT 1,
    `damage_multiplier`   FLOAT            NOT NULL DEFAULT 1,
    `stage_health_growth` FLOAT            NOT NULL DEFAULT 0.75 COMMENT 'extra enemy health per stage after the first',
    `stage_damage_growth` FLOAT            NOT NULL DEFAULT 0.35 COMMENT 'extra enemy damage per stage after the first',
    `stage_spawn_growth`  FLOAT            NOT NULL DEFAULT 0.2  COMMENT 'extra enemies per wave per stage after the first',
    `chest_cost`          INT UNSIGNED     NOT NULL DEFAULT 20   COMMENT 'coins for the first chest bought in a run',
    `chest_cost_growth`   FLOAT            NOT NULL DEFAULT 1    COMMENT 'price increase per chest bought, as a share of chest_cost',
    `unlock_tier`         TINYINT UNSIGNED NOT NULL DEFAULT 0    COMMENT 'reach unlock_stage on this tier to unlock; 0 = always open',
    `unlock_stage`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`),
    UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk difficulties';

DELETE FROM `bonk_tier`;
INSERT INTO `bonk_tier` (`id`, `key`, `name`, `health_multiplier`, `damage_multiplier`, `stage_health_growth`, `stage_damage_growth`,
    `stage_spawn_growth`, `chest_cost`, `chest_cost_growth`, `unlock_tier`, `unlock_stage`) VALUES
(1, 'easy', 'Easy', 1.0, 1.0, 0.75, 0.35, 0.20, 20, 1.0, 0, 0),
(2, 'hard', 'Hard', 1.0, 1.0, 0.90, 0.40, 0.25, 30, 1.0, 1, 3);

ALTER TABLE `bonk_map`
    CHANGE `difficulty`   `tier`         TINYINT UNSIGNED NOT NULL DEFAULT 1    COMMENT 'bonk_tier whose pool the map is in',
    CHANGE `duration_sec` `duration_sec` INT UNSIGNED     NOT NULL DEFAULT 600  COMMENT 'the stage boss arrives after this long',
    CHANGE `victory_gold` `stage_gold`   INT UNSIGNED     NOT NULL DEFAULT 5000 COMMENT 'copper for the stage boss, times the stage number',
    ADD COLUMN `coins_per_kill` INT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'in-run currency for chests' AFTER `stage_gold`;

UPDATE `bonk_map` SET `tier` = 1 WHERE `id` = 1;
UPDATE `bonk_map` SET `tier` = 2, `duration_sec` = 600 WHERE `id` = 2;

ALTER TABLE `bonk_map_creature`
    MODIFY `kind`    TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 normal, 1 elite, 2 stage boss, 3 mini-boss',
    MODIFY `min_sec` INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'seconds into the stage',
    MODIFY `max_sec` INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '0 = until the stage ends';

DELETE FROM `bonk_map_creature` WHERE `kind` = 3;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `min_sec`, `max_sec`, `weight`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(1,   644, 3,   0,   0,  2, 1.0, 1.0, 0.80, 1.3),
(1,   646, 3,   0,   0,  2, 1.0, 1.0, 0.80, 1.3),
(1,   647, 3,   0,   0,  1, 1.0, 1.0, 0.80, 1.3),
(2, 12118, 3,   0,   0,  2, 1.0, 1.0, 0.80, 0.6),
(2, 12259, 3,   0,   0,  2, 1.0, 1.0, 0.80, 0.6),
(2, 12057, 3,   0,   0,  1, 1.2, 1.0, 0.70, 0.5);

CREATE TABLE IF NOT EXISTS `bonk_map_event` (
    `bonk_map_id` TINYINT UNSIGNED NOT NULL,
    `second`      INT UNSIGNED     NOT NULL COMMENT 'seconds into the stage',
    `event`       TINYINT UNSIGNED NOT NULL COMMENT '0 mini-boss, 1 elites, 2 swarm of normal enemies, 3 chests that cost coins',
    `count`       INT UNSIGNED     NOT NULL DEFAULT 1,
    PRIMARY KEY (`bonk_map_id`, `second`, `event`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk timed stage events';

DELETE FROM `bonk_map_event`;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(1,   0, 3,  2),
(1, 120, 3,  1),
(1, 180, 2, 20),
(1, 300, 0,  1),
(1, 330, 3,  1),
(1, 420, 1,  2),
(1, 480, 2, 30),
(1, 540, 3,  1),
(2,   0, 3,  2),
(2, 150, 2, 25),
(2, 240, 3,  1),
(2, 300, 0,  1),
(2, 360, 1,  3),
(2, 420, 3,  1),
(2, 480, 2, 40),
(2, 540, 3,  1);

DELETE FROM `gameobject_template` WHERE `entry` IN (900001, 900002, 900003);
INSERT INTO `gameobject_template` (`entry`, `patch`, `type`, `displayId`, `name`, `size`, `script_name`) VALUES
(900001, 0, 10,  259, 'Treasure Chest', 1.0, 'go_bonk_chest'),
(900002, 0, 10, 1387, 'Elite Chest',    1.2, 'go_bonk_chest'),
(900003, 0, 10, 4396, 'Portal',         1.0, 'go_bonk_portal');

DELETE FROM `broadcast_text` WHERE `entry` = 900002;
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900002, 'The portal hums. Beyond it waits a harder fight, or the way home.',
         'The portal hums. Beyond it waits a harder fight, or the way home.');

DELETE FROM `npc_text` WHERE `ID` = 900002;
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES
(900002, 900002, 1);

UPDATE `broadcast_text` SET
    `male_text`   = 'Back already, $n? Pick a difficulty and I\'ll send you in. Every stage is harder than the last, so go as deep as you dare.$B$BWin or lose, you wake up right here.',
    `female_text` = 'Back already, $n? Pick a difficulty and I\'ll send you in. Every stage is harder than the last, so go as deep as you dare.$B$BWin or lose, you wake up right here.'
WHERE `entry` = 900001;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
