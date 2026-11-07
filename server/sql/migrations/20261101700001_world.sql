DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101700001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101700001');

DELETE FROM `bonk_level` WHERE `tier` = 2 AND `level` BETWEEN 12 AND 30 AND `level` <> 16;
INSERT INTO `bonk_level` (`tier`, `level`, `health`, `damage`, `extra_affixes`, `veteran_chance`, `reward`, `green_chance`, `blue_chance`, `epic_chance`, `legendary_chance`, `roll_floor`) VALUES
(2, 12, 3.618, 2.425, 2, 10, 1.9, 0, 75, 25, 3.5, 0.5),
(2, 13, 3.907, 2.547, 2, 10, 1.9, 0, 75, 25, 3.5, 0.5),
(2, 14, 4.22, 2.674, 2, 10, 1.9, 0, 75, 25, 3.5, 0.5),
(2, 15, 4.558, 2.808, 2, 10, 1.9, 0, 75, 25, 3.5, 0.5),
(2, 17, 5.316, 3.096, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 18, 5.741, 3.25, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 19, 6.201, 3.413, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 20, 6.697, 3.584, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 21, 7.232, 3.763, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 22, 7.811, 3.951, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 23, 8.436, 4.148, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 24, 9.111, 4.356, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 25, 9.84, 4.574, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 26, 10.627, 4.802, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 27, 11.477, 5.042, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 28, 12.395, 5.295, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 29, 13.387, 5.559, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75),
(2, 30, 14.458, 5.837, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75);

UPDATE `bonk_level` SET `epic_chance` = 25.0, `blue_chance` = 75.0, `legendary_chance` = 3.5 WHERE `tier` = 2 AND `level` = 11;
UPDATE `bonk_level` SET `epic_chance` = 25.5, `blue_chance` = 74.5, `legendary_chance` = 3.58 WHERE `tier` = 2 AND `level` = 12;
UPDATE `bonk_level` SET `epic_chance` = 26.1, `blue_chance` = 73.9, `legendary_chance` = 3.66 WHERE `tier` = 2 AND `level` = 13;
UPDATE `bonk_level` SET `epic_chance` = 26.6, `blue_chance` = 73.4, `legendary_chance` = 3.74 WHERE `tier` = 2 AND `level` = 14;
UPDATE `bonk_level` SET `epic_chance` = 27.1, `blue_chance` = 72.9, `legendary_chance` = 3.82 WHERE `tier` = 2 AND `level` = 15;
UPDATE `bonk_level` SET `epic_chance` = 27.6, `blue_chance` = 72.4, `legendary_chance` = 3.89 WHERE `tier` = 2 AND `level` = 16;
UPDATE `bonk_level` SET `epic_chance` = 28.2, `blue_chance` = 71.8, `legendary_chance` = 3.97 WHERE `tier` = 2 AND `level` = 17;
UPDATE `bonk_level` SET `epic_chance` = 28.7, `blue_chance` = 71.3, `legendary_chance` = 4.05 WHERE `tier` = 2 AND `level` = 18;
UPDATE `bonk_level` SET `epic_chance` = 29.2, `blue_chance` = 70.8, `legendary_chance` = 4.13 WHERE `tier` = 2 AND `level` = 19;
UPDATE `bonk_level` SET `epic_chance` = 29.7, `blue_chance` = 70.3, `legendary_chance` = 4.21 WHERE `tier` = 2 AND `level` = 20;
UPDATE `bonk_level` SET `epic_chance` = 30.3, `blue_chance` = 69.7, `legendary_chance` = 4.29 WHERE `tier` = 2 AND `level` = 21;
UPDATE `bonk_level` SET `epic_chance` = 30.8, `blue_chance` = 69.2, `legendary_chance` = 4.37 WHERE `tier` = 2 AND `level` = 22;
UPDATE `bonk_level` SET `epic_chance` = 31.3, `blue_chance` = 68.7, `legendary_chance` = 4.45 WHERE `tier` = 2 AND `level` = 23;
UPDATE `bonk_level` SET `epic_chance` = 31.8, `blue_chance` = 68.2, `legendary_chance` = 4.53 WHERE `tier` = 2 AND `level` = 24;
UPDATE `bonk_level` SET `epic_chance` = 32.4, `blue_chance` = 67.6, `legendary_chance` = 4.61 WHERE `tier` = 2 AND `level` = 25;
UPDATE `bonk_level` SET `epic_chance` = 32.9, `blue_chance` = 67.1, `legendary_chance` = 4.68 WHERE `tier` = 2 AND `level` = 26;
UPDATE `bonk_level` SET `epic_chance` = 33.4, `blue_chance` = 66.6, `legendary_chance` = 4.76 WHERE `tier` = 2 AND `level` = 27;
UPDATE `bonk_level` SET `epic_chance` = 33.9, `blue_chance` = 66.1, `legendary_chance` = 4.84 WHERE `tier` = 2 AND `level` = 28;
UPDATE `bonk_level` SET `epic_chance` = 34.5, `blue_chance` = 65.5, `legendary_chance` = 4.92 WHERE `tier` = 2 AND `level` = 29;
UPDATE `bonk_level` SET `epic_chance` = 35.0, `blue_chance` = 65.0, `legendary_chance` = 5.0 WHERE `tier` = 2 AND `level` = 30;

UPDATE `bonk_tier` SET `level_health_growth` = 1.15, `level_damage_growth` = 1.08 WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
