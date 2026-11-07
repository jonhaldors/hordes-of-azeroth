DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030200000');

DELETE FROM `bonk_account_disabled` WHERE `type` = 11 AND `id` = 30;
DELETE FROM `bonk_account_unlock` WHERE `type` = 11 AND `id` = 30;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
