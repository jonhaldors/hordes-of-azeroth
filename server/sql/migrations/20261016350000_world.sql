DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016350000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016350000');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 7273 AND `spell_id` IN (10737, 12734);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(7273, 10737, 0, 9000,  6000, 0, 40, 1.0, 3, 5, 4,  100, 'Gahz''rilla: Hail Storm, 5 icicles (4 yd circles) crash down round the hero'),
(7273, 12734, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'Gahz''rilla: Ground Smash, his Gahz''rilla Slam as a ring 13 yd round him (safe within 6.5)');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 7273 AND `spell_id` = 11902;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 6584 AND `spell_id` IN (12612, 17257);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(6584, 12612, 1, 10000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'King Mosh: Stomp, a devilsaur footfall, a ring 12 yd round him (safe within 6)'),
(6584, 17257, 0, 7000,  3000, 0, 8,  1.6, 1, 0, 9,  100, 'King Mosh: Bite, a cone 9 yd in front of him');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 6584 AND `spell_id` = 14331;
DELETE FROM `bonk_mob_ability` WHERE `entry` = 6584 AND `spell_id` = 15550;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 680 AND `spell_id` IN (4164, 16172);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(680, 4164,  0, 10000, 6000, 0, 35, 1.1, 3, 4, 3.5, 100, 'Mosh''Ogg Lord: Throw Rock, 4 rocks (3.5 yd circles) land round the hero'),
(680, 16172, 0, 7000,  3000, 0, 8,  1.6, 1, 0, 9,   100, 'Mosh''Ogg Lord: Head Crack, an overhead club swing, a cone 9 yd in front of him');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 12201 AND `spell_id` IN (21869, 21909);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(12201, 21869, 0, 8000,  3000, 0, 9,  1.5, 1, 0, 10, 100, 'Princess Theradras: Repulsive Gaze, a cone 10 yd in front of her'),
(12201, 21909, 1, 11000, 5000, 0, 14, 1.4, 2, 0, 14, 100, 'Princess Theradras: Dust Field, a ring 14 yd round her (safe within 7)');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 12201 AND `spell_id` = 5568;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 2748 AND `spell_id` IN (6524, 21071);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(2748, 6524,  1, 10000, 4000, 0, 13, 1.5, 2, 0, 13,  100, 'Archaedas: Ground Tremor, a ring 13 yd round him (safe within 6.5)'),
(2748, 21071, 0, 11000, 6000, 0, 40, 1.1, 3, 4, 4.5, 100, 'Archaedas: Boulder, 4 boulders (4.5 yd circles) fall round the hero');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 2748 AND `spell_id` = 5568;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 2611 AND `spell_id` IN (18944, 19798);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(2611, 18944, 0, 8000,  3000, 0, 9,  1.6, 1, 0, 10,  100, 'Fozruk: Smash, a giant''s fist, a cone 10 yd in front of him'),
(2611, 19798, 0, 11000, 6000, 0, 40, 1.1, 3, 4, 4.5, 100, 'Fozruk: Earthquake, the ground splits round the hero, 4 circles (4.5 yd)');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 8443 AND `spell_id` IN (6607, 12280);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(8443, 6607,  0, 8000,  3000, 0, 9,  1.5, 1, 0, 10, 100, 'Avatar of Hakkar: Lash, a cone 10 yd in front of him'),
(8443, 12280, 0, 10000, 6000, 0, 35, 1.1, 3, 4, 4,  100, 'Avatar of Hakkar: Acid of Hakkar, 4 splashes of acid (4 yd circles) round the hero');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 9019 AND `spell_id` IN (15636, 19132, 19717);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(9019, 15636, 1, 11000, 5000, 0, 12, 1.5, 2, 0, 12, 100, 'Emperor Dagran Thaurissan: Avatar of Flame, a ring 12 yd round him (safe within 6)'),
(9019, 19132, 0, 7000,  3000, 0, 7,  1.6, 1, 0, 8,  100, 'Emperor Dagran Thaurissan: Mighty Blow, an Ironfoe swing, a cone 8 yd in front of him'),
(9019, 19717, 0, 10000, 4000, 0, 40, 1.2, 3, 5, 4,  50,  'Emperor Dagran Thaurissan: from 50%, Rain of Fire, 5 circles (4 yd) round the hero');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 10363 AND `spell_id` IN (16419, 16805, 20691);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(10363, 16419, 0, 10000, 5000, 0, 40, 1.2, 3, 4, 5,  100, 'General Drakkisath: Flamestrike, 4 circles (5 yd) round the hero'),
(10363, 16805, 1, 12000, 3000, 0, 14, 1.8, 2, 0, 14, 50,  'General Drakkisath: from 50%, Conflagration, a ring of fire 14 yd round him (safe within 7)'),
(10363, 20691, 0, 7000,  3000, 0, 9,  1.6, 1, 0, 10, 100, 'General Drakkisath: Cleave, a cone 10 yd in front of him');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 10363 AND `spell_id` = 15754;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 10440 AND `spell_id` IN (15284, 17467);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(10440, 15284, 0, 7000,  3000, 0, 8,  1.6, 1, 0, 9,  100, 'Baron Rivendare: Cleave, a runeblade sweep, a cone 9 yd in front of him'),
(10440, 17467, 1, 10000, 5000, 0, 12, 1.4, 2, 0, 12, 100, 'Baron Rivendare: Unholy Aura, a ring 12 yd round him (safe within 6)');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 10440 AND `spell_id` = 15754;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 10813 AND `spell_id` IN (14297, 17281, 17289);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(10813, 14297, 0, 10000, 4000, 0, 40, 1.2, 3, 5, 4,  50,  'Balnazzar: from 50%, Shadow Storm, 5 circles (4 yd) round the hero'),
(10813, 17281, 0, 7000,  3000, 0, 9,  1.6, 1, 0, 10, 100, 'Balnazzar: Crusader Strike (Dathrohan''s), a cone 10 yd in front of him'),
(10813, 17289, 1, 10000, 5000, 0, 14, 1.5, 2, 0, 14, 100, 'Balnazzar: Shadow Shock, a ring 14 yd round him (safe within 7)');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 10813 AND `spell_id` = 1112;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 1853 AND `spell_id` IN (15791, 17950);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(1853, 15791, 0, 9000,  4000, 0, 35, 1.0, 3, 5, 3.5, 100, 'Darkmaster Gandling: Arcane Missiles, 5 missiles (3.5 yd circles) strike round the hero'),
(1853, 17950, 1, 12000, 6000, 0, 12, 1.5, 2, 0, 12,  100, 'Darkmaster Gandling: Shadow Portal, a ring of portals 12 yd round him (safe within 6)');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 11486 AND `spell_id` IN (19821, 22271, 22920);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(11486, 19821, 0, 10000, 6000, 0, 35, 1.1, 3, 4, 4,  100, 'Prince Tortheldrin: Arcane Bomb, 4 circles (4 yd) round the hero'),
(11486, 22271, 1, 12000, 3000, 0, 13, 1.7, 2, 0, 13, 50,  'Prince Tortheldrin: from 50%, Arcane Explosion, a ring 13 yd round him (safe within 6.5)'),
(11486, 22920, 0, 8000,  3000, 0, 8,  1.6, 1, 0, 9,  100, 'Prince Tortheldrin: Arcane Blast, a cone 9 yd in front of him');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 11501 AND `spell_id` IN (11876, 14099);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(11501, 11876, 1, 10000, 5000, 0, 13, 1.5, 2, 0, 13, 100, 'King Gordok: War Stomp, a ring 13 yd round him (safe within 6.5)'),
(11501, 14099, 0, 7000,  3000, 0, 9,  1.7, 1, 0, 10, 100, 'King Gordok: Mighty Blow, a cone 10 yd in front of him');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 10429 AND `spell_id` IN (8245, 16390);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(10429, 8245,  0, 10000, 6000, 0, 35, 1.1, 3, 4, 4,  100, 'Warchief Rend Blackhand: Corrosive Acid, Gyth spits 4 circles (4 yd) round the hero'),
(10429, 16390, 0, 8000,  4000, 0, 9,  1.6, 1, 0, 10, 100, 'Warchief Rend Blackhand: Flame Breath, Gyth''s breath, a cone 10 yd in front');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 10430 AND `spell_id` IN (11988, 20623);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(10430, 11988, 0, 10000, 5000, 0, 40, 1.1, 3, 5, 4,  100, 'The Beast: Fireball Volley, 5 fireballs (4 yd circles) land round the hero'),
(10430, 20623, 0, 8000,  3000, 0, 9,  1.6, 1, 0, 10, 100, 'The Beast: Fire Blast, a cone 10 yd in front of him');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 12397 AND `spell_id` IN (15496, 21056, 21341);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(12397, 15496, 0, 7000,  3000, 0, 9,  1.7, 1, 0, 10,  100, 'Lord Kazzak: Cleave, a cone 10 yd in front of him'),
(12397, 21056, 0, 12000, 3000, 0, 40, 1.6, 3, 3, 5,   50,  'Lord Kazzak: from 50%, Mark of Kazzak, 3 marks burst round the hero (5 yd circles)'),
(12397, 21341, 0, 9000,  5000, 0, 40, 1.0, 3, 5, 3.5, 100, 'Lord Kazzak: Shadow Bolt Volley, 5 bolts (3.5 yd circles) land round the hero');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 12397 AND `spell_id` = 16044;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 14467 AND `spell_id` IN (7139, 19695);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(14467, 7139,  1, 10000, 4000, 0, 13, 1.5, 2, 0, 13, 100, 'Kroshius: Fel Stomp, a ring 13 yd round him (safe within 6.5)'),
(14467, 19695, 0, 11000, 6000, 0, 40, 1.3, 3, 3, 5,  100, 'Kroshius: Inferno, 3 infernals crash down round the hero (5 yd circles)');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 11982 AND `spell_id` IN (19272, 19411, 19449);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(11982, 19272, 0, 8000,  4000, 0, 9,  1.7, 1, 0, 10,  100, 'Magmadar: Lava Breath, a cone 10 yd in front of him'),
(11982, 19411, 0, 10000, 6000, 0, 40, 1.2, 3, 4, 4.5, 100, 'Magmadar: Lava Bomb, 4 circles (4.5 yd) burst round the hero'),
(11982, 19449, 0, 9000,  3000, 0, 40, 1.0, 3, 6, 3,   50,  'Magmadar: from 50%, Magma Spit, 6 small circles (3 yd) spatter round the hero');

DELETE FROM `bonk_mob_ability` WHERE `entry` = 14834 AND `spell_id` IN (24322, 24328, 24688);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(14834, 24322, 0, 8000,  3000, 0, 9,  1.8, 1, 0, 10, 50,  'Hakkar: from 50%, Blood Siphon, a cone 10 yd in front of him'),
(14834, 24328, 0, 9000,  5000, 0, 40, 1.1, 3, 5, 4,  100, 'Hakkar: Corrupted Blood, 5 circles (4 yd) of blood burst round the hero'),
(14834, 24688, 1, 11000, 6000, 0, 14, 1.6, 2, 0, 14, 100, 'Hakkar: Aspect of Venoxis, a poison ring 14 yd round him (safe within 7)');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 14834 AND `spell_id` = 20741;

DELETE FROM `bonk_mob_ability` WHERE `entry` = 15339 AND `spell_id` IN (24375, 25160, 25176);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `comment`) VALUES
(15339, 24375, 1, 10000, 5000, 0, 14, 1.5, 2, 0, 14, 100, 'Ossirian the Unscarred: War Stomp, a ring 14 yd round him (safe within 7)'),
(15339, 25160, 0, 10000, 6000, 0, 40, 1.2, 3, 4, 5,  100, 'Ossirian the Unscarred: Sand Storm, 4 whirling circles (5 yd) round the hero'),
(15339, 25176, 0, 8000,  3000, 0, 9,  1.9, 1, 0, 10, 50,  'Ossirian the Unscarred: from 50%, Strength of Ossirian, his swing a cone 10 yd in front');
DELETE FROM `bonk_mob_ability` WHERE `entry` = 15339 AND `spell_id` = 25188;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
