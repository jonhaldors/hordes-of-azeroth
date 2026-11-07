DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016430000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016430000');

UPDATE `bonk_weapon` SET `target` = 7,
    `description` = 'Places a fire trap that goes off when an enemy comes close. It explodes and burns the ground for 4 sec, applying Burning.'
WHERE `id` = 202;
UPDATE `bonk_weapon` SET `target` = 7,
    `description` = 'Places a frost trap that goes off when an enemy comes close. For 6 sec, normal enemies inside are slowed by 60% and take 5% more damage.'
WHERE `id` = 204;
UPDATE `bonk_weapon_upgrade` SET `upgrade` = 12, `step` = 4 WHERE `weapon_id` IN (202, 204) AND `upgrade` = 3;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
