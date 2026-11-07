DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025340000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025340000');

UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Every sec, the storm also applies 1 stack of Moonfire', 'Every 2 sec, the storm also applies 1 stack of Moonfire') WHERE `id` = 1019;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
