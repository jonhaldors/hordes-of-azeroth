DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012090001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012090001');

CREATE TABLE IF NOT EXISTS `bonk_account_mastery` (
    `account` INT UNSIGNED     NOT NULL,
    `class`   TINYINT UNSIGNED NOT NULL,
    `xp`      INT UNSIGNED     NOT NULL DEFAULT 0,
    PRIMARY KEY (`account`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk Class Mastery experience per account and class';

CREATE TABLE IF NOT EXISTS `bonk_account_mastery_node` (
    `account` INT UNSIGNED     NOT NULL,
    `node`    INT UNSIGNED     NOT NULL COMMENT 'bonk_mastery.id',
    `rank`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account`, `node`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk Class Mastery ranks spent per account';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
