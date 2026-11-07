DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020996000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020996000');

UPDATE `gameobject_template` SET `size` = 0.9 WHERE `entry` = 900002;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
