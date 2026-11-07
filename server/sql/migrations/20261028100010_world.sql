DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100010');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100010');

UPDATE `spell_effect_mod` SET `EffectChainTarget` = 10, `Comment` = 'Elemental Mastery: jumps up to 10 times' WHERE `Id` = 28167 AND `EffectIndex` = 0;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.55, `description` = 'Hurls lightning at the nearest enemy that jumps up to 10 times, dealing Nature damage and 1 stack of Static to each. Each jump deals 15% less.' WHERE `id` = 714;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
