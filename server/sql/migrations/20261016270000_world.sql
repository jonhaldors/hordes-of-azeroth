DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016270000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016270000');

DELETE FROM `bonk_map` WHERE `id` = 10;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(10, 'desolace', 'Desolace', 3, 0, 1, 405, -715, 1840, 93, 0, 600, 1, 1, 1, 0, 0, 40, 50, 15, 5000, 1, 40, 3, 'Ability_Hunter_Pet_Scorpid');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 10;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(10, 4696, 0, 0, 0, 180, 7, 0, 1, 1, 0.85, 1),
(10, 12222, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(10, 4689, 0, 0, 360, 0, 5, 0, 1, 1, 0.9, 1),
(10, 4634, 0, 1, 0, 210, 10, 0, 1, 1, 0.75, 1),
(10, 4670, 0, 1, 60, 270, 8, 0, 1, 1, 0.8, 1),
(10, 4646, 0, 1, 120, 360, 8, 0, 1, 1, 0.85, 1),
(10, 4693, 0, 1, 210, 450, 7, 0, 1, 1, 0.9, 1),
(10, 11577, 0, 1, 270, 510, 6, 0, 1, 1, 0.8, 1),
(10, 4654, 0, 1, 300, 540, 6, 0, 1, 1, 0.8, 1),
(10, 4673, 0, 1, 360, 0, 6, 0, 1, 1, 0.8, 1),
(10, 11561, 0, 2, 0, 0, 5, 0, 1, 1, 0.65, 1),
(10, 4714, 0, 2, 0, 0, 4, 0, 1, 1, 0.7, 1),
(10, 4635, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(10, 4684, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(10, 4726, 0, 4, 420, 0, 2, 2, 1, 1, 0.8, 1),
(10, 11687, 1, 1, 0, 0, 3, 0, 1, 1, 0.8, 1.2),
(10, 4680, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(10, 11778, 1, 1, 200, 0, 2, 0, 1, 1, 0.7, 1.2),
(10, 4716, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.7, 1),
(10, 12201, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(10, 12203, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1),
(10, 12236, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.3),
(10, 12258, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1);

DELETE FROM `bonk_mob` WHERE `entry` IN (12222, 4635, 4684);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(12222, 2, 3.5, 'Creeping Sludge: bursts next to the player'),
(4635, 1, 20, 'Kolkar Windchaser'),
(4684, 1, 20, 'Nether Sorceress');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (12222, 4635, 4684, 4726, 11687, 4680, 11778, 4716, 12201, 12203, 12236, 12258);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(12222, 28361, 1, 1000, 0, 0, 10, 2, 'Creeping Sludge: bursts (Disease Cloud)'),
(4635, 9532, 0, 5000, 1500, 0, 30, 1, 'Kolkar Windchaser: Lightning Bolt'),
(4684, 20297, 0, 5000, 1500, 0, 30, 1, 'Nether Sorceress: Frostbolt'),
(4726, 6268, 1, 15000, 6000, 6, 30, 0, 'Raging Thunder Lizard: Rushing Charge'),
(11687, 11976, 0, 7000, 2000, 0, 5, 0, 'Ghostly Marauder: Strike'),
(4680, 15496, 0, 7000, 2000, 0, 5, 0, 'Doomwarder Captain: Cleave (its own Ignite is a DoT)'),
(11778, 10101, 0, 9000, 3000, 0, 5, 0, 'Shadowshard Smasher: Knock Away'),
(4716, 865, 1, 12000, 4000, 0, 8, 1, 'Slitherblade Tidehunter: Frost Nova'),
(4716, 10277, 0, 6000, 2000, 8, 30, 1, 'Slitherblade Tidehunter: Throw'),
(12201, 3391, 1, 12000, 6000, 0, 5, 0, 'Princess Theradras: Thrash'),
(12201, 5568, 1, 10000, 5000, 0, 8, 0, 'Princess Theradras: Trample (her Dust Field reaches 20 yd)'),
(12201, 21832, 0, 7000, 3000, 0, 30, 1.3, 'Princess Theradras: Boulder'),
(12203, 5568, 1, 9000, 3000, 0, 8, 0, 'Landslide: Trample'),
(12203, 18670, 0, 10000, 4000, 0, 5, 0, 'Landslide: Knock Away'),
(12236, 7964, 1, 14000, 6000, 0, 5, 0, 'Lord Vyletongue: Smoke Bomb'),
(12236, 16100, 0, 4000, 1500, 0, 30, 1, 'Lord Vyletongue: Shoot'),
(12258, 3391, 1, 10000, 4000, 0, 5, 0, 'Razorlash: Thrash'),
(12258, 11427, 0, 7000, 2000, 0, 5, 0, 'Razorlash: Cleave');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 10;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(10, 0, 3, 2),
(10, 150, 3, 1),
(10, 330, 3, 1),
(10, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 11;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(11, 'badlands', 'Badlands', 3, 0, 0, 3, -6930, -2885, 244, 0, 600, 1, 1, 1, 0, 0, 40, 50, 15, 5000, 1, 40, 3, 'Ability_Hunter_Pet_Vulture');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 11;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(11, 2725, 0, 0, 0, 180, 7, 0, 1, 1, 0.9, 1),
(11, 2739, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(11, 2727, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(11, 2743, 0, 1, 60, 270, 8, 0, 1, 1, 0.75, 1),
(11, 2731, 0, 1, 120, 360, 8, 0, 1, 1, 0.85, 1),
(11, 4851, 0, 1, 210, 450, 7, 0, 1, 1, 0.75, 1),
(11, 2831, 0, 1, 270, 510, 6, 0, 1, 1, 0.85, 1),
(11, 2893, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(11, 2728, 0, 1, 360, 0, 6, 0, 1, 1, 0.85, 1),
(11, 2717, 0, 2, 0, 0, 5, 0, 1, 1, 0.65, 1),
(11, 2736, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(11, 2892, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(11, 2740, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(11, 2734, 0, 4, 420, 0, 2, 2, 1, 1, 0.8, 1),
(11, 2726, 1, 1, 0, 0, 3, 0, 1, 1, 0.85, 1.2),
(11, 2716, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(11, 2749, 1, 1, 200, 0, 2, 0, 1, 1, 0.7, 1.2),
(11, 2754, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.65, 1.2),
(11, 2748, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(11, 7228, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(11, 4854, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.2),
(11, 7291, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (2739, 2892, 2740);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(2739, 2, 3.5, 'Shadowforge Tunneler: runs in with a blasting charge'),
(2892, 1, 20, 'Stonevault Seer'),
(2740, 1, 20, 'Shadowforge Darkweaver');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (2739, 2892, 2740, 2734, 2726, 2716, 2749, 2754, 2748, 7228, 4854, 7291);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(2739, 3204, 1, 1000, 0, 0, 10, 2, 'Shadowforge Tunneler: Sapper Explode'),
(2892, 9532, 0, 5000, 1500, 0, 30, 1, 'Stonevault Seer: Lightning Bolt'),
(2740, 20825, 0, 5000, 1500, 0, 30, 1, 'Shadowforge Darkweaver: Shadow Bolt'),
(2734, 6268, 1, 15000, 6000, 6, 30, 0, 'Ridge Stalker Patriarch: Rushing Charge'),
(2726, 9053, 0, 6000, 2000, 0, 30, 1, 'Scorched Guardian: Fireball (its Flame Breath is a cone)'),
(2716, 9483, 0, 6000, 2000, 8, 30, 1.2, 'Dustbelcher Wyrmhunter: Boulder'),
(2749, 10101, 0, 9000, 3000, 0, 5, 0, 'Siege Golem: Knock Away'),
(2754, 5568, 1, 8000, 3000, 0, 8, 0, 'Anathemus: Trample'),
(2748, 5568, 1, 10000, 5000, 0, 8, 0, 'Archaedas: Trample (his Ground Tremor reaches 20 yd)'),
(2748, 9483, 0, 7000, 3000, 0, 30, 1.3, 'Archaedas: Boulder'),
(2748, 10101, 0, 12000, 4000, 0, 5, 0, 'Archaedas: Knock Away'),
(7228, 8374, 0, 7000, 2000, 0, 5, 0, 'Ironaya: Arcing Smash'),
(7228, 11876, 1, 12000, 5000, 0, 5, 0, 'Ironaya: War Stomp'),
(4854, 6742, 1, 20000, 6000, 0, 30, 0, 'Grimlok: Bloodlust'),
(4854, 9532, 0, 5000, 2000, 0, 30, 1.2, 'Grimlok: Lightning Bolt'),
(7291, 9053, 0, 5000, 2000, 0, 30, 1.2, 'Galgann Firehammer: Fireball'),
(7291, 11969, 1, 12000, 5000, 0, 8, 1, 'Galgann Firehammer: Fire Nova');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 11;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(11, 0, 3, 2),
(11, 150, 3, 1),
(11, 330, 3, 1),
(11, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 12;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(12, 'arathi', 'Arathi Highlands', 3, 0, 0, 45, -1030, -2380, 50.5, 0, 600, 1, 1, 1, 0, 0, 40, 50, 15, 5000, 1, 40, 3, 'Ability_Hunter_Pet_Spider');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 12;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(12, 2563, 0, 0, 0, 180, 7, 0, 1, 1, 0.85, 1),
(12, 4062, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(12, 2572, 0, 0, 360, 0, 5, 0, 1, 1, 0.9, 1),
(12, 2560, 0, 1, 0, 210, 10, 0, 1, 1, 0.9, 1),
(12, 2586, 0, 1, 60, 270, 8, 0, 1, 1, 0.75, 1),
(12, 2556, 0, 1, 120, 360, 8, 0, 1, 1, 0.75, 1),
(12, 2559, 0, 1, 210, 450, 7, 0, 1, 1, 0.9, 1),
(12, 2565, 0, 1, 270, 510, 6, 0, 1, 1, 0.8, 1),
(12, 2589, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(12, 2760, 0, 1, 360, 0, 6, 0, 1, 1, 0.8, 1),
(12, 2566, 0, 2, 0, 0, 5, 0, 1, 1, 0.7, 1),
(12, 2569, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(12, 2553, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(12, 2591, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(12, 2561, 0, 4, 420, 0, 2, 2, 1, 1, 0.85, 1),
(12, 2762, 1, 1, 0, 0, 3, 0, 1, 1, 0.8, 1.2),
(12, 2779, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(12, 2571, 1, 1, 200, 0, 2, 0, 1, 1, 0.7, 1.2),
(12, 2604, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.65, 1.2),
(12, 2611, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(12, 2606, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.3),
(12, 2609, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(12, 2793, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (4062, 2553, 2591);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(4062, 2, 3.5, 'Dark Iron Bombardier: runs in with a bomb'),
(2553, 1, 20, 'Witherbark Shadowcaster'),
(2591, 1, 20, 'Syndicate Magus');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (4062, 2553, 2591, 2561, 2762, 2779, 2571, 2604, 2611, 2606, 2609, 2793);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(4062, 3204, 1, 1000, 0, 0, 10, 2, 'Dark Iron Bombardier: Sapper Explode'),
(2553, 20816, 0, 5000, 1500, 0, 30, 1, 'Witherbark Shadowcaster: Shadow Bolt'),
(2591, 9672, 0, 5000, 1500, 0, 30, 1, 'Syndicate Magus: Frostbolt'),
(2561, 6268, 1, 15000, 6000, 6, 30, 0, 'Highland Fleshstalker: Rushing Charge'),
(2762, 9532, 0, 6000, 2000, 0, 30, 1, 'Thundering Exile: Lightning Bolt'),
(2779, 10277, 0, 6000, 2000, 8, 30, 1, 'Prince Nazjak: Throw'),
(2779, 15496, 0, 7000, 2000, 0, 5, 0, 'Prince Nazjak: Cleave'),
(2571, 15496, 0, 7000, 2000, 0, 5, 0, 'Boulderfist Lord: Cleave'),
(2604, 10101, 0, 9000, 3000, 0, 5, 0, 'Molok the Crusher: Knock Away (his Backhand only stuns)'),
(2611, 5568, 1, 9000, 4000, 0, 8, 0, 'Fozruk: Trample (his Ground Tremor reaches 20 yd)'),
(2611, 9483, 0, 7000, 3000, 0, 30, 1.3, 'Fozruk: Boulder'),
(2611, 10101, 0, 12000, 5000, 0, 5, 0, 'Fozruk: Knock Away'),
(2606, 13737, 0, 8000, 3000, 0, 5, 0, 'Nimar the Slayer: Mortal Strike (his Execute needs the target under 20%)'),
(2606, 15576, 1, 10000, 4000, 0, 6, 0, 'Nimar the Slayer: Whirlwind (the 8 yd hit of his Whirlwind aura)'),
(2609, 11969, 1, 12000, 5000, 0, 8, 1, 'Geomancer Flintdagger: Fire Nova'),
(2609, 20823, 0, 5000, 2000, 0, 30, 1.2, 'Geomancer Flintdagger: Fireball'),
(2793, 865, 1, 14000, 5000, 0, 8, 1, 'Kor''gresh Coldrage: Frost Nova'),
(2793, 20822, 0, 5000, 2000, 0, 30, 1.2, 'Kor''gresh Coldrage: Frostbolt');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 12;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(12, 0, 3, 2),
(12, 150, 3, 1),
(12, 330, 3, 1),
(12, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 13;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(13, 'swampofsorrows', 'Swamp of Sorrows', 3, 0, 0, 8, -10270, -3150, 23, 0, 600, 1, 1, 1, 0, 0, 40, 50, 15, 5000, 1, 40, 3, 'Ability_Hunter_Pet_Crocolisk');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 13;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(13, 858, 0, 0, 0, 180, 7, 0, 1, 1, 0.85, 1),
(13, 5235, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(13, 1084, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(13, 757, 0, 1, 60, 270, 8, 0, 1, 1, 0.8, 1),
(13, 767, 0, 1, 120, 360, 8, 0, 1, 1, 0.9, 1),
(13, 750, 0, 1, 210, 450, 7, 0, 1, 1, 0.8, 1),
(13, 769, 0, 1, 270, 510, 6, 0, 1, 1, 0.85, 1),
(13, 5263, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(13, 922, 0, 1, 360, 0, 6, 0, 1, 1, 0.75, 1),
(13, 765, 0, 2, 0, 0, 5, 0, 1, 1, 0.65, 1),
(13, 1087, 0, 2, 0, 0, 4, 0, 1, 1, 0.7, 1),
(13, 759, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(13, 5269, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(13, 768, 0, 4, 420, 0, 2, 2, 1, 1, 0.8, 1),
(13, 746, 1, 1, 0, 0, 3, 0, 1, 1, 0.7, 1),
(13, 5399, 1, 1, 120, 0, 2, 0, 1, 1, 0.8, 1.2),
(13, 744, 1, 1, 200, 0, 2, 0, 1, 1, 0.75, 1),
(13, 1081, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.65, 1),
(13, 8443, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(13, 8580, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1),
(13, 5709, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.3),
(13, 5715, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (5235, 759, 5269);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(5235, 2, 3.5, 'Fungal Ooze: bursts next to the player'),
(759, 1, 22, 'Lost One Hunter'),
(5269, 1, 20, 'Atal''ai Priest');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (5235, 759, 5269, 768, 746, 5399, 744, 1081, 8443, 8580, 5709, 5715);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(5235, 28361, 1, 1000, 0, 0, 10, 2, 'Fungal Ooze: bursts (Disease Cloud)'),
(759, 6660, 0, 3000, 1000, 0, 30, 0.8, 'Lost One Hunter: Shoot'),
(5269, 9613, 0, 5000, 1500, 0, 30, 1, 'Atal''ai Priest: Shadow Bolt'),
(768, 6268, 1, 15000, 6000, 6, 30, 0, 'Shadow Panther: Rushing Charge'),
(746, 15496, 0, 7000, 2000, 0, 5, 0, 'Elder Dragonkin: Cleave (its Acid Splash leaves damage over time)'),
(5399, 8599, 1, 20000, 8000, 0, 30, 0, 'Veyzhak the Cannibal: Enrage'),
(5399, 15496, 0, 7000, 2000, 0, 5, 0, 'Veyzhak the Cannibal: Cleave'),
(744, 15496, 0, 7000, 2000, 0, 5, 0, 'Green Scalebane: Cleave'),
(1081, 9616, 1, 20000, 8000, 0, 30, 0, 'Mire Lord: Wild Regeneration'),
(8443, 12354, 1, 10000, 5000, 0, 8, 1.5, 'Avatar of Hakkar: Flame of Hakkar'),
(8443, 27806, 0, 6000, 3000, 0, 30, 1.3, 'Avatar of Hakkar: Venom Spit (his own Lash and Cause Insanity cannot be dodged)'),
(8580, 5568, 1, 10000, 5000, 0, 8, 0, 'Atal''alarion: Trample (his Ground Tremor reaches 20 yd)'),
(8580, 12887, 0, 8000, 3000, 0, 5, 0, 'Atal''alarion: Sweeping Slam'),
(5709, 3391, 1, 10000, 3000, 0, 5, 0, 'Shade of Eranikus: Thrash'),
(5709, 11876, 1, 12000, 4000, 0, 5, 0, 'Shade of Eranikus: War Stomp'),
(5715, 1112, 1, 12000, 5000, 0, 8, 1, 'Hukku: Shadow Nova II (his Shadow Bolt Volley reaches 30 yd)'),
(5715, 12471, 0, 5000, 2000, 0, 30, 1.2, 'Hukku: Shadow Bolt');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 13;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(13, 0, 3, 2),
(13, 150, 3, 1),
(13, 330, 3, 1),
(13, 540, 3, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
