DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012210001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012210001');

DROP TEMPORARY TABLE IF EXISTS `bonk_old_upgrade_price`;
CREATE TEMPORARY TABLE `bonk_old_upgrade_price` (
    `upgrade` INT UNSIGNED NOT NULL PRIMARY KEY,
    `cost`    INT UNSIGNED NOT NULL,
    `growth`  FLOAT        NOT NULL
);
INSERT INTO `bonk_old_upgrade_price` VALUES
    (1, 6000, 1), (2, 6000, 1), (3, 4000, 1), (4, 5000, 1), (5, 4000, 1), (6, 5000, 1), (7, 4000, 1), (8, 50000, 0),
    (9, 6500, 1), (10, 5500, 1), (11, 9000, 1), (12, 5500, 1), (13, 9000, 1), (14, 3500, 1), (15, 9000, 1);

UPDATE `bonk_account` AS `a`
JOIN (
    SELECT `u`.`account`, SUM(ROUND(`p`.`cost` * (`u`.`rank` + `p`.`growth` * `u`.`rank` * (`u`.`rank` - 1) / 2))) AS `refund`
    FROM `bonk_account_upgrade` AS `u`
    JOIN `bonk_old_upgrade_price` AS `p` ON `p`.`upgrade` = `u`.`upgrade`
    GROUP BY `u`.`account`
) AS `r` ON `r`.`account` = `a`.`account`
SET `a`.`gold` = `a`.`gold` + `r`.`refund`;

DELETE FROM `bonk_account_upgrade`;
DROP TEMPORARY TABLE `bonk_old_upgrade_price`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
