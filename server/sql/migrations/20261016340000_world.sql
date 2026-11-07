DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016340000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016340000');

UPDATE `bonk_wave` SET `mini_events` = `mini_events` | 128 WHERE `start_sec` = 285;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
