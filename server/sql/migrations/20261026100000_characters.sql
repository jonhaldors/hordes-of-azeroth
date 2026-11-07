DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100000');

ALTER TABLE `bonk_account` ADD COLUMN `determination` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'deaths before the first Normal clear, capped at 5';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
