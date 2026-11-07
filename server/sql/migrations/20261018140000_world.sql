DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018140000');

UPDATE `bonk_passive` SET `description` = '+{10}% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.' WHERE `id` = 11;
UPDATE `bonk_mastery` SET `description` = '+4% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.' WHERE `id` IN (80209, 80303);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
