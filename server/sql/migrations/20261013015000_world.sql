DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013015000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013015000');

DELETE FROM `bonk_weapon` WHERE `id` IN (200, 210);

UPDATE `bonk_weapon` SET `spell_id` = 13810, `alt_spell_id` = 0 WHERE `id` = 204;
UPDATE `bonk_weapon` SET `spell_id` = 13810 WHERE `id` = 214;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
