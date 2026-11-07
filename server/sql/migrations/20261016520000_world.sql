DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016520000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016520000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (212, 213, 214, 215);
DELETE FROM `bonk_weapon` WHERE `id` IN (212, 213, 214, 215);
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(212, 'Chimera Shot', 'Spell_Nature_NullifyPoison_02', 'An instant shot that deals Arcane damage to the nearest enemy. It consumes all Poison on the target, dealing the poison''s remaining damage instantly.', 3044, 0, 1500, 35, 1.1, 4, 0, 7, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 128, 0, 0, 5, 0),
(213, 'Ricochet', 'Ability_Hunter_CriticalShot', 'An instant shot that deals Arcane damage to the nearest enemy, then jumps to up to 2 additional enemies within 10 yards, Marked enemies first. Each jump deals 25% more damage than the one before.', 3044, 0, 1500, 35, 1.1, 4, 0, 7, 0, 0, 0, 22, 2, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(214, 'Trick Shots', 'Ability_Hunter_RunningShot', 'Fires 3 arrows in a cone in front of you. Every enemy it kills fires 3 arrows from where it fell at the nearest enemies within 15 yards, and enemies those arrows kill fire again.', 2643, 6, 2500, 25, 0.7, 4, 0, 37, 0, 0, 0, 23, 3, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(215, 'Serpent Spread', 'Ability_Hunter_Pet_WindSerpent', 'Fires 3 arrows in a cone in front of you that deal 25% of Multi-Shot''s damage and apply 2 stacks of Poison to each enemy hit.', 2643, 6, 2500, 25, 0.175, 4, 0, 37, 0, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 0, 5, 2, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(212, 1, 10), (212, 2, 10), (212, 3, 8),
(213, 1, 10), (213, 2, 10), (213, 3, 8),
(214, 1, 10), (214, 2, 10), (214, 3, 8),
(215, 1, 10), (215, 2, 10), (215, 3, 8), (215, 9, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
