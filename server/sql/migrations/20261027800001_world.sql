DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027800001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027800001');

UPDATE `item_template` SET `description` = '' WHERE `entry` BETWEEN 903000 AND 904899 AND `description` LIKE 'Tier %';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
