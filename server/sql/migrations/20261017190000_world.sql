DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017190000');

DELETE FROM `creature` WHERE `guid` = 900011;
DELETE FROM `creature_template` WHERE `entry` = 900129;
DROP TEMPORARY TABLE IF EXISTS `bonk_mailbox_beacon`;
CREATE TEMPORARY TABLE `bonk_mailbox_beacon` AS SELECT * FROM `creature_template` WHERE `entry` = 900113;
UPDATE `bonk_mailbox_beacon` SET `entry` = 900129, `name` = '', `subname` = '', `static_flags1` = 544;
INSERT INTO `creature_template` SELECT * FROM `bonk_mailbox_beacon`;
DROP TEMPORARY TABLE `bonk_mailbox_beacon`;

INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `wander_distance`, `movement_type`) VALUES
(900011, 900129, 1, 16219.5, 16272.8, 12.9696, 0, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
