DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101700003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101700003');

CREATE TABLE IF NOT EXISTS `bonk_account_level_best` (
  `account` int(10) unsigned NOT NULL,
  `class` tinyint(3) unsigned NOT NULL,
  `level` int(10) unsigned NOT NULL,
  `clears` int(10) unsigned NOT NULL DEFAULT 0,
  `first_clear` int(10) unsigned NOT NULL DEFAULT 0,
  `best_ms` int(10) unsigned NOT NULL DEFAULT 0,
  `best_ms_by` varchar(12) NOT NULL DEFAULT '',
  `damage_per_second` int(10) unsigned NOT NULL DEFAULT 0,
  `damage_by` varchar(12) NOT NULL DEFAULT '',
  `kills` int(10) unsigned NOT NULL DEFAULT 0,
  `kills_by` varchar(12) NOT NULL DEFAULT '',
  `gold_per_minute` int(10) unsigned NOT NULL DEFAULT 0,
  `gold_by` varchar(12) NOT NULL DEFAULT '',
  `valor_per_minute` int(10) unsigned NOT NULL DEFAULT 0,
  `valor_by` varchar(12) NOT NULL DEFAULT '',
  `finale` int(10) unsigned NOT NULL DEFAULT 0,
  `finale_seconds` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`, `class`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
