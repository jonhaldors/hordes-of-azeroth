DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016280000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016280000');

DELETE FROM `bonk_map` WHERE `id` = 14;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(14, 'burningsteppes', 'Burning Steppes', 2, 0, 0, 46, -7781.5, -2912.5, 132.5, 1.7, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'INV_Misc_Head_Dragon_Black');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 14;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(14, 7047, 0, 0, 0, 210, 7, 0, 1, 1, 0.9, 1),
(14, 7048, 0, 0, 180, 420, 5, 0, 1, 1, 0.9, 1),
(14, 9777, 0, 0, 390, 0, 4, 0, 1, 1, 0.95, 1),
(14, 9690, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(14, 7025, 0, 1, 60, 270, 8, 0, 1, 1, 0.75, 1),
(14, 7038, 0, 1, 120, 360, 7, 0, 1, 1, 0.8, 1),
(14, 7027, 0, 1, 210, 450, 7, 0, 1, 1, 0.8, 1),
(14, 7031, 0, 1, 270, 510, 6, 0, 1, 1, 0.7, 1),
(14, 7037, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(14, 7029, 0, 1, 420, 0, 5, 0, 1, 1, 0.8, 1),
(14, 7033, 0, 2, 0, 0, 6, 0, 1, 1, 0.7, 1),
(14, 7039, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(14, 7026, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(14, 7028, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(14, 9697, 0, 4, 420, 0, 2, 2, 1, 1, 0.85, 1),
(14, 7040, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(14, 7041, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(14, 9819, 1, 1, 200, 0, 2, 0, 1, 1, 0.8, 1.2),
(14, 7042, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.7, 1.2),
(14, 9019, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(14, 10363, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(14, 9196, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(14, 9237, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(14, 9568, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(14, 9017, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (7026, 7028);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(7026, 1, 22, 'Blackrock Sorcerer'),
(7028, 1, 22, 'Blackrock Warlock');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (7026, 7028, 7040, 7041, 9819, 7042, 9019, 10363, 9196, 9237, 9568, 9017);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(7026, 20823, 0, 5000, 1500, 0, 30, 1, 'Blackrock Sorcerer: Fireball'),
(7028, 20825, 0, 5000, 2000, 0, 30, 1, 'Blackrock Warlock: Shadow Bolt'),
(7040, 15663, 0, 7000, 2000, 0, 5, 0, 'Black Dragonspawn: Cleave (its Rend is a DoT)'),
(7041, 14034, 0, 6000, 2000, 0, 30, 1.2, 'Black Wyrmkin: Fireball'),
(7041, 12470, 1, 12000, 5000, 0, 10, 1.5, 'Black Wyrmkin: Fire Nova'),
(9819, 15749, 0, 10000, 2000, 8, 25, 0, 'Blackhand Veteran: Shield Charge'),
(9819, 14516, 0, 6000, 2000, 0, 5, 0, 'Blackhand Veteran: Strike'),
(7042, 13340, 0, 6000, 2000, 0, 20, 1.2, 'Flamescale Dragonspawn: Fire Blast'),
(9019, 15242, 0, 6000, 3000, 0, 35, 1.3, 'Emperor Dagran Thaurissan: Fireball (his Hand of Thaurissan stuns)'),
(9019, 15744, 1, 12000, 6000, 0, 10, 1.5, 'Emperor Dagran Thaurissan: Blast Wave'),
(9019, 15642, 1, 15000, 8000, 0, 5, 0, 'Emperor Dagran Thaurissan: Ironfoe (extra swings)'),
(10363, 15754, 0, 7000, 2000, 0, 5, 0, 'General Drakkisath: Cleave'),
(10363, 15588, 1, 12000, 5000, 0, 10, 1.5, 'General Drakkisath: Thunderclap'),
(10363, 16789, 1, 30000, 15000, 0, 40, 0, 'General Drakkisath: Rage'),
(9196, 18368, 0, 6000, 2000, 0, 5, 0, 'Highlord Omokk: Strike'),
(9196, 11876, 1, 12000, 5000, 0, 5, 0, 'Highlord Omokk: War Stomp (5 yd; his own 24375 reaches 15)'),
(9237, 15708, 0, 8000, 3000, 0, 5, 0, 'War Master Voone: Mortal Strike'),
(9237, 16000, 0, 6000, 2000, 6, 30, 1.2, 'War Master Voone: Throw (his Throw Axe stuns)'),
(9568, 20691, 0, 7000, 2000, 0, 5, 0, 'Overlord Wyrmthalak: Cleave'),
(9568, 11130, 1, 14000, 6000, 0, 10, 0, 'Overlord Wyrmthalak: Knock Away'),
(9017, 14099, 0, 9000, 3000, 0, 5, 0, 'Lord Incendius: Mighty Blow'),
(9017, 16079, 1, 12000, 5000, 0, 10, 1.5, 'Lord Incendius: Fire Nova');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 14;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(14, 0, 3, 2),
(14, 150, 3, 1),
(14, 330, 3, 1),
(14, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 15;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(15, 'easternplaguelands', 'Eastern Plaguelands', 2, 0, 0, 139, 2881, -4168.6, 96.4, 2, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'Spell_Shadow_AbominationExplosion');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 15;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(15, 8600, 0, 0, 0, 210, 7, 0, 1, 1, 0.9, 1),
(15, 8596, 0, 0, 240, 480, 4, 0, 1, 1, 0.95, 1),
(15, 8597, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(15, 8530, 0, 1, 60, 270, 8, 0, 1, 1, 0.8, 1),
(15, 8523, 0, 1, 120, 360, 7, 0, 1, 1, 0.75, 1),
(15, 8547, 0, 1, 210, 450, 7, 0, 1, 1, 0.75, 1),
(15, 8556, 0, 1, 270, 510, 6, 0, 1, 1, 0.75, 1),
(15, 11290, 0, 1, 300, 540, 6, 0, 1, 1, 0.7, 1),
(15, 8540, 0, 1, 420, 0, 5, 0, 1, 1, 0.8, 1),
(15, 1812, 0, 2, 0, 0, 6, 0, 1, 1, 0.65, 1),
(15, 8545, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(15, 8551, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(15, 8526, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(15, 8598, 0, 4, 420, 0, 2, 2, 1, 1, 0.9, 1),
(15, 8529, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(15, 10405, 1, 1, 120, 0, 2, 0, 1, 1, 0.85, 1.2),
(15, 9449, 1, 1, 200, 0, 2, 0, 1, 1, 0.75, 1.2),
(15, 9448, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.7, 1.2),
(15, 10440, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(15, 10813, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(15, 10439, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(15, 10997, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(15, 10438, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(15, 10435, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (8551, 8526);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(8551, 1, 22, 'Dark Summoner'),
(8526, 1, 22, 'Dark Caster');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (8551, 8526, 8529, 10405, 9449, 9448, 10440, 10813, 10439, 10997, 10438, 10435);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(8551, 20829, 0, 5000, 1500, 0, 30, 1, 'Dark Summoner: Arcane Bolt'),
(8526, 20825, 0, 5000, 2000, 0, 30, 1, 'Dark Caster: Shadow Bolt'),
(8529, 13737, 0, 8000, 2000, 0, 5, 0, 'Scourge Champion: Mortal Strike'),
(10405, 15613, 0, 7000, 2000, 0, 5, 0, 'Plague Ghoul: Cleave'),
(10405, 8599, 1, 25000, 10000, 0, 40, 0, 'Plague Ghoul: Enrage'),
(9449, 15587, 0, 6000, 2000, 0, 30, 1.2, 'Scarlet Cleric: Mind Blast'),
(9449, 15586, 1, 15000, 8000, 0, 40, 0, 'Scarlet Cleric: Heal'),
(9448, 17143, 0, 7000, 2000, 0, 5, 0, 'Scarlet Praetorian: Holy Strike'),
(9448, 17149, 0, 8000, 3000, 0, 30, 1.2, 'Scarlet Praetorian: Exorcism'),
(10440, 17393, 0, 6000, 3000, 0, 35, 1.3, 'Baron Rivendare: Shadow Bolt'),
(10440, 15708, 0, 8000, 3000, 0, 5, 0, 'Baron Rivendare: Mortal Strike'),
(10440, 15754, 0, 7000, 2000, 0, 5, 0, 'Baron Rivendare: Cleave'),
(10813, 17287, 0, 6000, 2000, 0, 30, 1.4, 'Balnazzar: Mind Blast'),
(10813, 1112, 1, 14000, 6000, 0, 8, 1.5, 'Balnazzar: Shadow Nova II (his Psychic Scream is a fear; his Shadow Shock reaches 15)'),
(10439, 5568, 1, 10000, 4000, 0, 10, 0, 'Ramstein the Gorger: Trample'),
(10439, 8269, 1, 30000, 12000, 0, 40, 0, 'Ramstein the Gorger: Enrage (his Knockout stuns)'),
(10997, 20463, 0, 4000, 1500, 6, 30, 1, 'Cannon Master Willey: Shoot'),
(10997, 10101, 0, 10000, 4000, 0, 5, 0, 'Cannon Master Willey: Knock Away'),
(10438, 17503, 0, 5000, 2000, 0, 30, 1.3, 'Maleki the Pallid: Frostbolt'),
(10438, 14907, 1, 14000, 6000, 0, 10, 1, 'Maleki the Pallid: Frost Nova (The Unforgiven''s; his Ice Tomb stuns)'),
(10435, 10887, 1, 12000, 5000, 0, 10, 0, 'Magistrate Barthilas: Crowd Pummel'),
(10435, 14099, 0, 9000, 3000, 0, 5, 0, 'Magistrate Barthilas: Mighty Blow');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 15;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(15, 0, 3, 2),
(15, 150, 3, 1),
(15, 330, 3, 1),
(15, 540, 3, 1);

DELETE FROM `bonk_map` WHERE `id` = 16;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(16, 'westernplaguelands', 'Western Plaguelands', 2, 0, 0, 28, 1900, -2300, 60.1, 0, 600, 1, 1, 1, 0, 0, 40, 50, 25, 10000, 1, 40, 3, 'INV_Misc_Bone_HumanSkull_01');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 16;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(16, 10441, 0, 0, 0, 210, 7, 0, 1, 1, 0.95, 1),
(16, 8603, 0, 0, 240, 480, 4, 0, 1, 1, 0.85, 1),
(16, 1783, 0, 1, 0, 210, 10, 0, 1, 1, 0.8, 1),
(16, 1884, 0, 1, 60, 270, 8, 0, 1, 1, 0.75, 1),
(16, 1791, 0, 1, 120, 360, 7, 0, 1, 1, 0.85, 1),
(16, 1883, 0, 1, 210, 450, 7, 0, 1, 1, 0.75, 1),
(16, 1821, 0, 1, 270, 510, 6, 0, 1, 1, 0.85, 1),
(16, 1833, 0, 1, 300, 540, 6, 0, 1, 1, 0.75, 1),
(16, 1793, 0, 1, 420, 0, 5, 0, 1, 1, 0.8, 1),
(16, 1824, 0, 2, 0, 0, 6, 0, 1, 1, 0.7, 1),
(16, 1816, 0, 2, 0, 0, 4, 0, 1, 1, 0.65, 1),
(16, 1784, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(16, 1826, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(16, 1817, 0, 4, 420, 0, 2, 2, 1, 1, 0.9, 1),
(16, 1834, 1, 1, 0, 0, 3, 0, 1, 1, 0.75, 1.2),
(16, 11076, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.2),
(16, 1832, 1, 1, 200, 0, 2, 0, 1, 1, 0.75, 1.2),
(16, 1805, 1, 1, 300, 0, 2, 0, 1.2, 1.2, 0.65, 1.2),
(16, 1853, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(16, 11622, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(16, 10508, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(16, 10507, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(16, 10506, 3, 1, 0, 0, 2, 0, 1, 1, 0.85, 1.3);

DELETE FROM `bonk_mob` WHERE `entry` IN (1784, 1826);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(1784, 1, 22, 'Skeletal Sorcerer'),
(1826, 1, 22, 'Scarlet Mage');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (1784, 1826, 1834, 11076, 1832, 1805, 1853, 11622, 10508, 10507, 10506);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(1784, 9672, 0, 5000, 1500, 0, 30, 1, 'Skeletal Sorcerer: Frostbolt'),
(1826, 20823, 0, 5000, 2000, 0, 30, 1, 'Scarlet Mage: Fireball'),
(1834, 17143, 0, 7000, 2000, 0, 5, 0, 'Scarlet Paladin: Holy Strike'),
(1834, 15493, 1, 18000, 8000, 0, 40, 0, 'Scarlet Paladin: Holy Light'),
(11076, 12471, 0, 5000, 2000, 0, 30, 1.2, 'Cauldron Lord Razarch: Shadow Bolt'),
(1832, 14034, 0, 6000, 2000, 0, 30, 1.2, 'Scarlet Magus: Fireball'),
(1832, 15744, 1, 12000, 5000, 0, 10, 1.5, 'Scarlet Magus: Blast Wave'),
(1805, 10966, 0, 9000, 3000, 0, 5, 0, 'Flesh Golem: Uppercut'),
(1853, 12739, 0, 5000, 2000, 0, 35, 1.3, 'Darkmaster Gandling: Shadow Bolt'),
(1853, 17234, 0, 9000, 4000, 0, 20, 1, 'Darkmaster Gandling: Shadow Shock'),
(1853, 16431, 1, 30000, 10000, 0, 40, 0, 'Darkmaster Gandling: Bone Armor (his Shadow Shield hurts melee attackers)'),
(11622, 18368, 0, 6000, 2000, 0, 5, 0, 'Rattlegore: Strike'),
(11622, 16727, 1, 12000, 5000, 0, 5, 0, 'Rattlegore: War Stomp'),
(10508, 21369, 0, 5000, 2000, 0, 30, 1.3, 'Ras Frostwhisper: Frostbolt'),
(10508, 18099, 1, 14000, 6000, 0, 10, 1.2, 'Ras Frostwhisper: Chill Nova'),
(10507, 15550, 1, 10000, 4000, 0, 10, 0, 'The Ravenian: Trample'),
(10507, 20691, 0, 7000, 2000, 0, 5, 0, 'The Ravenian: Cleave'),
(10506, 12739, 0, 5000, 2000, 0, 30, 1.2, 'Kirtonos the Herald: Shadow Bolt (his Shadow Bolt Volley reaches 30)'),
(10506, 6016, 0, 8000, 3000, 0, 5, 0, 'Kirtonos the Herald: Pierce Armor');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 16;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(16, 0, 3, 2),
(16, 150, 3, 1),
(16, 330, 3, 1),
(16, 540, 3, 1);

UPDATE `bonk_map` SET `tier` = 0 WHERE `id` IN (2, 5, 6);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
