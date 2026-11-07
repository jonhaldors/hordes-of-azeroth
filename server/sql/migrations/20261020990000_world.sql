DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020990000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020990000');

UPDATE `bonk_glyph` SET `icon` = 'Ability_Tracking' WHERE `id` = 24;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
