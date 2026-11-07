DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261104130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261104130000');

CREATE TABLE IF NOT EXISTS `hoa_aura` (
    `entry`            INT UNSIGNED     NOT NULL,
    `key`              VARCHAR(64)      NOT NULL,
    `icon`             VARCHAR(255)     NOT NULL,
    `name`             VARCHAR(128)     NOT NULL,
    `description`      VARCHAR(1024)    NOT NULL DEFAULT '',
    `stack_max`        TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `duration_index`   SMALLINT UNSIGNED NOT NULL DEFAULT 28,
    `visible`          TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `dynamic_kind`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `dynamic_template` VARCHAR(512)     NOT NULL DEFAULT '',
    `source_kind`      VARCHAR(16)      NOT NULL,
    `source_id`        INT UNSIGNED     NULL,
    PRIMARY KEY (`entry`),
    UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk custom aura display and source binding';

CREATE TABLE IF NOT EXISTS `hoa_aura_locale` (
    `entry`            INT UNSIGNED  NOT NULL,
    `locale`           VARCHAR(4)    NOT NULL,
    `name`             VARCHAR(128)  NOT NULL DEFAULT '',
    `description`      VARCHAR(1024) NOT NULL DEFAULT '',
    `dynamic_template` VARCHAR(512)  NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk custom aura translations; empty fields fall back to English';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
