DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031200001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031200001');

UPDATE `bonk_weapon_locale` SET `name` = '左右开弓' WHERE `id` = 612 AND `locale` = 'zhCN';
UPDATE `bonk_mastery_locale` SET `name` = '厚皮' WHERE `id` IN (30111, 110203) AND `locale` = 'zhCN';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
