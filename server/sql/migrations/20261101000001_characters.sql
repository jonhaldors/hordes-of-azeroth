DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101000001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101000001');

UPDATE `item_instance` SET `durability` = 0 WHERE `durability` <> 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
