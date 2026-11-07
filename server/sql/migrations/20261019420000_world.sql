DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019420000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019420000');

UPDATE `bonk_weapon` SET `range` = 10, `description` = REPLACE(`description`, 'within 12 yards', 'within 10 yards') WHERE `id` IN (606, 624, 625);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
