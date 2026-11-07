DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025300000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` = 1003;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Hurls Wrath at the nearest enemy, splashing 30% on enemies within 5 yards.', 'Hurls Wrath at the nearest enemy, splashing 45% on enemies within 5 yards.') WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
