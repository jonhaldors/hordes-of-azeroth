DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024040000');

UPDATE `bonk_mob_ability` SET `size` = 16 WHERE `shape` = 11;
UPDATE `bonk_mob_ability` SET `size` = `size` + 3 WHERE `shape` IN (1, 10);
UPDATE `bonk_mob_ability` SET `comment` = REGEXP_REPLACE(`comment`, 'cones .[0-9.]+ yd.', CONCAT('cones (', `size` + 0, ' yd)')) WHERE `shape` = 11;
UPDATE `bonk_mob_ability` SET `comment` = REGEXP_REPLACE(`comment`, 'a cone [0-9.]+ yd', CONCAT('a cone ', `size` + 0, ' yd')) WHERE `shape` = 1;
UPDATE `bonk_mob_ability` SET `comment` = REGEXP_REPLACE(`comment`, 'cones [0-9.]+ yd', CONCAT('cones ', `size` + 0, ' yd')) WHERE `shape` = 10;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
