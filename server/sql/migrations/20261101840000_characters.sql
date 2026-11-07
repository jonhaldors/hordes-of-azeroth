DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101840000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101840000');

ALTER TABLE `bonk_item_found` ADD COLUMN `season` smallint(5) unsigned NOT NULL DEFAULT 0;

CREATE TABLE IF NOT EXISTS `bonk_account_board` (
  `account` int(10) unsigned NOT NULL,
  `show_on_board` tinyint(3) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
