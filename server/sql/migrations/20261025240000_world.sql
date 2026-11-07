DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025240000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025240000');

UPDATE `bonk_weapon` SET `description` = REPLACE(REPLACE(`description`,
    'Cat: fast claws on the nearest enemy, 30% splash within 5 yd', 'Cat: fast claws on the nearest enemy, 40% splash within 5 yd'),
    'Bear: mauls the nearest enemy, 50% splash within 5 yd', 'Bear: mauls the nearest enemy, 30% splash within 5 yd')
    WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
