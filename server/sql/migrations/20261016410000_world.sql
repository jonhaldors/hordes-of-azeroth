DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016410000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016410000');

UPDATE `spell_template` SET `durationIndex` = 8 WHERE `entry` = 23505;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
