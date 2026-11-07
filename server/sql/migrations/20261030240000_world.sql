DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030240000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030240000');

UPDATE `bonk_item_stat` SET `dodge` = ROUND(`dodge` * 1.25, 1) WHERE `dodge` > 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
