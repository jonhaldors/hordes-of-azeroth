DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027730000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027730000');

DELETE FROM `bonk_account_disabled` WHERE `type` = 12 AND `id` IN (1, 3, 4, 9, 10, 14, 26);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
