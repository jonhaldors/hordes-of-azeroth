DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021170000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0,
    `description` = 'Every hit from your other Paladin spells, including splash and area hits, also deals 20% of its damage as Holy damage.'
    WHERE `id` = 803;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
