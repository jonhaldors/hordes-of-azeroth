DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013005000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013005000');

UPDATE `creature_template` SET `display_id1` = 16587, `display_scale1` = 1.8 WHERE `entry` = 900102;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
