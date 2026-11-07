DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020993000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020993000');

ALTER TABLE `bonk_tier` ADD COLUMN `details` VARCHAR(1024) NOT NULL DEFAULT '' AFTER `description`;

UPDATE `bonk_tier` SET `details` = 'Bosses lead their spells slightly.^Elites have 1 affix.' WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `details` = 'Enemies have 60% more health and deal 30% more damage.^Casters lead their shots slightly more accurately.^Bosses lead their spells more and get extra attacks.^15% of enemies are Veterans: tougher and worth more.^Elites have 2 affixes and dodge more. Chargers charge more often.' WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `details` = 'Enemies have 180% more health and deal 60% more damage.^Casters lead their shots precisely.^Bosses lead their spells precisely and get even more attacks.^25% of enemies are Veterans: tougher and worth more.^Elites have 3 affixes and dodge even more. Chargers charge more often.' WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
