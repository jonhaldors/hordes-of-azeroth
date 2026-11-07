DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023160000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33500 AND 33504;
DROP TEMPORARY TABLE IF EXISTS `bonk_fel_spell`;
CREATE TEMPORARY TABLE `bonk_fel_spell` SELECT * FROM `spell_template` WHERE `entry` IN (11763, 19717, 348, 5857, 133);
UPDATE `bonk_fel_spell` SET `name` = 'Fel Firebolt', `entry` = 33500 WHERE `entry` = 11763;
UPDATE `bonk_fel_spell` SET `name` = 'Rain of Felfire', `entry` = 33501 WHERE `entry` = 19717;
UPDATE `bonk_fel_spell` SET `name` = 'Fel Immolate', `entry` = 33502 WHERE `entry` = 348;
UPDATE `bonk_fel_spell` SET `name` = 'Fel Hellfire', `entry` = 33503 WHERE `entry` = 5857;
UPDATE `bonk_fel_spell` SET `name` = 'Chaos Bolt', `entry` = 33504 WHERE `entry` = 133;
INSERT INTO `spell_template` SELECT * FROM `bonk_fel_spell`;
DROP TEMPORARY TABLE `bonk_fel_spell`;

UPDATE `bonk_weapon` SET `name` = 'Rain of Fire', `icon` = 'Spell_Shadow_RainOfFire' WHERE `id` = 910;
UPDATE `bonk_weapon` SET `spell_id` = 33504 WHERE `id` = 925;
UPDATE `bonk_weapon` SET `spell_id` = 33502 WHERE `id` IN (927, 928);
UPDATE `bonk_weapon` SET `spell_id` = 33503 WHERE `id` IN (929, 930);
UPDATE `bonk_weapon` SET `spell_id` = 33501 WHERE `id` IN (931, 932);
UPDATE `creature_template` SET `display_id1` = 4449 WHERE `entry` = 900141;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
