DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011236000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011236000');

DELETE FROM `bonk_map` WHERE `id` BETWEEN 7 AND 9;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `icon`, `tier`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_interval_ms`, `spawn_batch`, `spawn_batch_growth_per_min`, `max_alive`, `spawn_min_distance`, `spawn_max_distance`,
    `elite_interval_sec`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`) VALUES
(7, 'tanaris',      'Tanaris',             'Ability_Hunter_Pet_Hyena',   3, 1, 440,  -9315.0, -2998.0,   10.6, 0.00, 600, 1, 1.3, 0.35, 0.20, 0.07, 1800, 2.5, 1.0, 85, 40, 50, 75, 15, 5000, 1, 40, 3),
(8, 'ungoro',       'Un''Goro Crater',     'Ability_Hunter_Pet_Raptor',  3, 1, 490,  -7913.0, -1606.0, -270.9, 0.00, 600, 1, 1.3, 0.35, 0.20, 0.07, 1800, 2.5, 1.0, 85, 38, 48, 75, 15, 5000, 1, 40, 3),
(9, 'stranglethorn', 'Stranglethorn Vale', 'Ability_Hunter_Pet_Gorilla', 3, 0,  33, -12702.0,  -440.0,   32.5, 0.00, 600, 1, 1.3, 0.35, 0.20, 0.07, 1800, 2.5, 1.0, 85, 34, 44, 75, 15, 5000, 1, 40, 3);

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` BETWEEN 7 AND 9;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(7,  5425, 0,   0, 210, 10, 0, 1.0, 1.0, 0.80, 1.0),
(7,  5423, 0,   0, 180,  7, 0, 0.7, 0.9, 0.85, 1.0),
(7,  5616, 0,  60, 270,  8, 0, 1.0, 1.0, 0.75, 1.0),
(7,  5441, 0, 120, 360,  7, 0, 0.7, 0.9, 0.90, 0.7),
(7,  5617, 0, 150, 330,  3, 3, 0.8, 1.0, 0.70, 1.0),
(7,  5615, 0, 210, 450,  7, 0, 1.0, 1.1, 0.80, 1.0),
(7,  7857, 0, 240, 480,  3, 3, 0.5, 1.0, 0.95, 1.0),
(7,  5426, 0, 270, 510,  6, 0, 1.1, 1.1, 0.85, 1.0),
(7,  5419, 0, 300, 540,  6, 0, 1.3, 1.1, 0.70, 0.9),
(7,  7856, 0, 360, 540,  3, 3, 0.8, 1.0, 0.70, 1.0),
(7,  5471, 0, 360,   0,  6, 0, 1.4, 1.2, 0.70, 1.0),
(7,  5424, 0, 420,   0,  5, 0, 1.3, 1.2, 0.80, 1.0),
(7,  5427, 0, 420,   0,  2, 2, 1.2, 1.0, 0.80, 1.0),
(7,  5472, 0, 480,   0,  4, 0, 2.0, 1.4, 0.65, 1.0),
(7,  5432, 1,   0,   0,  3, 0, 1.0, 1.0, 0.70, 0.8),
(7,  5645, 1, 120,   0,  2, 0, 1.0, 1.0, 0.75, 1.2),
(7,  5429, 1, 200,   0,  2, 0, 1.0, 1.0, 0.85, 1.0),
(7,  5469, 1, 300,   0,  2, 0, 1.2, 1.2, 0.65, 0.6),
(7,  8127, 3,   0,   0,  2, 0, 1.0, 1.0, 0.80, 1.3),
(7,  7271, 3,   0,   0,  2, 0, 1.0, 1.0, 0.80, 1.3),
(7,  7795, 3,   0,   0,  2, 0, 1.0, 1.0, 0.80, 1.3),
(7,  7273, 2,   0,   0,  1, 0, 1.0, 1.0, 0.85, 0.7),

(8,  6509, 0,   0, 210, 10, 0, 1.0, 1.0, 0.75, 1.0),
(8,  9162, 0,   0, 180,  7, 0, 0.8, 0.9, 0.85, 1.0),
(8,  6556, 0,  60, 270,  8, 0, 1.0, 1.0, 0.70, 1.0),
(8,  6505, 0, 120, 360,  8, 0, 0.9, 1.0, 0.90, 1.0),
(8,  6520, 0, 150, 330,  3, 3, 0.8, 1.0, 0.70, 0.9),
(8,  6551, 0, 210, 450,  7, 0, 0.9, 1.0, 0.90, 0.8),
(8,  6557, 0, 240, 480,  3, 3, 0.5, 1.0, 0.95, 1.0),
(8,  9166, 0, 270, 510,  6, 0, 1.0, 1.1, 0.85, 0.8),
(8,  6510, 0, 300, 540,  6, 0, 1.2, 1.1, 0.75, 1.0),
(8,  6512, 0, 360, 540,  3, 3, 0.8, 1.0, 0.70, 1.0),
(8,  9164, 0, 360,   0,  6, 0, 1.4, 1.2, 0.80, 1.0),
(8,  6517, 0, 420,   0,  5, 0, 1.5, 1.2, 0.70, 1.0),
(8,  6513, 0, 420,   0,  2, 2, 1.3, 1.1, 0.80, 0.9),
(8,  6553, 0, 480,   0,  4, 0, 1.8, 1.4, 0.70, 0.9),
(8,  6502, 1,   0,   0,  3, 0, 1.0, 1.0, 0.70, 0.7),
(8,  9376, 1, 150,   0,  2, 0, 1.0, 1.0, 0.80, 1.0),
(8,  6503, 1, 250,   0,  2, 0, 1.0, 1.0, 0.70, 0.7),
(8,  6498, 1, 350,   0,  2, 0, 1.2, 1.2, 0.80, 0.5),
(8,  6581, 3,   0,   0,  2, 0, 1.0, 1.0, 0.85, 1.3),
(8,  6583, 3,   0,   0,  2, 0, 1.0, 1.0, 0.80, 0.6),
(8,  9622, 3,   0,   0,  2, 0, 1.0, 1.0, 0.80, 1.2),
(8,  6584, 2,   0,   0,  1, 0, 1.0, 1.0, 0.85, 0.6),

(9,   681, 0,   0, 210, 10, 0, 0.8, 0.9, 0.85, 1.0),
(9,   683, 0,   0, 180,  7, 0, 0.7, 0.9, 0.90, 1.0),
(9,   937, 0,  60, 270,  8, 0, 1.0, 1.0, 0.70, 1.0),
(9,   686, 0, 120, 360,  8, 0, 0.9, 1.0, 0.90, 1.0),
(9,   588, 0, 150, 330,  3, 3, 0.8, 1.0, 0.70, 1.0),
(9,   597, 0, 210, 450,  7, 0, 1.1, 1.1, 0.80, 1.0),
(9,  1488, 0, 240, 480,  3, 3, 0.5, 1.0, 0.95, 1.0),
(9,  1108, 0, 270, 510,  6, 0, 1.2, 1.1, 0.75, 1.0),
(9,   684, 0, 300, 540,  6, 0, 1.1, 1.1, 0.85, 1.0),
(9,   669, 0, 360, 540,  3, 3, 0.8, 1.0, 0.70, 1.0),
(9,   667, 0, 360,   0,  6, 0, 1.3, 1.2, 0.75, 1.0),
(9,  1142, 0, 420,   0,  5, 0, 1.6, 1.3, 0.70, 1.0),
(9,  1114, 0, 420,   0,  2, 2, 1.3, 1.1, 0.80, 1.0),
(9,  1558, 0, 480,   0,  4, 0, 2.0, 1.4, 0.70, 1.0),
(9,   709, 1,   0,   0,  3, 0, 1.0, 1.0, 0.75, 1.2),
(9,  1713, 1, 120,   0,  2, 0, 1.0, 1.0, 0.85, 1.3),
(9,   679, 1, 200,   0,  2, 0, 1.0, 1.0, 0.75, 1.2),
(9,   678, 1, 300,   0,  2, 0, 1.2, 1.2, 0.75, 1.2),
(9,   731, 3,   0,   0,  2, 0, 1.0, 1.0, 0.85, 1.4),
(9,   728, 3,   0,   0,  2, 0, 1.0, 1.0, 0.85, 1.4),
(9,   730, 3,   0,   0,  2, 0, 1.0, 1.0, 0.85, 1.4),
(9,   680, 2,   0,   0,  1, 0, 1.0, 1.0, 0.85, 1.6);

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` BETWEEN 7 AND 9;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(7,   0, 3,  2), (7, 100, 5, 20), (7, 150, 3,  1), (7, 200, 2, 24), (7, 270, 4, 20), (7, 300, 0,  1),
(7, 330, 3,  1), (7, 360, 2, 28), (7, 420, 1,  2), (7, 450, 5, 28), (7, 510, 4, 26), (7, 540, 3,  1),
(8,   0, 3,  2), (8, 120, 4, 18), (8, 150, 3,  1), (8, 180, 2, 24), (8, 240, 5, 22), (8, 300, 0,  1),
(8, 330, 3,  1), (8, 380, 4, 24), (8, 420, 1,  2), (8, 470, 2, 32), (8, 520, 5, 28), (8, 540, 3,  1),
(9,   0, 3,  2), (9,  90, 5, 18), (9, 150, 3,  1), (9, 180, 4, 18), (9, 240, 2, 24), (9, 300, 0,  1),
(9, 330, 3,  1), (9, 390, 5, 26), (9, 420, 1,  2), (9, 470, 4, 24), (9, 510, 2, 32), (9, 540, 3,  1);

DELETE FROM `bonk_mob` WHERE `entry` IN (5617, 7856, 7857, 6520, 6512, 6557, 588, 669, 1488);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(  5617, 1, 20,  'Wastewander Shadow Mage'),
(  7856, 1, 22,  'Southsea Freebooter'),
(  7857, 2, 3.5, 'Southsea Dock Worker: runs in with a powder keg'),
(  6520, 1, 20,  'Scorching Elemental'),
(  6512, 1, 20,  'Bloodpetal Trapper'),
(  6557, 2, 3.5, 'Primal Ooze: bursts next to the player'),
(   588, 1, 22,  'Bloodscalp Scout'),
(   669, 1, 22,  'Skullsplitter Hunter'),
(  1488, 2, 3.5, 'Zanzil Zombie: bursts next to the player');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (5617, 7856, 7857, 5427, 5429, 5469, 5645, 8127, 7271, 7795, 7273,
    6520, 6512, 6557, 6513, 6505, 6553, 6502, 6498, 9376, 6581, 6583, 9622, 6584,
    588, 669, 1488, 1114, 709, 679, 678, 1713, 731, 728, 730, 680);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(  5617, 20825, 0,  5000,  1500, 0,  30, 1.0, 'Wastewander Shadow Mage: Shadow Bolt'),
(  7856,  6660, 0,  3000,  1000, 0,  30, 0.8, 'Southsea Freebooter: Shoot'),
(  7857,  3204, 1,  1000,     0, 0,  10, 2.0, 'Southsea Dock Worker: Sapper Explode'),
(  5427,  6268, 1, 12000,  3000, 6,  30, 0,   'Rabid Blisterpaw: Rushing Charge'),
(  5429, 11021, 0,  6000,  2000, 0,  30, 1.0, 'Fire Roc: Flamespit'),
(  5469,  5568, 1,  8000,  3000, 0,   8, 0,   'Dune Smasher: Trample'),
(  5645, 15496, 0,  7000,  2000, 0,   5, 0,   'Sandfury Hideskinner: Cleave'),
(  8127, 10413, 0,  7000,  2000, 0,  20, 1.2, 'Antu''sul: Earth Shock'),
(  8127, 20602, 1, 12000,  5000, 0,  10, 1.0, 'Antu''sul: Fire Nova'),
(  7271, 12739, 0,  5000,  2000, 0,  30, 1.2, 'Witch Doctor Zum''rah: Shadow Bolt'),
(  7271, 15245, 1, 14000,  6000, 0,  30, 0.8, 'Witch Doctor Zum''rah: Shadow Bolt Volley'),
(  7795, 20792, 0,  5000,  2000, 0,  30, 1.2, 'Hydromancer Velratha: Frostbolt'),
(  7795, 15245, 1, 14000,  6000, 0,  30, 0.8, 'Hydromancer Velratha: Shadow Bolt Volley'),
(  7273, 11902, 1, 10000,  4000, 0,  10, 0,   'Gahz''rilla: Gahz''rilla Slam'),
(  7273, 11131, 0,  7000,  3000, 0,  40, 1.2, 'Gahz''rilla: Icicle'),
(  6520, 13878, 0,  4000,  1500, 0,  30, 1.0, 'Scorching Elemental: Scorch'),
(  6512, 11922, 0,  8000,  2000, 0,  30, 0.4, 'Bloodpetal Trapper: Entangling Roots (per tick; the root itself has no hold in a run)'),
(  6557, 28361, 1,  1000,     0, 0,  10, 2.0, 'Primal Ooze: bursts (Disease Cloud)'),
(  6513,  6268, 1, 12000,  3000, 6,  30, 0,   'Un''Goro Stomper: Rushing Charge'),
(  6505, 13443, 0, 12000,  2000, 0,   5, 0.3, 'Ravasaur: Rend (per tick)'),
(  6553, 11427, 0,  7000,  2000, 0,   5, 0,   'Gorishi Reaver: Cleave'),
(  6502,  5568, 1,  8000,  3000, 0,   8, 0,   'Plated Stegodon: Trample'),
(  6498, 14099, 0,  8000,  3000, 0,   5, 0,   'Devilsaur: Mighty Blow'),
(  9376, 17277, 1, 10000,  3000, 0,  10, 1.0, 'Blazerunner: Blast Wave'),
(  6581,  6268, 1, 10000,  2000, 6,  30, 0,   'Ravasaur Matriarch: Rushing Charge'),
(  6581, 13445, 0, 12000,  3000, 0,   5, 0.4, 'Ravasaur Matriarch: Rend (per tick)'),
(  6583, 15548, 1, 10000,  4000, 0,   8, 1.0, 'Gruff: Thunderclap'),
(  6583, 15549, 0,  7000,  2000, 0,  30, 1.2, 'Gruff: Chained Bolt'),
(  9622,  8374, 0,  7000,  2000, 0,   5, 0,   'U''cha: Arcing Smash'),
(  6584, 15550, 1,  9000,  3000, 0,   8, 0,   'King Mosh: Trample'),
(  6584, 14331, 0, 12000,  4000, 0,   5, 0.5, 'King Mosh: Vicious Rend (per tick)'),
(  6584, 22911, 0, 12000,  5000, 8,  25, 0,   'King Mosh: Charge'),
(   588,  6660, 0,  3000,  1000, 0,  30, 0.8, 'Bloodscalp Scout: Shoot'),
(   669,  6660, 0,  3000,  1000, 0,  30, 0.9, 'Skullsplitter Hunter: Shoot'),
(  1488, 28361, 1,  1000,     0, 0,  10, 2.0, 'Zanzil Zombie: bursts (Disease Cloud)'),
(  1114,  6268, 1, 12000,  3000, 6,  30, 0,   'Jungle Thunderer: Rushing Charge'),
(   709,  8147, 1, 10000,  3000, 0,   8, 1.0, 'Mosh''Ogg Warmonger: Thunderclap'),
(   679, 12058, 0,  6000,  2000, 0,  30, 1.2, 'Mosh''Ogg Shaman: Chain Lightning'),
(   678, 15496, 0,  7000,  2000, 0,   5, 0,   'Mosh''Ogg Mauler: Cleave'),
(  1713,  6268, 1, 10000,  2000, 6,  30, 0,   'Elder Shadowmaw Panther: Rushing Charge'),
(   731,  6268, 1, 10000,  2000, 6,  30, 0,   'King Bangalash: Rushing Charge'),
(   731, 13443, 0, 12000,  3000, 0,   5, 0.4, 'King Bangalash: Rend (per tick)'),
(   728,  3147, 0, 12000,  3000, 0,   5, 0.4, 'Bhag''thera: Rend Flesh (per tick)'),
(   730,  6268, 1, 10000,  2000, 6,  30, 0,   'Tethis: Rushing Charge'),
(   680,  8147, 1, 10000,  4000, 0,   8, 1.2, 'Mosh''Ogg Lord: Thunderclap'),
(   680, 22911, 0, 12000,  5000, 8,  25, 0,   'Mosh''Ogg Lord: Charge');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
