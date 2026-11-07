DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021120000');

UPDATE `spell_template` SET `spellFamilyName` = 0, `spellFamilyFlags` = 0, `baseLevel` = 0 WHERE `entry` = 20183;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
