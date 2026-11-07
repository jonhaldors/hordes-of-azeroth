DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017095000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017095000');

DELETE FROM `spell_template` WHERE `entry` = 33401;
DROP TEMPORARY TABLE IF EXISTS `bonk_blood_aura_look`;
CREATE TEMPORARY TABLE `bonk_blood_aura_look` SELECT * FROM `spell_template` WHERE `entry` = 7069 AND `build` = 5086;
UPDATE `bonk_blood_aura_look` SET `entry` = 33401, `attributes` = 0, `attributesEx` = 0, `procFlags` = 0, `procChance` = 0, `procCharges` = 0,
    `effect1` = 6, `effectBasePoints1` = 0, `effectImplicitTargetA1` = 1, `effectImplicitTargetB1` = 0, `effectRadiusIndex1` = 0,
    `effectApplyAuraName1` = 4, `effectTriggerSpell1` = 0, `spellIconId` = 130,
    `name` = 'Blood Aura', `auraDescription` = 'Enemies near you bleed.';
INSERT INTO `spell_template` SELECT * FROM `bonk_blood_aura_look`;
DROP TEMPORARY TABLE `bonk_blood_aura_look`;

UPDATE `bonk_keyword` SET `max_stacks` = 30 WHERE `id` IN (3, 4, 5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
