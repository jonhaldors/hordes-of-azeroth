DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011191001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011191001');

CREATE TABLE IF NOT EXISTS `bonk_account_tier` (
    `account`    INT UNSIGNED      NOT NULL,
    `tier`       TINYINT UNSIGNED  NOT NULL,
    `best_stage` SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'furthest stage reached',
    PRIMARY KEY (`account`, `tier`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk account-wide tier progress';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
