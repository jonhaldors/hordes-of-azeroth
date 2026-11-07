DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300009');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300009');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33642 AND 33648;
DROP TEMPORARY TABLE IF EXISTS `bonk_loot_core`;
CREATE TEMPORARY TABLE `bonk_loot_core` SELECT * FROM `spell_template` WHERE `entry` = 25824;
UPDATE `bonk_loot_core` SET `entry` = 33642, `spellVisual1` = 8472, `name` = 'Uncommon Loot Core';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33643, `spellVisual1` = 8473, `name` = 'Rare Loot Core';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33644, `spellVisual1` = 8474, `name` = 'Epic Loot Core';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33645, `spellVisual1` = 8475, `name` = 'Legendary Loot Core';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33646, `spellVisual1` = 8476, `name` = 'Rare Loot Swirl';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33647, `spellVisual1` = 8477, `name` = 'Epic Loot Swirl';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
UPDATE `bonk_loot_core` SET `entry` = 33648, `spellVisual1` = 8478, `name` = 'Legendary Loot Swirl';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_core`;
DROP TEMPORARY TABLE `bonk_loot_core`;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
