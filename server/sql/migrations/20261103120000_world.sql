DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103120000');

DELETE FROM `creature_template` WHERE `entry` = 900192;
DROP TEMPORARY TABLE IF EXISTS `bonk_ticket`;
CREATE TEMPORARY TABLE `bonk_ticket` SELECT * FROM `creature_template` WHERE `entry` = 900116;
UPDATE `bonk_ticket` SET `entry` = 900192, `display_id1` = 17995, `display_scale1` = 2;
INSERT INTO `creature_template` SELECT * FROM `bonk_ticket`;
DROP TEMPORARY TABLE `bonk_ticket`;

DELETE FROM `creature_display_info_addon` WHERE `display_id` = 17995;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`) VALUES
(17995, 0, 0.5, 1, 1, 1.14286, 2, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
