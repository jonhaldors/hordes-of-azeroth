DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101500000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101500000');

CREATE TABLE IF NOT EXISTS `bonk_coop_applied` (
  `account` int(10) unsigned NOT NULL,
  `game` varchar(64) NOT NULL,
  `seq` int(10) unsigned NOT NULL,
  PRIMARY KEY (`account`, `game`, `seq`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
