DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016540000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016540000');

DELETE FROM `bonk_weapon_upgrade` WHERE `upgrade` = 1 AND `weapon_id` IN (37, 214, 215);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
