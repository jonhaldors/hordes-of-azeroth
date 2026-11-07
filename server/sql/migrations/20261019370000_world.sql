DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019370000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019370000');

REPLACE INTO `gameobject_display_info_addon` (`display_id`, `min_x`, `min_y`, `min_z`, `max_x`, `max_y`, `max_z`)
VALUES (4718, -5.247, -8.634, -0.151, 5.247, 8.612, 29.696);

END IF;
END??
DELIMITER ;
CALL add_migration();
