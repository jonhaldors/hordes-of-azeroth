DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031200000');

UPDATE `creature` SET `position_x` = 16255.399, `position_y` = 16301.568, `position_z` = 20.865, `orientation` = 2.6165 WHERE `guid` = 900008;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
