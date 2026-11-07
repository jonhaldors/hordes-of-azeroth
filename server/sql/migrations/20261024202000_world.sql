DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024202000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024202000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.45 WHERE `id` = 1003;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.0 WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.0 WHERE `id` = 1006;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.75 WHERE `id` = 1011;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
