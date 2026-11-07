DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030251346');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030251346');

CREATE TABLE IF NOT EXISTS `bonk_weapon_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(2048) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Spell translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_card_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Darkmoon Card translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_keyword_locale` (
    `id`           TINYINT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(32) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk keyword translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_map_locale` (
    `id`           TINYINT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `summary`      VARCHAR(128) NOT NULL DEFAULT '',
    `description`  VARCHAR(512) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk map translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_tier_locale` (
    `id`           TINYINT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    `details`      VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk difficulty translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_mastery_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Mastery talent translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_mastery_tree_locale` (
    `id`      INT UNSIGNED NOT NULL,
    `locale`  VARCHAR(4) NOT NULL,
    `name`    VARCHAR(32) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Mastery tree translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_passive_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk passive translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_pet_family_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(32) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk pet family translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_quest_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk quest translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_talent_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Dark Fortune translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_upgrade_locale` (
    `id`           INT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `name`         VARCHAR(64) NOT NULL DEFAULT '',
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk upgrade translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_archetype_locale` (
    `id`      TINYINT UNSIGNED NOT NULL,
    `locale`  VARCHAR(4) NOT NULL,
    `name`    VARCHAR(32) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk enemy archetype translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_item_set_locale` (
    `id`      INT UNSIGNED NOT NULL,
    `locale`  VARCHAR(4) NOT NULL,
    `name`    VARCHAR(64) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk item set translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_item_set_bonus_locale` (
    `set_id`       INT UNSIGNED NOT NULL,
    `pieces`       TINYINT UNSIGNED NOT NULL,
    `locale`       VARCHAR(4) NOT NULL,
    `description`  VARCHAR(1024) NOT NULL DEFAULT '',
    PRIMARY KEY (`set_id`, `pieces`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk item set bonus translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_hidden_locale` (
    `id`          INT UNSIGNED NOT NULL,
    `locale`      VARCHAR(4) NOT NULL,
    `name`        VARCHAR(64) NOT NULL DEFAULT '',
    `yell`        VARCHAR(255) NOT NULL DEFAULT '',
    `found_text`  VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk hidden encounter translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_shop_tree_locale` (
    `id`      INT UNSIGNED NOT NULL,
    `locale`  VARCHAR(4) NOT NULL,
    `name`    VARCHAR(32) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk shop tree translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_title_locale` (
    `id`       INT UNSIGNED NOT NULL,
    `locale`   VARCHAR(4) NOT NULL,
    `name`     VARCHAR(64) NOT NULL DEFAULT '',
    `pattern`  VARCHAR(64) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk title translations; empty fields fall back to English';

CREATE TABLE IF NOT EXISTS `bonk_wave_locale` (
    `start_sec`  INT UNSIGNED NOT NULL,
    `locale`     VARCHAR(4) NOT NULL,
    `name`       VARCHAR(48) NOT NULL DEFAULT '',
    PRIMARY KEY (`start_sec`, `locale`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk wave translations; empty fields fall back to English';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
