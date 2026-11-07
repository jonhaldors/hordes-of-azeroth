DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030180000');

UPDATE `bonk_mob_ability` SET `damage` = 1.0 WHERE `shape` = 8 AND ABS(`damage` - 0.4) < 0.001;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
