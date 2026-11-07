DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100006');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100006');

UPDATE `bonk_mastery` SET `icon` = 'ability_warrior_challange' WHERE `id` = 10113;
UPDATE `bonk_mastery` SET `icon` = 'spell_holy_dispelmagic' WHERE `id` = 20211;
UPDATE `bonk_mastery` SET `icon` = 'spell_holy_invulnerable' WHERE `id` = 20214;
UPDATE `bonk_mastery` SET `icon` = 'spell_holy_heal' WHERE `id` = 20313;
UPDATE `bonk_mastery` SET `icon` = 'ability_hunter_aimedshot' WHERE `id` = 30313;
UPDATE `bonk_mastery` SET `icon` = 'ability_rogue_rupture' WHERE `id` = 40311;
UPDATE `bonk_mastery` SET `icon` = 'ability_rogue_dualweild' WHERE `id` = 40312;
UPDATE `bonk_mastery` SET `icon` = 'spell_shadow_mindrot' WHERE `id` = 50311;
UPDATE `bonk_mastery` SET `icon` = 'spell_nature_naturesblessing' WHERE `id` = 70111;
UPDATE `bonk_mastery` SET `icon` = 'spell_nature_magicimmunity' WHERE `id` = 70114;
UPDATE `bonk_mastery` SET `icon` = 'spell_fire_firebolt' WHERE `id` = 80213;
UPDATE `bonk_mastery` SET `icon` = 'spell_shadow_blackplague' WHERE `id` = 90112;
UPDATE `bonk_mastery` SET `icon` = 'spell_shadow_shadetruesight' WHERE `id` = 90213;
UPDATE `bonk_mastery` SET `icon` = 'spell_shadow_mindsteal' WHERE `id` = 90314;
UPDATE `bonk_mastery` SET `icon` = 'spell_nature_naturesblessing' WHERE `id` = 110114;
UPDATE `bonk_mastery` SET `icon` = 'ability_druid_maul' WHERE `id` = 110211;
UPDATE `bonk_mastery` SET `icon` = 'ability_druid_ferociousbite' WHERE `id` = 110213;
UPDATE `bonk_mastery` SET `icon` = 'spell_nature_farsight' WHERE `id` = 110312;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
