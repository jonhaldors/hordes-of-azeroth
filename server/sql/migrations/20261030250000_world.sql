DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030250000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030250000');

UPDATE `item_template` SET `buy_price` = ROUND(`buy_price` * 4 * POW(1.099, `item_level` - 61))
WHERE `entry` BETWEEN 903000 AND 904999 AND `item_level` BETWEEN 61 AND 70;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
