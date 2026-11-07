DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012060000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012060000');

UPDATE `bonk_map` SET `health_growth_per_min` = 0.05, `damage_growth_per_min` = 0.05 WHERE `id` IN (1, 3, 4);
UPDATE `bonk_map` SET `health_growth_per_min` = 0.06, `damage_growth_per_min` = 0.055 WHERE `id` IN (7, 8, 9);
UPDATE `bonk_map` SET `health_growth_per_min` = 0.07, `damage_growth_per_min` = 0.06 WHERE `id` IN (2, 5, 6);

UPDATE `bonk_tier` SET `stage_health_growth` = 0.15, `stage_damage_growth` = 0.10 WHERE `key` = 'easy';
UPDATE `bonk_tier` SET `stage_health_growth` = 0.18, `stage_damage_growth` = 0.11 WHERE `key` = 'medium';
UPDATE `bonk_tier` SET `stage_health_growth` = 0.20, `stage_damage_growth` = 0.12 WHERE `key` = 'hard';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
