DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300005');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300005');

ALTER TABLE `bonk_tier`
    ADD COLUMN `floor_knee2` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'last stage on the late growth rates; later stages use the last rates',
    ADD COLUMN `last_health_growth` FLOAT NOT NULL DEFAULT 0,
    ADD COLUMN `last_damage_growth` FLOAT NOT NULL DEFAULT 0;

UPDATE `bonk_tier` SET `stage_health_growth` = 0.05, `stage_damage_growth` = 0.04, `floor_knee` = 10,
    `late_health_growth` = 0.12, `late_damage_growth` = 0.08, `floor_knee2` = 15, `last_health_growth` = 0.20, `last_damage_growth` = 0.12
WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
