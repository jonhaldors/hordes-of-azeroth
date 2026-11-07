DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101600000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101600000');

DELETE FROM `gameobject_template` WHERE `entry` = 900064;
DROP TEMPORARY TABLE IF EXISTS `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900063;
UPDATE `bonk_go_copy` SET `entry` = 900064, `displayId` = 2491, `name` = 'Leaderboard', `size` = 1, `script_name` = 'go_bonk_board';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;

DELETE FROM `gameobject` WHERE `guid` = 3999101;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecsmin`, `spawntimesecsmax`, `animprogress`, `state`, `spawn_flags`, `visibility_mod`, `patch_min`, `patch_max`) VALUES
(3999101, 900064, 1, 16246.687, 16296.372, 20.865, 1.5215, 0, 0, 0.689465, 0.724319, 900, 900, 100, 1, 0, 0, 0, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
