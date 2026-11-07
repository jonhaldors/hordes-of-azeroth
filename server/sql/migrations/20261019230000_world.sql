DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019230000');

ALTER TABLE `bonk_tier` ADD COLUMN IF NOT EXISTS `veteran_chance` FLOAT NOT NULL DEFAULT 0;

UPDATE `bonk_tier` SET `max_alive` = 110;
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.1, `health_multiplier` = 1.6, `damage_multiplier` = 1.3, `veteran_chance` = 15 WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.15, `health_multiplier` = 2.8, `damage_multiplier` = 1.6, `veteran_chance` = 25 WHERE `key` = 'mythic';
UPDATE `bonk_tier` SET `veteran_chance` = 0 WHERE `key` = 'normal';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
