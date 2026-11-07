DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024020000');

UPDATE `bonk_mob_ability` SET `size` = `size` + 3, `damage` = ROUND(`damage` * 1.75, 2) WHERE `shape` = 9;
UPDATE `bonk_mob_ability` SET `comment` = REGEXP_REPLACE(`comment`, 'a circle [0-9.]+ yd', CONCAT('a circle ', `size` + 0, ' yd')) WHERE `shape` = 9;
UPDATE `bonk_mob_ability` SET `size` = LEAST(`size` + 3, 15) WHERE `shape` = 11;
UPDATE `bonk_mob_ability` SET `comment` = REGEXP_REPLACE(`comment`, 'cones .[0-9.]+ yd.', CONCAT('cones (', `size` + 0, ' yd)')) WHERE `shape` = 11;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
