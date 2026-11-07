DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012001000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012001000');

UPDATE `bonk_mob_ability` SET `cooldown_ms` = 20000, `first_ms` = 8000
WHERE `spell_id` = 6268 AND `entry` IN (521, 730, 731, 1713, 3395, 3475, 6581, 15067);
UPDATE `bonk_mob_ability` SET `cooldown_ms` = 15000, `first_ms` = 6000
WHERE `spell_id` = 6268 AND `entry` IN (157, 206, 454, 1114, 5427, 6513);

DELETE FROM `bonk_mob_ability` WHERE `entry` = 646 AND `spell_id` = 6432;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
