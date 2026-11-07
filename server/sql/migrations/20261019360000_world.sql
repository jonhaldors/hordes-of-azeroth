DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019360000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019360000');

UPDATE `bonk_weapon` SET `base_targets` = 2, `damage_fraction` = 0.4, `cooldown_ms` = 800,
    `description` = 'Throws 2 shurikens at the nearest enemies you have not hit yet, within 30 yards, or the nearest enemies when you have hit them all.' WHERE `id` = 608;
UPDATE `bonk_weapon` SET `base_targets` = 2, `damage_fraction` = 0.4, `cooldown_ms` = 800,
    `description` = 'Throws 2 shurikens at the nearest enemies you have not hit yet, within 30 yards. Each shuriken jumps to 2 additional nearby enemies, ones you have not hit yet first.' WHERE `id` = 628;
UPDATE `bonk_weapon` SET `base_targets` = 2, `damage_fraction` = 0.4, `cooldown_ms` = 800,
    `description` = 'Throws 2 shurikens at the nearest enemies you have not hit yet, within 30 yards. A shadow stays where each one hits and bursts 1.5 seconds later for Shadow damage to enemies within 5 yards.' WHERE `id` = 629;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
