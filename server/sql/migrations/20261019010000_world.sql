DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019010000');

UPDATE `bonk_weapon` SET `range` = 12, `damage_fraction` = 0.8 WHERE `id` = 705 OR `evolves_from` = 705;
UPDATE `bonk_weapon` SET `range` = 8 WHERE `id` = 704 OR `evolves_from` = 704;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.3 WHERE `id` = 709 OR `evolves_from` = 709;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Strikes up to 3 enemies around you twice', 'Strikes up to 3 enemies within 12 yards twice') WHERE `id` = 705 OR `evolves_from` = 705;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
