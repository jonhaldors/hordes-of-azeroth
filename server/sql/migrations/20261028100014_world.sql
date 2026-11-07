DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100014');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100014');

UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 431;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.5 WHERE `id` IN (708, 729);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (900, 911, 912);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` IN (903, 917, 918);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
