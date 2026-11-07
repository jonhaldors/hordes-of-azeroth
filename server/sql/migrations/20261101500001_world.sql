DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101500001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101500001');

DELETE FROM `creature_template` WHERE `entry` = 900191;
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`) VALUES
(900191, 0, 'Yours', '', 1, 1, 35, 0, 11686, 1, 1, 10, 1, 4);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
