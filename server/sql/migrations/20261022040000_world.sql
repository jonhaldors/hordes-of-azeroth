DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022040000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.5 WHERE `id` = 608;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
