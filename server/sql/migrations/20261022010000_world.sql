DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022010000');

UPDATE `bonk_weapon` SET `cooldown_ms` = 8000, `duration_ms` = 0 WHERE `id` IN (809, 831, 832);
UPDATE `bonk_weapon` SET `description` = 'Every 8 sec, a golden bubble forms around you. The next enemy hit that would take more than 5% of your maximum health is blocked completely.' WHERE `id` = 809;
UPDATE `bonk_weapon` SET `description` = 'Every 8 sec, a golden bubble forms around you. The next enemy hit that would take more than 5% of your maximum health is blocked completely. When you fall below 30% health, you are protected from all damage for 2 sec, at most once every 30 sec.' WHERE `id` = 831;
UPDATE `bonk_weapon` SET `description` = 'Every 8 sec, a golden bubble forms around you. The next enemy hit that would take more than 5% of your maximum health is blocked completely, and the bubble bursts, dealing Holy damage to every enemy within 10 yards.' WHERE `id` = 832;
DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (809, 831, 832) AND `upgrade` = 5;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
