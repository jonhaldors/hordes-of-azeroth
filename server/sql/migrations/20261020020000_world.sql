DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020020000');

DELETE FROM `bonk_glyph` WHERE `id` BETWEEN 18 AND 27;
INSERT INTO `bonk_glyph` (`id`, `name`, `icon`, `description`, `drawback`, `rarity`, `effect`, `value1`, `value2`, `value3`, `card_id`, `starter`) VALUES
(18, 'Glyph of Blinding Speed', 'Spell_Nature_Invisibilty', 'Your dash gains 1 extra charge and recharges 30% faster.', '', 0, 15, 1, 30, 0, 0, 1),
(19, 'Glyph of Foresight', 'Spell_Holy_MindVision', '+2 rerolls, and 2 more at the start of every later stage.', '', 0, 16, 2, 0, 0, 0, 1),
(20, 'Glyph of the Treasure Hunter', 'INV_Box_02', 'One extra chest appears near you every stage, a minute in.', '', 0, 17, 60000, 0, 0, 0, 1),
(21, 'Glyph of the Scavenger', 'INV_Misc_Gear_01', 'Every elite you kill drops a power-up.', '', 0, 18, 0, 0, 0, 0, 1),
(22, 'Glyph of the Prodigy', 'Spell_Holy_SealOfWisdom', 'Your starter spell gains 2 ranks right away.', '', 1, 19, 2, 0, 0, 0, 1),
(23, 'Glyph of Ambition', 'Ability_Warrior_BattleShout', 'One extra mini-boss arrives with every mini-boss wave, and mini-bosses give double rewards.', 'Mini-bosses deal 25% more damage.', 1, 20, 1, 100, 25, 0, 1),
(24, 'Glyph of the Hunt', 'Ability_Hunter_BeastTracking', 'Twice as many elites appear, and each gives 3 times the experience.', 'More elites means more danger.', 1, 21, 100, 3, 0, 0, 1),
(25, 'Glyph of the Last Stand', 'Ability_Warrior_Challange', 'While below 30% health, gain 40% Haste and 20% movement speed.', '', 2, 22, 30, 40, 20, 0, 1),
(26, 'Glyph of the Turtle', 'Ability_Defend', '+30% Power and +30% Armor while you stand still.', '-15% movement speed.', 2, 23, 30, 30, 15, 0, 1),
(27, 'Glyph of the Nomad', 'Ability_Rogue_Sprint', '+25% Power while you move.', 'Losing health turns it into -25% Power for 5 sec. Damage a Shield absorbs does not.', 2, 24, 25, 25, 5000, 0, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
