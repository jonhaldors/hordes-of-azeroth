DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019240000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019240000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` = 502;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` = 516;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.1 WHERE `id` = 517;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
