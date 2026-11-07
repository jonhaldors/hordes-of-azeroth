DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018190000');

UPDATE `creature_template` SET `display_id1` = 4613 WHERE `entry` = 900130;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.5 WHERE `id` = 709;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` = 708;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
