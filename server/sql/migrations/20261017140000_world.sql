DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017140000');

DELETE FROM `spell_effect_mod` WHERE `Id` IN (116, 205, 122, 133, 11366, 26607);
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `EffectBasePoints`, `Comment`) VALUES
(116,   0, 0, 0, -1, 'Vanilla Bonk: Frostbolt slows through Chill, not its own slow'),
(205,   0, 0, 0, -1, 'Vanilla Bonk: the Water Elemental''s Frostbolt slows through Chill'),
(122,   1, 0, 0, -1, 'Vanilla Bonk: Frost Nova chills instead of rooting'),
(133,   1, 0, 0, -1, 'Vanilla Bonk: Fireball burns through Burning, not its own damage over time'),
(11366, 1, 0, 0, -1, 'Vanilla Bonk: Pyroblast leaves no damage over time'),
(26607, 1, 0, 0, -1, 'Vanilla Bonk: Blizzard slows through Chill, not its own slow');

DELETE FROM `creature_template` WHERE `entry` IN (900125, 900126, 900127);
DROP TEMPORARY TABLE IF EXISTS `bonk_elemental`;
CREATE TEMPORARY TABLE `bonk_elemental` AS SELECT * FROM `creature_template` WHERE `entry` = 900114;
UPDATE `bonk_elemental` SET `entry` = 900125, `name` = 'Water Elemental', `display_id1` = 525, `display_scale1` = 1, `type` = 4, `pet_family` = 0, `damage_school` = 4;
INSERT INTO `creature_template` SELECT * FROM `bonk_elemental`;
UPDATE `bonk_elemental` SET `entry` = 900126, `name` = 'Fire Elemental', `display_id1` = 1405, `damage_school` = 2;
INSERT INTO `creature_template` SELECT * FROM `bonk_elemental`;
UPDATE `bonk_elemental` SET `entry` = 900127, `name` = 'Arcane Elemental', `display_id1` = 14253, `damage_school` = 6;
INSERT INTO `creature_template` SELECT * FROM `bonk_elemental`;
DROP TEMPORARY TABLE `bonk_elemental`;

DELETE FROM `bonk_pet_ability` WHERE `family` IN (2, 3, 4);
DELETE FROM `bonk_pet_family` WHERE `id` IN (2, 3, 4);
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`) VALUES
(2, 'Water Elemental', 900125, 0.6, 1500, 1, 1),
(3, 'Fire Elemental', 900126, 0.6, 1500, 3, 1),
(4, 'Arcane Elemental', 900127, 0.7, 1500, 0, 0);
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `comment`) VALUES
(2, 205,   0, 3000, 2, 1, 20, 'Water Elemental: Frostbolt from 20 yd, 2 bites worth, 1 Chill'),
(3, 9487,  0, 3000, 2, 2, 20, 'Fire Elemental: Fireball from 20 yd, 2 bites worth, 2 Burning'),
(4, 13901, 0, 2500, 3, 0, 20, 'Arcane Elemental: Arcane Bolt from 20 yd, 3 bites worth');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 400 AND 449;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 400 AND 449;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(400, 'Frostbolt', 'Spell_Frost_FrostBolt02', 'Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more damage to Frozen enemies. Your Frost spells always critically strike Frozen enemies.', 116, 0, 1500, 30, 1, 128, 128, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 50),
(401, 'Blizzard', 'Spell_Frost_IceStorm', 'Ice shards pelt the largest group of enemies for 4 sec, dealing Frost damage and applying 1 stack of Chill every sec.', 26607, 3, 5000, 20, 0.3, 128, 0, 0, 0, 4000, 0, 0, 0, 1000, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
(402, 'Frost Nova', 'Spell_Frost_FrostNova', 'Blasts all enemies within 10 yards of you with frost, dealing Frost damage and applying 3 stacks of Chill.', 122, 1, 4000, 10, 0.6, 128, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 3, 0, 0),
(403, 'Fireball', 'Spell_Fire_FlameBolt', 'Hurls a fiery ball at the nearest enemy, dealing Fire damage and applying 2 stacks of Burning.', 133, 0, 2000, 35, 0.9, 128, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(404, 'Flamestrike', 'Spell_Fire_SelfDestruct', 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 2 stacks of Burning.', 2120, 3, 5000, 20, 0.8, 128, 0, 0, 0, 1500, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(405, 'Pyroblast', 'Spell_Fire_Fireball02', 'Hurls a huge fireball at an elite or boss, otherwise at the largest group of enemies, dealing heavy Fire damage to the target and 35% of it to all other enemies within 6 yards.', 11366, 0, 8000, 35, 4, 128, 0, 0, 0, 0, 0, 55, 0, 0, 1, 0, 0, 0.35, 0, 0, 0, 0, 0, 0, 0),
(406, 'Fire Blast', 'Spell_Fire_Fireball', 'Blasts the 3 enemies with the most stacks of Burning, dealing Fire damage. Deals 10% more damage for each stack of Burning on the target, counting up to 30 stacks.', 2136, 0, 3000, 30, 0.8, 128, 0, 0, 0, 0, 0, 56, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 3, 10),
(407, 'Blink', 'Spell_Arcane_Blink', 'Your dash becomes Blink: it gains 1 charge and recharges 30% faster. Each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to all enemies within 10 yards.', 8437, 1, 1000, 10, 1, 128, 0, 0, 0, 0, 0, 54, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(408, 'Arcane Explosion', 'Spell_Nature_WispSplode', 'Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. It also goes off where you land after each Blink.', 1449, 1, 2500, 10, 0.7, 128, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 4194304, 0, 0, 0, 0),
(409, 'Arcane Missiles', 'Spell_Nature_StarFall', 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once at the nearest enemies.', 7268, 0, 2500, 30, 0.3, 128, 0, 0, 0, 0, 0, 57, 5, 0, 1, 0, 0, 1, 0, 0, 4194304, 0, 0, 0, 0),
(410, 'Summon Elemental', 'Spell_Frost_SummonWaterElemental', 'Summons an elemental to fight for you, following the school most of your spells belong to: Frost a Water Elemental that applies Chill, Fire a Fire Elemental that applies Burning, Arcane an Arcane Elemental.', 17162, 7, 3000, 0, 1.2, 128, 0, 0, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(400, 1, 10), (400, 9, 1), (400, 2, 10), (400, 3, 8),
(401, 5, 15), (401, 9, 1), (401, 3, 8),
(402, 9, 1), (402, 2, 10), (402, 3, 8),
(403, 1, 10), (403, 9, 1), (403, 2, 10), (403, 3, 8),
(404, 5, 15), (404, 9, 1), (404, 2, 10), (404, 3, 8),
(405, 2, 10), (405, 3, 8),
(406, 1, 10), (406, 2, 10), (406, 3, 8),
(407, 2, 10), (407, 3, 8),
(408, 2, 10), (408, 3, 8),
(409, 1, 10), (409, 2, 10), (409, 3, 8),
(410, 7, 15), (410, 8, 10), (410, 3, 8);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
