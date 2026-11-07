DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013012600');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013012600');

UPDATE `creature_template` SET `name` = '' WHERE `entry` = 900111;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
