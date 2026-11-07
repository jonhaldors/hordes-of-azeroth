DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023110000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` IN (400, 411, 412);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.4 WHERE `id` IN (401, 413, 414, 409, 429, 430);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` IN (402, 415, 416);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.9 WHERE `id` IN (408, 427, 428);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
