DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019320000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019320000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` = 600;
UPDATE `bonk_weapon` SET `cooldown_ms` = 12000, `duration_ms` = 8000,
    `description` = 'For 8 seconds, your single-target Rogue hits also strike 4 additional enemies within 8 yards. The extra hits carry your poisons and openers.' WHERE `id` = 601;
UPDATE `bonk_weapon` SET `behavior_value` = 14,
    `description` = 'Strikes 14 times over 3 seconds, each strike at a random enemy within 10 yards. Every strike carries your poisons and openers.' WHERE `id` = 603;
UPDATE `bonk_weapon` SET `base_targets` = 4,
    `description` = 'Throws 4 shurikens at the nearest enemies you have not hit yet, within 30 yards, or the nearest enemies when you have hit them all.' WHERE `id` = 608;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.0 WHERE `id` = 609;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
