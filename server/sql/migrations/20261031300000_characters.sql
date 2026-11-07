DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031300000');

CREATE TABLE IF NOT EXISTS `bonk_account_level` (
  `account` int(10) unsigned NOT NULL,
  `class` tinyint(3) unsigned NOT NULL,
  `best_level` int(10) unsigned NOT NULL DEFAULT 0,
  `best_ms` int(10) unsigned NOT NULL DEFAULT 0,
  `best_finale` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci COMMENT='Hordes of Azeroth highest level cleared per class';

IF EXISTS (SELECT 1 FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_account_tier') THEN
    INSERT IGNORE INTO `bonk_account_level` (`account`, `class`, `best_level`)
    SELECT t.`account`, c.`class`,
        CASE WHEN MAX(t.`tier` = 3 AND t.`best_stage` > 2) THEN 9 WHEN MAX(t.`tier` = 1 AND t.`best_stage` > 1) THEN 4 ELSE 0 END
    FROM `bonk_account_tier` t
    JOIN (SELECT 1 AS `class` UNION SELECT 2 UNION SELECT 3 UNION SELECT 4 UNION SELECT 5 UNION SELECT 7 UNION SELECT 8 UNION SELECT 9 UNION SELECT 11) c
    GROUP BY t.`account`, c.`class`;
    DROP TABLE `bonk_account_tier`;
END IF;

IF EXISTS (SELECT 1 FROM `information_schema`.`TABLES` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_account_floor') THEN
    INSERT INTO `bonk_account_level` (`account`, `class`, `best_level`)
    SELECT `account`, `class`, `best_floor` FROM `bonk_account_floor`
    ON DUPLICATE KEY UPDATE `best_level` = GREATEST(`bonk_account_level`.`best_level`, VALUES(`best_level`));
    DROP TABLE `bonk_account_floor`;
END IF;

DELETE FROM `bonk_account_level` WHERE `best_level` = 0;

IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_character_stats' AND `COLUMN_NAME` = 'best_stage') THEN
    ALTER TABLE `bonk_character_stats` CHANGE COLUMN `best_stage` `best_level` int(10) unsigned NOT NULL DEFAULT 0;
    UPDATE `bonk_character_stats` s
    JOIN `characters` c ON c.`guid` = s.`guid`
    LEFT JOIN `bonk_account_level` l ON l.`account` = c.`account` AND l.`class` = c.`class`
    SET s.`best_level` = COALESCE(l.`best_level`, 0);
END IF;

DELETE FROM `bonk_account_quest` WHERE `completed` = 0 AND `quest` IN (8, 9, 14, 51, 141, 148, 149, 150, 151, 157, 158, 159, 160, 166, 167, 168,
    169, 175, 176, 177, 178, 184, 185, 186, 260, 266, 267, 268, 270, 276, 277, 278, 280, 286, 287, 288, 320, 326, 327, 328, 407, 412, 413, 414,
    415, 416, 417, 540, 541, 542, 543, 544, 545, 546, 547, 548, 549, 550, 551, 552, 553, 554, 555, 556, 557, 558, 559, 560, 561, 562, 563, 564,
    565, 566, 567, 568, 569, 570, 571, 572, 573, 574, 575);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
