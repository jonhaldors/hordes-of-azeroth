DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020992000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020992000');

UPDATE `bonk_wave` SET `crowd_start` = 40, `crowd_end` = 50, `spawn_per_tick` = 18 WHERE `start_sec` = 120;
UPDATE `bonk_wave` SET `crowd_start` = 25, `crowd_end` = 25 WHERE `start_sec` = 150;
UPDATE `bonk_wave` SET `crowd_start` = 50, `crowd_end` = 54, `spawn_per_tick` = 18 WHERE `start_sec` = 195;
UPDATE `bonk_wave` SET `crowd_start` = 54, `crowd_end` = 62, `spawn_per_tick` = 18 WHERE `start_sec` = 210;
UPDATE `bonk_wave` SET `crowd_start` = 25, `crowd_end` = 25 WHERE `start_sec` = 285;
UPDATE `bonk_wave` SET `crowd_start` = 62, `crowd_end` = 72, `spawn_per_tick` = 18 WHERE `start_sec` = 315;
UPDATE `bonk_wave` SET `crowd_start` = 72, `crowd_end` = 80, `spawn_per_tick` = 18 WHERE `start_sec` = 360;
UPDATE `bonk_wave` SET `start_sec` = 580, `swarmer` = 50, `grunt` = 50, `crowd_start` = 50, `crowd_end` = 50 WHERE `start_sec` = 570;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
