DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015210000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (108, 138, 206, 212, 213, 214, 215, 216);
DELETE FROM `bonk_weapon` WHERE `id` IN (108, 138, 206, 212, 213, 214, 215, 216);

UPDATE `bonk_weapon` SET `spell_id` = 3044, `target` = 0, `cooldown_ms` = 1500, `range` = 35, `damage_fraction` = 1.1,
    `class_mask` = 4, `starter_class_mask` = 4, `evolves_from` = 0, `duration_ms` = 0, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 0, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 0, `uses_pct` = 0,
    `description` = 'An instant shot that deals Arcane damage to the nearest enemy.'
WHERE `id` = 7;

UPDATE `bonk_weapon` SET `spell_id` = 2643, `target` = 6, `cooldown_ms` = 2500, `range` = 25, `damage_fraction` = 0.7,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 0, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 0, `base_targets` = 5, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 0, `uses_pct` = 0,
    `description` = 'Fires 5 arrows in a cone in front of you.'
WHERE `id` = 37;

UPDATE `bonk_weapon` SET `spell_id` = 19434, `target` = 8, `cooldown_ms` = 3000, `range` = 35, `damage_fraction` = 1.5,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 0, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 0, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 0, `uses_pct` = 0,
    `description` = 'A powerful aimed shot that passes through every enemy in a line toward the Marked group or the largest group.'
WHERE `id` = 203;

UPDATE `bonk_weapon` SET `spell_id` = 22908, `target` = 3, `cooldown_ms` = 6000, `range` = 20, `damage_fraction` = 0.4,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 3000, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 1000, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 255, `uses_pct` = 5,
    `description` = 'Rains arrows on the largest group of enemies for 3 sec. Deals 5% more damage for each different debuff on the target.'
WHERE `id` = 137;

UPDATE `bonk_weapon` SET `spell_id` = 1978, `target` = 0, `cooldown_ms` = 1200, `range` = 30, `damage_fraction` = 0,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 0, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 0, `base_targets` = 1, `base_jumps` = 2, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 5, `apply_stacks` = 1, `uses` = 0, `uses_pct` = 0,
    `description` = 'Stings the nearest enemy and 2 enemies near it, applying a stack of Poison to each.'
WHERE `id` = 38;

UPDATE `bonk_weapon` SET `spell_id` = 13812, `target` = 3, `cooldown_ms` = 5000, `range` = 6, `damage_fraction` = 0.8,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 4000, `chains` = 0, `behavior` = 19, `behavior_value` = 900009,
    `tick_ms` = 1000, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 3, `apply_stacks` = 1, `uses` = 0, `uses_pct` = 0,
    `description` = 'Throws a fire trap at the largest group of enemies. It explodes and burns the ground for 4 sec, applying Burning.'
WHERE `id` = 202;

UPDATE `bonk_weapon` SET `spell_id` = 13810, `target` = 3, `cooldown_ms` = 7000, `range` = 6, `damage_fraction` = 0.15,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 6000, `chains` = 0, `behavior` = 19, `behavior_value` = 900010,
    `tick_ms` = 1000, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 1, `apply_stacks` = 1, `uses` = 0, `uses_pct` = 0,
    `description` = 'Throws a frost trap that freezes the ground under the largest group for 6 sec, dealing Frost damage and applying Chill.'
WHERE `id` = 204;

UPDATE `bonk_weapon` SET `spell_id` = 1543, `target` = 3, `cooldown_ms` = 6000, `range` = 20, `damage_fraction` = 0,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 8000, `chains` = 0, `behavior` = 0, `behavior_value` = 0,
    `tick_ms` = 0, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 9, `apply_stacks` = 1, `uses` = 0, `uses_pct` = 0,
    `description` = 'Fires a flare at the largest group of enemies, marking those within 10 yards for 8 sec. Marked enemies take 15% more damage.'
WHERE `id` = 205;

UPDATE `bonk_weapon` SET `spell_id` = 883, `target` = 7, `cooldown_ms` = 3000, `range` = 0, `damage_fraction` = 0.6,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 0, `chains` = 0, `behavior` = 20, `behavior_value` = 1,
    `tick_ms` = 1500, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 0, `uses_pct` = 0,
    `description` = 'Summons your cat to fight for you. Its bites apply Bleed.'
WHERE `id` = 201;

UPDATE `bonk_weapon` SET `spell_id` = 19574, `target` = 7, `cooldown_ms` = 15000, `range` = 30, `damage_fraction` = 1.5,
    `class_mask` = 4, `starter_class_mask` = 0, `evolves_from` = 0, `duration_ms` = 6000, `chains` = 0, `behavior` = 21, `behavior_value` = 900115,
    `tick_ms` = 0, `base_targets` = 1, `base_jumps` = 0, `alt_spell_id` = 0, `alt_every` = 0, `alt_damage` = 1, `flags` = 0,
    `applies` = 0, `apply_stacks` = 0, `uses` = 0, `uses_pct` = 0,
    `description` = 'Every 15 sec, a spectral beast leaps into the largest group of enemies and roars. Your pet frenzies for 6 sec.'
WHERE `id` = 211;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (7, 37, 38, 137, 201, 202, 203, 204, 205, 211);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(7,   1, 10), (7,   2, 10), (7,   3, 8),
(37,  1, 10), (37,  2, 10), (37,  3, 8),
(203, 2, 10), (203, 3, 8),
(137, 5, 15), (137, 2, 10), (137, 3, 8),
(38,  9, 1),  (38,  5, 15), (38,  3, 8),
(202, 5, 15), (202, 9, 1),  (202, 3, 8),
(204, 5, 15), (204, 9, 1),  (204, 3, 8),
(205, 5, 15), (205, 6, 3),  (205, 3, 8),
(201, 7, 15), (201, 8, 10),
(211, 7, 15), (211, 8, 10);
ALTER TABLE `bonk_weapon_upgrade` MODIFY `upgrade` TINYINT UNSIGNED NOT NULL
    COMMENT 'BonkSpellUpgrade: 1 spell cleave, 2 hit twice, 3 Haste, 4 retired (radius), 5 duration, 6 Mark strength, 7 summon damage, 8 summon size, 9 +1 stack applied';

UPDATE `bonk_keyword` SET `value_per_stack` = 0.1, `max_stacks` = 255 WHERE `id` IN (3, 4, 5);

DELETE FROM `creature_template` WHERE `entry` = 900115;
DROP TEMPORARY TABLE IF EXISTS `bonk_beast`;
CREATE TEMPORARY TABLE `bonk_beast` AS SELECT * FROM `creature_template` WHERE `entry` = 900114;
UPDATE `bonk_beast` SET `entry` = 900115, `name` = 'Spectral Beast', `display_id1` = 4613, `display_scale1` = 0.8;
INSERT INTO `creature_template` SELECT * FROM `bonk_beast`;
DROP TEMPORARY TABLE `bonk_beast`;

DELETE FROM `spell_effect_mod` WHERE `Id` IN (1978, 13810, 1543, 19574);
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `EffectBasePoints`, `Comment`) VALUES
(1978,  0, 3,  0,  -1, 'Vanilla Bonk: Serpent Sting is only its look'),
(13810, 0, -1, 4,  -1, 'Vanilla Bonk: Frost Trap field without its slow'),
(13810, 1, -1, 4,  -1, 'Vanilla Bonk: Frost Trap field without its slow'),
(1543,  0, -1, 4,  -1, 'Vanilla Bonk: the flare only shows'),
(1543,  1, -1, 4,  -1, 'Vanilla Bonk: the flare only shows'),
(19574, 0, -1, 4,  -1, 'Vanilla Bonk: the run sets frenzied pets'' size'),
(19574, 1, -1, 4,  -1, 'Vanilla Bonk: frenzy damage is the run''s'),
(19574, 2, -1, 4,  -1, 'Vanilla Bonk: frenzy grants no immunity');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
