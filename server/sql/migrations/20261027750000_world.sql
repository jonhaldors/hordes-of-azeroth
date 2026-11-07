DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027750000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027750000');

UPDATE `creature` SET `position_x` = 16255.512, `position_y` = 16312.338, `position_z` = 20.865, `orientation` = 3.3233 WHERE `guid` = 900003;
UPDATE `gameobject` SET `position_x` = 16255.188, `position_y` = 16314.286, `position_z` = 20.865, `orientation` = 3.8123,
    `rotation2` = SIN(3.8123 / 2), `rotation3` = COS(3.8123 / 2) WHERE `guid` = 3999100;
UPDATE `creature` SET `position_x` = 16246.727, `position_y` = 16296.358, `position_z` = 20.865, `orientation` = 2.2103 WHERE `guid` = 900013;

DELETE FROM `creature_addon` WHERE `guid` = 900006;
INSERT INTO `creature_addon` (`guid`, `patch`, `display_id`, `mount_display_id`, `equipment_id`, `stand_state`, `sheath_state`, `emote_state`, `auras`) VALUES
(900006, 0, 0, 0, -1, 0, 0, 133, NULL);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
