DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013013000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013013000');

DELETE FROM `creature_display_info_addon` WHERE `display_id` = 18001;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
SELECT 18001, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`
FROM `creature_display_info_addon` WHERE `display_id` = 16587;

UPDATE `creature_template` SET `display_id1` = 18000, `display_scale1` = 0.6 WHERE `entry` = 900101;
UPDATE `creature_template` SET `display_id1` = 18001, `display_scale1` = 0.9 WHERE `entry` = 900102;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
