DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025330000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025330000');

UPDATE `bonk_weapon` SET `icon` = 'Spell_Holy_SearingLight' WHERE `id` = 1016;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
