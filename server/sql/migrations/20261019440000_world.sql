DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019440000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019440000');

ALTER TABLE `bonk_tier` ADD COLUMN IF NOT EXISTS `chest_cost_minute_growth` FLOAT NOT NULL DEFAULT 0 AFTER `chest_cost_growth`;
UPDATE `bonk_tier` SET `chest_cost_growth` = 0.5, `chest_cost_minute_growth` = 0.6;

DELETE FROM `bonk_upgrade` WHERE `id` = 31;
INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(31, 'Restock', 'Zixil the goblin merchant can restock his wares 1 more time per visit. Wares you already bought stay sold.', 115, 1, 2, 20000, 2, 'INV_Misc_Bag_10', 2, 3, 1, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
