DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103110000');

DELETE FROM `bonk_talent` WHERE `id` = 23;
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`, `rank_levels`) VALUES
(23, 'Rewritten Fate', '+1 Glyph reroll per run.', 21, 1, 0, 2, 20, 2, 'INV_Misc_Rune_04', 4, 2, 4, 0, 0, '', '');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
