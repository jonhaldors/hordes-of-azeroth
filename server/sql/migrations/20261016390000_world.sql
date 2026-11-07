DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016390000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016390000');

UPDATE `bonk_glyph` SET `description` = '+40% experience.' WHERE `id` = 1;
UPDATE `bonk_card` SET `stat1_value` = 40, `description` = '+40% experience.' WHERE `id` = 150;
UPDATE `bonk_glyph` SET `value1` = 100, `description` = '+50% pickup range, and power-ups stay on the ground twice as long.' WHERE `id` = 2;
UPDATE `bonk_card` SET `stat1_value` = 50, `description` = '+50% pickup range.' WHERE `id` = 151;
UPDATE `bonk_glyph` SET `value1` = 30, `description` = 'Chests cost 30% less Valor.' WHERE `id` = 3;
UPDATE `bonk_glyph` SET `description` = '+40% damage to elites, mini-bosses and bosses.' WHERE `id` = 4;
UPDATE `bonk_card` SET `value1` = 40, `description` = '+40% damage to elites, mini-bosses and bosses.' WHERE `id` = 152;
UPDATE `bonk_glyph` SET `value1` = 30, `description` = 'An elite, mini-boss or boss dying within 30 yards heals you for 30% of your maximum health.' WHERE `id` = 5;
UPDATE `bonk_glyph` SET `description` = '30% chance for any spell to go off a second time.' WHERE `id` = 7;
UPDATE `bonk_card` SET `value1` = 30, `description` = '30% chance for a spell to go off a second time.' WHERE `id` = 153;
UPDATE `bonk_glyph` SET `value2` = 50, `value3` = 10000, `description` = 'Every 50 kills, gain 50% Haste for 10 seconds.' WHERE `id` = 8;
UPDATE `bonk_glyph` SET `description` = '+60% Valor.' WHERE `id` = 9;
UPDATE `bonk_card` SET `value1` = 60, `description` = '+60% Valor.' WHERE `id` = 154;
UPDATE `bonk_glyph` SET `description` = '+50% Power.' WHERE `id` = 10;
UPDATE `bonk_card` SET `stat1_value` = 50, `description` = '+50% Power.' WHERE `id` = 155;
UPDATE `bonk_glyph` SET `value1` = 100, `description` = 'Once each stage, when you would die, you come back at full health instead.' WHERE `id` = 11;
UPDATE `bonk_glyph` SET `value1` = 50, `value2` = 3, `value3` = 3000, `description` = 'Every 50 kills, you deal triple damage for 3 seconds.' WHERE `id` = 12;
UPDATE `bonk_glyph` SET `value1` = 1, `description` = '+1% Power for every 1% of health you are missing.' WHERE `id` = 13;
UPDATE `bonk_glyph` SET `value1` = 3000, `value2` = 8, `description` = 'Every 3 seconds, lightning strikes up to 8 enemies near you. These strikes always crit.' WHERE `id` = 16;
UPDATE `bonk_glyph` SET `value1` = 6000, `value2` = 6, `value3` = 10, `description` = 'Every 6 seconds, a meteor crashes into the thickest crowd of enemies near you.' WHERE `id` = 17;

DELETE FROM `spell_template` WHERE `entry` = 33400;
DROP TEMPORARY TABLE IF EXISTS `bonk_lit_fuse`;
CREATE TEMPORARY TABLE `bonk_lit_fuse` SELECT * FROM `spell_template` WHERE `entry` = 4051 AND `build` = 5302;
UPDATE `bonk_lit_fuse` SET `entry` = 33400, `attributes` = 0, `attributesEx` = 0, `procFlags` = 0, `procChance` = 0, `procCharges` = 0,
    `baseLevel` = 0, `spellLevel` = 0, `effectApplyAuraName1` = 4, `effectTriggerSpell1` = 0, `spellIconId` = 37,
    `name` = 'Lit Fuse', `auraDescription` = 'Blows up when it reaches you.';
INSERT INTO `spell_template` SELECT * FROM `bonk_lit_fuse`;
DROP TEMPORARY TABLE `bonk_lit_fuse`;

UPDATE `game_event` SET `disabled` = 1;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
