DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016400000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016400000');

UPDATE `bonk_glyph` SET `description` = '+20% experience.' WHERE `id` = 1;
UPDATE `bonk_card` SET `stat1_value` = 20, `description` = '+20% experience.' WHERE `id` = 150;
UPDATE `bonk_glyph` SET `value1` = 100, `description` = '+60% pickup range, and power-ups stay on the ground twice as long.' WHERE `id` = 2;
UPDATE `bonk_card` SET `stat1_value` = 60, `description` = '+60% pickup range.' WHERE `id` = 151;
UPDATE `bonk_glyph` SET `description` = '+30% damage to elites, mini-bosses and bosses.' WHERE `id` = 4;
UPDATE `bonk_card` SET `value1` = 30, `description` = '+30% damage to elites, mini-bosses and bosses.' WHERE `id` = 152;
UPDATE `bonk_glyph` SET `value2` = 40, `value3` = 8000, `description` = 'Every 50 kills, gain 40% Haste for 8 seconds.' WHERE `id` = 8;
UPDATE `bonk_glyph` SET `description` = '+50% Valor.' WHERE `id` = 9;
UPDATE `bonk_card` SET `value1` = 50, `description` = '+50% Valor.' WHERE `id` = 154;
UPDATE `bonk_glyph` SET `value3` = 2000, `description` = 'Every 50 kills, you deal triple damage for 2 seconds.' WHERE `id` = 12;
UPDATE `bonk_glyph` SET `value1` = 0.5, `description` = '+2% Power for every 1% of health you are missing.' WHERE `id` = 13;
UPDATE `bonk_glyph` SET `description` = '+60% experience.' WHERE `id` = 14;
UPDATE `bonk_card` SET `stat1_value` = 60, `description` = '+60% experience.' WHERE `id` = 156;

DELETE FROM `bonk_upgrade` WHERE `id` = 30;
INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(30, 'Foresight', 'Runs start with a Glyph to choose, on top of the ones mini-bosses and bosses give.', 114, 1, 1, 100000, 1, 'Spell_Holy_MindVision', 6, 1, 1, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
