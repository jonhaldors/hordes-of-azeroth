DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019400000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019400000');

UPDATE `bonk_weapon` SET `range` = 20, `description` = REPLACE(`description`, 'within 30 yards', 'within 20 yards') WHERE `id` IN (608, 628, 629);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
