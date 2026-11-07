DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021220000');

UPDATE `bonk_weapon` SET `range` = 10,
    `description` = REPLACE(REPLACE(`description`, 'within 8 yards', 'within 10 yards'), 'within 6 yards', 'within 10 yards')
    WHERE `id` IN (306, 308, 313, 323, 324, 325, 326, 327, 328, 506, 524, 525, 804, 806, 810);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
