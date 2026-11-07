DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023190000');

DELETE FROM `bonk_weapon_upgrade` WHERE `upgrade` = 18 AND `weapon_id` IN (904, 905, 919, 920, 921, 922);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(904, 18, 1), (905, 18, 1), (919, 18, 1), (920, 18, 1), (921, 18, 1), (922, 18, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
