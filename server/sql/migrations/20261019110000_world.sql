DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019110000');

ALTER TABLE `bonk_map_creature` ADD COLUMN IF NOT EXISTS `flyer` TINYINT UNSIGNED NOT NULL DEFAULT 0;

DELETE FROM `bonk_map_creature` WHERE `flyer` = 1;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `archetype`, `min_sec`, `max_sec`, `weight`, `max_alive`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`, `flyer`) VALUES
(1, 832, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(2, 10442, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(3, 4117, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(4, 1554, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(5, 4539, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(6, 11727, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(7, 5455, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(8, 9167, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(9, 4861, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(10, 4694, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(11, 4323, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(12, 4862, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(13, 740, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(14, 7049, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(15, 8601, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(16, 8600, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(17, 5278, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(18, 4324, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1),
(19, 8776, 0, 0, 0, 0, 1, 0, 1, 1, 0.9, 1, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
