DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018050000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018050000');

UPDATE `creature` SET `position_x` = 16240.454, `position_y` = 16291.547, `position_z` = 22.932, `orientation` = 1.4781 WHERE `guid` = 900001;
UPDATE `creature` SET `position_x` = 16255.166, `position_y` = 16313.181, `position_z` = 20.845, `orientation` = 3.6065 WHERE `guid` = 900003;
UPDATE `creature` SET `position_x` = 16223.271, `position_y` = 16293.705, `position_z` = 20.850, `orientation` = 0.6337 WHERE `guid` = 900005;
UPDATE `creature` SET `position_x` = 16249.786, `position_y` = 16296.764, `position_z` = 20.846, `orientation` = 2.1103 WHERE `guid` = 900004;
UPDATE `creature` SET `position_x` = 16230.604, `position_y` = 16287.414, `position_z` = 31.431, `orientation` = 2.7857 WHERE `guid` = 900008;
UPDATE `creature` SET `position_x` = 16253.647, `position_y` = 16299.232, `position_z` = 20.845, `orientation` = 6.1786 WHERE `guid` = 900006;
UPDATE `creature` SET `position_x` = 16256.856, `position_y` = 16295.706, `position_z` = 13.176, `orientation` = 3.0605 WHERE `guid` = 900009;
UPDATE `creature` SET `position_x` = 16239.766, `position_y` = 16316.365, `position_z` = 20.846, `orientation` = 3.7595 WHERE `guid` = 900010;
UPDATE `creature` SET `position_x` = 16222.784, `position_y` = 16275.168, `position_z` = 20.929, `orientation` = 4.4507 WHERE `guid` = 900002;
UPDATE `creature` SET `position_x` = 16233.525, `position_y` = 16299.351, `position_z` = 21.245 WHERE `guid` = 900011;
UPDATE `gameobject` SET `position_x` = 16233.525, `position_y` = 16299.351, `position_z` = 20.845, `orientation` = 1.5211, `rotation0` = 0, `rotation1` = 0, `rotation2` = 0.689320, `rotation3` = 0.724457 WHERE `guid` = 230922;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
