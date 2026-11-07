DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021235000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021235000');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.4 WHERE `id` = 801;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.375 WHERE `id` = 804;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.125 WHERE `id` = 806;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.3125 WHERE `id` = 810;
UPDATE `bonk_weapon` SET `cooldown_ms` = 5000 WHERE `id` = 811;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
