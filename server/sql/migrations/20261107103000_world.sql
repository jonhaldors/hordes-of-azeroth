DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261107103000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261107103000');

UPDATE `item_template` SET `display_id` = 20621 WHERE `entry` = 939000;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
