DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019170000');

UPDATE `bonk_wave` SET `crowd_end` = 62.857 WHERE `start_sec` = 315;

DELETE FROM `bonk_wave` WHERE `start_sec` = 360;
INSERT INTO `bonk_wave` (`start_sec`, `name`, `beat`, `swarmer`, `grunt`, `bruiser`, `caster`, `charger`, `crowd_start`, `crowd_end`,
    `spawn_per_tick`, `max_bruisers`, `elite_interval_sec`, `elites`, `minibosses`, `mini_events`) VALUES
(360, 'Build-up', 0, 0, 50, 0, 25, 25, 62.857, 66, 0, 0, 30, 0, 0, 0);

UPDATE `bonk_wave` SET `crowd_start` = 80, `crowd_end` = 80, `spawn_per_tick` = 0 WHERE `start_sec` = 420;
UPDATE `bonk_wave` SET `crowd_start` = 30, `crowd_end` = 30 WHERE `start_sec` = 465;
UPDATE `bonk_wave` SET `crowd_start` = 20, `crowd_end` = 20 WHERE `start_sec` = 480;
UPDATE `bonk_wave` SET `crowd_start` = 60, `crowd_end` = 70 WHERE `start_sec` = 495;
UPDATE `bonk_wave` SET `crowd_start` = 70, `crowd_end` = 85 WHERE `start_sec` = 525;
UPDATE `bonk_wave` SET `crowd_start` = 30, `crowd_end` = 30 WHERE `start_sec` = 570;
UPDATE `bonk_wave` SET `crowd_start` = 50, `crowd_end` = 50 WHERE `start_sec` = 600;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
