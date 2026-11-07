DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012160000');

CREATE TABLE IF NOT EXISTS `bonk_archetype` (
    `id`                TINYINT UNSIGNED NOT NULL COMMENT '0 swarmer, 1 grunt, 2 bruiser, 3 caster, 4 charger',
    `name`              VARCHAR(32)      NOT NULL,
    `health_multiplier` FLOAT            NOT NULL DEFAULT 1 COMMENT 'times a grunt''s health',
    `damage_multiplier` FLOAT            NOT NULL DEFAULT 1,
    `experience`        FLOAT            NOT NULL DEFAULT 1 COMMENT 'times a grunt''s experience',
    `first_sec`         INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'into a stage before it shows up, stage 1',
    `first_sec_later`   INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'the same from stage 2 on',
    `orb`               TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 blue, 1 green, 2 red',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk enemy archetypes';

DELETE FROM `bonk_archetype`;
INSERT INTO `bonk_archetype` (`id`, `name`, `health_multiplier`, `damage_multiplier`, `experience`, `first_sec`, `first_sec_later`, `orb`) VALUES
(0, 'Swarmer', 0.5, 0.7, 0.5,   0,   0, 0),
(1, 'Grunt',   1.0, 1.0, 1.0,   0,   0, 0),
(2, 'Bruiser', 5.0, 1.8, 4.0, 120,  60, 1),
(3, 'Caster',  1.0, 1.0, 1.0, 180, 180, 0),
(4, 'Charger', 1.5, 1.2, 1.0, 240, 240, 0);

CREATE TABLE IF NOT EXISTS `bonk_spawn_curve` (
    `second`             INT UNSIGNED NOT NULL COMMENT 'into a stage',
    `min_alive`          FLOAT        NOT NULL COMMENT 'normal enemies kept alive at this second, rising evenly to the next point',
    `bruiser_share`      FLOAT        NOT NULL DEFAULT 0 COMMENT '% of new enemies that are bruisers, from this second',
    `elite_interval_sec` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'an elite this often from this second, 0 = none',
    PRIMARY KEY (`second`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk spawn curve, Easy stage 1';

DELETE FROM `bonk_spawn_curve`;
INSERT INTO `bonk_spawn_curve` (`second`, `min_alive`, `bruiser_share`, `elite_interval_sec`) VALUES
(  0,  25,  0,  0),
(120,  50,  5, 90),
(240,  75, 10, 90),
(360, 100, 15, 75),
(480, 130, 20, 60),
(600, 160, 20, 60);

ALTER TABLE `bonk_tier`
    DROP COLUMN `stage_spawn_growth`,
    ADD COLUMN `stage_health_accel` FLOAT NOT NULL DEFAULT 0.05 COMMENT 'enemy health at stage s: 1 + growth (s - 1) + accel (s - 1)(s - 2)' AFTER `stage_damage_growth`,
    ADD COLUMN `stage_damage_accel` FLOAT NOT NULL DEFAULT 0.05 AFTER `stage_health_accel`,
    ADD COLUMN `min_alive_multiplier` FLOAT NOT NULL DEFAULT 1 COMMENT 'times the spawn curve''s crowd' AFTER `elite_affixes`,
    ADD COLUMN `max_alive` INT UNSIGNED NOT NULL DEFAULT 200 COMMENT 'enemies alive at once; a bigger crowd makes enemies tougher instead' AFTER `min_alive_multiplier`,
    ADD COLUMN `max_bruisers` INT UNSIGNED NOT NULL DEFAULT 8 AFTER `max_alive`,
    ADD COLUMN `first_elite_sec` INT UNSIGNED NOT NULL DEFAULT 150 COMMENT 'into a stage' AFTER `max_bruisers`;
UPDATE `bonk_tier` SET `stage_health_growth` = 0.25, `stage_damage_growth` = 0.25, `stage_health_accel` = 0.05, `stage_damage_accel` = 0.05;
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.0 WHERE `key` = 'easy';
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.3 WHERE `key` = 'medium';
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.6 WHERE `key` = 'hard';

ALTER TABLE `bonk_map`
    DROP COLUMN `spawn_interval_ms`,
    DROP COLUMN `spawn_batch`,
    DROP COLUMN `spawn_batch_growth_per_min`,
    DROP COLUMN `max_alive`,
    DROP COLUMN `max_alive_start`,
    DROP COLUMN `max_alive_ramp_sec`,
    DROP COLUMN `elite_interval_sec`;

ALTER TABLE `bonk_map_creature`
    ADD COLUMN `archetype` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'normal enemies: 0 swarmer, 1 grunt, 2 bruiser, 3 caster, 4 charger' AFTER `kind`;
UPDATE `bonk_map_creature` mc LEFT JOIN `bonk_mob` m ON m.`entry` = mc.`entry`
SET mc.`archetype` = CASE
    WHEN IFNULL(m.`role`, 0) = 1 THEN 3
    WHEN IFNULL(m.`role`, 0) = 2 THEN 0
    WHEN EXISTS (SELECT 1 FROM `bonk_mob_ability` a WHERE a.`entry` = mc.`entry` AND a.`spell_id` IN (22911, 6268)) THEN 4
    WHEN mc.`health_multiplier` >= 1.6 THEN 2
    WHEN mc.`health_multiplier` <= 0.8 THEN 0
    ELSE 1 END
WHERE mc.`kind` = 0;
UPDATE `bonk_map_creature` SET `min_sec` = 0, `max_sec` = 0 WHERE `kind` = 0 AND `archetype` = 2;
UPDATE `bonk_map_creature` SET `health_multiplier` = 1, `damage_multiplier` = 1 WHERE `kind` = 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
