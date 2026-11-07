DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019480000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019480000');

DELETE FROM `bonk_map_creature` WHERE `kind` = 2 AND `entry` IN (1763, 642, 11988, 12056, 4422, 3654, 1200, 314, 14509, 11382, 15205, 7267, 10041, 1061, 12225, 13596, 7206, 7023, 2779, 5710, 5719, 10503, 11261, 6228);
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(1, 1763, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(1, 642, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.2),
(2, 11988, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(2, 12056, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(3, 4422, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(3, 3654, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.3),
(4, 1200, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(4, 314, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(5, 14509, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(5, 11382, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(6, 15205, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(7, 7267, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(8, 10041, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(9, 1061, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(10, 12225, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.3),
(10, 13596, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(11, 7206, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(11, 7023, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(12, 2779, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(13, 5710, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(13, 5719, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1),
(16, 10503, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(16, 11261, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5),
(20, 6228, 2, 1, 0, 0, 1, 0, 1, 1, 0.85, 1.5);

DELETE FROM `bonk_mob_ability` WHERE `entry` IN (1763, 642, 11988, 12056, 4422, 3654, 1200, 314, 14509, 11382, 15205, 7267, 10041, 1061, 12225, 13596, 7206, 7023, 2779, 5710, 5719, 10503, 11261, 6228);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(1763, 19272, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Gilnid: Molten Metal, a ladle of slag, a cone 10 yd in front of him'),
(1763, 15636, 1, 11000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Gilnid: Smelting Blast, a ring 12 yd round him (safe within 6)'),
(1763, 11518, 0, 10000, 6000, 0, 40, 1.1, 3, 4, 5, 100, 'Gilnid: sparks from the forge, 4 circles (5 yd) round the hero'),
(1763, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Gilnid: slag wave, a red line toward the hero, then a knockback wave'),
(1763, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Gilnid: from 66%, slag pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(642, 15496, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Sneed''s Shredder: saw blades, a cone 10 yd in front of it'),
(642, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Sneed''s Shredder: shredder rush (Charge: a red line, then the dash)'),
(642, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Sneed''s Shredder: Stomp, a shredder footfall, a ring 12 yd round it (safe within 6)'),
(642, 11638, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Sneed''s Shredder: oil slicks, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(642, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 5, 24, 66, 'Sneed''s Shredder: from 66%, whirling saws, 5 red lines all around, one at the hero (+1 per difficulty step)'),
(11988, 18944, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Golemagg the Incinerator: Magma Fist, a cone 10 yd in front of him'),
(11988, 16805, 1, 12000, 5000, 0, 14, 1.6, 2, 0, 14, 100, 'Golemagg the Incinerator: Magma Splash, a ring 14 yd round him (safe within 7)'),
(11988, 19411, 0, 10000, 6000, 0, 40, 1.2, 3, 4, 6, 100, 'Golemagg the Incinerator: Pyroblast, 4 circles (6 yd) round the hero'),
(11988, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Golemagg the Incinerator: giant leap, leaps onto the hero (red circle where they stand, then the landing)'),
(11988, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Golemagg the Incinerator: from 66%, magma pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(12056, 9053, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Baron Geddon: Fireball'),
(12056, 15636, 1, 11000, 5000, 0, 14, 1.6, 2, 0, 14, 100, 'Baron Geddon: Inferno, a ring 14 yd round him (safe within 7)'),
(12056, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 100, 'Baron Geddon: flame lines, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(12056, 19717, 0, 11000, 6000, 0, 40, 1.3, 3, 3, 6.5, 100, 'Baron Geddon: Living Bomb, 3 circles (6.5 yd) round the hero'),
(12056, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 50, 'Baron Geddon: from 50%, burning ground, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(4422, 17257, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'Agathelos the Raging: Tusk Swipe, a cone 9 yd in front of him'),
(4422, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Agathelos the Raging: boar charge (Charge: a red line, then the dash)'),
(4422, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Agathelos the Raging: Rampage, a hoof stomp, a ring 12 yd round him (safe within 6)'),
(4422, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Agathelos the Raging: gore, a red line toward the hero, then a knockback wave'),
(4422, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 50, 'Agathelos the Raging: from 50%, raging leap, leaps onto the hero (red circle where they stand, then the landing)'),
(3654, 9532, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Mutanus the Devourer: Lightning Bolt'),
(3654, 6607, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'Mutanus the Devourer: Devour, a bite, a cone 9 yd in front of him'),
(3654, 11876, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Mutanus the Devourer: Thundercrack, a ring 13 yd round him (safe within 6.5)'),
(3654, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Mutanus the Devourer: nightmare pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(3654, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 66, 'Mutanus the Devourer: from 66%, Naralex''s Nightmare, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(1200, 9613, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Morbent Fel: Shadow Bolt'),
(1200, 17289, 1, 10000, 5000, 0, 14, 1.5, 2, 0, 14, 100, 'Morbent Fel: Unholy Shock, a ring 14 yd round him (safe within 7)'),
(1200, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Morbent Fel: unholy ground, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(1200, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 100, 'Morbent Fel: the dead rise around him (2 of the stage''s enemies)'),
(1200, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 50, 'Morbent Fel: from 50%, death lines, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(314, 9672, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Eliza: Frostbolt'),
(314, 12734, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Eliza: Frost Nova, a ring 13 yd round her (safe within 6.5)'),
(314, 10737, 0, 9000, 6000, 0, 40, 1, 3, 5, 5, 100, 'Eliza: Hail Storm, 5 circles (5 yd) round the hero'),
(314, 16390, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Eliza: Cone of Cold, a cone 10 yd in front of her'),
(314, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 66, 'Eliza: from 66%, frozen grief, 3 red lines fanned toward the hero, then a knockback wave'),
(14509, 17257, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'High Priest Thekal: Tiger Claw, a cone 9 yd in front of him'),
(14509, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'High Priest Thekal: tiger pounce, leaps onto the hero (red circle where they stand, then the landing)'),
(14509, 24688, 1, 10000, 5000, 0, 14, 1.5, 2, 0, 14, 100, 'High Priest Thekal: Blood Siphon of Hethiss, a ring 14 yd round him (safe within 7)'),
(14509, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 100, 'High Priest Thekal: zealot''s fury, 3 red lines fanned toward the hero, then a knockback wave'),
(14509, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 50, 'High Priest Thekal: from 50%, Zealots Lor''Khan and Zath join him (2 of the stage''s enemies)'),
(11382, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Bloodlord Mandokir: raptor charge (Charge: a red line, then the dash)'),
(11382, 15284, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'Bloodlord Mandokir: Cleave, Ohgan''s sweep, a cone 9 yd in front of him'),
(11382, 11876, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Bloodlord Mandokir: Whirlwind, a ring 12 yd round him (safe within 6)'),
(11382, 24328, 0, 9000, 6000, 0, 40, 1.1, 3, 5, 5, 100, 'Bloodlord Mandokir: Threatening Gaze, 5 circles (5 yd) round the hero'),
(11382, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 50, 'Bloodlord Mandokir: from 50%, Mandokir''s fury, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(15205, 9672, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Baron Kazum: Frostbolt'),
(15205, 12734, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Baron Kazum: Tidal Crash, a ring 13 yd round him (safe within 6.5)'),
(15205, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 100, 'Baron Kazum: tidal wave, 3 red lines fanned toward the hero, then a knockback wave'),
(15205, 10737, 0, 9000, 6000, 0, 40, 1, 3, 5, 5, 100, 'Baron Kazum: water spouts, 5 circles (5 yd) round the hero'),
(15205, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Baron Kazum: from 66%, flood pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(7267, 15496, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Chief Ukorz Sandscalp: Cleave, a cone 10 yd in front of him'),
(7267, 11876, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Chief Ukorz Sandscalp: Wide Slash, a ring 12 yd round him (safe within 6)'),
(7267, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Chief Ukorz Sandscalp: troll leap, leaps onto the hero (red circle where they stand, then the landing)'),
(7267, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Chief Ukorz Sandscalp: axe slam, a red line toward the hero, then a knockback wave'),
(7267, 8269, 1, 30000, 1000, 0, 40, 0, 0, 0, 0, 30, 'Chief Ukorz Sandscalp: below 30%, Enrage'),
(10041, 24334, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Gorishi Hive Queen: Acid Spit'),
(10041, 17257, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'Gorishi Hive Queen: Mandible Bite, a cone 9 yd in front of her'),
(10041, 12280, 0, 10000, 6000, 0, 40, 1.1, 3, 4, 5, 100, 'Gorishi Hive Queen: acid splashes, 4 circles (5 yd) round the hero'),
(10041, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 100, 'Gorishi Hive Queen: hive guards burrow up (2 of the stage''s enemies)'),
(10041, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 50, 'Gorishi Hive Queen: from 50%, swarm lines, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(1061, 15496, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Gan''zulah: Cleave, a cone 10 yd in front of him'),
(1061, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Gan''zulah: Bloodscalp charge (Charge: a red line, then the dash)'),
(1061, 4164, 0, 10000, 6000, 0, 40, 1.1, 3, 4, 4.5, 100, 'Gan''zulah: axe throws, 4 circles (4.5 yd) round the hero'),
(1061, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Gan''zulah: headhunter''s leap, leaps onto the hero (red circle where they stand, then the landing)'),
(1061, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 50, 'Gan''zulah: from 50%, blood wave, 3 red lines fanned toward the hero, then a knockback wave'),
(12225, 9532, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Celebras the Cursed: Wrath'),
(12225, 8148, 1, 11000, 7000, 0, 12, 1.5, 2, 0, 12, 100, 'Celebras the Cursed: a ring of thorns, a ring 12 yd round him (safe within 6)'),
(12225, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Celebras the Cursed: Twisted Tranquility, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(12225, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 100, 'Celebras the Cursed: the grove''s guardians answer him (2 of the stage''s enemies)'),
(12225, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 66, 'Celebras the Cursed: from 66%, entangling roots, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(13596, 17257, 0, 7000, 3000, 0, 8, 1.6, 1, 0, 9, 100, 'Rotgrip: Bite, a cone 9 yd in front of him'),
(13596, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Rotgrip: lunge, leaps onto the hero (red circle where they stand, then the landing)'),
(13596, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 1, 30, 100, 'Rotgrip: tail sweep, a red line toward the hero, then a knockback wave'),
(13596, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Rotgrip: Death Roll, a ring 12 yd round him (safe within 6)'),
(13596, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Rotgrip: from 66%, swamp muck, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(7206, 18944, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Ancient Stone Keeper: stone fist, a cone 10 yd in front of it'),
(7206, 6524, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Ancient Stone Keeper: Ground Tremor, a ring 13 yd round it (safe within 6.5)'),
(7206, 21071, 0, 10000, 6000, 0, 40, 1.1, 3, 4, 6, 100, 'Ancient Stone Keeper: falling stones, 4 circles (6 yd) round the hero'),
(7206, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Ancient Stone Keeper: stone crash, leaps onto the hero (red circle where they stand, then the landing)'),
(7206, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 50, 'Ancient Stone Keeper: from 50%, sand storm, 3 red lines fanned toward the hero, then a knockback wave'),
(7023, 18944, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Obsidian Sentinel: obsidian fist, a cone 10 yd in front of it'),
(7023, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Obsidian Sentinel: sentinel''s rush (Charge: a red line, then the dash)'),
(7023, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Obsidian Sentinel: Stomp, a ring 12 yd round it (safe within 6)'),
(7023, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 100, 'Obsidian Sentinel: obsidian shards rise (2 of the stage''s enemies)'),
(7023, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 66, 'Obsidian Sentinel: from 66%, obsidian shards, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(2779, 9672, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Prince Nazjak: Frostbolt'),
(2779, 15496, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Prince Nazjak: trident sweep, a cone 10 yd in front of him'),
(2779, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 100, 'Prince Nazjak: tidal wave, 3 red lines fanned toward the hero, then a knockback wave'),
(2779, 10737, 0, 9000, 6000, 0, 40, 1, 3, 5, 5, 100, 'Prince Nazjak: hail of ice, 5 circles (5 yd) round the hero'),
(2779, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Prince Nazjak: from 66%, brine pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(5710, 9053, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Jammal''an the Prophet: Fireball'),
(5710, 16419, 0, 10000, 6000, 0, 40, 1.2, 3, 4, 6.5, 100, 'Jammal''an the Prophet: Flamestrike, 4 circles (6.5 yd) round the hero'),
(5710, 15636, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Jammal''an the Prophet: Hex of Jammal''an, a ring 12 yd round him (safe within 6)'),
(5710, 17616, 1, 15000, 5000, 0, 60, 0, 4, 2, 0, 100, 'Jammal''an the Prophet: Atal''ai deathwalkers rise (2 of the stage''s enemies)'),
(5710, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 66, 'Jammal''an the Prophet: from 66%, prophecy lines, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(5719, 16390, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Morphaz: Acid Breath, a cone 10 yd in front of him'),
(5719, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 100, 'Morphaz: wing slam, leaps onto the hero (red circle where they stand, then the landing)'),
(5719, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Morphaz: Wing Buffet, a ring 12 yd round him (safe within 6)'),
(5719, 12280, 0, 10000, 6000, 0, 40, 1.1, 3, 4, 5, 100, 'Morphaz: acid splashes, 4 circles (5 yd) round the hero'),
(5719, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 50, 'Morphaz: from 50%, breath sweep, 3 red lines fanned toward the hero, then a knockback wave'),
(10503, 13748, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Jandice Barov: Arcane Bolt'),
(10503, 22271, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Jandice Barov: Arcane Explosion, a ring 13 yd round her (safe within 6.5)'),
(10503, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Jandice Barov: Curse of Blood, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(10503, 17616, 1, 15000, 5000, 0, 60, 0, 4, 3, 0, 66, 'Jandice Barov: from 66%, her illusions appear (3 of the stage''s enemies)'),
(10503, 1698, 0, 13000, 8000, 0, 26, 1.25, 7, 6, 24, 50, 'Jandice Barov: from 50%, curse lines, 6 red lines all around, one at the hero (+1 per difficulty step)'),
(11261, 15496, 0, 7000, 3000, 0, 9, 1.6, 1, 0, 10, 100, 'Doctor Theolen Krastinov: Rend, a cone 10 yd in front of him'),
(11261, 22911, 0, 12000, 5000, 8, 30, 1.5, 0, 0, 0, 100, 'Doctor Theolen Krastinov: butcher''s rush (Charge: a red line, then the dash)'),
(11261, 11876, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Doctor Theolen Krastinov: Frenzy, a ring 12 yd round him (safe within 6)'),
(11261, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 100, 'Doctor Theolen Krastinov: blood pools, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)'),
(11261, 6545, 0, 14000, 6000, 12, 40, 2, 5, 0, 7, 50, 'Doctor Theolen Krastinov: from 50%, frenzied leap, leaps onto the hero (red circle where they stand, then the landing)'),
(6228, 9053, 0, 6000, 3000, 0, 35, 1.3, 0, 0, 0, 100, 'Dark Iron Ambassador: Fireball'),
(6228, 16419, 0, 10000, 6000, 0, 40, 1.2, 3, 4, 6.5, 100, 'Dark Iron Ambassador: Flamestrike, 4 circles (6.5 yd) round the hero'),
(6228, 15636, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Dark Iron Ambassador: Fire Shield, a ring 12 yd round him (safe within 6)'),
(6228, 25425, 0, 10000, 3000, 0, 30, 1.5, 6, 3, 30, 100, 'Dark Iron Ambassador: fire wave, 3 red lines fanned toward the hero, then a knockback wave'),
(6228, 28863, 0, 12000, 5000, 0, 40, 0.4, 8, 2, 5, 66, 'Dark Iron Ambassador: from 66%, burning ground, 2 red circles at and near the hero that burn for 6 sec (+1 per difficulty step)');


UPDATE `bonk_map` SET `description` = 'Farmland overrun by the Defias Brotherhood. Edwin VanCleef, Gilnid or Sneed''s Shredder leads the stage.' WHERE `id` = 1;
UPDATE `bonk_map` SET `description` = 'The burning heart of Blackrock Mountain. Magmadar, Golemagg or Baron Geddon leads the stage, with Garr, Lucifron and Gehennas close behind.' WHERE `id` = 2;
UPDATE `bonk_map` SET `description` = 'Endless dry plains full of Razormane and Kolkar raiders. Charlga Razorflank, Agathelos the Raging or Mutanus the Devourer leads the stage.' WHERE `id` = 3;
UPDATE `bonk_map` SET `description` = 'A dark forest where the dead walk. Stitches, Morbent Fel or Eliza leads the stage.' WHERE `id` = 4;
UPDATE `bonk_map` SET `description` = 'The temple city of the Gurubashi. Hakkar, High Priest Thekal or Bloodlord Mandokir leads the stage, with Jin''do, Venoxis and Mar''li close behind.' WHERE `id` = 5;
UPDATE `bonk_map` SET `description` = 'The ruined gates of Ahn''Qiraj. Ossirian the Unscarred or Baron Kazum leads the stage.' WHERE `id` = 6;
UPDATE `bonk_map` SET `description` = 'Sun-baked dunes around Zul''Farrak. Gahz''rilla or Chief Ukorz Sandscalp leads the stage.' WHERE `id` = 7;
UPDATE `bonk_map` SET `description` = 'A primal crater ruled by giant beasts. King Mosh or the Gorishi Hive Queen leads the stage.' WHERE `id` = 8;
UPDATE `bonk_map` SET `description` = 'Thick jungle full of Bloodscalp and Skullsplitter trolls. The Mosh''Ogg Lord or Gan''zulah leads the stage.' WHERE `id` = 9;
UPDATE `bonk_map` SET `description` = 'A barren land of warring centaur clans. Princess Theradras, Celebras the Cursed or Rotgrip leads the stage.' WHERE `id` = 10;
UPDATE `bonk_map` SET `description` = 'Scorched canyons above Uldaman. Archaedas, the Ancient Stone Keeper or the Obsidian Sentinel leads the stage.' WHERE `id` = 11;
UPDATE `bonk_map` SET `description` = 'Rolling highlands held by ogres and outlaws. Fozruk or Prince Nazjak leads the stage.' WHERE `id` = 12;
UPDATE `bonk_map` SET `description` = 'A sunken swamp around the Temple of Atal''Hakkar. The Avatar of Hakkar, Jammal''an the Prophet or Morphaz leads the stage.' WHERE `id` = 13;
UPDATE `bonk_map` SET `description` = 'Fields between Scholomance and the Scarlet camps. Darkmaster Gandling, Jandice Barov or Doctor Theolen Krastinov leads the stage.' WHERE `id` = 16;
UPDATE `bonk_map` SET `description` = 'The frozen shore of Iceflow Lake below Gnomeregan. Troggs and trolls come first, then Mekgineer Thermaplugg or the Dark Iron Ambassador and his machines.' WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
