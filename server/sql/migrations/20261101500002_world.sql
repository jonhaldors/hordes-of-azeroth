DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101500002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101500002');

UPDATE `creature_template` SET `name` = 'Your Vault' WHERE `entry` = 900191;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
