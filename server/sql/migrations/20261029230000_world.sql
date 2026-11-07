DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029230000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `boss_health_multiplier` FLOAT NOT NULL DEFAULT 1,
    ADD COLUMN `miniboss_health_multiplier` FLOAT NOT NULL DEFAULT 1,
    ADD COLUMN `boss_health_ramp_floors` INT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `bonk_tier`
SET `boss_health_multiplier` = 14, `miniboss_health_multiplier` = 4, `boss_health_ramp_floors` = 5
WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
