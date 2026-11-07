DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200020');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200020');

UPDATE `bonk_weapon` SET `range` = 18 WHERE `id` IN (37, 214, 215);
UPDATE `bonk_weapon` SET `range` = 12 WHERE `id` IN (502, 516, 517, 827, 833);
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, '16 yards', '12 yards') WHERE `id` IN (502, 516, 517);
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, '14 yards', '12 yards') WHERE `id` IN (827, 833);
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'reaches 16 yards', 'reaches 12 yards') WHERE `id` = 312;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'within 20 yards', 'within 14 yards') WHERE `id` = 633;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'enemies within 20 yards', 'enemies within 12 yards') WHERE `id` = 730;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
