DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018235000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018235000');

UPDATE `bonk_keyword` SET `description` = 'Slows the enemy by 30% for 4 sec.' WHERE `id` = 10;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
