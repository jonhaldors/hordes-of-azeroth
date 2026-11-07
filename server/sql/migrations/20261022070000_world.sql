DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022070000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022070000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` IN (304, 319, 320);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;