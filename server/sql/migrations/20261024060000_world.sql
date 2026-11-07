DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024060000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024060000');

DELETE FROM `bonk_weapon_upgrade` WHERE `upgrade` = 9 AND `weapon_id` IN (904, 905, 919, 920, 921, 922);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
