DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016510000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016510000');

DELETE FROM `bonk_card` WHERE `id` = 31;
INSERT INTO `bonk_card` (`id`, `name`, `icon`, `description`, `rarity`, `stat1`, `stat1_value`, `stat2`, `stat2_value`, `effect`, `value1`, `value2`, `value3`, `cooldown_ms`, `max_copies`, `in_chests`) VALUES
(31, 'Darkmoon Card: Ascension', 'INV_Misc_Ticket_Tarot_Portal_01', 'Your next level-up with a spell at rank 10 or higher that can evolve always offers that spell''s evolution. Used up once the evolution is offered, even if you skip, reroll or banish.', 3, 255, 0, 255, 0, 23, 0, 0, 0, 0, 1, 1);

DELETE FROM `bonk_talent` WHERE `id` = 12;
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`) VALUES
(12, 'Second Sight', 'When an evolution is offered, you see every evolution of that spell as its own card and choose which one to take.', 11, 1, 0, 1, 10, 0, 'Spell_Nature_FarSight', 4, 3, 3, 0, 0, '');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
