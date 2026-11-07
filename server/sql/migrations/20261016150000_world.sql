DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016150000');

DELETE FROM `spell_effect_mod` WHERE `Id` IN (8292, 6254, 15549, 23979) AND `EffectIndex` = 0;
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectDieSides`, `EffectBaseDice`, `EffectDicePerLevel`, `EffectRealPointsPerLevel`,
    `EffectBasePoints`, `EffectAmplitude`, `EffectPointsPerComboPoint`, `EffectChainTarget`, `EffectMultipleValue`, `EffectMechanic`,
    `EffectImplicitTargetA`, `EffectImplicitTargetB`, `EffectRadiusIndex`, `EffectApplyAuraName`, `EffectItemType`, `EffectMiscValue`,
    `EffectTriggerSpell`, `Comment`) VALUES
(8292,  0, 2, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 'Vanilla Bonk: Chain Bolt hits one target'),
(6254,  0, 2, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 'Vanilla Bonk: Chained Bolt hits one target'),
(15549, 0, 2, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 'Vanilla Bonk: Chained Bolt hits one target'),
(23979, 0, 2, -1, -1, -1, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 'Vanilla Bonk: Holy Wrath hits one target');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
