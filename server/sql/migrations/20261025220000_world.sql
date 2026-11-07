DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025220000');

UPDATE `bonk_weapon` SET `damage_fraction` = 5.6 WHERE `id` = 1002;
UPDATE `bonk_weapon` SET `damage_fraction` = 7.5 WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `damage_fraction` = 5.0 WHERE `id` = 1005;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` = 1008;
UPDATE `bonk_weapon` SET `description` = REPLACE(REPLACE(`description`, 'Moonkin hurls Wrath at the nearest enemy.', 'Moonkin hurls Wrath at the nearest enemy, splashing 30% of it on enemies within 5 yards.'), 'Cat claws the nearest enemy quickly and applies 1 stack of Bleed.', 'Cat claws the nearest enemy quickly, splashing 30% on enemies within 5 yards, and applies 1 stack of Bleed.') WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
