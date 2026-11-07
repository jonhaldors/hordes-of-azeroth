DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031110000');

UPDATE `bonk_mob_ability` SET `impact_kit` = 1066 WHERE `entry` = 15339 AND `spell_id` = 25160 AND `shape` = 12;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
