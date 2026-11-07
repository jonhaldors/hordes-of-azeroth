DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300001');

ALTER TABLE `bonk_tier`
    ADD COLUMN `stage_compound` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '1: stage growth multiplies per stage instead of adding',
    ADD COLUMN `floor_knee` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'last stage on the first growth rates; later stages use the late rates',
    ADD COLUMN `late_health_growth` FLOAT NOT NULL DEFAULT 0,
    ADD COLUMN `late_damage_growth` FLOAT NOT NULL DEFAULT 0;

UPDATE `bonk_tier` SET `stage_compound` = 1, `stage_health_growth` = 0.15, `stage_damage_growth` = 0.10, `stage_health_accel` = 0, `stage_damage_accel` = 0,
    `floor_knee` = 10, `late_health_growth` = 0.20, `late_damage_growth` = 0.13
WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
