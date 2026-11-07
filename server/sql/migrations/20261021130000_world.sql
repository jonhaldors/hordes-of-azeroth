DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021130000');

UPDATE `spell_template` SET `customFlags` = `customFlags` & ~256 WHERE `entry` = 20183;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
