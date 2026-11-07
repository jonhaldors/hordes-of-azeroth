DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011200000');

CREATE TABLE IF NOT EXISTS `bonk_character_stats` (
    `guid`          INT UNSIGNED NOT NULL COMMENT 'characters.guid',
    `runs`          INT UNSIGNED NOT NULL DEFAULT 0,
    `best_stage`    INT UNSIGNED NOT NULL DEFAULT 0,
    `best_time_sec` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'longest run',
    `kills`         INT UNSIGNED NOT NULL DEFAULT 0,
    `gold_earned`   INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'copper, all runs',
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk hero records';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
