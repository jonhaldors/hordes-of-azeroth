DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016460000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016460000');

UPDATE `bonk_mastery` SET `name` = 'Executioner' WHERE `id` = 10109;
UPDATE `bonk_mastery` SET `name` = 'Axe Toss' WHERE `id` = 20206;
UPDATE `bonk_mastery` SET `name` = 'Lock and Load' WHERE `id` = 30206;
UPDATE `bonk_mastery` SET `name` = 'Riposte' WHERE `id` = 40206;
UPDATE `bonk_mastery` SET `name` = 'Spirit Tap' WHERE `id` = 50309;
UPDATE `bonk_mastery` SET `name` = 'Divine Initiate' WHERE `id` = 50206;
UPDATE `bonk_quest` SET `name` = 'Zealot' WHERE `id` = 133;
UPDATE `bonk_quest` SET `name` = 'Lightbringer' WHERE `id` = 213;
UPDATE `bonk_quest` SET `name` = 'Thunderhead' WHERE `id` = 172;
UPDATE `bonk_quest` SET `name` = 'Force of Nature' WHERE `id` = 223;
UPDATE `bonk_quest` SET `name` = 'Earthshaker' WHERE `id` = 122;
UPDATE `bonk_quest` SET `name` = 'Shadowblade' WHERE `id` = 215;
UPDATE `bonk_quest` SET `name` = 'Hail of Bolts' WHERE `id` = 254;
UPDATE `bonk_quest` SET `name` = 'Deadliest Foes' WHERE `id` = 9;
UPDATE `bonk_talent` SET `name` = 'Second Chance' WHERE `id` = 7;
UPDATE `bonk_upgrade` SET `name` = 'Clarity' WHERE `id` = 22;
UPDATE `bonk_upgrade` SET `name` = 'Fleet Foot' WHERE `id` = 5;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
