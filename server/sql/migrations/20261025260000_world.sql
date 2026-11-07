DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025260000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025260000');

UPDATE `bonk_weapon` SET `uses_pct` = 4, `description` = REPLACE(`description`, '5% more per stack of Bleed', '4% more per stack of Bleed') WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Mauls the nearest enemy, splashing 30% on enemies within 5 yards.', 'Mauls the nearest enemy, splashing 20% on enemies within 5 yards.') WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
