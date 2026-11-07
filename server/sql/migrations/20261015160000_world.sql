DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015160000');

DROP TABLE IF EXISTS `bonk_wave`;
CREATE TABLE `bonk_wave` (
    `start_sec`          INT UNSIGNED     NOT NULL COMMENT 'into a stage; lasts until the next block',
    `name`               VARCHAR(48)      NOT NULL DEFAULT '' COMMENT 'walls are announced by it',
    `beat`               TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 build-up, 1 lull, 2 wall, 3 mini-boss',
    `swarmer`            INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'roster weights by archetype',
    `grunt`              INT UNSIGNED     NOT NULL DEFAULT 0,
    `bruiser`            INT UNSIGNED     NOT NULL DEFAULT 0,
    `caster`             INT UNSIGNED     NOT NULL DEFAULT 0,
    `charger`            INT UNSIGNED     NOT NULL DEFAULT 0,
    `crowd_start`        FLOAT            NOT NULL DEFAULT 0 COMMENT 'roster enemies kept alive at its start (Easy)...',
    `crowd_end`          FLOAT            NOT NULL DEFAULT 0 COMMENT '...rising to this at its end',
    `spawn_per_tick`     INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'a second; 0 = the usual',
    `max_bruisers`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '0 = the tier''s',
    `elite_interval_sec` INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '0 = none',
    `elites`             INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'arrive at its start',
    `minibosses`         INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'arrive at its start',
    `mini_events`        INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'a slot: bits 1 horde, 2 goblin, 4 bounty',
    PRIMARY KEY (`start_sec`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk stage timeline';

INSERT INTO `bonk_wave` (`start_sec`, `name`, `beat`, `swarmer`, `grunt`, `bruiser`, `caster`, `charger`, `crowd_start`, `crowd_end`,
    `spawn_per_tick`, `max_bruisers`, `elite_interval_sec`, `elites`, `minibosses`, `mini_events`) VALUES
(0,   'Opening',              0, 100,   0,   0,   0,   0,  15,  25,  0,  0,  0, 0, 0, 0),
(60,  'Build-up',             0,  40,  60,   0,   0,   0,  25,  33,  0,  0,  0, 0, 0, 0),
(120, 'Build-up',             0,  40,  60,   0,   0,   0,  33,  40,  0,  0,  0, 0, 0, 7),
(150, 'Lull',                 1, 100,   0,   0,   0,   0,  20,  20,  0,  0,  0, 0, 0, 0),
(180, 'Mini-boss',            3, 100,   0,   0,   0,   0,  15,  15,  0,  0,  0, 0, 1, 0),
(195, 'Build-up',             0,   0,  70,   0,  30,   0,  40,  43,  0,  0,  0, 0, 0, 0),
(210, 'Build-up',             0,   0,  70,   0,  30,   0,  43,  50,  0,  0,  0, 1, 0, 0),
(240, 'Brutes incoming',      2,   0,   0, 100,   0,   0,  14,  14,  4, 16,  0, 0, 0, 0),
(285, 'Breather',             1, 100,   0,   0,   0,   0,  20,  20,  0,  0,  0, 0, 0, 6),
(315, 'Build-up',             0,   0,  50,   0,  25,  25,  50,  80,  0,  0, 75, 0, 0, 0),
(420, 'Here comes the swarm', 2,  50,  50,   0,   0,   0, 120, 120, 20,  0,  0, 2, 0, 1),
(465, 'Breather',             1, 100,   0,   0,   0,   0,  40,  40,  0,  0,  0, 0, 0, 0),
(480, 'Mini-boss',            3, 100,   0,   0,   0,   0,  25,  25,  0,  0,  0, 0, 1, 0),
(495, 'Peak',                 0,  20,  40,  20,  10,  10,  90, 110,  0,  0, 60, 0, 0, 0),
(525, 'Peak',                 0,  20,  40,  20,  10,  10, 110, 140,  0,  0, 60, 0, 0, 7),
(570, 'Lull',                 1, 100,   0,   0,   0,   0,  40,  40,  0,  0,  0, 0, 0, 0),
(600, 'Boss',                 0,  30,  40,   0,  15,  15,  80,  80,  0,  0,  0, 0, 0, 0);

DROP TABLE IF EXISTS `bonk_scaling`;
CREATE TABLE `bonk_scaling` (
    `minute`    FLOAT NOT NULL COMMENT 'of the run, all stages',
    `hit_share` FLOAT NOT NULL COMMENT 'a grunt hit, % of the hero''s base health (before stage and difficulty)',
    `health`    FLOAT NOT NULL COMMENT 'enemy toughness, times its table health',
    PRIMARY KEY (`minute`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk enemy scaling over a run';

INSERT INTO `bonk_scaling` (`minute`, `hit_share`, `health`) VALUES
(0,  5,  1.0),
(2,  6,  1.6),
(4,  7,  2.4),
(6,  8,  3.3),
(8,  9,  4.2),
(10, 10, 5.0);

DROP TABLE IF EXISTS `bonk_spawn_curve`;

UPDATE `bonk_archetype` SET `damage_multiplier` = 0.6 WHERE `id` = 0;
UPDATE `bonk_archetype` SET `damage_multiplier` = 1.0 WHERE `id` IN (1, 3, 4);
UPDATE `bonk_archetype` SET `damage_multiplier` = 2.0 WHERE `id` = 2;

UPDATE `bonk_tier` SET `health_multiplier` = 1.0,  `damage_multiplier` = 1.0  WHERE `key` = 'easy';
UPDATE `bonk_tier` SET `health_multiplier` = 1.25, `damage_multiplier` = 1.25 WHERE `key` = 'medium';
UPDATE `bonk_tier` SET `health_multiplier` = 1.5,  `damage_multiplier` = 1.5  WHERE `key` = 'hard';

UPDATE `bonk_map` SET `health_multiplier` = 1, `damage_multiplier` = 1, `health_growth_per_min` = 0, `damage_growth_per_min` = 0;

DELETE FROM `bonk_map_event` WHERE `event` <> 3;

UPDATE `bonk_passive` SET `value_per_rank` = 0.2, `description` = 'Regain 0.2% of your health every second.' WHERE `id` = 6;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
