DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017150000');

CREATE TABLE IF NOT EXISTS `bonk_account_starter` (
  `account` int(10) unsigned NOT NULL,
  `class` tinyint(3) unsigned NOT NULL,
  `weapon` int(10) unsigned NOT NULL,
  PRIMARY KEY (`account`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
