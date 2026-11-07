DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024010000');

UPDATE `bonk_mastery` SET `description` = 'Shadow Bolt''s Nightfall fires up to 3 free Shadow Bolts a sec instead of 1, and they deal 50% more damage. Your critical strike chance is reduced by 10%.' WHERE `id` = 90310;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
