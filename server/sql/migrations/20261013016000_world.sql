DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013016000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013016000');

CREATE TABLE IF NOT EXISTS `bonk_keyword` (
    `id`               TINYINT UNSIGNED NOT NULL COMMENT 'BonkKeyword',
    `name`             VARCHAR(32)      NOT NULL,
    `icon`             VARCHAR(64)      NOT NULL DEFAULT '' COMMENT 'Interface\\Icons texture, for the results screen',
    `spell_id`         INT UNSIGNED     NOT NULL COMMENT 'the debuff that carries it',
    `max_stacks`       TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `value_per_stack`  FLOAT            NOT NULL DEFAULT 0 COMMENT '% slower or more damage taken; damage over time: share of a same-level enemy''s health a second',
    `tick_ms`          INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'damage over time: how often it ticks before Haste',
    `duration_ms`      INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'how long it stays after it was last applied',
    `spreads_on_death` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'half its stacks go to the 2 nearest enemies within 8 yards',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk keywords: shared debuffs with stacks';

DELETE FROM `bonk_keyword`;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`) VALUES
( 1, 'Chill',                'Spell_Frost_IceStorm',       12485,  5, 10,     0,  4000, 0),
( 2, 'Frozen',               'Spell_Frost_Glacier',        18798,  1,  0,     0,  2000, 0),
( 3, 'Burning',              'Spell_Fire_Incinerate',      12654, 10,  0.033, 1000,  6000, 1),
( 4, 'Bleed',                'Ability_BackStab',           12721, 10,  0.033, 1000,  6000, 1),
( 5, 'Poison',               'Spell_Nature_CorrosiveBreath', 19448, 10, 0.033, 1000, 6000, 1),
( 6, 'Fire Vulnerability',   'Spell_Fire_SoulBurn',        22959,  5,  3,     0, 15000, 0),
( 7, 'Sunder Armor',         'Ability_Warrior_Sunder',     27991,  5,  4,     0, 15000, 0),
( 8, 'Shadow Vulnerability', 'Spell_Shadow_BlackPlague',   15258,  5,  3,     0, 15000, 0),
( 9, 'Hunter''s Mark',       'Ability_Hunter_SniperShot',  20374,  1, 15,     0,  8000, 0),
(10, 'Dazed',                'Spell_Frost_Stun',           13496,  1, 30,     0,  4000, 0);

ALTER TABLE `bonk_weapon`
    ADD COLUMN `applies`      TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'BonkKeyword put on every enemy each hit or tick strikes' AFTER `flags`,
    ADD COLUMN `apply_stacks` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'stacks of it per hit or tick' AFTER `applies`,
    ADD COLUMN `uses`         TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'BonkKeyword it pays off, 255 = every different keyword on the enemy' AFTER `apply_stacks`,
    ADD COLUMN `uses_pct`     FLOAT            NOT NULL DEFAULT 0 COMMENT '% more damage for each stack (or keyword) of it on the enemy' AFTER `uses`;

DELETE FROM `spell_effect_mod` WHERE `Id` = 18798 AND `EffectIndex` = 0;
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectDieSides`, `EffectBaseDice`, `EffectDicePerLevel`, `EffectRealPointsPerLevel`, `EffectBasePoints`, `EffectAmplitude`, `EffectPointsPerComboPoint`, `EffectChainTarget`, `EffectMultipleValue`, `EffectMechanic`, `EffectImplicitTargetA`, `EffectImplicitTargetB`, `EffectRadiusIndex`, `EffectApplyAuraName`, `EffectItemType`, `EffectMiscValue`, `EffectTriggerSpell`, `Comment`) VALUES
(18798, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, -1, 26, -1, -1, -1, 'Vanilla Bonk: Frozen keyword holds in place (root, not stun)');

DELETE FROM `spell_effect_mod` WHERE `Id` = 27991 AND `EffectIndex` = 0;
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectDieSides`, `EffectBaseDice`, `EffectDicePerLevel`, `EffectRealPointsPerLevel`, `EffectBasePoints`, `EffectAmplitude`, `EffectPointsPerComboPoint`, `EffectChainTarget`, `EffectMultipleValue`, `EffectMechanic`, `EffectImplicitTargetA`, `EffectImplicitTargetB`, `EffectRadiusIndex`, `EffectApplyAuraName`, `EffectItemType`, `EffectMiscValue`, `EffectTriggerSpell`, `Comment`) VALUES
(27991, 0, -1, -1, -1, -1, 0, -1, -1, -1, -1, -1, -1, -1, -1, -1, 87, -1, 1, -1, 'Vanilla Bonk: Sunder Armor keyword, +% Physical damage taken');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
