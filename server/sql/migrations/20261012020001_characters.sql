DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012020001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012020001');

CREATE TABLE IF NOT EXISTS `bonk_account_quest` (
    `account`   INT UNSIGNED     NOT NULL,
    `quest`     INT UNSIGNED     NOT NULL,
    `progress`  INT UNSIGNED     NOT NULL DEFAULT 0,
    `completed` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account`, `quest`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk quest progress per account';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
