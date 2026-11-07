DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030235000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030235000');

UPDATE `bonk_glyph` SET `value2` = 5, `value3` = 0.6, `description` = 'Every 3 sec, lightning strikes up to 5 nearby enemies for 60% of a normal enemy''s health on Normal. Always critically strikes.' WHERE `id` = 16;
UPDATE `bonk_glyph` SET `value2` = 3, `description` = 'Every 50 kills, the souls you gathered strike all enemies within 20 yards for 3 times a normal enemy''s health on Normal.' WHERE `id` = 38;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
