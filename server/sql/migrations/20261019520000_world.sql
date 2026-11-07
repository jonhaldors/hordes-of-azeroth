DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019520000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019520000');

UPDATE `bonk_mob_ability` SET `size` = CASE WHEN `size` <= 8 THEN 8 WHEN `size` <= 12 THEN 9 ELSE 10 END WHERE `shape` = 2;
UPDATE `bonk_mob_ability` SET `comment` = REPLACE(`comment`, 'a ring of thorns, ', 'thorns, ') WHERE `shape` = 2;
UPDATE `bonk_mob_ability` SET `comment` = CONCAT(SUBSTRING_INDEX(`comment`, 'a ring', 1), 'a circle ', CAST(`size` AS UNSIGNED), ' yd round ', SUBSTRING_INDEX(SUBSTRING_INDEX(`comment`, ' round ', -1), ' ', 1), ': get out') WHERE `shape` = 2;
UPDATE `bonk_mob_ability` SET `shape` = 9 WHERE `shape` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
