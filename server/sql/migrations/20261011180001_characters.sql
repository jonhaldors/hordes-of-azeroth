DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011180001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011180001');

CREATE TABLE IF NOT EXISTS `bonk_account` (
    `account` INT UNSIGNED NOT NULL,
    `gold`    INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'copper',
    PRIMARY KEY (`account`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk account-wide progress';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
