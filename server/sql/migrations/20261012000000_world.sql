DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012000000');

ALTER TABLE `bonk_map`
    ADD COLUMN `max_alive_start`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'most enemies alive at once as a stage starts, 0 = max_alive',
    ADD COLUMN `max_alive_ramp_sec` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'seconds for that cap to grow to max_alive';

UPDATE `bonk_map` SET `spawn_interval_ms` = 2600, `spawn_batch` = 1.0, `spawn_batch_growth_per_min` = 0.6,
    `max_alive_start` = 12, `max_alive_ramp_sec` = 300 WHERE `id` IN (1, 3, 4);

UPDATE `bonk_map` SET `spawn_interval_ms` = 2200, `spawn_batch` = 1.5, `spawn_batch_growth_per_min` = 0.8,
    `max_alive_start` = 16, `max_alive_ramp_sec` = 270 WHERE `id` IN (7, 8, 9);

UPDATE `bonk_map` SET `spawn_interval_ms` = 1800, `spawn_batch` = 2.0, `spawn_batch_growth_per_min` = 1.0,
    `max_alive_start` = 22, `max_alive_ramp_sec` = 240 WHERE `id` IN (2, 5);
UPDATE `bonk_map` SET `spawn_interval_ms` = 1600, `spawn_batch` = 2.5, `spawn_batch_growth_per_min` = 1.1,
    `max_alive_start` = 22, `max_alive_ramp_sec` = 240 WHERE `id` = 6;

UPDATE `bonk_map_event` SET `count` = 10 WHERE `bonk_map_id` = 1 AND `second` = 150 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 12 WHERE `bonk_map_id` = 1 AND `second` = 180 AND `event` = 2;
UPDATE `bonk_map_event` SET `second` = 160, `count` = 10 WHERE `bonk_map_id` = 3 AND `second` = 100 AND `event` = 5;
UPDATE `bonk_map_event` SET `count` = 14 WHERE `bonk_map_id` = 3 AND `second` = 200 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 12 WHERE `bonk_map_id` = 3 AND `second` = 270 AND `event` = 4;
UPDATE `bonk_map_event` SET `second` = 160, `count` = 10 WHERE `bonk_map_id` = 4 AND `second` = 120 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 12 WHERE `bonk_map_id` = 4 AND `second` = 180 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 12 WHERE `bonk_map_id` = 4 AND `second` = 240 AND `event` = 5;
UPDATE `bonk_map_event` SET `second` = 120, `count` = 14 WHERE `bonk_map_id` = 7 AND `second` = 100 AND `event` = 5;
UPDATE `bonk_map_event` SET `count` = 18 WHERE `bonk_map_id` = 7 AND `second` = 200 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 16 WHERE `bonk_map_id` = 7 AND `second` = 270 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 14 WHERE `bonk_map_id` = 8 AND `second` = 120 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 18 WHERE `bonk_map_id` = 8 AND `second` = 180 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 16 WHERE `bonk_map_id` = 8 AND `second` = 240 AND `event` = 5;
UPDATE `bonk_map_event` SET `second` = 120, `count` = 14 WHERE `bonk_map_id` = 9 AND `second` = 90 AND `event` = 5;
UPDATE `bonk_map_event` SET `count` = 14 WHERE `bonk_map_id` = 9 AND `second` = 180 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 18 WHERE `bonk_map_id` = 9 AND `second` = 240 AND `event` = 2;
UPDATE `bonk_map_event` SET `second` = 120, `count` = 14 WHERE `bonk_map_id` = 2 AND `second` = 90 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 20 WHERE `bonk_map_id` = 2 AND `second` = 150 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 20 WHERE `bonk_map_id` = 2 AND `second` = 210 AND `event` = 5;
UPDATE `bonk_map_event` SET `second` = 120, `count` = 16 WHERE `bonk_map_id` = 5 AND `second` = 90 AND `event` = 5;
UPDATE `bonk_map_event` SET `count` = 20 WHERE `bonk_map_id` = 5 AND `second` = 150 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 18 WHERE `bonk_map_id` = 5 AND `second` = 210 AND `event` = 4;
UPDATE `bonk_map_event` SET `second` = 90, `count` = 18 WHERE `bonk_map_id` = 6 AND `second` = 60 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 16 WHERE `bonk_map_id` = 6 AND `second` = 120 AND `event` = 4;
UPDATE `bonk_map_event` SET `count` = 24 WHERE `bonk_map_id` = 6 AND `second` = 180 AND `event` = 2;
UPDATE `bonk_map_event` SET `count` = 22 WHERE `bonk_map_id` = 6 AND `second` = 270 AND `event` = 5;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
