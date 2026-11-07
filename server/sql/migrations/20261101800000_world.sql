DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101800000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101800000');

UPDATE `bonk_passive` SET `value_per_rank` = 7.5, `description` = '+{7.5}% movement speed.' WHERE `id` = 4;
UPDATE `bonk_passive_locale` SET `description` = '移动速度提高{7.5}%。' WHERE `id` = 4 AND `locale` = 'zhCN';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
