DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015130000');

UPDATE `bonk_weapon` SET `range` = 20 WHERE `target` = 3 AND `range` > 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
