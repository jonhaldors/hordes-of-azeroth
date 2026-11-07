DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016440000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016440000');

UPDATE `bonk_card` SET `description` = '+3% critical strike chance.' WHERE `id` = 22;
UPDATE `bonk_card` SET `description` = '+4% Power and +2% critical strike chance.' WHERE `id` = 25;
UPDATE `bonk_card` SET `description` = '+1 Count: your spells fire 1 more bolt and land 1 more ground spell. +15% Area: bigger area spells and melee reach.' WHERE `id` = 105;
UPDATE `bonk_passive` SET `description` = '+4% critical strike chance.' WHERE `id` = 16;
UPDATE `bonk_glyph` SET `description` = 'Every 3 seconds, lightning strikes up to 8 enemies near you. Every strike is a critical strike.' WHERE `id` = 16;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
