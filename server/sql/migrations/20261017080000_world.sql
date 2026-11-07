DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017080000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017080000');

DELETE FROM `creature_template` WHERE `entry` IN (900123, 900124);
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900123, 0, 'Sandbox Keeper', 'Developer', 60, 60, 35, 1, 6710, 1, 1, 7, 8, 1, 366, 'npc_bonk_sandbox'),
(900124, 0, 'Training Dummy', NULL, 1, 1, 14, 0, 3019, 1, 1, 7, 1, 1, 262, '');

DELETE FROM `creature` WHERE `guid` = 900010;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900010, 900123, 1, 16229.5, 16270.5, 13.4, 4.473, 120, 120, 0, 0);

DELETE FROM `broadcast_text` WHERE `entry` IN (900012, 900013, 900014);
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900012, 'Welcome, $n. The sandbox is a quiet stretch of the Barrens for testing spells, evolutions and enemies. Nothing you do there counts: no gold, quests, records or rewards.',
         'Welcome, $n. The sandbox is a quiet stretch of the Barrens for testing spells, evolutions and enemies. Nothing you do there counts: no gold, quests, records or rewards.'),
(900013, 'What shall we test, $n? Training dummies stand still and never die, and nothing here counts. Talk to me again whenever you need more.',
         'What shall we test, $n? Training dummies stand still and never die, and nothing here counts. Talk to me again whenever you need more.'),
(900014, 'Sorry, $n. My tools are for the developers.',
         'Sorry, $n. My tools are for the developers.');
DELETE FROM `npc_text` WHERE `ID` IN (900012, 900013, 900014);
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900012, 900012, 1), (900013, 900013, 1), (900014, 900014, 1);

DELETE FROM `command` WHERE `name` = 'bonk sandbox';
INSERT INTO `command` (`name`, `security`, `help`, `flags`) VALUES
('bonk sandbox', 2, 'Syntax: .bonk sandbox\r\nStarts the developer sandbox from camp: a quiet spot in the Barrens with god mode on and the Sandbox Keeper beside you. Talk to the keeper for dummies, enemies, levels, spells and resets. Nothing in the sandbox counts. Leave through the keeper or with .bonk stop.', 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
