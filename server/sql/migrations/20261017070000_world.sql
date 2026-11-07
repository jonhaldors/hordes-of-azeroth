DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017070000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017070000');

UPDATE `bonk_weapon` SET `starter_class_mask` = 0 WHERE `id` = 300;
UPDATE `bonk_weapon` SET `starter_class_mask` = 1 WHERE `id` = 304;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
