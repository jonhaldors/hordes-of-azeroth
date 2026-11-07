DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016220000');

INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectDieSides`, `EffectBaseDice`, `EffectDicePerLevel`, `EffectRealPointsPerLevel`,
    `EffectBasePoints`, `EffectAmplitude`, `EffectPointsPerComboPoint`, `EffectChainTarget`, `EffectMultipleValue`, `EffectMechanic`,
    `EffectImplicitTargetA`, `EffectImplicitTargetB`, `EffectRadiusIndex`, `EffectApplyAuraName`, `EffectItemType`, `EffectMiscValue`,
    `EffectTriggerSpell`, `Comment`) VALUES
(19408, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Panic 10 yards (was 45)'),
(19496, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Magma Shackles 10 yards (was 45)'),
(19702, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Impending Doom 10 yards (was 45)'),
(19716, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 13, -1, -1, -1, -1, 'Vanilla Bonk: Gehennas'' Curse 10 yards (was 45)')
ON DUPLICATE KEY UPDATE `EffectRadiusIndex` = VALUES(`EffectRadiusIndex`);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
