DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012002000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012002000');

CREATE TABLE IF NOT EXISTS `bonk_account_upgrade` (
    `account` INT UNSIGNED     NOT NULL,
    `upgrade` INT UNSIGNED     NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`account`, `upgrade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk permanent upgrades per account';

CREATE TABLE IF NOT EXISTS `bonk_account_talent` (
    `account` INT UNSIGNED     NOT NULL,
    `talent`  INT UNSIGNED     NOT NULL,
    `rank`    TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `enabled` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'difficulty toggles: switched on',
    PRIMARY KEY (`account`, `talent`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk run unlocks per account';

ALTER TABLE `bonk_account`
    ADD COLUMN `shards` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'Talent Shards';

INSERT INTO `bonk_account_upgrade` (`account`, `upgrade`, `rank`)
SELECT c.`account`, u.`upgrade`, MAX(u.`rank`)
FROM `bonk_character_upgrade` u JOIN `characters` c ON c.`guid` = u.`guid`
GROUP BY c.`account`, u.`upgrade`
ON DUPLICATE KEY UPDATE `rank` = GREATEST(`bonk_account_upgrade`.`rank`, VALUES(`rank`));

INSERT INTO `bonk_account_talent` (`account`, `talent`, `rank`, `enabled`)
SELECT c.`account`, t.`talent`, MAX(t.`rank`), MAX(t.`enabled`)
FROM `bonk_character_talent` t JOIN `characters` c ON c.`guid` = t.`guid`
GROUP BY c.`account`, t.`talent`
ON DUPLICATE KEY UPDATE `rank` = GREATEST(`bonk_account_talent`.`rank`, VALUES(`rank`));

INSERT INTO `bonk_account` (`account`, `shards`)
SELECT c.`account`, SUM(s.`shards`)
FROM `bonk_character_shards` s JOIN `characters` c ON c.`guid` = s.`guid`
GROUP BY c.`account`
ON DUPLICATE KEY UPDATE `shards` = `bonk_account`.`shards` + VALUES(`shards`);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
