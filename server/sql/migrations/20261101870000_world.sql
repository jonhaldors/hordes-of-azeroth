DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101870000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101870000');

UPDATE `gameobject` SET `position_x` = 16235.757, `position_y` = 16296.770 WHERE `guid` = 3999101;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
