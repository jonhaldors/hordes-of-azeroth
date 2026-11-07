DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100003');

CREATE TABLE IF NOT EXISTS `bonk_account_floor` (
  `account` INT UNSIGNED NOT NULL,
  `class` TINYINT UNSIGNED NOT NULL,
  `best_floor` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'highest Mythic floor cleared on this class',
  PRIMARY KEY (`account`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Hordes of Azeroth best Mythic floor per class';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
