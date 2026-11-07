DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017055500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017055500');

UPDATE `bonk_mastery` SET `icon` = 'Ability_Parry' WHERE `id` = 30306;
UPDATE `bonk_glyph` SET `icon` = 'Spell_Holy_RighteousFury' WHERE `id` = 8;
UPDATE `bonk_glyph` SET `icon` = 'Spell_Holy_SealOfWrath' WHERE `id` = 13;

UPDATE `bonk_weapon` SET `icon` = 'Ability_Whirlwind' WHERE `id` = 306;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Nature_BloodLust' WHERE `id` = 304;
UPDATE `bonk_weapon` SET `icon` = 'Ability_BackStab' WHERE `id` = 302;
UPDATE `bonk_weapon` SET `icon` = 'Ability_ThunderClap' WHERE `id` = 308;
UPDATE `bonk_weapon` SET `icon` = 'Ability_Warrior_Revenge' WHERE `id` = 309;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
