DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030160000');

CREATE TABLE IF NOT EXISTS `bonk_account_mastery_preset` (
    `account` INT UNSIGNED     NOT NULL,
    `class`   TINYINT UNSIGNED NOT NULL,
    `slot`    TINYINT UNSIGNED NOT NULL,
    `node`    INT UNSIGNED     NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL,
    PRIMARY KEY (`account`, `class`, `slot`, `node`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;