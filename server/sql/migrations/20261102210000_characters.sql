DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102210000');

CREATE TABLE IF NOT EXISTS `bonk_coop_mail_taken` (
  `id` int(10) unsigned NOT NULL AUTO_INCREMENT,
  `character_guid` int(10) unsigned NOT NULL,
  `item_id` int(10) unsigned NOT NULL,
  PRIMARY KEY (`id`),
  KEY `character_item` (`character_guid`, `item_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
