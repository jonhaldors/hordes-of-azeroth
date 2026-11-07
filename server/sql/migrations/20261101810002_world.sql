DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101810002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101810002');

ALTER TABLE `bonk_upgrade` ADD COLUMN `required_level` int(10) unsigned NOT NULL DEFAULT 0 AFTER `required_rank`;
ALTER TABLE `bonk_talent` ADD COLUMN `rank_levels` varchar(64) NOT NULL DEFAULT '' AFTER `rank_quests`;

UPDATE `bonk_upgrade` SET `cost_growth` = 1.6 WHERE `tree` = 7;
UPDATE `bonk_upgrade` SET `cost_growth` = 1.6 WHERE `max_rank` = 5 AND `tree` IN (1, 2, 3);
UPDATE `bonk_upgrade` SET `cost` = 80000 WHERE `id` = 18;
UPDATE `bonk_upgrade` SET `cost` = 150000 WHERE `id` = 22;
UPDATE `bonk_upgrade` SET `cost` = 100000 WHERE `id` = 21;
UPDATE `bonk_upgrade` SET `cost` = 40000, `cost_growth` = 2 WHERE `id` = 31;
UPDATE `bonk_upgrade` SET `cost` = 400000 WHERE `id` = 30;
UPDATE `bonk_upgrade` SET `cost` = 30000, `cost_growth` = 2 WHERE `id` = 26;
UPDATE `bonk_upgrade` SET `cost` = 40000, `cost_growth` = 2 WHERE `id` = 27;
UPDATE `bonk_upgrade` SET `cost` = 2500000, `required_level` = 24 WHERE `id` = 28;

UPDATE `bonk_talent` SET `rank_quests` = '25,0', `rank_levels` = '0,14' WHERE `id` = 11;
UPDATE `bonk_talent` SET `rank_quests` = '15,35,0', `rank_levels` = '0,0,19' WHERE `id` = 10;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
