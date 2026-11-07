DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100007');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100007');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` IN (202, 224);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.2 WHERE `id` = 225;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` = 226;

UPDATE `bonk_weapon` SET `damage_fraction` = 4.0 WHERE `id` = 522;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.4 WHERE `id` = 523;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.0 WHERE `id` IN (526, 527);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
