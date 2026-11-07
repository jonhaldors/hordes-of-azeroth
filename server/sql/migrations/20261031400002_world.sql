DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031400002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031400002');

ALTER TABLE `bonk_level` ADD COLUMN `green_chance` FLOAT NOT NULL DEFAULT 0, ADD COLUMN `blue_chance` FLOAT NOT NULL DEFAULT 0,
    ADD COLUMN `epic_chance` FLOAT NOT NULL DEFAULT 0, ADD COLUMN `legendary_chance` FLOAT NOT NULL DEFAULT 0, ADD COLUMN `roll_floor` FLOAT NOT NULL DEFAULT 0;
UPDATE `bonk_level` SET `green_chance` = 0 WHERE `tier` = 1 AND `level` = 1;
UPDATE `bonk_level` SET `green_chance` = 20 WHERE `tier` = 1 AND `level` = 2;
UPDATE `bonk_level` SET `green_chance` = 35 WHERE `tier` = 1 AND `level` = 3;
UPDATE `bonk_level` SET `green_chance` = 50 WHERE `tier` = 1 AND `level` = 4;
UPDATE `bonk_level` SET `green_chance` = 70, `blue_chance` = 10 WHERE `tier` = 3 AND `level` = 1;
UPDATE `bonk_level` SET `green_chance` = 65, `blue_chance` = 25 WHERE `tier` = 3 AND `level` = 2;
UPDATE `bonk_level` SET `green_chance` = 40, `blue_chance` = 60 WHERE `tier` = 3 AND `level` = 3;
UPDATE `bonk_level` SET `green_chance` = 27, `blue_chance` = 73 WHERE `tier` = 3 AND `level` = 4;
UPDATE `bonk_level` SET `green_chance` = 15, `blue_chance` = 85 WHERE `tier` = 3 AND `level` = 5;
DELETE FROM `bonk_level` WHERE `tier` = 2;
INSERT INTO `bonk_level` (`tier`, `level`, `health`, `damage`, `extra_affixes`, `veteran_chance`, `reward`, `green_chance`, `blue_chance`, `epic_chance`, `legendary_chance`, `roll_floor`) VALUES
  (2, 1, 1.55, 1.42, 1, 5, 1.9, 0, 95, 5, 0, 0),
  (2, 2, 1.674, 1.491, 1, 5, 1.9, 0, 93, 7, 0, 0),
  (2, 3, 1.808, 1.566, 1, 5, 1.9, 0, 91, 9, 0, 0),
  (2, 4, 1.953, 1.644, 1, 5, 1.9, 0, 89, 11, 0, 0),
  (2, 5, 2.109, 1.726, 1, 5, 1.9, 0, 87, 13, 0, 0),
  (2, 6, 2.28, 1.81, 1, 10, 1.9, 0, 85, 15, 1, 0),
  (2, 7, 2.462, 1.901, 1, 10, 1.9, 0, 83, 17, 1.5, 0),
  (2, 8, 2.659, 1.996, 1, 10, 1.9, 0, 81, 19, 2, 0),
  (2, 9, 2.872, 2.095, 1, 10, 1.9, 0, 79, 21, 2.5, 0),
  (2, 10, 3.102, 2.2, 1, 10, 1.9, 0, 77, 23, 3, 0),
  (2, 11, 3.35, 2.31, 2, 10, 1.9, 0, 75, 25, 3.5, 0.5),
  (2, 16, 4.922, 2.948, 2, 10, 1.9, 0, 75, 25, 3.5, 0.75);
DELETE FROM `bonk_string_locale` WHERE `entry` IN (69, 70, 242, 243, 244, 282, 283, 759, 834, 835, 836, 838, 839, 840, 841, 842, 871, 872);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
