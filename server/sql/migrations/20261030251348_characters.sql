DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030251348');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030251348');

ALTER TABLE `bonk_account`
  ADD COLUMN IF NOT EXISTS `locale` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Bonk language the player last chose, applied at login';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
