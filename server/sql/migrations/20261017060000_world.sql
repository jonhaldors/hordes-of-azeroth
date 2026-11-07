DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017060000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017060000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 323 AND 332;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 323 AND 332;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(323, 'Bladestorm', 'INV_Axe_17', 'Spins for 3 sec, striking all enemies within 8 yards of you every 0.5 sec while you keep moving. Haste makes it strike more often. If you are Enraged when it starts, the spin lasts 50% longer.', 15576, 1, 4000, 8, 0.4, 1, 0, 306, 0, 0, 0, 44, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(324, 'Steel Cyclone', 'Spell_Nature_EyeOfTheStorm', 'Spins, striking all enemies within 8 yards of you. While you are Enraged, it spins twice. Each spin leaves a storm of blades where you stood for 3 sec, striking all enemies within 8 yards of it every 0.5 sec for 20% of the damage.', 15576, 1, 4000, 8, 1.1, 1, 0, 306, 0, 0, 0, 45, 400, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(325, 'Aegis', 'INV_Shield_06', 'Every 10 sec, gives you a Shield equal to 10% of your maximum health. Each hit your Shield absorbs sends out a shockwave that strikes all enemies within 6 yards of you. The shockwave can occur once every 0.5 sec.', 2565, 7, 10000, 6, 0.3, 1, 0, 307, 0, 0, 0, 46, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(326, 'Spiked Shield', 'Spell_Nature_Thorns', 'Every 10 sec, gives you a Shield equal to 10% of your maximum health. While you hold any Shield, its spikes strike all enemies within 6 yards of you every 1 sec.', 2565, 7, 10000, 6, 0.3, 1, 0, 307, 0, 0, 0, 47, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(327, 'Rolling Thunder', 'Spell_Nature_StormReach', 'Blasts all enemies within 8 yards of you with thunder after every 40 hits by your other spells, instead of on a cooldown. Enemies hit attack 20% slower for 6 sec. Haste lowers the count, down to 15 hits.', 6343, 1, 3000, 8, 0.7, 1, 0, 308, 0, 6000, 0, 48, 20, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(328, 'Demoralizing Shout', 'Ability_Warrior_WarCry', 'Blasts all enemies within 8 yards of you with thunder. Enemies hit attack 20% slower and deal 30% less damage for 6 sec. Each blast heals you for 1% of your maximum health for each enemy hit, up to 10%.', 6343, 1, 3000, 8, 0.7, 1, 0, 308, 1, 6000, 0, 49, 20, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(329, 'Vengeance', 'Spell_Holy_Retribution', 'When you are struck, strikes all enemies within 6 yards of you. Damage you take is stored, up to 50% of your maximum health, and released by the next strike for up to 200% more damage. Can occur once every 2 sec.', 19632, 1, 2000, 6, 0.9, 1, 0, 309, 0, 0, 0, 50, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(330, 'Berserker Rage', 'Ability_Warrior_InnerRage', 'When you are struck, strikes all enemies within 6 yards of you and Enrages you. Enrage gives you 25% Haste for 4 sec. Can occur once every 2 sec.', 19632, 1, 2000, 6, 0.9, 1, 0, 309, 0, 0, 0, 51, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(331, 'Avenger''s Shield', 'Ability_Warrior_ShieldBash', 'Hurls your shield at the nearest enemy within 20 yards. It jumps to 5 more enemies within 10 yards, never the same one twice. Each hit deals 2% more damage for each 1% of your maximum health held in your Shield, up to 200% more.', 20240, 0, 5000, 20, 1.4, 1, 0, 310, 0, 0, 0, 52, 2, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(332, 'Bulwark', 'Ability_Warrior_ShieldWall', 'Slams all enemies within 6 yards of you. Deals 2% more damage for each 1% of your maximum health held in your Shield, up to 200% more. Each enemy hit gives you Shield equal to 1% of your maximum health, up to 10% per slam.', 20240, 1, 5000, 6, 1.4, 1, 0, 310, 0, 0, 0, 53, 2, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(323, 3, 8), (323, 2, 10),
(324, 3, 8), (324, 2, 10), (324, 5, 15),
(325, 14, 15), (325, 3, 8),
(326, 14, 15), (326, 3, 8),
(327, 3, 8), (327, 2, 10),
(328, 3, 8), (328, 2, 10),
(329, 15, 8), (329, 2, 10),
(330, 15, 8), (330, 2, 10),
(331, 3, 8), (331, 2, 10),
(332, 3, 8), (332, 2, 10), (332, 14, 15);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
