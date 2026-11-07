DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100003');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.5 WHERE `id` = 609;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` = 630;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 631;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
