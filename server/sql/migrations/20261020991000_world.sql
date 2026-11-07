DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020991000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020991000');

UPDATE `bonk_weapon` SET `range` = 10 WHERE `range` < 10 AND `target` IN (0, 1) AND `class_mask` IN (1, 8, 64) AND (`flags` & 0x4000000) = 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
