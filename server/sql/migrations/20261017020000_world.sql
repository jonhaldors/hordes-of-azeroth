DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017020000');

DELETE FROM `bonk_weapon_upgrade` WHERE `upgrade` = 13 AND `weapon_id` IN (202, 204, 224, 226);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(202, 13, 10),
(204, 13, 10),
(224, 13, 10),
(226, 13, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
