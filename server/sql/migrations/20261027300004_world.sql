DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300004');

UPDATE `bonk_tier` SET `details` = REPLACE(`details`, 'Enemies have 180% more health and deal 60% more damage.', 'Enemies have 220% more health and deal 60% more damage, more on every floor.')
WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
