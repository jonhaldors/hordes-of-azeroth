DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025430000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025430000');

DELETE FROM `spell_template` WHERE `entry` = 33460;
DROP TEMPORARY TABLE IF EXISTS `bonk_sand_vortex`;
CREATE TEMPORARY TABLE `bonk_sand_vortex` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_sand_vortex` SET `entry` = 33460, `spellVisual1` = 8359, `name` = 'Sand Vortex', `auraDescription` = 'A sand vortex.';
INSERT INTO `spell_template` SELECT * FROM `bonk_sand_vortex`;
DROP TEMPORARY TABLE `bonk_sand_vortex`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
