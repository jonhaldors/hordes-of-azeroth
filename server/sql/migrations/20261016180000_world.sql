DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016180000');

DELETE FROM `creature_template` WHERE `entry` = 900116;
DROP TEMPORARY TABLE IF EXISTS `bonk_turkey`;
CREATE TEMPORARY TABLE `bonk_turkey` SELECT * FROM `creature_template` WHERE `entry` = 900100;
UPDATE `bonk_turkey` SET `entry` = 900116, `display_id1` = 17994, `display_scale1` = 2;
INSERT INTO `creature_template` SELECT * FROM `bonk_turkey`;
DROP TEMPORARY TABLE `bonk_turkey`;

DELETE FROM `creature_display_info_addon` WHERE `display_id` = 17994;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`) VALUES
(17994, 0, 0.5, 1, 1, 1.14286, 2, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
