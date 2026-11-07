DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101830000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101830000');

UPDATE `gameobject` SET `position_x` = 16235.192, `position_y` = 16296.277, `position_z` = 20.855, `orientation` = 0.7164,
    `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.350589, `rotation3` = 0.936529 WHERE `guid` = 3999101;

UPDATE `creature` SET `position_x` = 16224.109, `position_y` = 16299.579, `position_z` = 20.873, `orientation` = 6.2567 WHERE `guid` = 900190;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
