DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019430000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019430000');

DELETE FROM `bonk_map` WHERE `id` = 20;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `tier`, `map_type`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`, `damage_growth_per_min`,
    `spawn_min_distance`, `spawn_max_distance`, `gold_per_kill`, `stage_gold`, `coins_per_kill`, `powerup_interval_sec`, `powerup_max`, `icon`) VALUES
(20, 'dunmorogh', 'Dun Morogh', 1, 0, 0, 1, -5305, 75, 386.3, 5.8, 600, 0, 1, 1, 0, 0, 40, 50, 8, 2000, 1, 40, 3, 'Ability_Mount_MechaStrider');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 20;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(20, 1199, 0, 0, 0, 180, 6, 0, 1, 1, 0.9, 1),
(20, 1718, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1),
(20, 1131, 0, 1, 0, 210, 10, 0, 1, 1, 0.85, 1),
(20, 1117, 0, 1, 60, 300, 8, 0, 1, 1, 0.75, 1),
(20, 1120, 0, 1, 120, 360, 7, 0, 1, 1, 0.75, 1),
(20, 1201, 0, 1, 210, 450, 7, 0, 1, 1, 0.85, 1),
(20, 1211, 0, 1, 330, 0, 6, 0, 1, 1, 0.75, 1),
(20, 1122, 0, 1, 420, 0, 6, 0, 1, 1, 0.75, 1),
(20, 6209, 0, 1, 480, 0, 3, 3, 1, 1, 0.75, 1),
(20, 1135, 0, 2, 0, 0, 5, 0, 1, 1, 0.6, 1.3),
(20, 6225, 0, 2, 240, 0, 4, 0, 1, 1, 0.65, 1),
(20, 1124, 0, 3, 150, 330, 3, 3, 1, 1, 0.7, 1),
(20, 1397, 0, 3, 360, 540, 3, 3, 1, 1, 0.7, 1),
(20, 1125, 0, 4, 150, 330, 2, 2, 1, 1, 0.8, 1),
(20, 1127, 0, 4, 420, 0, 2, 2, 1, 1, 0.8, 1),
(20, 1132, 1, 1, 0, 0, 3, 0, 1, 1, 0.85, 1.3),
(20, 1119, 1, 1, 120, 0, 2, 0, 1, 1, 0.75, 1.3),
(20, 1260, 1, 1, 200, 0, 2, 0, 1, 1, 0.75, 1.3),
(20, 1271, 1, 1, 300, 0, 3, 0, 1.3, 1.2, 0.65, 1),
(20, 7800, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(20, 7361, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.3),
(20, 6235, 3, 1, 0, 0, 2, 0, 1, 1, 0.8, 1.2),
(20, 6229, 3, 1, 0, 0, 2, 0, 1, 1, 0.75, 1),
(20, 7079, 3, 1, 0, 0, 1, 0, 1, 1, 0.7, 1);

DELETE FROM `bonk_mob` WHERE `entry` IN (1124, 1397);
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(1124, 1, 20, 'Frostmane Shadowcaster'),
(1397, 1, 20, 'Frostmane Seer');

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (1124, 1397, 1125, 1127, 1132, 1119, 1260, 1271, 7800, 7361, 6235, 6229, 7079);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(1124, 20825, 0, 5000, 1500, 0, 30, 1, 0, 0, 0, 100, 'Frostmane Shadowcaster: Shadow Bolt'),
(1397, 9532, 0, 5000, 1500, 0, 30, 1, 0, 0, 0, 100, 'Frostmane Seer: Lightning Bolt'),
(1125, 6268, 1, 15000, 6000, 6, 30, 0, 0, 0, 0, 100, 'Crag Boar: Rushing Charge'),
(1127, 6268, 1, 15000, 6000, 6, 30, 0, 0, 0, 0, 100, 'Elder Crag Boar: Rushing Charge'),
(1132, 3391, 1, 9000, 4000, 0, 10, 0, 0, 0, 0, 100, 'Timber: Thrash'),
(1132, 6268, 1, 15000, 6000, 6, 30, 0, 0, 0, 0, 100, 'Timber: Rushing Charge'),
(1119, 10101, 0, 9000, 3000, 0, 5, 0, 0, 0, 0, 100, 'Hammerspine: Knock Away'),
(1260, 9672, 0, 4000, 1500, 0, 30, 1, 0, 0, 0, 100, 'Great Father Arctikus: Frostbolt'),
(1271, 5568, 1, 8000, 3000, 0, 8, 0, 0, 0, 0, 100, 'Old Icebeard: Trample'),
(7800, 10101, 0, 9000, 4000, 0, 5, 0, 0, 0, 0, 100, 'Mekgineer Thermaplugg: Knock Away'),
(7800, 11518, 0, 9000, 6000, 0, 40, 1, 3, 5, 5, 66, 'Mekgineer Thermaplugg: bombs from 66%, 5 circles round the hero'),
(7800, 11638, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 50, 'Mekgineer Thermaplugg: radiation pools from 50%'),
(7800, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 100, 'Mekgineer Thermaplugg: pounder stomp, 3 red lines fanned toward the hero, then a knockback wave'),
(7361, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 6, 100, 'Grubbis: leaps onto the hero (red circle where they stand, then the landing)'),
(7361, 15496, 0, 6000, 3000, 0, 7, 1.5, 1, 0, 8, 100, 'Grubbis: Cleave, a cone at the hero'),
(7361, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Grubbis: slam, a red line toward the hero, then a knockback wave'),
(6235, 11082, 1, 9000, 3000, 0, 8, 1.2, 2, 0, 8, 100, 'Electrocutioner 6000: Megavolt, a ring round him (safe up close)'),
(6235, 11085, 0, 9000, 5000, 0, 40, 1, 3, 3, 4, 100, 'Electrocutioner 6000: Chain Bolt, 3 circles round the hero'),
(6235, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Electrocutioner 6000: discharge, a red line toward the hero, then a knockback wave'),
(6229, 5568, 1, 10000, 5000, 0, 10, 1.2, 2, 0, 10, 100, 'Crowd Pummeler 9-60: Trample, a ring round it (safe up close)'),
(6229, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 6, 100, 'Crowd Pummeler 9-60: leaps onto the hero (red circle where they stand, then the landing)'),
(6229, 8374, 0, 7000, 3000, 0, 8, 1.5, 1, 0, 9, 100, 'Crowd Pummeler 9-60: Arcing Smash, a cone at the hero'),
(7079, 9459, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Viscous Fallout: Corrosive Ooze pools'),
(7079, 21687, 0, 9000, 4000, 0, 40, 1, 3, 4, 4, 100, 'Viscous Fallout: Toxic Volley, 4 circles round the hero'),
(7079, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Viscous Fallout: slime wave, a red line toward the hero, then a knockback wave');

DELETE FROM `bonk_map_event` WHERE `bonk_map_id` = 20;
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(20, 0, 3, 2),
(20, 150, 3, 1),
(20, 330, 3, 1),
(20, 540, 3, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
