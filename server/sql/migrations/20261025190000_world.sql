DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025190000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `opening_crowd` FLOAT NOT NULL DEFAULT 1 AFTER `min_alive_multiplier`,
    ADD COLUMN `opening_sec` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `opening_crowd`;

UPDATE `bonk_tier` SET `opening_crowd` = 0.5, `opening_sec` = 360 WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `opening_crowd` = 0.8, `opening_sec` = 120 WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `opening_crowd` = 1, `opening_sec` = 0 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
