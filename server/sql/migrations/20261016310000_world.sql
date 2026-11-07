DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016310000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016310000');

DELETE FROM `bonk_map` WHERE `id` = 17;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(17, 'feralas', 'Feralas', 2, 0, 1, 357, -4180, -140, 56.3, 3.9, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'INV_Crown_01');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 17;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(17, 13022, 0, 0, 0, 210, 7, 0, 1, 1, 0.9, 1),
(17, 13276, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(17, 12418, 0, 0, 390, 0, 4, 0, 1, 1, 0.95, 1),
(17, 5286, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(17, 5255, 0, 1, 60, 270, 8, 0, 1, 1, 0.8, 1),
(17, 11452, 0, 1, 120, 360, 7, 0, 1, 1, 0.85, 1),
(17, 5292, 0, 1, 210, 450, 7, 0, 1, 1, 0.8, 1),
(17, 11476, 0, 1, 270, 510, 6, 0, 1, 1, 0.75, 1),
(17, 7725, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(17, 11462, 0, 1, 420, 0, 5, 0, 1, 1, 0.7, 1),
(17, 11441, 0, 2, 0, 0, 6, 0, 1, 1, 0.7, 1),
(17, 13285, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(17, 5254, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(17, 11466, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(17, 5288, 0, 4, 420, 0, 2, 2, 1, 1, 0.9, 1),
(17, 11457, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(17, 11445, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1),
(17, 11484, 1, 1, 200, 0, 2, 0, 1, 1, 0.8, 1.2),
(17, 11465, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.7, 1),
(17, 11501, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(17, 11486, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(17, 11492, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1),
(17, 11489, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(17, 11496, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1),
(17, 11487, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (13276, 5254, 11466);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(13276, 2, 3.5, 'Wildspawn Imp: bursts into flame next to the player'),
(5254, 1, 20, 'Woodpaw Mystic'),
(11466, 1, 20, 'Highborne Summoner');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (13276, 5254, 11466, 5288, 11457, 11445, 11484, 11465, 11501, 11486, 11492, 11489, 11496, 11487);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(13276, 20602, 1, 1000, 0, 0, 10, 2, 'Wildspawn Imp: bursts (Fire Nova, as the Flame Imp)'),
(5254, 9532, 0, 5000, 1500, 0, 30, 1, 'Woodpaw Mystic: Lightning Bolt'),
(11466, 12466, 0, 5000, 2000, 0, 30, 1, 'Highborne Summoner: Fireball (its Frost Nova roots)'),
(5288, 6268, 1, 15000, 6000, 6, 30, 0, 'Rabid Longtooth: Rushing Charge'),
(11457, 15228, 0, 6000, 2000, 0, 30, 1.2, 'Wildspawn Hellcaller: Fireball (its Rain of Fire is a ground area)'),
(11445, 22574, 0, 7000, 2000, 0, 5, 0, 'Gordok Captain: Dark Strike'),
(11445, 22575, 0, 8000, 3000, 0, 20, 1.2, 'Gordok Captain: Shadow Shock (its Fear is left out)'),
(11484, 15230, 0, 5000, 2000, 0, 30, 1.2, 'Residual Monstrosity: Arcane Bolt'),
(11484, 22940, 1, 14000, 6000, 0, 10, 1.2, 'Residual Monstrosity: Arcane Blast (10 yd, knocks back)'),
(11465, 3391, 1, 10000, 4000, 0, 5, 0, 'Warpwood Stomper: Thrash'),
(11465, 16727, 1, 15000, 6000, 0, 5, 0, 'Warpwood Stomper: War Stomp'),
(11501, 15708, 0, 8000, 3000, 0, 5, 0, 'King Gordok: Mortal Strike'),
(11501, 16727, 1, 12000, 5000, 0, 5, 0, 'King Gordok: War Stomp'),
(11501, 22886, 0, 14000, 6000, 8, 25, 0, 'King Gordok: Berserker Charge'),
(11486, 15589, 1, 12000, 5000, 0, 8, 0, 'Prince Tortheldrin: Whirlwind (the 8 yd hit)'),
(11486, 3391, 1, 10000, 4000, 0, 5, 0, 'Prince Tortheldrin: Thrash'),
(11486, 15230, 0, 6000, 3000, 0, 35, 1.3, 'Prince Tortheldrin: Arcane Bolt (the Residual Monstrosities''; his Arcane Blast is melee range, his Counterspell silences)'),
(11492, 19319, 0, 7000, 2000, 0, 5, 0, 'Alzzin the Wildshaper: Vicious Bite (his wolf form)'),
(11492, 10101, 0, 10000, 4000, 0, 5, 0, 'Alzzin the Wildshaper: Knock Away (his tree form)'),
(11492, 7948, 1, 25000, 10000, 0, 40, 0, 'Alzzin the Wildshaper: Wild Regeneration (his Wither and Mangle leave damage over time, his Thorns hurts attackers)'),
(11489, 5568, 1, 10000, 4000, 0, 10, 0, 'Tendris Warpwood: Trample'),
(11489, 22916, 0, 9000, 3000, 0, 5, 0, 'Tendris Warpwood: Uppercut'),
(11489, 8269, 1, 30000, 12000, 0, 40, 0, 'Tendris Warpwood: Enrage (his Grasping Vines and Entangle root)'),
(11496, 5568, 1, 10000, 4000, 0, 10, 0, 'Immol''thar: Trample'),
(11496, 8269, 1, 30000, 12000, 0, 40, 0, 'Immol''thar: Enrage (his Infected Bite is a DoT, his Eye summons, his Portal teleports)'),
(11487, 17287, 0, 6000, 2000, 0, 30, 1.3, 'Magister Kalendris: Mind Blast'),
(11487, 22917, 1, 30000, 5000, 0, 40, 0, 'Magister Kalendris: Shadowform (his Shadow Word: Pain and Mind Flay are DoTs, his Dominate Mind a charm)');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 17;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(17, 0, 3, 2),
(17, 150, 3, 1),
(17, 330, 3, 1),
(17, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 18;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(18, 'searinggorge', 'Searing Gorge', 2, 0, 0, 51, -7135, -1505, 241.2, 0.8, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'Ability_GolemThunderClap');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 18;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(18, 5857, 0, 0, 0, 210, 7, 0, 1, 1, 0.9, 1),
(18, 5839, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(18, 8921, 0, 0, 390, 0, 4, 0, 1, 1, 0.95, 1),
(18, 9318, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(18, 5844, 0, 1, 60, 270, 8, 0, 1, 1, 0.75, 1),
(18, 5855, 0, 1, 120, 360, 7, 0, 1, 1, 0.7, 1),
(18, 5846, 0, 1, 210, 450, 7, 0, 1, 1, 0.75, 1),
(18, 5850, 0, 1, 270, 510, 6, 0, 1, 1, 0.75, 1),
(18, 8892, 0, 1, 300, 540, 6, 0, 1, 1, 0.8, 1),
(18, 8893, 0, 1, 420, 0, 5, 0, 1, 1, 0.8, 1),
(18, 5854, 0, 2, 0, 0, 6, 0, 1, 1, 0.65, 1),
(18, 8907, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(18, 5858, 0, 3, 150, 330, 3, 3, 1, 1, 0.75, 1),
(18, 8900, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(18, 8922, 0, 4, 420, 0, 2, 2, 1, 1, 0.9, 1),
(18, 8898, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(18, 8899, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(18, 8894, 1, 1, 200, 0, 2, 0, 1, 1, 0.75, 1.2),
(18, 8910, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.75, 1.2),
(18, 10429, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(18, 10430, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(18, 9033, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(18, 8983, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(18, 9816, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.5),
(18, 10220, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1);

DELETE FROM `bonk_mob` WHERE `entry` IN (5839, 5858, 8900);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(5839, 2, 3.5, 'Dark Iron Geologist: runs in with a blasting charge'),
(5858, 1, 20, 'Greater Lava Spider'),
(8900, 1, 20, 'Doomforge Arcanasmith');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (5839, 5858, 8900, 8922, 8898, 8899, 8894, 8910, 10429, 10430, 9033, 8983, 9816, 10220);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(5839, 3204, 1, 1000, 0, 0, 10, 2, 'Dark Iron Geologist: Sapper Explode (its own Bomb hits a ground area)'),
(5858, 11985, 0, 5000, 1500, 0, 30, 1, 'Greater Lava Spider: Fireball'),
(8900, 13748, 0, 5000, 2000, 0, 30, 1, 'Doomforge Arcanasmith: Arcane Bolt'),
(8922, 6268, 1, 15000, 6000, 6, 30, 0, 'Bloodhound Mastiff: Rushing Charge'),
(8898, 13953, 0, 7000, 2000, 0, 5, 0, 'Anvilrage Marshal: Holy Strike'),
(8898, 15493, 1, 18000, 8000, 0, 40, 0, 'Anvilrage Marshal: Holy Light'),
(8899, 15622, 0, 7000, 2000, 0, 5, 0, 'Doomforge Dragoon: Cleave'),
(8899, 15620, 0, 6000, 2000, 8, 30, 1, 'Doomforge Dragoon: Shoot (its Explosive Shot hits a ground area)'),
(8894, 15587, 0, 6000, 2000, 0, 30, 1.2, 'Anvilrage Medic: Mind Blast'),
(8894, 15586, 1, 15000, 8000, 0, 40, 0, 'Anvilrage Medic: Heal'),
(8910, 15241, 0, 6000, 2000, 0, 30, 1.2, 'Blazing Fireguard: Scorch'),
(8910, 13341, 0, 8000, 3000, 0, 20, 1, 'Blazing Fireguard: Fire Blast (its Immolate is a DoT)'),
(10429, 15589, 1, 12000, 5000, 0, 8, 0, 'Warchief Rend Blackhand: Whirlwind (the 8 yd hit of his Whirlwind aura)'),
(10429, 15708, 0, 8000, 3000, 0, 5, 0, 'Warchief Rend Blackhand: Mortal Strike'),
(10429, 15754, 0, 7000, 2000, 0, 5, 0, 'Warchief Rend Blackhand: Cleave'),
(10429, 8269, 1, 30000, 15000, 0, 40, 0, 'Warchief Rend Blackhand: Enrage'),
(10430, 16785, 1, 12000, 5000, 0, 10, 1.5, 'The Beast: Flamebreak (10 yd, knocks back)'),
(10430, 16788, 0, 6000, 3000, 0, 35, 1.3, 'The Beast: Fireball'),
(10430, 16636, 0, 14000, 6000, 8, 25, 0, 'The Beast: Berserker Charge (his Terrifying Roar is a fear)'),
(9033, 15754, 0, 7000, 2000, 0, 5, 0, 'General Angerforge: Cleave (the Anvilrage Soldiers''; his own Sunder Armor only lowers armor)'),
(9033, 15061, 1, 25000, 10000, 0, 40, 0, 'General Angerforge: Enrage (the buff of his passive Enrage)'),
(8983, 15605, 0, 5000, 2000, 0, 20, 1.2, 'Golem Lord Argelmach: Shock'),
(8983, 10966, 0, 9000, 3000, 0, 5, 0, 'Golem Lord Argelmach: Uppercut (his Wrath Hammer Constructs''; his Chain Lightning chains, his Lightning Shield hurts attackers)'),
(9816, 16079, 1, 12000, 5000, 0, 10, 1.5, 'Pyroguard Emberseer: Fire Nova'),
(9816, 16536, 0, 6000, 2000, 0, 20, 1.2, 'Pyroguard Emberseer: Flame Buffet (the bolt deals damage only, its debuff never reaches the hero)'),
(10220, 10887, 1, 12000, 5000, 0, 10, 0, 'Halycon: Crowd Pummel'),
(10220, 14099, 0, 9000, 3000, 0, 5, 0, 'Halycon: Mighty Blow');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 18;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(18, 0, 3, 2),
(18, 150, 3, 1),
(18, 330, 3, 1),
(18, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 19;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(19, 'felwood', 'Felwood', 2, 0, 1, 361, 6270, -1380, 370.6, 0.8, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'Spell_Shadow_SummonInfernal');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 19;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(19, 7125, 0, 0, 0, 210, 7, 0, 1, 1, 0.9, 1),
(19, 7092, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(19, 7097, 0, 0, 390, 0, 4, 0, 1, 1, 0.9, 1),
(19, 8956, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(19, 7105, 0, 1, 60, 270, 8, 0, 1, 1, 0.8, 1),
(19, 7153, 0, 1, 120, 360, 7, 0, 1, 1, 0.75, 1),
(19, 9878, 0, 1, 210, 450, 7, 0, 1, 1, 0.8, 1),
(19, 7139, 0, 1, 270, 510, 6, 0, 1, 1, 0.7, 1),
(19, 7110, 0, 1, 300, 540, 6, 0, 1, 1, 0.85, 1),
(19, 7126, 0, 1, 420, 0, 5, 0, 1, 1, 0.85, 1),
(19, 7101, 0, 2, 0, 0, 6, 0, 1, 1, 0.7, 1),
(19, 7136, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(19, 7109, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(19, 7158, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(19, 8961, 0, 4, 420, 0, 2, 2, 1, 1, 0.9, 1),
(19, 7111, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(19, 9862, 1, 1, 120, 0, 2, 0, 1, 1, 0.8, 1.2),
(19, 8957, 1, 1, 200, 0, 2, 0, 1, 1, 0.85, 1.2),
(19, 7108, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.8, 1.2),
(19, 12397, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(19, 14467, 2, 1, 0, 0, 1, 0, 1, 1, 0.8, 1),
(19, 9517, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.5),
(19, 9877, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.4),
(19, 9464, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (7092, 7109, 7158);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(7092, 2, 3.5, 'Tainted Ooze: bursts next to the player'),
(7109, 1, 20, 'Jadefire Felsworn'),
(7158, 1, 20, 'Deadwood Shaman');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (7092, 7109, 7158, 8961, 7111, 9862, 8957, 7108, 12397, 14467, 9517, 9877, 9464);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(7092, 28361, 1, 1000, 0, 0, 10, 2, 'Tainted Ooze: bursts (Disease Cloud)'),
(7109, 9613, 0, 5000, 1500, 0, 30, 1, 'Jadefire Felsworn: Shadow Bolt (its Cripple slows)'),
(7158, 9532, 0, 5000, 2000, 0, 30, 1, 'Deadwood Shaman: Lightning Bolt (its Chain Lightning chains)'),
(8961, 6268, 1, 15000, 6000, 6, 30, 0, 'Felpaw Ravager: Rushing Charge'),
(7111, 20823, 0, 6000, 2000, 0, 30, 1.2, 'Jadefire Hellcaller: Fireball (its Rain of Fire is a ground area, its Jadefire shield hurts attackers)'),
(9862, 10966, 0, 9000, 3000, 0, 5, 0, 'Jaedenar Legionnaire: Uppercut'),
(9862, 15754, 0, 7000, 2000, 0, 5, 0, 'Jaedenar Legionnaire: Cleave (the Felguard Elites'' of the Tainted Scar)'),
(8957, 15793, 0, 7000, 2000, 0, 5, 0, 'Angerclaw Grizzly: Maul (the Angerclaw Maulers''; its own Low Swipe stuns)'),
(8957, 8599, 1, 25000, 10000, 0, 40, 0, 'Angerclaw Grizzly: Enrage'),
(7108, 5532, 0, 7000, 2000, 0, 5, 0, 'Jadefire Betrayer: Cleave (its Rend is a DoT)'),
(12397, 16044, 0, 7000, 2000, 0, 5, 0, 'Lord Kazzak: Cleave'),
(12397, 8078, 1, 12000, 5000, 0, 10, 1.5, 'Lord Kazzak: Thunderclap'),
(12397, 21066, 0, 6000, 3000, 0, 35, 1.4, 'Lord Kazzak: Void Bolt (his Shadow Bolt Volley reaches 100 yd; Mark of Kazzak and Twisted Reflection left out)'),
(14467, 10101, 0, 10000, 4000, 0, 5, 0, 'Kroshius: Knock Away'),
(14467, 20153, 1, 9000, 4000, 0, 8, 1.5, 'Kroshius: Immolation (the 8 yd pulse of the Corrupted Infernals'' Immolation aura)'),
(14467, 22703, 1, 20000, 8000, 0, 10, 1, 'Kroshius: Inferno Effect (10 yd, stuns: the Corrupted Infernals'' landing)'),
(9517, 20825, 0, 5000, 2000, 0, 35, 1.3, 'Shadow Lord Fel''dan: Shadow Bolt'),
(9517, 16583, 0, 9000, 4000, 0, 20, 1.1, 'Shadow Lord Fel''dan: Shadow Shock (his Shadow Bolt Volley reaches 30 yd)'),
(9877, 9613, 0, 5000, 2000, 0, 30, 1.2, 'Prince Xavalis: Shadow Bolt (the Jadefire Felsworns''; his Immolate is a DoT, his Jadefire shield hurts attackers)'),
(9877, 8599, 1, 25000, 10000, 0, 40, 0, 'Prince Xavalis: Enrage (his lieutenant Xavathras'')'),
(9464, 15793, 0, 7000, 2000, 0, 5, 0, 'Overlord Ror: Maul'),
(9464, 8599, 1, 25000, 10000, 0, 40, 0, 'Overlord Ror: Enrage (the Deadwood Avengers''; his Terrifying Roar is a fear)');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 19;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(19, 0, 3, 2),
(19, 150, 3, 1),
(19, 330, 3, 1),
(19, 540, 3, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
