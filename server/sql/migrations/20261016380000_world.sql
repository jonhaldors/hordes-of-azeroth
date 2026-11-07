DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016380000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016380000');

DELETE FROM `bonk_upgrade` WHERE `id` = 29;
INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(29, 'Stacked Deck', 'Switch off 1 more Darkmoon Card or Glyph in the Spellbook, so runs never offer it.', 113, 1, 5, 100000, 2, 'INV_Misc_Ticket_Tarot_Stack_01', 2, 3, 2, 22, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
