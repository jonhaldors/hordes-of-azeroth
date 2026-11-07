DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028600004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028600004');

DELETE FROM `bonk_account_upgrade` WHERE `upgrade` = 11;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
