DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024070000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024070000');

UPDATE `bonk_map` SET `spawn_min_distance` = `spawn_min_distance` + 8, `spawn_max_distance` = `spawn_max_distance` + 12;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
