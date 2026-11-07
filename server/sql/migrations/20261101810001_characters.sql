DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101810001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101810001');

CREATE TABLE IF NOT EXISTS `bonk_account_epic_luck` (
  `account` int(10) unsigned NOT NULL,
  `misses` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
