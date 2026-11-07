DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021140000');

UPDATE `bonk_weapon` SET `starter_class_mask` = 2, `starter_option_mask` = 0 WHERE `id` = 800;
UPDATE `bonk_weapon` SET `starter_class_mask` = 0, `starter_option_mask` = 2 WHERE `id` = 801;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
