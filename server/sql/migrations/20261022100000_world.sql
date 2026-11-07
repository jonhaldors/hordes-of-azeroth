DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022100000');

DELETE FROM `creature_template` WHERE `entry` = 900140;
DROP TEMPORARY TABLE IF EXISTS `bonk_innkeeper`;
CREATE TEMPORARY TABLE `bonk_innkeeper` SELECT * FROM `creature_template` WHERE `entry` = 900004;
UPDATE `bonk_innkeeper` SET `entry` = 900140, `name` = 'Tarn Oakhoof', `subname` = 'Innkeeper', `npc_flags` = 1, `display_id1` = 9902, `equipment_id` = 900140, `gossip_menu_id` = 0;
INSERT INTO `creature_template` SELECT * FROM `bonk_innkeeper`;

DELETE FROM `creature_equip_template` WHERE `entry` = 900140;
INSERT INTO `creature_equip_template` (`entry`, `probability`, `item1`, `item2`, `item3`, `patch_min`, `patch_max`) VALUES (900140, 1, 2703, 0, 0, 0, 10);

DELETE FROM `creature` WHERE `guid` = 900012;
DROP TEMPORARY TABLE IF EXISTS `bonk_innkeeper_spawn`;
CREATE TEMPORARY TABLE `bonk_innkeeper_spawn` SELECT * FROM `creature` WHERE `guid` = 900004;
UPDATE `bonk_innkeeper_spawn` SET `guid` = 900012, `id` = 900140, `position_x` = 16229.551, `position_y` = 16306.438, `position_z` = 20.858, `orientation` = 6.1864;
INSERT INTO `creature` SELECT * FROM `bonk_innkeeper_spawn`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
