DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028910000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028910000');

CREATE TABLE IF NOT EXISTS `bonk_character_title` (
  `guid` INT UNSIGNED NOT NULL,
  `title` INT UNSIGNED NOT NULL,
  PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk title shown and worn by each character';
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
