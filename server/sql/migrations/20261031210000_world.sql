DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031210000');

DELETE FROM `creature_template` WHERE `entry` = 900190;
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900190, 0, 'Corin Bannerfield', 'Group Settings', 60, 60, 35, 1, 15114, 1, 1, 7, 1, 1, 262, 'npc_bonk_coop');

DELETE FROM `creature` WHERE `guid` = 900190;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900190, 900190, 1, 16240.6, 16309.4, 20.9, 5.3, 120, 120, 0, 0);

DELETE FROM `broadcast_text` WHERE `entry` = 900190;
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900190, 'Playing together, $n? The host decides how the group runs. Changes apply from the next run.',
         'Playing together, $n? The host decides how the group runs. Changes apply from the next run.');
DELETE FROM `npc_text` WHERE `ID` = 900190;
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900190, 900190, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
