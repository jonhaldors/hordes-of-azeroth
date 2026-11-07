DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028700000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028700000');

UPDATE `bonk_weapon` SET `radius` = 6 WHERE `id` = 719;
UPDATE `spell_effect_mod` SET `EffectChainTarget` = 5, `Comment` = 'Chain Lightning jumps to 4 additional enemies' WHERE `Id` = 421 AND `EffectIndex` = 0;
UPDATE `spell_effect_mod` SET `EffectChainTarget` = 11, `Comment` = 'Elemental Mastery: jumps up to 10 times' WHERE `Id` = 28167 AND `EffectIndex` = 0;
UPDATE `bonk_weapon` SET `flags` = `flags` | 32768 WHERE `id` IN (38, 222, 223);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
