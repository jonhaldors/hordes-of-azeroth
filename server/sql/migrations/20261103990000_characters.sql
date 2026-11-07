DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103990000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103990000');

CREATE TABLE IF NOT EXISTS `bonk_coop_mail_token` (
  `token` varchar(48) NOT NULL,
  `character_guid` int(10) unsigned NOT NULL,
  `item_guid` int(10) unsigned NOT NULL,
  PRIMARY KEY (`token`, `character_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
