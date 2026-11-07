DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021230000');

UPDATE `bonk_weapon` SET `damage_fraction` = 3.1 WHERE `id` = 800;
UPDATE `bonk_weapon` SET `damage_fraction` = 10.0,
    `description` = REPLACE(`description`, 'at most once every 2 sec', 'at most once every 1 sec')
    WHERE `id` = 805;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.0 WHERE `id` = 811;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` = 812;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
