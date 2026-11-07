DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103300000');

ALTER TABLE `bonk_level`
    ADD COLUMN `boss_health` FLOAT NOT NULL DEFAULT 1,
    ADD COLUMN `boss_damage` FLOAT NOT NULL DEFAULT 1;

ALTER TABLE `bonk_tier`
    ADD COLUMN `miniboss_damage_multiplier` FLOAT NOT NULL DEFAULT 1;

UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.00 WHERE `tier` = 1 AND `level` = 1;
UPDATE `bonk_level` SET `boss_health` = 1.07, `boss_damage` = 1.05 WHERE `tier` = 1 AND `level` = 2;
UPDATE `bonk_level` SET `boss_health` = 1.05, `boss_damage` = 1.15 WHERE `tier` = 1 AND `level` = 3;
UPDATE `bonk_level` SET `boss_health` = 1.30, `boss_damage` = 1.25 WHERE `tier` = 1 AND `level` = 4;

UPDATE `bonk_level` SET `boss_health` = 1.15, `boss_damage` = 1.15 WHERE `tier` = 3 AND `level` = 1;
UPDATE `bonk_level` SET `boss_health` = 1.70, `boss_damage` = 1.20 WHERE `tier` = 3 AND `level` = 2;
UPDATE `bonk_level` SET `boss_health` = 1.80, `boss_damage` = 1.30 WHERE `tier` = 3 AND `level` = 3;
UPDATE `bonk_level` SET `boss_health` = 2.25, `boss_damage` = 1.35 WHERE `tier` = 3 AND `level` = 4;
UPDATE `bonk_level` SET `boss_health` = 2.80, `boss_damage` = 1.40 WHERE `tier` = 3 AND `level` = 5;

UPDATE `bonk_level` SET `boss_health` = 0.70, `boss_damage` = 1.00 WHERE `tier` = 2 AND `level` = 1;
UPDATE `bonk_level` SET `boss_health` = 0.80, `boss_damage` = 1.10 WHERE `tier` = 2 AND `level` = 2;
UPDATE `bonk_level` SET `boss_health` = 0.90, `boss_damage` = 1.20 WHERE `tier` = 2 AND `level` = 3;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.30 WHERE `tier` = 2 AND `level` = 4;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.34 WHERE `tier` = 2 AND `level` = 5;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.38 WHERE `tier` = 2 AND `level` = 6;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.42 WHERE `tier` = 2 AND `level` = 7;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.46 WHERE `tier` = 2 AND `level` = 8;
UPDATE `bonk_level` SET `boss_health` = 1.00, `boss_damage` = 1.50 WHERE `tier` = 2 AND `level` >= 9;

UPDATE `bonk_tier` SET `miniboss_damage_multiplier` = 1.0 WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `miniboss_damage_multiplier` = 1.3, `miniboss_health_multiplier` = 1.3 WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `miniboss_damage_multiplier` = 1.3 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
