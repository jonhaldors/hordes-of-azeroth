DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016530000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016530000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (216, 217, 218, 219, 220, 221);
DELETE FROM `bonk_weapon` WHERE `id` IN (216, 217, 218, 219, 220, 221);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(216, 'Chain Detonation', 'INV_Misc_Bomb_05', 'Fires a powerful shot that pierces every enemy in a line, aimed at the Marked group or else the largest group. A moment later, each enemy it pierced explodes in turn down the line, dealing 40% of the shot''s damage to all enemies within 4 yards.', 19434, 8, 3000, 35, 1.5, 4, 0, 203, 0, 0, 0, 24, 0.4, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(217, 'Steady Aim', 'Ability_Hunter_AimedShot', 'Fires a powerful shot that pierces every enemy in a line, aimed at the Marked group or else the largest group. While you stand still, it attacks 100% more often, and each full second you stand still makes its line 100% wider, up to 3 times as wide.', 19434, 8, 3000, 35, 1.5, 4, 0, 203, 0, 0, 0, 25, 3, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(218, 'Arrow Storm', 'INV_Ammo_Arrow_01', 'Rains arrows on the largest group of enemies for 3 sec. While it rains, the storm moves with the largest group of enemies within 25 yards of it. Deals 5% more damage for each different debuff on the target.', 22908, 3, 6000, 20, 0.4, 4, 0, 137, 0, 3000, 0, 26, 7, 1000, 1, 0, 0, 1, 0, 0, 0, 0, 0, 255, 5),
(219, 'Gravity Volley', 'Spell_Nature_Cyclone', 'Pulls every normal enemy within 12 yards of the largest group of enemies into the middle, then rains arrows on them for 3 sec. Elites, mini-bosses and bosses resist the pull. Deals 5% more damage for each different debuff on the target.', 22908, 3, 6000, 20, 0.4, 4, 0, 137, 0, 3000, 0, 27, 1.5, 1000, 1, 0, 0, 1, 0, 0, 0, 0, 0, 255, 5),
(220, 'Flare', 'Spell_Fire_Flare', 'Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage. The flare burns on the ground for 6 sec, and each of your shots that hits an enemy inside it fires 1 additional shot at the nearest other enemy inside it.', 1543, 3, 6000, 20, 0, 4, 0, 205, 0, 8000, 0, 28, 6000, 0, 1, 0, 0, 1, 0, 0, 0, 9, 1, 0, 0),
(221, 'Marked for Death', 'INV_Enchant_ShardBrilliantLarge', 'Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage. When a Marked enemy dies, it bursts into arcane shards that deal Arcane damage to all enemies within 8 yards.', 1543, 3, 6000, 20, 0.5, 4, 0, 205, 0, 8000, 0, 29, 8, 0, 1, 0, 0, 1, 0, 0, 0, 9, 1, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(216, 2, 10), (216, 3, 8),
(217, 2, 10), (217, 3, 8),
(218, 2, 10), (218, 3, 8), (218, 5, 15),
(219, 2, 10), (219, 3, 8), (219, 5, 15),
(220, 3, 8), (220, 5, 15), (220, 6, 3),
(221, 3, 8), (221, 5, 15), (221, 6, 3);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
