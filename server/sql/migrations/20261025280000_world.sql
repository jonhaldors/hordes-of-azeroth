DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025280000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025280000');

UPDATE `bonk_weapon` SET `damage_fraction` = 3.0, `uses_pct` = 3, `description` = REPLACE(`description`, '4% more per stack of Bleed', '3% more per stack of Bleed') WHERE `id` = 1005;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
