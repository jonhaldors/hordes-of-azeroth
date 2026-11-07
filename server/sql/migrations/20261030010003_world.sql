DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030010003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030010003');

DELETE FROM `creature_template` WHERE `entry` = 900160;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchanter`;
CREATE TEMPORARY TABLE `bonk_enchanter` SELECT * FROM `creature_template` WHERE `entry` = 900004;
UPDATE `bonk_enchanter` SET `entry` = 900160, `name` = 'Ilsa Runeweaver', `subname` = 'Enchanter', `npc_flags` = 1, `display_id1` = 1481,
  `display_id2` = 0, `display_id3` = 0, `display_id4` = 0, `equipment_id` = 0, `gossip_menu_id` = 0, `script_name` = '';
INSERT INTO `creature_template` SELECT * FROM `bonk_enchanter`;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchanter`;

DELETE FROM `creature` WHERE `guid` = 900014;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchanter_spawn`;
CREATE TEMPORARY TABLE `bonk_enchanter_spawn` SELECT * FROM `creature` WHERE `guid` = 900004;
UPDATE `bonk_enchanter_spawn` SET `guid` = 900014, `id` = 900160, `position_x` = 16244.8, `position_y` = 16314.6, `position_z` = 20.86, `orientation` = 4.71;
INSERT INTO `creature` SELECT * FROM `bonk_enchanter_spawn`;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchanter_spawn`;

DELETE FROM `gameobject_template` WHERE `entry` = 900080;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchant_focus`;
CREATE TEMPORARY TABLE `bonk_enchant_focus` SELECT * FROM `gameobject_template` WHERE `entry` = 150140;
UPDATE `bonk_enchant_focus` SET `entry` = 900080, `type` = 5, `name` = 'Arcane Focus', `size` = 0.35, `data0` = 0, `script_name` = '';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_enchant_focus`;
DROP TEMPORARY TABLE IF EXISTS `bonk_enchant_focus`;

DELETE FROM `gameobject` WHERE `guid` = 900500;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`,
  `spawntimesecsmin`, `spawntimesecsmax`, `animprogress`, `state`, `spawn_flags`, `visibility_mod`, `patch_min`, `patch_max`)
VALUES (900500, 900080, 1, 16242.6, 16315.4, 20.86, 4.71, 0, 0, 0, 0, 0, 0, 100, 1, 0, 0, 0, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
