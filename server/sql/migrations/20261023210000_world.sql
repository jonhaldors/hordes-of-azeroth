DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023210000');

UPDATE `bonk_weapon` SET `range` = 16, `description` = REPLACE(`description`, 'within 20 yards', 'within 16 yards') WHERE `id` IN (906, 923, 924);
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_ChaosBolt' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_FireBolt' WHERE `id` = 911;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_ImpSwarm' WHERE `id` = 912;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_Conflagrate' WHERE `id` = 927;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_Shadowflame' WHERE `id` = 928;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_Inferno' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `icon` = 'Spell_Fel_DemonicImmolation' WHERE `id` = 930;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
