DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012080000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012080000');

DELETE FROM `creature_template` WHERE `entry` = 900006;
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900006, 0, 'Archmage Tovin Quill', 'Spellbook', 60, 60, 35, 1, 1595, 1, 1, 7, 8, 1, 262, 'npc_bonk_codex');

DELETE FROM `creature` WHERE `guid` = 900006;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900006, 900006, 1, 16233.0, 16246.0, 14.362, 2.124, 120, 120, 0, 0);

DELETE FROM `broadcast_text` WHERE `entry` = 900006;
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900006, 'Every spell a hero can learn out there is written in here - how it grows, what it becomes, and what you must do before it will answer you.',
         'Every spell a hero can learn out there is written in here - how it grows, what it becomes, and what you must do before it will answer you.');
DELETE FROM `npc_text` WHERE `ID` = 900006;
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900006, 900006, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
