DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019100000');

UPDATE `bonk_wave` SET `name` = 'Swarm' WHERE `start_sec` = 420;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
