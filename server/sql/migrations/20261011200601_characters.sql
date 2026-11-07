DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011200601');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011200601');

CREATE TABLE IF NOT EXISTS `bonk_character_upgrade` (
    `guid`    INT UNSIGNED     NOT NULL,
    `upgrade` INT UNSIGNED     NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`guid`, `upgrade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk permanent upgrades per character';

CREATE TABLE IF NOT EXISTS `bonk_character_talent` (
    `guid`    INT UNSIGNED     NOT NULL,
    `talent`  INT UNSIGNED     NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'difficulty toggles: switched on',
    PRIMARY KEY (`guid`, `talent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk run unlocks per character';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
