DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020987000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020987000');

UPDATE `bonk_weapon` SET `flags` = `flags` | 0x10000000 WHERE `id` = 714;
UPDATE `spell_template` SET `dmgMultiplier1` = 0.85 WHERE `entry` = 28167;
UPDATE `spell_effect_mod` SET `EffectMultipleValue` = -1, `Comment` = 'Elemental Mastery: jumps on and on' WHERE `Id` = 28167 AND `EffectIndex` = 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
