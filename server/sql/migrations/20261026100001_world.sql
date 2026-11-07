DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100001');

INSERT INTO `bonk_shop_tree` (`id`, `shop`, `name`, `background`) VALUES (7, 1, 'Training', 'WarriorArms');

INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(40, 'Might', '+3% Power.', 0, 3, 10, 3000, 1.45, 'Spell_Holy_FistOfJustice', 7, 1, 1, 0, 0),
(41, 'Swiftness', '+1.5% Haste.', 1, 1.5, 10, 3000, 1.45, 'Racial_Troll_Berserk', 7, 1, 2, 0, 0),
(42, 'Precision', '+0.8% critical strike chance.', 15, 0.8, 10, 3000, 1.45, 'INV_Potion_32', 7, 1, 3, 0, 0),
(43, 'Fortitude', '+4% maximum health.', 4, 4, 10, 2500, 1.45, 'Spell_Holy_WordFortitude', 7, 2, 1, 0, 0),
(44, 'Toughness', '+1.5 Armor.', 12, 1.5, 10, 2500, 1.45, 'Spell_Holy_DevotionAura', 7, 2, 2, 0, 0),
(45, 'Agility', '+0.5% dodge chance.', 14, 0.5, 10, 2500, 1.45, 'Spell_Holy_BlessingOfAgility', 7, 2, 3, 0, 0),
(46, 'Ruthlessness', '+4% critical strike damage.', 16, 4, 10, 3000, 1.45, 'Ability_Rogue_Eviscerate', 7, 3, 1, 0, 0),
(47, 'Reach', '+1.5% Area.', 10, 1.5, 10, 3000, 1.45, 'Spell_Holy_ArcaneIntellect', 7, 3, 2, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
