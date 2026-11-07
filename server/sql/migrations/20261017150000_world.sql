DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017150000');

ALTER TABLE `bonk_weapon` ADD COLUMN `starter_option_mask` int(10) unsigned NOT NULL DEFAULT 0 AFTER `starter_class_mask`;

UPDATE `bonk_weapon` SET `starter_option_mask` = 4 WHERE `id` IN (37, 38, 201);
UPDATE `bonk_weapon` SET `starter_option_mask` = 1 WHERE `id` IN (300, 301, 308);
UPDATE `bonk_weapon` SET `starter_option_mask` = 128 WHERE `id` IN (403, 409);

UPDATE `bonk_mastery` SET `description` = 'Call Pet can be your starter spell. Choose it at the Run Master.' WHERE `id` = 30106;
UPDATE `bonk_mastery` SET `description` = 'Multi-Shot can be your starter spell. Choose it at the Run Master.' WHERE `id` = 30206;
UPDATE `bonk_mastery` SET `description` = 'Serpent Sting can be your starter spell once a quest unlocks it. Choose it at the Run Master.' WHERE `id` = 30306;

UPDATE `bonk_weapon` SET `flags` = 12582912,
    `description` = 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once. As your starter spell, it turns your dash into Blink.'
    WHERE `id` = 409;
UPDATE `bonk_weapon` SET
    `description` = 'Your dash becomes Blink, teleporting you. Blink gains 1 charge and recharges 30% faster, and each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to all enemies within 10 yards.'
    WHERE `id` = 407;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
