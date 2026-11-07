DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025270000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025270000');

UPDATE `bonk_weapon` SET `icon` = 'Spell_Nature_NatureTouchGrow' WHERE `id` = 1009;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.5 WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `damage_fraction` = 9.0 WHERE `id` = 1001;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
