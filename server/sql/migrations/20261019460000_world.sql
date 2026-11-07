DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019460000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019460000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33456 AND 33459;
DROP TEMPORARY TABLE IF EXISTS `bonk_loot_beam`;
CREATE TEMPORARY TABLE `bonk_loot_beam` SELECT * FROM `spell_template` WHERE `entry` = 25824;
UPDATE `bonk_loot_beam` SET `entry` = 33456, `spellVisual1` = 8460, `name` = 'Uncommon Loot Beam';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_beam`;
UPDATE `bonk_loot_beam` SET `entry` = 33457, `spellVisual1` = 8461, `name` = 'Rare Loot Beam';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_beam`;
UPDATE `bonk_loot_beam` SET `entry` = 33458, `spellVisual1` = 8462, `name` = 'Epic Loot Beam';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_beam`;
UPDATE `bonk_loot_beam` SET `entry` = 33459, `spellVisual1` = 8463, `name` = 'Legendary Loot Beam';
INSERT INTO `spell_template` SELECT * FROM `bonk_loot_beam`;
DROP TEMPORARY TABLE `bonk_loot_beam`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
