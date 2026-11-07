DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300008');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300008');

DELETE FROM `gameobject_template` WHERE `entry` = 900062;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `size`) VALUES
(900062, 5, 1667, 'Glyph', 0.15);
DELETE FROM `spell_template` WHERE `entry` BETWEEN 33640 AND 33641;
DROP TEMPORARY TABLE IF EXISTS `bonk_drop_glow`;
CREATE TEMPORARY TABLE `bonk_drop_glow` SELECT * FROM `spell_template` WHERE `entry` = 25824;
UPDATE `bonk_drop_glow` SET `entry` = 33640, `spellVisual1` = 8470, `name` = 'Ticket Pool';
INSERT INTO `spell_template` SELECT * FROM `bonk_drop_glow`;
UPDATE `bonk_drop_glow` SET `entry` = 33641, `spellVisual1` = 8471, `name` = 'Glyph Pool';
INSERT INTO `spell_template` SELECT * FROM `bonk_drop_glow`;
DROP TEMPORARY TABLE `bonk_drop_glow`;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
