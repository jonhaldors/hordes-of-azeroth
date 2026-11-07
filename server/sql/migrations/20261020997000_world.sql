DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020997000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020997000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (301, 314) AND `upgrade` = 17;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(301, 17, 10),
(314, 17, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
