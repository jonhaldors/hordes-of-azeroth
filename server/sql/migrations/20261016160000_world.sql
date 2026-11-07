DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016160000');

UPDATE `creature_template` SET `display_probability2` = 0, `display_probability3` = 0, `display_probability4` = 0,
    `display_total_probability` = `display_probability1`
WHERE `entry` = 3285;

UPDATE `bonk_map_creature` SET `scale` = 1.35 WHERE `bonk_map_id` = 1 AND `entry` = 36 AND `kind` = 0;

INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectDieSides`, `EffectBaseDice`, `EffectDicePerLevel`, `EffectRealPointsPerLevel`,
    `EffectBasePoints`, `EffectAmplitude`, `EffectPointsPerComboPoint`, `EffectChainTarget`, `EffectMultipleValue`, `EffectMechanic`,
    `EffectImplicitTargetA`, `EffectImplicitTargetB`, `EffectRadiusIndex`, `EffectApplyAuraName`, `EffectItemType`, `EffectMiscValue`,
    `EffectTriggerSpell`, `Comment`) VALUES
(15245, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Shadow Bolt Volley 10 yards (was 30)'),
(20603, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Shadow Shock 10 yards (was 20)'),
(11902, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Gahz''rilla Slam 10 yards (was 20)'),
(11902, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Gahz''rilla Slam 10 yards (was 20)'),
(19497, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Eruption 10 yards (was 15)'),
(19497, 1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Eruption 10 yards (was 15)'),
(28361, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 29, -1, -1, -1, -1, 'Vanilla Bonk: Disease Cloud 6 yards (was 10)')
ON DUPLICATE KEY UPDATE `EffectRadiusIndex` = VALUES(`EffectRadiusIndex`);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
