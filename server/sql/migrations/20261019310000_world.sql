DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019310000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019310000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.0 WHERE `id` = 600;
UPDATE `bonk_weapon` SET `behavior_value` = 4,
    `description` = 'For 6 seconds, your single-target Rogue hits also strike 4 additional enemies within 8 yards. The extra hits carry your poisons and openers.' WHERE `id` = 601;
UPDATE `bonk_weapon` SET `damage_fraction` = 6.0 WHERE `id` = 602;
UPDATE `bonk_weapon` SET `behavior_value` = 10, `damage_fraction` = 1.0, `cooldown_ms` = 12000 WHERE `id` = 603;
UPDATE `bonk_weapon` SET `base_targets` = 3, `damage_fraction` = 0.6,
    `description` = 'Throws 3 shurikens at the nearest enemies you have not hit yet, within 30 yards, or the nearest enemies when you have hit them all.' WHERE `id` = 608;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 609;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
