DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022030000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022030000');

UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'for each enemy hit, up to 5%', 'for each enemy hit, up to 2%') WHERE `id` IN (502, 516, 517);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
