DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015120000');

UPDATE `creature_template` SET `display_scale1` = 0.45 WHERE `entry` = 900101;
UPDATE `creature_template` SET `display_scale1` = 0.55 WHERE `entry` = 900102;

DELETE FROM `creature_display_info_addon` WHERE `display_id` = 17999;
INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
SELECT 17999, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`
FROM `creature_display_info_addon` WHERE `display_id` = 18001;

DROP TEMPORARY TABLE IF EXISTS `bonk_orb_template`;
CREATE TEMPORARY TABLE `bonk_orb_template` SELECT * FROM `creature_template` WHERE `entry` = 900102;
UPDATE `bonk_orb_template` SET `entry` = 900103, `display_id1` = 17999, `display_scale1` = 0.65;
DELETE FROM `creature_template` WHERE `entry` = 900103;
INSERT INTO `creature_template` SELECT * FROM `bonk_orb_template`;
DROP TEMPORARY TABLE `bonk_orb_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
