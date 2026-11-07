DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018020000');

DELETE FROM `spell_template` WHERE `entry` = 33454;
DROP TEMPORARY TABLE IF EXISTS `bonk_loot_sparkle`;
CREATE TEMPORARY TABLE `bonk_loot_sparkle` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_loot_sparkle` SET `entry` = 33454, `spellVisual1` = 8357, `name` = 'Loot Sparkle', `auraDescription` = 'Something worth picking up.';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_sparkle`;
DROP TEMPORARY TABLE `bonk_loot_sparkle`;

UPDATE `creature_template` SET `auras` = '33454', `display_scale1` = 1.8 WHERE `entry` = 900129;
UPDATE `creature` SET `position_z` = 13.4 WHERE `guid` = 900011;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
