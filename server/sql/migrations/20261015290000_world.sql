DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015290000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015290000');

UPDATE `gameobject` SET `spawn_flags` = `spawn_flags` & ~2 WHERE `guid` = 230922;
DELETE FROM `bonk_hidden_gameobject` WHERE `guid` = 230922;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
