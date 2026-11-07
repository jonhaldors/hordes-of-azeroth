DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103800000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103800000');

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (8127, 7291, 12057, 10997, 2609, 12259, 9017, 9816);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 19717 AND `entry` IN (8127, 7291, 12057, 10997, 2609, 12259, 9017, 9816);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 19717, 1, 16000, 8000, 0, 40, 1.2, 14, 0, 0, 100, 0, 728, CONCAT(MIN(`name`), ': meteor shower, falling circles scattered all around it')
FROM `creature_template` WHERE `entry` IN (8127, 7291, 12057, 10997, 2609, 12259, 9017, 9816) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (315, 12118, 5715, 9517, 9877, 10506, 522, 11487, 10435);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 30138 AND `entry` IN (315, 12118, 5715, 9517, 9877, 10506, 522, 11487, 10435);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 30138, 1, 16000, 8000, 0, 30, 2.0, 15, 0, 0, 100, 0, 2350, CONCAT(MIN(`name`), ': shadow ring, everything but the space next to it burns')
FROM `creature_template` WHERE `entry` IN (315, 12118, 5715, 9517, 9877, 10506, 522, 11487, 10435) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (10508, 2793, 10438, 7795);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 29849 AND `entry` IN (10508, 2793, 10438, 7795);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 29849, 1, 16000, 8000, 0, 30, 2.0, 15, 0, 0, 100, 0, 160, CONCAT(MIN(`name`), ': frost ring, everything but the space next to it freezes')
FROM `creature_template` WHERE `entry` IN (10508, 2793, 10438, 7795) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (15340, 5709);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 1449 AND `entry` IN (15340, 5709);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 1449, 1, 16000, 8000, 0, 30, 2.0, 15, 0, 0, 100, 0, 984, CONCAT(MIN(`name`), ': arcane ring, everything but the space next to it erupts')
FROM `creature_template` WHERE `entry` IN (15340, 5709) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (7228, 12203, 644, 9196, 11622, 646, 10439, 11496, 8580, 6229, 8983, 15341, 15370, 7361, 9622, 9464, 10507);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 19798 AND `entry` IN (7228, 12203, 644, 9196, 11622, 646, 10439, 11496, 8580, 6229, 8983, 15341, 15370, 7361, 9622, 9464, 10507);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 19798, 1, 16000, 8000, 0, 36, 1.5, 16, 0, 30, 100, 0, 7400, CONCAT(MIN(`name`), ': earthquake sweep, spokes all around, then a second set between them')
FROM `creature_template` WHERE `entry` IN (7228, 12203, 644, 9196, 11622, 646, 10439, 11496, 8580, 6229, 8983, 15341, 15370, 7361, 9622, 9464, 10507) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (4854, 7271, 14507, 14510, 11489, 11492, 12236, 7079, 6235, 11380);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 8078 AND `entry` IN (4854, 7271, 14507, 14510, 11489, 11492, 12236, 7079, 6235, 11380);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 8078, 1, 16000, 8000, 0, 36, 1.5, 16, 0, 30, 100, 0, 0, CONCAT(MIN(`name`), ': storm sweep, spokes all around, then a second set between them')
FROM `creature_template` WHERE `entry` IN (4854, 7271, 14507, 14510, 11489, 11492, 12236, 7079, 6235, 11380) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (728, 730, 731, 6581, 6583, 12258, 534, 10220, 15369, 15348);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 26083 AND `entry` IN (728, 730, 731, 6581, 6583, 12258, 534, 10220, 15369, 15348);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 26083, 0, 16000, 8000, 0, 24, 1.5, 11, 3, 0, 100, 366, 903, CONCAT(MIN(`name`), ': rending sweeps, wide cones one after another')
FROM `creature_template` WHERE `entry` IN (728, 730, 731, 6581, 6583, 12258, 534, 10220, 15369, 15348) GROUP BY `entry`;

DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 25425 AND `entry` IN (3394, 3395, 3396, 647, 2606, 9237, 9568, 9033);
DELETE FROM `bonk_mob_ability` WHERE `spell_id` = 6524 AND `entry` IN (3394, 3395, 3396, 647, 2606, 9237, 9568, 9033);
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `shape`, `count`, `size`, `below_health`, `cast_kit`, `impact_kit`, `comment`)
SELECT `entry`, 6524, 0, 16000, 8000, 0, 30, 1.5, 12, 3, 30, 100, 0, 7400, CONCAT(MIN(`name`), ': battle lines, walls of force that cut the ground into lanes')
FROM `creature_template` WHERE `entry` IN (3394, 3395, 3396, 647, 2606, 9237, 9568, 9033) GROUP BY `entry`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
