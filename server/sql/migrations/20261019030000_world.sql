DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019030000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019030000');

DELETE FROM `bonk_keyword` WHERE `id` = 13;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(13, 'Decay', 'Spell_Shadow_ChillTouch', 594, 30, 0.1, 1000, 6000, 1,
 'Each stack deals Shadow damage every sec. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a decaying enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards.');
UPDATE `bonk_keyword` SET `description` = 'Increases Shadow damage taken by 3% per stack. Stacks up to 5 times.' WHERE `id` = 8;

DELETE FROM `spell_effect_mod` WHERE (`Id` = 17 AND `EffectIndex` = 0) OR (`Id` = 139 AND `EffectIndex` = 0) OR (`Id` = 15261 AND `EffectIndex` = 1);
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `EffectApplyAuraName`, `Comment`) VALUES
(17, 0, 4, 'Power Word: Shield: the look only, the server shields'),
(139, 0, 4, 'Renew: the look only, the server heals');
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `Comment`) VALUES
(15261, 1, 0, 0, 'Holy Word: Chastise: no Holy Fire burn');

DELETE FROM `creature_template` WHERE `entry` = 900134;
DROP TEMPORARY TABLE IF EXISTS `bonk_priest_pet`;
CREATE TEMPORARY TABLE `bonk_priest_pet` SELECT * FROM `creature_template` WHERE `entry` = 900130;
UPDATE `bonk_priest_pet` SET `entry` = 900134, `name` = 'Shadowfiend', `display_id1` = 15547, `display_scale1` = 0.6;
INSERT INTO `creature_template` SELECT * FROM `bonk_priest_pet`;
DROP TEMPORARY TABLE `bonk_priest_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` = 11;
DELETE FROM `bonk_pet_family` WHERE `id` = 11;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(11, 'Shadowfiend', 900134, 0.6, 1500, 13, 1, '');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 500 AND 511;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 500 AND 511;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(500, 'Smite', 'Spell_Holy_HolySmite', 'Smites the nearest enemy with Holy damage. Each Smite takes 1 sec off Holy Word: Chastise.',
    585, 0, 1500, 30, 1.0, 16, 16, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 502),
(501, 'Renew', 'Spell_Holy_Renew', 'Heals you for 1% of your maximum health every second. While you are at full health, each tick instead smites the nearest enemy within 30 yards for Holy damage.',
    139, 7, 1000, 30, 0.5, 16, 0, 0, 0, 1.0, 0, 0, 84, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 502),
(502, 'Halo', 'Spell_Holy_PrayerOfHealing02', 'A ring of light deals Holy damage to every enemy between 8 and 25 yards from you, and heals you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 8 yards are not hit.',
    15237, 1, 8000, 25, 0.9, 16, 0, 0, 0, 0, 0, 0, 85, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 502),
(503, 'Holy Word: Chastise', 'Spell_Holy_Excorcism_02', 'The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage. Smite and Halo take 1 sec off its cooldown each time they are cast.',
    15261, 4, 20000, 30, 4.0, 16, 0, 0, 0, 0, 0, 0, 86, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 502),
(504, 'Power Word: Shield', 'Spell_Holy_PowerWordShield', 'Shields you for 10% of your maximum health. The Shield does not build up; each cast tops it back up. While you have a Shield, you move 10% faster.',
    17, 7, 12000, 0, 0, 16, 0, 16, 0, 0, 0, 0, 87, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 501),
(505, 'Penance', 'Spell_Holy_HolyBolt', 'Fires 3 holy bolts at the enemies that struck you most recently, or the nearest enemies when nobody has. Each bolt heals you for 0.5% of your maximum health; healing past full health becomes Shield.',
    591, 0, 5000, 30, 0.6, 16, 0, 0, 0, 0, 0, 0, 88, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 501),
(506, 'Psychic Scream', 'Spell_Shadow_PsychicScream', 'Normal enemies within 8 yards flee in fear for 2 seconds. Elites, mini-bosses and bosses do not flee.',
    8122, 1, 15000, 8, 0, 16, 0, 0, 0, 0, 0, 0, 89, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 501),
(507, 'Shackle', 'Spell_Nature_Slow', 'Binds the strongest enemy nearby, elites first, in chains of light for 2 seconds and deals Holy damage to it. Bosses and mini-bosses cannot be bound but still take the damage.',
    9484, 4, 8000, 30, 1.2, 16, 0, 0, 0, 0, 0, 0, 90, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 501),
(508, 'Shadow Word: Pain', 'Spell_Shadow_ShadowWordPain', 'Afflicts the 3 enemies farthest from you within 35 yards, applying 4 stacks of Decay.',
    589, 5, 2000, 35, 0, 16, 0, 16, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 32768, 13, 4, 0, 0, 503),
(509, 'Mind Flay', 'Spell_Shadow_SiphonMana', 'Flays the mind of the nearest enemy every 0.5 seconds, dealing Shadow damage, applying 1 stack of Decay and slowing it by 30%. It keeps flaying the same enemy until it dies or gets out of 20 yards.',
    15407, 0, 500, 20, 0.25, 16, 0, 0, 0, 0, 0, 0, 91, 0, 0, 1, 0, 0, 1, 0, 0, 0, 13, 1, 0, 0, 503),
(510, 'Mind Blast', 'Spell_Shadow_UnholyFrenzy', 'Blasts the enemy with the most stacks of Decay for Shadow damage, and its mind shatters: every enemy within 8 yards of it gains as many stacks of Decay as it has, up to 10.',
    8092, 0, 6000, 30, 1.5, 16, 0, 0, 0, 0, 0, 0, 92, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 503),
(511, 'Shadowfiend', 'Spell_Shadow_GatherShadows', 'Summons a Shadowfiend whose attacks apply Decay and heal you for 0.5% of your maximum health.',
    2944, 7, 3000, 0, 1.2, 16, 0, 0, 0, 0.5, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 503);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(500, 1, 10), (500, 2, 10), (500, 3, 8),
(501, 3, 8),
(502, 3, 8), (502, 16, 1),
(503, 2, 10), (503, 3, 8),
(504, 3, 8), (504, 14, 15),
(505, 3, 8),
(506, 3, 8), (506, 5, 15),
(507, 3, 8),
(508, 3, 8), (508, 5, 15), (508, 9, 1),
(509, 3, 8),
(510, 3, 8),
(511, 3, 8), (511, 7, 15), (511, 8, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
