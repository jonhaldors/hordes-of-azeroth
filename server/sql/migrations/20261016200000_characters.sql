DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016200000');

CREATE TABLE IF NOT EXISTS `bonk_account_unlock` (
    `account` INT UNSIGNED NOT NULL,
    `type`    TINYINT UNSIGNED NOT NULL,
    `id`      INT UNSIGNED NOT NULL,
    PRIMARY KEY (`account`, `type`, `id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk unlocks bought at the Spellbook';

INSERT IGNORE INTO `bonk_account_unlock` (`account`, `type`, `id`)
SELECT `aq`.`account`, `q`.`reward_type`, `q`.`reward_value`
FROM `bonk_account_quest` AS `aq`
JOIN `mangos`.`bonk_quest` AS `q` ON `q`.`id` = `aq`.`quest`
WHERE `aq`.`completed` = 1 AND `q`.`reward_type` IN (2, 3);

DROP TEMPORARY TABLE IF EXISTS `bonk_old_upgrade_price`;
CREATE TEMPORARY TABLE `bonk_old_upgrade_price` (
    `upgrade` INT UNSIGNED NOT NULL PRIMARY KEY,
    `cost`    INT UNSIGNED NOT NULL,
    `growth`  FLOAT        NOT NULL
);
INSERT INTO `bonk_old_upgrade_price` VALUES
    (1, 4500, 1.4), (2, 6500, 1.4), (3, 4500, 1.4), (9, 6500, 1.4), (10, 5500, 1.4), (11, 9000, 1.4), (12, 5500, 1.4), (13, 9000, 1.4);

DROP TEMPORARY TABLE IF EXISTS `bonk_rank_number`;
CREATE TEMPORARY TABLE `bonk_rank_number` (`n` TINYINT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO `bonk_rank_number` VALUES (0), (1), (2), (3), (4), (5), (6), (7), (8), (9);

UPDATE `bonk_account` AS `a`
JOIN (
    SELECT `u`.`account`, SUM(ROUND(`p`.`cost` * POW(`p`.`growth`, `r`.`n`) / 100) * 100) AS `refund`
    FROM `bonk_account_upgrade` AS `u`
    JOIN `bonk_old_upgrade_price` AS `p` ON `p`.`upgrade` = `u`.`upgrade`
    JOIN `bonk_rank_number` AS `r` ON `r`.`n` < `u`.`rank`
    GROUP BY `u`.`account`
) AS `refunds` ON `refunds`.`account` = `a`.`account`
SET `a`.`gold` = `a`.`gold` + `refunds`.`refund`;

DELETE FROM `bonk_account_upgrade` WHERE `upgrade` IN (1, 2, 3, 9, 10, 11, 12, 13);
DROP TEMPORARY TABLE `bonk_old_upgrade_price`;
DROP TEMPORARY TABLE `bonk_rank_number`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
