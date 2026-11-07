DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015010000');

DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900020 AND 900023;
INSERT INTO `gameobject_template` (`entry`, `type`, `displayId`, `name`, `flags`, `size`) VALUES
(900020, 5, 2232, 'Shrine', 16, 5),
(900021, 5, 266,  'Goblin Merchant', 16, 5),
(900022, 5, 1311, 'Event', 16, 5),
(900023, 5, 2234, 'Extraction Point', 16, 5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
