DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200024');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200024');

UPDATE `bonk_item_stat` SET `crit` = `crit` + `hit` WHERE `hit` > 0;
ALTER TABLE `bonk_item_stat` DROP COLUMN `hit`;
ALTER TABLE `bonk_tier` DROP COLUMN `elite_dodge`;
UPDATE `bonk_tier` SET `details` = REPLACE(`details`, 'Elites have 3 affixes and dodge even more.', 'Elites have 3 affixes.') WHERE `id` = 2;
UPDATE `bonk_tier` SET `details` = REPLACE(`details`, 'Elites have 2 affixes and dodge more.', 'Elites have 2 affixes.') WHERE `id` = 3;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
