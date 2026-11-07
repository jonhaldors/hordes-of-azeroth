DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024201000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024201000');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 1000;
UPDATE `bonk_weapon` SET `damage_fraction` = 6.0 WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` = 1004;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` = 1008;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 1009;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 1010;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
