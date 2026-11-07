DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101000000');

UPDATE `item_template` SET `max_durability` = 0 WHERE `max_durability` <> 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
