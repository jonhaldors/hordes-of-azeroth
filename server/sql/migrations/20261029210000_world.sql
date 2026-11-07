DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029210000');

DELETE FROM `bonk_shop_tree` WHERE `id` = 8;
INSERT INTO `bonk_shop_tree` (`id`, `shop`, `name`, `background`) VALUES
(8, 2, 'Darkmoon Favors', 'PriestHoly');

DELETE FROM `bonk_talent` WHERE `id` IN (20, 21, 22);
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`) VALUES
(20, 'Might', '+1% Power and +1% Max health.', 19, 1, 0, 255, 15, 0.333333, 'Spell_Holy_FistOfJustice', 8, 1, 1, 0, 0, ''),
(21, 'Insight', '+2% experience in runs.', 12, 2, 0, 255, 15, 0.333333, 'Spell_Holy_MindSooth', 8, 1, 2, 0, 0, ''),
(22, 'Fortune', '+3% gold and Scrap from runs.', 20, 3, 0, 255, 15, 0.333333, 'INV_Misc_Coin_01', 8, 1, 3, 0, 0, '');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
