DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200027');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200027');

UPDATE `bonk_mastery` SET `description` = 'Your pets deal 5% more damage while Pack Leader is out.' WHERE `id` = 30105;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
