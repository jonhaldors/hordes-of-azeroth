DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022060000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022060000');

UPDATE `bonk_weapon` SET `range` = 8,
    `description` = REPLACE(`description`, 'within 10 yards', 'within 8 yards')
    WHERE `id` IN (306, 308, 313, 323, 324, 325, 326, 327, 328, 506, 524, 525);

UPDATE `bonk_weapon` SET `cooldown_ms` = 3000 WHERE `id` = 701;

UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'each jumping to 3 additional', 'each jumping to 4 additional') WHERE `id` = 715;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;