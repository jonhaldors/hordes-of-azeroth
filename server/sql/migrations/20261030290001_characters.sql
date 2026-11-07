DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030290001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030290001');

IF NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_account' AND `COLUMN_NAME` = 'gear_notice') THEN
    ALTER TABLE `bonk_account` ADD COLUMN `gear_notice` TINYINT UNSIGNED NOT NULL DEFAULT 0;
END IF;
UPDATE `bonk_account` SET `gear_notice` = 1;

CREATE TABLE IF NOT EXISTS `bonk_character_notice` (
    `guid` INT UNSIGNED NOT NULL,
    `old_legendaries` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;
INSERT IGNORE INTO `bonk_character_notice` (`guid`, `old_legendaries`) SELECT `guid`, 1 FROM `characters`;

UPDATE `bonk_item_found` SET `tier` = 20 WHERE `tier` > 20;
UPDATE `bonk_account_tier` SET `best_stage` = 21 WHERE `tier` = 2 AND `best_stage` > 21;
UPDATE `bonk_account_floor` SET `best_floor` = 20 WHERE `best_floor` > 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
