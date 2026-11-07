DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029004141');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029004141');

CREATE TABLE IF NOT EXISTS `bonk_string_locale` (
    `entry`       INT UNSIGNED NOT NULL,
    `locale`      VARCHAR(4) NOT NULL COMMENT 'koKR, frFR, deDE, zhCN, zhTW, esES, esMX or ruRU',
    `source_hash` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'CRC32 of the English text it was translated from',
    `content`     TEXT NOT NULL,
    PRIMARY KEY (`entry`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk server text translations; the English text is in BonkStrings.cpp';

CREATE TABLE IF NOT EXISTS `bonk_glyph_locale` (
    `id`          INT UNSIGNED NOT NULL,
    `locale`      VARCHAR(4) NOT NULL,
    `name`        VARCHAR(64) NOT NULL DEFAULT '',
    `description` VARCHAR(1024) NOT NULL DEFAULT '',
    `drawback`    VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Glyph translations; empty fields fall back to English';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
