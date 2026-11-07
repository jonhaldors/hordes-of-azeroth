DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE displayId INT DEFAULT 18507;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024141500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024141500');

DELETE FROM `creature_display_info_addon` WHERE `display_id` BETWEEN 18507 AND 18599;
WHILE displayId <= 18599 DO
    INSERT INTO `creature_display_info_addon` (`display_id`, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`)
    SELECT displayId, `build`, `bounding_radius`, `combat_reach`, `speed_walk`, `speed_run`, `gender`, `display_id_other_gender`
    FROM `creature_display_info_addon` WHERE `display_id` = 16587;
    SET displayId = displayId + 1;
END WHILE;

UPDATE `item_template` SET `description` = 'Lets you escape the run early, for emergencies. Opens a ring at your feet that fills over 15 sec. Be inside it when it fills to return to the Inn with 1 item from the Extraction Vault. Disappears when the run ends.' WHERE `entry` = 900230;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
