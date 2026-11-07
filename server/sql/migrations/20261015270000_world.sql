DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015270000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015270000');

UPDATE `bonk_map_creature` SET `scale` = 1 WHERE `scale` < 1;

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 1 AND `entry` IN (480, 735) AND `kind` = 0;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(1, 735, 0, 0, 240, 480, 3, 3, 1, 1, 0.95, 1);

UPDATE `bonk_map_creature` SET `archetype` = 1 WHERE `bonk_map_id` = 2 AND `entry` = 12099 AND `kind` = 0;
UPDATE `bonk_map_creature` SET `archetype` = 2, `min_sec` = 0, `max_sec` = 0 WHERE `bonk_map_id` = 2 AND `entry` = 11661 AND `kind` = 0;

UPDATE `bonk_map_creature` SET `archetype` = 1 WHERE `bonk_map_id` = 3 AND `entry` = 3245 AND `kind` = 0;

UPDATE `bonk_map_creature` SET `archetype` = 4, `weight` = 2, `max_alive` = 2 WHERE `bonk_map_id` = 5 AND `entry` = 14750 AND `kind` = 0;
UPDATE `bonk_map_creature` SET `archetype` = 2, `min_sec` = 0, `max_sec` = 0, `max_alive` = 3 WHERE `bonk_map_id` = 5 AND `entry` = 14532 AND `kind` = 0;

UPDATE `bonk_map_creature` SET `archetype` = 1 WHERE `bonk_map_id` = 6 AND `entry` = 15325 AND `kind` = 0;
UPDATE `bonk_map_creature` SET `archetype` = 0 WHERE `bonk_map_id` = 6 AND `entry` = 15461 AND `kind` = 0;
UPDATE `bonk_map_creature` SET `archetype` = 2, `min_sec` = 0, `max_sec` = 0, `max_alive` = 3 WHERE `bonk_map_id` = 6 AND `entry` IN (15320, 15323) AND `kind` = 0;

UPDATE `bonk_map_creature` SET `archetype` = 1 WHERE `bonk_map_id` = 7 AND `entry` = 5441 AND `kind` = 0;
UPDATE `bonk_map_creature` SET `archetype` = 2, `min_sec` = 0, `max_sec` = 0 WHERE `bonk_map_id` = 7 AND `entry` = 5471 AND `kind` = 0;

UPDATE `bonk_map_creature` SET `archetype` = 2, `min_sec` = 0, `max_sec` = 0 WHERE `bonk_map_id` = 8 AND `entry` IN (6517, 9164, 9166) AND `kind` = 0;
DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 8 AND `entry` = 9157 AND `kind` = 0;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(8, 9157, 0, 0, 0, 240, 6, 0, 1, 1, 0.9, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
