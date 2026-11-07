DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018060000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018060000');

UPDATE `bonk_passive` SET `description` = '+{10}% Power.' WHERE `id` = 1;
UPDATE `bonk_passive` SET `description` = '+{8}% Haste. You attack and dots tick {8}% more often.' WHERE `id` = 2;
UPDATE `bonk_passive` SET `description` = '+{10}% movement speed.' WHERE `id` = 4;
UPDATE `bonk_passive` SET `description` = '+{25}% maximum health.' WHERE `id` = 5;
UPDATE `bonk_passive` SET `description` = 'Regain {0.4}% of your health every second.' WHERE `id` = 6;
UPDATE `bonk_passive` SET `description` = '+{15}% experience.' WHERE `id` = 8;
UPDATE `bonk_passive` SET `description` = '+{30}% pickup range for experience orbs and turkey legs.' WHERE `id` = 9;
UPDATE `bonk_passive` SET `description` = '+{10}% Area. Your area spells cover more ground and your melee attacks reach farther.' WHERE `id` = 11;
UPDATE `bonk_passive` SET `description` = '+{10} Armor. Enemies deal less damage to you.' WHERE `id` = 13;
UPDATE `bonk_passive` SET `description` = '+{5}% chance to dodge enemy swings.' WHERE `id` = 15;
UPDATE `bonk_passive` SET `description` = '+{4}% critical strike chance.' WHERE `id` = 16;
UPDATE `bonk_passive` SET `description` = 'Gain a Shield equal to {10}% of your maximum health.' WHERE `id` = 17;
UPDATE `bonk_passive` SET `description` = '+{5} Luck. Chests and level-ups offer rarer choices.' WHERE `id` = 18;
UPDATE `bonk_passive` SET `description` = '+{1} Count. Each Count makes your spells fire 1 additional bolt, land 1 additional ground effect, cast again or affect 1 additional target.' WHERE `id` = 19;
UPDATE `bonk_passive` SET `description` = 'Your hits have a {10}% chance to heal you for 1% of your maximum health, healing at most {0.3}% of your maximum health per second.' WHERE `id` = 20;
UPDATE `bonk_passive` SET `description` = '+{10}% Poison damage.' WHERE `id` = 21;

DELETE FROM `spell_template` WHERE `entry` = 33455;
DROP TEMPORARY TABLE IF EXISTS `bonk_mail_sparkle`;
CREATE TEMPORARY TABLE `bonk_mail_sparkle` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_mail_sparkle` SET `entry` = 33455, `spellVisual1` = 8358, `name` = 'Mail Sparkle', `auraDescription` = 'You have mail.';
INSERT INTO `spell_template` SELECT * FROM `bonk_mail_sparkle`;
DROP TEMPORARY TABLE `bonk_mail_sparkle`;

UPDATE `creature_template` SET `auras` = '33455' WHERE `entry` = 900129;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
