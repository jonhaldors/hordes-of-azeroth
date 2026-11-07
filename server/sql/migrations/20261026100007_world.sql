DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100007');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100007');

UPDATE `bonk_mastery` SET `icon` = 'spell_holy_holyprotection' WHERE `id` = 20214;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
