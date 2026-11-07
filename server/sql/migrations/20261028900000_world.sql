DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028900000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028900000');

UPDATE `bonk_card` SET `description` = 'When an enemy hits you, thorns strike all enemies within 8 yards for 40% of a normal enemy''s health on Normal. Once every 0.5 sec.' WHERE `id` = 12;
UPDATE `bonk_glyph` SET `description` = 'Every 50 kills, the souls you gathered strike all enemies within 20 yards for 5 times a normal enemy''s health on Normal.' WHERE `id` = 38;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
