DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018175000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018175000');

UPDATE `bonk_map_creature` SET `entry` = 3425 WHERE `bonk_map_id` = 3 AND `entry` = 3285 AND `kind` = 0;

DELETE FROM `bonk_mob_ability` WHERE `target` = 1 AND `spell_id` IN (3204, 19497, 20602, 24024, 28361)
    AND `entry` IN (480, 1270, 1488, 2739, 3285, 4062, 5235, 5839, 6557, 7092, 7857, 11669, 12099, 12222, 13276, 14750, 15333);
DELETE FROM `bonk_mob` WHERE `role` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
