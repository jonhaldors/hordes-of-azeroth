DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015040000');

DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900030 AND 900034;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `flags`, `size`, `script_name`) VALUES
(900030, 5,  343,  'Ley Line', 16, 3, ''),
(900031, 10, 4718, 'Greed Totem', 0, 0.6, 'go_bonk_shrine'),
(900032, 10, 4076, 'Challenge Altar', 0, 1, 'go_bonk_shrine'),
(900033, 10, 439,  'Moonwell', 0, 2, 'go_bonk_shrine'),
(900034, 10, 5492, 'Summoning Stone', 0, 1, 'go_bonk_shrine');

UPDATE `bonk_quest` SET `param` = 300, `description` = 'Kill a stage boss before 5:00. A Summoning Stone calls it early.' WHERE `id` = 207;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
