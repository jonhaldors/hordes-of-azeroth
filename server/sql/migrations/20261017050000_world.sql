DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017050000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017050000');

UPDATE `bonk_weapon` SET `spell_id` = 15613, `range` = 8, `description` = 'Strikes all enemies within 8 yards of you.' WHERE `id` = 300;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 311 AND 322;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 311 AND 322;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(311, 'Wake of Blades', 'Ability_Hunter_SwiftStrike', 'Strikes all enemies within 8 yards of you. Each swing leaves an echo where you stood that strikes all enemies within 8 yards of it 1 sec later.', 15613, 1, 1500, 8, 0.55, 1, 0, 300, 0, 0, 0, 38, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(312, 'Fourth Swing', 'Ability_Warrior_DecisiveStrike', 'Strikes all enemies within 8 yards of you. Every 4th swing strikes all enemies within 16 yards instead and knocks normal enemies back.', 15613, 1, 1500, 8, 0.55, 1, 0, 300, 0, 0, 0, 39, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(313, 'Blood Aura', 'Spell_Shadow_RitualOfSacrifice', 'Every 1 sec, all enemies within 6 yards of you gain 1 stack of Bleed.', 13318, 7, 1000, 6, 0, 1, 0, 301, 0, 0, 0, 40, 0, 0, 1, 0, 0, 1, 0, 0, 32768, 4, 1, 0, 0),
(314, 'Blood Pool', 'Ability_Rogue_Rupture', 'Wounds the 3 nearest enemies within 10 yards, applying 3 stacks of Bleed to each. Bleeding enemies that die leave a pool of blood for 4 sec. Enemies within 4 yards of a pool gain 1 stack of Bleed every 1 sec.', 13318, 0, 1500, 10, 0, 1, 0, 301, 0, 0, 0, 41, 4, 0, 3, 0, 0, 1, 0, 0, 32768, 4, 3, 0, 0),
(315, 'Bloodsplatter', 'Ability_Rogue_Eviscerate', 'Your critical strikes wound the enemy and every enemy within 4 yards of it, applying 2 stacks of Bleed to each. Can occur once every 0.5 sec on each enemy.', 12162, 7, 500, 0, 0, 1, 0, 302, 0, 0, 0, 33, 0, 0, 1, 0, 0, 1, 0, 0, 65536, 4, 2, 0, 0),
(316, 'Hemorrhage', 'Spell_Shadow_LifeDrain', 'Your critical strikes wound the enemy, applying 2 stacks of Bleed. Each tick of this Bleed deals 10% more damage than the last, up to 200% more. Can occur once every 0.5 sec on each enemy.', 12162, 7, 500, 0, 0, 1, 0, 302, 0, 0, 0, 33, 0, 0, 1, 0, 0, 1, 0, 0, 131072, 4, 2, 0, 0),
(317, 'Bloodlust', 'Spell_Shadow_UnholyFrenzy', 'Strikes all enemies within 8 yards of you. Deals 8% more damage to each enemy for each stack of Bleed on it, counting up to 25 stacks. Each Bleeding enemy hit shortens its cooldown by 0.5 sec, down to 1 sec.', 13446, 1, 6000, 8, 2, 1, 0, 303, 0, 0, 0, 42, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 8),
(318, 'Aftershock', 'Spell_Nature_Earthquake', 'Strikes all enemies within 8 yards of you, dealing 8% more damage for each stack of Bleed on them, up to 25 stacks. 1.5 sec later the ground where you struck erupts for 50% of that damage, applying 2 stacks of Bleed to each enemy within 8 yards.', 13446, 1, 6000, 8, 2, 1, 0, 303, 0, 0, 0, 43, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 8),
(319, 'Blood Shield', 'Spell_Shadow_SacrificialShield', 'Strikes the 3 nearest enemies within 8 yards, healing you 1% of your maximum health per enemy hit. Healing above your maximum health becomes a Blood Shield that explodes when it breaks, dealing 200% damage within 8 yards. Its critical strikes Enrage you.', 23881, 0, 2000, 8, 1, 1, 0, 304, 1, 0, 0, 34, 2, 0, 3, 0, 0, 1, 0, 0, 262144, 0, 0, 0, 0),
(320, 'Bloodbath', 'Spell_Shadow_DeathPact', 'Strikes the 3 nearest enemies within 8 yards and heals you for 1% of your maximum health for each enemy hit. While you are below 50% health, it strikes all enemies within 8 yards instead. Its critical strikes Enrage you (25% Haste for 4 sec).', 23881, 0, 2000, 8, 1, 1, 0, 304, 1, 0, 0, 34, 0, 0, 3, 0, 0, 1, 0, 0, 524288, 0, 0, 0, 0),
(321, 'Chain Execution', 'Ability_Warrior_PunishingBlow', 'Strikes all enemies within 8 yards of you. Normal enemies below 20% health die instantly; elites and bosses below 20% take triple damage. Enemies it kills explode for 50% damage within 5 yards, executing normal enemies left below 20%. Kills Enrage you.', 24316, 1, 2500, 8, 0.7, 1, 0, 305, 0, 0, 0, 11, 20, 0, 1, 0, 0, 3, 0, 20, 1048576, 0, 0, 0, 0),
(322, 'Sweep', 'INV_Axe_09', 'Strikes all enemies within 8 yards of you; elites and bosses below 20% health take triple damage. Every normal enemy within 40 yards below 20% health dies instantly. Each kill Enrages you, or refreshes your Enrage (25% Haste for 4 sec).', 24316, 1, 2500, 8, 0.7, 1, 0, 305, 0, 0, 0, 11, 20, 0, 1, 0, 0, 3, 0, 20, 2097152, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(311, 3, 8), (311, 2, 10),
(312, 3, 8), (312, 2, 10),
(313, 9, 1), (313, 5, 15), (313, 3, 8),
(314, 9, 1), (314, 5, 15), (314, 3, 8),
(315, 15, 8), (315, 9, 1), (315, 5, 15),
(316, 15, 8), (316, 9, 1), (316, 5, 15),
(317, 3, 8), (317, 2, 10),
(318, 3, 8), (318, 2, 10),
(319, 3, 8), (319, 2, 10),
(320, 3, 8), (320, 2, 10),
(321, 3, 8), (321, 2, 10),
(322, 3, 8), (322, 2, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
