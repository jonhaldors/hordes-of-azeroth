DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013017000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013017000');

UPDATE `bonk_archetype` SET `health_multiplier` = 4 WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
