DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018230000');

UPDATE `bonk_weapon` SET `icon` = 'Spell_Nature_Tranquility' WHERE `id` = 733;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Nature_ProtectionformNature' WHERE `id` = 734;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
