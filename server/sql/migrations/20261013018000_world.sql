DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013018000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013018000');

UPDATE `bonk_spawn_curve` SET `min_alive` = 20  WHERE `second` = 0;
UPDATE `bonk_spawn_curve` SET `min_alive` = 38  WHERE `second` = 120;
UPDATE `bonk_spawn_curve` SET `min_alive` = 58  WHERE `second` = 240;
UPDATE `bonk_spawn_curve` SET `min_alive` = 85  WHERE `second` = 360;
UPDATE `bonk_spawn_curve` SET `min_alive` = 120 WHERE `second` = 480;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
