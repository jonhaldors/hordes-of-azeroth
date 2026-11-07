DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020000000');

ALTER TABLE `bonk_mob_ability`
    ADD COLUMN `cast_kit` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `below_health`,
    ADD COLUMN `impact_kit` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `cast_kit`;

UPDATE `bonk_mob_ability` SET `shape` = 3, `count` = 3, `size` = 5, `impact_kit` = 7452, `target` = 0,
    `comment` = CONCAT(SUBSTRING_INDEX(`comment`, ':', 1), ': Shadow Bolt Volley, 3 circles of 5 yd round the hero: keep moving')
    WHERE `spell_id` IN (15245, 20741) AND `shape` = 0;
UPDATE `bonk_mob_ability` SET `shape` = 9, `size` = 10, `cast_kit` = 984, `impact_kit` = 728, `target` = 0,
    `comment` = 'Garr: Magma Shackles, a circle 10 yd round him: get out' WHERE `entry` = 12057 AND `spell_id` = 19496;
UPDATE `bonk_mob_ability` SET `shape` = 3, `count` = 3, `size` = 6, `impact_kit` = 7452, `target` = 0,
    `comment` = 'Lucifron: Impending Doom, 3 circles of 6 yd round the hero: keep moving' WHERE `entry` = 12118 AND `spell_id` = 19702;
UPDATE `bonk_mob_ability` SET `shape` = 9, `size` = 10, `cast_kit` = 7452, `impact_kit` = 2350, `target` = 0,
    `comment` = 'Lucifron: Shadow Shock, a circle 10 yd round him: get out' WHERE `entry` = 12118 AND `spell_id` = 20603;
UPDATE `bonk_mob_ability` SET `shape` = 3, `count` = 3, `size` = 6, `impact_kit` = 7452, `target` = 0,
    `comment` = 'Gehennas: Gehennas'' Curse, 3 circles of 6 yd round the hero: keep moving' WHERE `entry` = 12259 AND `spell_id` = 19716;
UPDATE `bonk_mob_ability` SET `shape` = 9, `size` = 10, `cast_kit` = 1004, `impact_kit` = 1005, `target` = 0,
    `comment` = 'Moam: Arcane Eruption, a circle 10 yd round him: get out' WHERE `entry` = 15340 AND `spell_id` = 25672;
UPDATE `bonk_mob_ability` SET `shape` = 9, `size` = 10, `cast_kit` = 356, `impact_kit` = 283, `target` = 0,
    `comment` = 'General Rajaxx: Thundercrash, a circle 10 yd round him: get out' WHERE `entry` = 15341 AND `spell_id` = 25599;
UPDATE `bonk_mob_ability` SET `shape` = 1, `size` = 12, `cast_kit` = 7451, `impact_kit` = 813, `target` = 0,
    `comment` = 'Ayamiss the Hunter: Stinger Spray, a cone 12 yd in front of her: step aside' WHERE `entry` = 15369 AND `spell_id` = 25749;
UPDATE `bonk_mob_ability` SET `shape` = 3, `count` = 3, `size` = 5, `impact_kit` = 7452, `target` = 0,
    `comment` = 'Anubisath Guardian: Shadow Storm, 3 circles of 5 yd round the hero: keep moving' WHERE `entry` = 15355 AND `spell_id` = 26546;
UPDATE `bonk_mob_ability` SET `shape` = 9, `size` = 10, `cast_kit` = 356, `impact_kit` = 283, `target` = 0,
    `comment` = 'Anubisath Guardian: Thunderclap, a circle 10 yd round it: get out' WHERE `entry` = 15355 AND `spell_id` = 26554;

UPDATE `bonk_mob_ability` SET `cast_kit` = 356, `impact_kit` = 283 WHERE `shape` = 9 AND `spell_id` IN (8078, 8147, 15588);
UPDATE `bonk_mob_ability` SET `impact_kit` = 437 WHERE `shape` = 9 AND `spell_id` IN (11876, 24375, 12612, 12734, 5568);
UPDATE `bonk_mob_ability` SET `cast_kit` = 356, `impact_kit` = 437 WHERE `shape` = 9 AND `spell_id` = 6432;
UPDATE `bonk_mob_ability` SET `cast_kit` = 7452, `impact_kit` = 2350 WHERE `shape` = 9 AND `spell_id` IN (7139, 17289, 17950);
UPDATE `bonk_mob_ability` SET `cast_kit` = 356, `impact_kit` = 282 WHERE `shape` = 9 AND `spell_id` = 11082;
UPDATE `bonk_mob_ability` SET `cast_kit` = 895, `impact_kit` = 895 WHERE `shape` = 9 AND `spell_id` = 8148;
UPDATE `bonk_mob_ability` SET `cast_kit` = 984, `impact_kit` = 728 WHERE `shape` = 9 AND `spell_id` IN (15636, 16785);
UPDATE `bonk_mob_ability` SET `cast_kit` = 984, `impact_kit` = 2750 WHERE `shape` = 9 AND `spell_id` = 16805;
UPDATE `bonk_mob_ability` SET `cast_kit` = 389, `impact_kit` = 437 WHERE `shape` = 9 AND `spell_id` = 21869;
UPDATE `bonk_mob_ability` SET `cast_kit` = 1004, `impact_kit` = 1005 WHERE `shape` = 9 AND `spell_id` = 22271;
UPDATE `bonk_mob_ability` SET `cast_kit` = 7454, `impact_kit` = 813 WHERE `shape` = 9 AND `spell_id` = 24688;

UPDATE `bonk_mob_ability` SET `impact_kit` = 507 WHERE `shape` IN (1, 10) AND `spell_id` IN (15284, 15496, 15754, 20691);
UPDATE `bonk_mob_ability` SET `impact_kit` = 437 WHERE `shape` IN (1, 10) AND `spell_id` IN (17257, 8374, 14099, 18944, 12734);
UPDATE `bonk_mob_ability` SET `cast_kit` = 3449, `impact_kit` = 728 WHERE `shape` = 1 AND `spell_id` = 20623;
UPDATE `bonk_mob_ability` SET `cast_kit` = 730, `impact_kit` = 419 WHERE `shape` = 1 AND `spell_id` = 22920;
UPDATE `bonk_mob_ability` SET `cast_kit` = 3449, `impact_kit` = 76 WHERE `shape` IN (1, 11) AND `spell_id` IN (19272, 16390);
UPDATE `bonk_mob_ability` SET `cast_kit` = 7451, `impact_kit` = 813 WHERE `shape` = 11 AND `spell_id` = 24322;
UPDATE `bonk_mob_ability` SET `cast_kit` = 7450, `impact_kit` = 216 WHERE `shape` = 11 AND `spell_id` IN (11131, 10737);

UPDATE `bonk_mob_ability` SET `impact_kit` = 160 WHERE `shape` = 3 AND `spell_id` = 10737;
UPDATE `bonk_mob_ability` SET `impact_kit` = 282 WHERE `shape` = 3 AND `spell_id` = 11085;
UPDATE `bonk_mob_ability` SET `impact_kit` = 6377 WHERE `shape` = 3 AND `spell_id` IN (12280, 21687, 8245);
UPDATE `bonk_mob_ability` SET `impact_kit` = 7452 WHERE `shape` = 3 AND `spell_id` IN (14297, 21056);
UPDATE `bonk_mob_ability` SET `impact_kit` = 1004 WHERE `shape` IN (3, 12, 13) AND `spell_id` IN (15791, 22271);
UPDATE `bonk_mob_ability` SET `impact_kit` = 437 WHERE `shape` = 3 AND `spell_id` = 16000;
UPDATE `bonk_mob_ability` SET `impact_kit` = 845 WHERE `shape` IN (3, 12, 13) AND `spell_id` IN (16419, 19717, 19695, 19411, 20153);
UPDATE `bonk_mob_ability` SET `impact_kit` = 7456 WHERE `shape` IN (3, 13) AND `spell_id` IN (19798, 21071, 4164, 6524, 12734);
UPDATE `bonk_mob_ability` SET `impact_kit` = 809 WHERE `shape` = 3 AND `spell_id` = 24328;
UPDATE `bonk_mob_ability` SET `impact_kit` = 895 WHERE `shape` = 13 AND `spell_id` = 8148;
UPDATE `bonk_mob_ability` SET `impact_kit` = 160 WHERE `shape` = 12 AND `spell_id` = 16390;
UPDATE `bonk_mob_ability` SET `impact_kit` = 6472 WHERE `shape` = 12 AND `spell_id` = 25160;

UPDATE `bonk_mob_ability` a
    JOIN (SELECT `entry`, MIN(`bonk_map_id`) AS `map` FROM `bonk_map_creature` GROUP BY `entry`) m ON m.`entry` = a.`entry`
    SET a.`impact_kit` = CASE
        WHEN m.`map` IN (2, 14, 18) THEN IF(a.`shape` IN (6, 7), 845, 0)
        WHEN m.`map` IN (4, 15, 16, 19) THEN CASE a.`shape` WHEN 8 THEN 7453 WHEN 5 THEN 7452 ELSE 7457 END
        WHEN m.`map` = 5 THEN 809
        WHEN m.`map` IN (6, 7) THEN IF(a.`shape` = 8, 6472, 7400)
        WHEN m.`map` IN (8, 9, 13) THEN IF(a.`shape` = 8, 7454, 6377)
        WHEN m.`map` = 3 THEN IF(a.`shape` = 8, 895, 7400)
        WHEN m.`map` = 17 THEN 1004
        WHEN m.`map` = 20 THEN 160
        ELSE IF(a.`shape` = 8, 7456, 7400)
    END
    WHERE a.`shape` IN (5, 6, 7, 8) AND a.`impact_kit` = 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
