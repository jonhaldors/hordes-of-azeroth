DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015150000');

DELETE FROM `creature_display_info_addon` WHERE `display_id` IN (17990, 17991, 17992, 17993, 17999, 18000, 18001);
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
SELECT d.`id`, a.`build`, a.`bounding_radius`, a.`combat_reach`, a.`speed_walk`, a.`speed_run`, a.`gender`, a.`display_id_other_gender`
FROM `creature_display_info_addon` a
JOIN (SELECT 17990 AS `id` UNION SELECT 17991 UNION SELECT 17992 UNION SELECT 17993) d
WHERE a.`display_id` = 10045;

UPDATE `creature_template` SET `display_id1` = 17990, `display_scale1` = 0.3  WHERE `entry` = 900100;
UPDATE `creature_template` SET `display_id1` = 17991, `display_scale1` = 0.36 WHERE `entry` = 900101;
UPDATE `creature_template` SET `display_id1` = 17992, `display_scale1` = 0.42 WHERE `entry` = 900102;
UPDATE `creature_template` SET `display_id1` = 17993, `display_scale1` = 0.5  WHERE `entry` = 900103;

UPDATE `gameobject_template` SET `displayId` = 7900, `size` = 2 WHERE `entry` = 900007;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
