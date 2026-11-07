DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200025');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200025');

UPDATE `bonk_upgrade` SET `name` = 'Area' WHERE `id` = 47;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
