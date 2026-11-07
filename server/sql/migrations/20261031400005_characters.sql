DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031400005');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031400005');

DROP TEMPORARY TABLE IF EXISTS `favor_cap`;
CREATE TEMPORARY TABLE `favor_cap` (`talent` INT UNSIGNED NOT NULL PRIMARY KEY, `cap` TINYINT UNSIGNED NOT NULL);
INSERT INTO `favor_cap` VALUES (20, 30), (21, 25), (22, 20);
DROP TEMPORARY TABLE IF EXISTS `favor_refund`;
CREATE TEMPORARY TABLE `favor_refund` AS
    WITH RECURSIVE `ranks` AS (SELECT 0 AS `r` UNION ALL SELECT `r` + 1 FROM `ranks` WHERE `r` < 254)
    SELECT t.`account`, SUM(FLOOR(15 * (1 + 0.333333 * k.`r`) + 0.5)) AS `tickets`
    FROM `bonk_account_talent` t JOIN `favor_cap` c ON c.`talent` = t.`talent` JOIN `ranks` k ON k.`r` >= c.`cap` AND k.`r` < t.`rank`
    GROUP BY t.`account`;
UPDATE `bonk_account` a JOIN `favor_refund` f ON f.`account` = a.`account` SET a.`shards` = a.`shards` + f.`tickets`;
UPDATE `bonk_account_talent` t JOIN `favor_cap` c ON c.`talent` = t.`talent` SET t.`rank` = c.`cap` WHERE t.`rank` > c.`cap`;
DROP TEMPORARY TABLE IF EXISTS `favor_refund`;
DROP TEMPORARY TABLE IF EXISTS `favor_cap`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
