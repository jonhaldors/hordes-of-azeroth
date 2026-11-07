DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012230500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012230500');

UPDATE `bonk_weapon` SET `description` = 'Lightning that hits several enemies, one after another.' WHERE `id` = 11;
UPDATE `bonk_weapon` SET `description` = 'Lightning that hits up to 10 enemies, one after another.' WHERE `id` = 104;
UPDATE `bonk_weapon` SET `description` = 'Holy light that hits up to 50 enemies, one after another.' WHERE `id` = 110;
UPDATE `bonk_weapon` SET `description` = 'Throws an axe at the farthest enemy in range; it also hits 4 enemies near it.' WHERE `id` = 190;
UPDATE `bonk_weapon` SET `description` = 'Poisons 3 nearby enemies; when one dies, the poison spreads to the nearest enemy.' WHERE `id` = 138;

UPDATE `bonk_mastery` SET `description` = REPLACE(`description`, ' reaches one more enemy.', ' hits 1 more enemy.');
UPDATE `bonk_mastery` SET `description` = REPLACE(`description`, ' strikes one more enemy.', ' hits 1 more enemy.');
UPDATE `bonk_mastery` SET `description` = REPLACE(`description`, ' hits one more enemy.', ' hits 1 more enemy.');
UPDATE `bonk_mastery` SET `description` = 'Call Pet calls 1 more beast.' WHERE `id` = 30108;

UPDATE `bonk_upgrade` SET `description` = '+4% Area: bigger area spells and melee reach.' WHERE `id` = 10;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
