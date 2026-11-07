DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016300000');

UPDATE `bonk_wave` SET `mini_events` = 1 | 2 | 4 | 8 | 64 WHERE `start_sec` = 120;
UPDATE `bonk_wave` SET `mini_events` = 2 | 4 | 8 | 16 | 32 WHERE `start_sec` = 285;
UPDATE `bonk_wave` SET `mini_events` = 1 | 64 WHERE `start_sec` = 420;
UPDATE `bonk_wave` SET `mini_events` = 1 | 2 | 4 | 8 | 64 WHERE `start_sec` = 525;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
