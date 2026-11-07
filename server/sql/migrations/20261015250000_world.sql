DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015250000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015250000');

UPDATE `bonk_passive` SET `value_per_rank` = 25, `description` = '+25% maximum health.' WHERE `id` = 5;
UPDATE `bonk_passive` SET `value_per_rank` = 0.4, `description` = 'Regain 0.4% of your health every second.' WHERE `id` = 6;
UPDATE `bonk_passive` SET `value_per_rank` = 10, `description` = '+10 Armor: enemies deal less damage to you.' WHERE `id` = 13;
UPDATE `bonk_passive` SET `value_per_rank` = 5, `description` = '+5% chance to dodge enemy swings.' WHERE `id` = 15;
UPDATE `bonk_passive` SET `value_per_rank` = 10, `description` = '+10% of your maximum health as a Shield.' WHERE `id` = 17;
UPDATE `bonk_passive` SET `value_per_rank` = 10, `description` = 'Each hit has a 10% chance to heal 1% of your maximum health (at most 3% a second).' WHERE `id` = 20;

DELETE FROM `bonk_talent` WHERE `id` IN (10, 11);
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(10, 'Passive Slot', '+1 passive slot in runs (3 at the start).', 10, 1, 0, 3, 5, 1, 'INV_Misc_Rune_01', 4, 2, 1, 0, 0),
(11, 'Spell Slot',   '+1 spell slot in runs (3 at the start).',   9,  1, 0, 2, 8, 1, 'INV_Misc_Book_09', 4, 2, 2, 0, 0);

DELETE FROM `bonk_quest` WHERE `id` IN (256, 257);
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(256, 'Apprentice',          'Complete 5 quests.',  'INV_Misc_Rune_01', 17, 0, 0, 5,  4, 10, 0, 5),
(257, 'Seasoned Adventurer', 'Complete 20 quests.', 'INV_Misc_Book_09', 17, 0, 0, 20, 4, 11, 0, 5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
