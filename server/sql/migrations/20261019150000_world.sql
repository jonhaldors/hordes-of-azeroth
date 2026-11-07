DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019150000');

UPDATE `creature_template` SET `display_id1` = 4629, `display_scale1` = 0.8 WHERE `entry` = 900134;
UPDATE `bonk_pet_family` SET `scale` = 0.8 WHERE `id` = 11;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
