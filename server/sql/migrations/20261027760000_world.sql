DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027760000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027760000');

UPDATE `creature` SET `position_x` = 16254.825, `position_y` = 16314.124, `position_z` = 20.865, `orientation` = 3.7857 WHERE `guid` = 900003;
UPDATE `gameobject` SET `position_x` = 16256.093, `position_y` = 16312.241, `position_z` = 20.865, `orientation` = 3.0417,
    `rotation2` = SIN(3.0417 / 2), `rotation3` = COS(3.0417 / 2) WHERE `guid` = 3999100;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
