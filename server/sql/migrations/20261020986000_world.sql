DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020986000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020986000');

UPDATE `bonk_glyph` SET `drawback` = 'Losing health turns it into 25% less Power for 5 sec. Damage a Shield absorbs does not.' WHERE `id` = 27;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
