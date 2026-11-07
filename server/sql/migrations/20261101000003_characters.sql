DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101000003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101000003');

CREATE TABLE IF NOT EXISTS `bonk_character_mode` (
  `guid` int(10) unsigned NOT NULL,
  `mode` tinyint(3) unsigned NOT NULL DEFAULT 1,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

INSERT IGNORE INTO `bonk_character_mode` (`guid`, `mode`) SELECT `guid`, 0 FROM `characters`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
