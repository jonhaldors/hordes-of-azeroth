DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030290002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030290002');

UPDATE `bonk_tier` SET `knee_health_step` = 1, `knee2_health_step` = 1, `late_health_growth` = 0.12, `last_health_growth` = 0.12
WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
