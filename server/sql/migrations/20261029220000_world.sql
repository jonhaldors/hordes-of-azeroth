DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029220000');

UPDATE `item_template`
SET `buy_price` = ROUND(`buy_price` * POW(1.25 / 1.11, FLOOR(MOD(`entry` - 903000, 160) / 8) + 1 - 15)),
    `sell_price` = ROUND(`buy_price` / 10)
WHERE `entry` BETWEEN 903000 AND 904439 AND FLOOR(MOD(`entry` - 903000, 160) / 8) + 1 > 15;

UPDATE `item_template`
SET `buy_price` = ROUND(`buy_price` * POW(1.25 / 1.11, MOD(`entry` - 904500, 20) + 1 - 15)),
    `sell_price` = ROUND(`buy_price` / 10)
WHERE `entry` BETWEEN 904500 AND 904899 AND MOD(`entry` - 904500, 20) + 1 > 15;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
