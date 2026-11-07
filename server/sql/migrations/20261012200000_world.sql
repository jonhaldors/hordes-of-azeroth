DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012200000');

ALTER TABLE `bonk_weapon`
    ADD COLUMN `base_jumps` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'pierces, bounces or cleaved enemies before ranks' AFTER `alt_damage`,
    ADD COLUMN `kill_below_pct` FLOAT NOT NULL DEFAULT 0 COMMENT 'normal enemies below this % health die to a hit' AFTER `base_jumps`,
    ADD COLUMN `flags` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'BonkWeaponFlags' AFTER `kill_below_pct`;

UPDATE `bonk_weapon` SET `class_mask` = 2 WHERE `id` = 2;
UPDATE `bonk_weapon` SET `class_mask` = 8 WHERE `id` = 8;
UPDATE `bonk_weapon` SET `class_mask` = 8 WHERE `id` = 26;

UPDATE `bonk_weapon` SET `description` = 'Thunder Clap, and a moment later a shockwave that stuns the enemies around you.',
    `spell_id` = 8078, `target` = 1, `cooldown_ms` = 2500, `range` = 10, `damage_fraction` = 0.55,
    `behavior` = 6, `behavior_value` = 300, `alt_spell_id` = 25425, `alt_every` = 0, `alt_damage` = 0.5
WHERE `id` = 106;

UPDATE `bonk_weapon` SET `name` = 'Execute', `icon` = 'Ability_Warrior_DecisiveStrike',
    `description` = 'Cleaves; normal enemies it hits below 20% health die at once.',
    `damage_fraction` = 0.6, `behavior_value` = 0.8, `kill_below_pct` = 20, `flags` = 32, `alt_spell_id` = 20647
WHERE `id` = 130;

UPDATE `bonk_weapon` SET `description` = 'You spin for a moment, striking every enemy around you again and again.',
    `cooldown_ms` = 4000, `damage_fraction` = 0.25, `behavior` = 12, `behavior_value` = 500, `duration_ms` = 1500
WHERE `id` = 31;
UPDATE `bonk_weapon` SET `description` = 'A spin that never stops and goes where you go.',
    `cooldown_ms` = 2000, `damage_fraction` = 0.22, `behavior` = 12, `behavior_value` = 500, `duration_ms` = 1500
WHERE `id` = 131;

UPDATE `bonk_weapon` SET `description` = 'Makes 3 nearby enemies bleed.', `base_targets` = 3, `behavior` = 0, `behavior_value` = 0
WHERE `id` = 32;
UPDATE `bonk_weapon` SET `name` = 'Bloodthirst', `icon` = 'Spell_Nature_BloodLust',
    `description` = 'Makes 3 nearby enemies bleed; 10% of the bleeding heals you.',
    `spell_id` = 13318, `target` = 2, `cooldown_ms` = 1300, `range` = 10, `damage_fraction` = 0.3, `duration_ms` = 9000,
    `base_targets` = 3, `behavior` = 13, `behavior_value` = 10
WHERE `id` = 132;

UPDATE `bonk_weapon` SET `name` = 'Mortal Strike', `icon` = 'Ability_Warrior_SavageBlow',
    `description` = 'A heavy strike at the strongest enemy in reach, elites first.',
    `spell_id` = 17547, `target` = 4, `cooldown_ms` = 3000, `range` = 8, `damage_fraction` = 1.3, `heal_pct` = 0
WHERE `id` = 33;
UPDATE `bonk_weapon` SET `name` = 'Colossus Smash', `icon` = 'Ability_Warrior_Sunder',
    `description` = 'Heavy strikes at the strongest enemy in reach; it takes 20% more damage from everything for 5 seconds.',
    `spell_id` = 17547, `target` = 4, `cooldown_ms` = 2500, `range` = 8, `damage_fraction` = 1.4, `heal_pct` = 0,
    `duration_ms` = 5000, `behavior` = 14, `behavior_value` = 20
WHERE `id` = 133;

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`,
    `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`) VALUES
(180, 'Heroic Throw',       'INV_ThrowingAxe_01',            'Throws an axe at the farthest enemy in range.',
    16075, 5,  2500, 30, 0.8,  1, 0,   0, 0,    0, 0,  0,  0,    0, 1,     0, 0, 1,   0,  0,  0),
(181, 'Demoralizing Shout', 'Ability_Warrior_WarCry',        'A shout at the enemies around you: they deal 20% less damage.',
    1160,  1,  4000, 10, 0.5,  1, 0,   0, 0, 6000, 0, 15, 20,    0, 1,     0, 0, 1,   0,  0,  0),
(182, 'Battle Shout',       'Ability_Warrior_BattleShout',   'Every 12 seconds, a shout that gives you 20% more Power for 6 seconds.',
    6673,  7, 12000,  0, 0.5,  1, 0,   0, 0, 6000, 0, 16, 20,    0, 1,     0, 0, 1,   0,  0,  0),
(183, 'Revenge',            'Ability_Warrior_Revenge',       'Gives 5% Dodge; when you dodge, you strike back at every enemy around you.',
    13446, 1,  1000,  8, 0.8,  1, 0,   0, 0,    0, 0, 17,  5,    0, 1,     0, 0, 1,   0,  0,  0),
(184, 'Hamstring',          'Ability_ShockWave',             'Strikes the legs of the nearest enemy in reach, slowing it.',
    26141, 0,  1500,  6, 0.35, 1, 0,   0, 0,    0, 0,  0,  0,    0, 1,     0, 0, 1,   0,  0,  0),
(190, 'Thunderous Throw',   'INV_ThrowingAxe_02',            'Throws an axe at the farthest enemy in range; it bounces on to 4 enemies near it.',
    16075, 5,  2200, 30, 0.9,  0, 0, 180, 0,    0, 0,  0,  0,    0, 1,     0, 0, 1,   4,  0,  0),
(191, 'Rallying Cry',       'Spell_Holy_BlessingOfStrength', 'A shout at the enemies around you: they deal 25% less damage, and you heal 3% of your health.',
    1160,  1,  4000, 10, 0.5,  0, 0, 181, 3, 6000, 0, 15, 25,    0, 1,     0, 0, 1,   0,  0,  0),
(192, 'Recklessness',       'Ability_CriticalStrike',        'Battle Shout, and while it lasts every hit you deal crits.',
    6673,  7, 12000,  0, 0.5,  0, 0, 182, 0, 6000, 0, 16, 20,    0, 1,     0, 0, 1,   0,  0,  2),
(193, 'Retaliation',        'Ability_Warrior_Challange',     'Revenge, and for 5 seconds after a dodge every enemy that hits you is struck back.',
    13446, 1,   800,  8, 0.9,  0, 0, 183, 0, 5000, 0, 17,  5,    0, 1,     0, 0, 1,   0,  0,  0),
(194, 'Piercing Howl',      'Spell_Shadow_DeathScream',      'Leg strikes, and every third one a howl that slows every enemy around you.',
    26141, 0,  1200,  6, 0.4,  0, 0, 184, 0,    0, 0,  0,  0,    0, 1, 12323, 3, 1,   0,  0,  0);

UPDATE `bonk_weapon` SET `description` = 'A quick arcane arrow at the nearest enemy that hits 1 more enemy behind it.', `base_jumps` = 1
WHERE `id` = 7;
UPDATE `bonk_weapon` SET `name` = 'Chimera Shot', `icon` = 'Ability_Hunter_SwiftStrike',
    `description` = 'Arcane arrows that always crit, hit 1 more enemy, and renew your stings on what they hit.',
    `spell_id` = 3044, `target` = 0, `cooldown_ms` = 1500, `range` = 35, `damage_fraction` = 0.55, `base_jumps` = 1, `flags` = 6
WHERE `id` = 108;

UPDATE `bonk_weapon` SET `name` = 'Volley', `icon` = 'Ability_Marksmanship',
    `description` = 'Arrows rain down on the biggest pack of enemies.',
    `spell_id` = 22908, `target` = 3, `cooldown_ms` = 5000, `range` = 35, `damage_fraction` = 0.3, `duration_ms` = 6000, `chains` = 0
WHERE `id` = 137;

UPDATE `bonk_weapon` SET `description` = 'Poisons 3 nearby enemies.', `base_targets` = 3, `behavior` = 0, `behavior_value` = 0
WHERE `id` = 38;
UPDATE `bonk_weapon` SET `name` = 'Serpent Spread',
    `description` = 'Poisons 3 nearby enemies; when one dies, the poison jumps to the nearest enemy.',
    `spell_id` = (SELECT `spell_id` FROM (SELECT `spell_id` FROM `bonk_weapon` WHERE `id` = 38) AS `sting`),
    `base_targets` = 3, `behavior` = 2, `behavior_value` = 1
WHERE `id` = 138;

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`,
    `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`) VALUES
(200, 'Auto Shot',          'Ability_Whirlwind',             'Quick arrows at the nearest enemy.',
    6660,  0,   900, 35, 0.3,  4, 0,   0, 0,    0, 0,  0,      0,    0, 1,     0, 0, 1,   0,  0,  0),
(201, 'Call Pet',           'Ability_Hunter_BeastCall',      'Calls a wolf that hunts the enemies near you.',
    883,   7,  3000,  0, 0.4,  4, 0,   0, 0,    0, 0, 20,      1, 1500, 1,     0, 0, 1,   0,  0,  0),
(202, 'Explosive Trap',     'Spell_Fire_SelfDestruct',       'Drops a trap at your feet; when an enemy steps on it, it explodes and leaves the ground burning.',
    13812, 7,  5000,  5, 0.8,  4, 0,   0, 0, 6000, 0, 19, 900009,  0, 1,     0, 0, 1,   0,  0,  0),
(203, 'Aimed Shot',         'INV_Spear_07',                  'A slow, heavy shot at the strongest enemy in range.',
    19434, 4,  3000, 35, 1.4,  4, 0,   0, 0,    0, 0,  0,      0,    0, 1,     0, 0, 1,   0,  0,  0),
(204, 'Frost Trap',         'Spell_Frost_FreezingBreath',    'Drops a trap at your feet; when an enemy steps on it, it bursts into a patch of ice that slows.',
    12737, 7,  6000,  6, 0.4,  4, 0,   0, 0, 8000, 0, 19, 900010,  0, 1, 13810, 0, 1,   0,  0,  0),
(205, 'Hunter''s Mark',     'Ability_Hunter_SniperShot',     'Marks the strongest enemy in range: it takes 20% more damage from everything.',
    14325, 4,  4000, 40, 0.5,  4, 0,   0, 0, 8000, 0, 14,     20,    0, 1,     0, 0, 1,   0,  0,  0),
(206, 'Scatter Shot',       'Ability_GolemStormBolt',        'A spray of shots at the enemies in front of you that knocks them back.',
    19503, 6,  4000, 20, 0.5,  4, 0,   0, 0, 1000, 0,  0,      0,    0, 1,     0, 0, 1,   0,  0,  8),
(210, 'Rapid Fire',         'Ability_Hunter_RunningShot',    'Bursts of three quick arrows at the nearest enemy.',
    6660,  0,   900, 35, 0.3,  0, 0, 200, 0,    0, 0, 18,      2,    0, 1,     0, 0, 1,   0,  0,  0),
(211, 'Bestial Wrath',      'Ability_Druid_FerociousBite',   'Your beasts grow and frenzy: bigger, quicker and harder-biting.',
    883,   7,  3000,  0, 0.5,  0, 0, 201, 0,    0, 0, 20,    1.5, 1200, 1, 19574, 0, 1,   0,  0,  0),
(212, 'Trap Launcher',      'INV_Misc_Bomb_05',              'Fires explosive traps into the biggest pack of enemies; they go off there and leave the ground burning.',
    13812, 3,  4000, 30, 0.8,  0, 0, 202, 0, 6000, 0,  0,      0,    0, 1,     0, 0, 1,   0,  0,  0),
(213, 'Kill Shot',          'Ability_PierceDamage',          'Heavy shots; normal enemies below 25% health die at once, and a kill readies it again.',
    19434, 4,  2500, 35, 1.5,  0, 0, 203, 0,    0, 0,  0,      0,    0, 1,     0, 0, 1,   0, 25,  1),
(214, 'Freezing Trap',      'Spell_Frost_ChainsOfIce',       'Drops a trap at your feet; when an enemy steps on it, every enemy near freezes for 2 seconds.',
    12737, 7,  6000,  6, 0.5,  0, 0, 204, 0, 2000, 0, 19, 900011,  0, 1, 12494, 0, 1,   0,  0,  0),
(215, 'Marked for Death',   'Spell_Shadow_UnholyFrenzy',     'Marks the strongest enemy: it takes 25% more damage, explodes when it dies, and the mark moves on.',
    14325, 4,  4000, 40, 0.8,  0, 0, 205, 0, 8000, 0, 14,     25,    0, 1, 12354, 0, 1,   0,  0, 16),
(216, 'Concussive Barrage', 'Spell_Frost_Stun',              'Shots at the enemies in front of you that knock them back; they are slowed and take 20% more damage for 4 seconds.',
    19503, 6,  3500, 20, 0.6,  0, 0, 206, 0, 4000, 0, 14,     20,    0, 1,  5116, 0, 1,   0,  0,  8);

UPDATE `bonk_mastery` SET `name` = 'Improved Mortal Strike', `description` = '+5% Mortal Strike damage.' WHERE `id` = 10201;
UPDATE `bonk_mastery` SET `name` = 'Blood Craze', `description` = 'Mortal Strike recharges 6% faster.' WHERE `id` = 10204;
UPDATE `bonk_mastery` SET `description` = 'Start every run with Mortal Strike.' WHERE `id` = 10206;
UPDATE `bonk_mastery` SET `description` = 'Mortal Strike strikes one more enemy.' WHERE `id` = 10208;
UPDATE `bonk_mastery` SET `target` = 180, `description` = 'Start every run with Heroic Throw.' WHERE `id` = 10306;
UPDATE `bonk_mastery` SET `target` = 201, `description` = 'Start every run with Call Pet.' WHERE `id` = 30106;
UPDATE `bonk_mastery` SET `target` = 201, `description` = '+8% Call Pet damage.' WHERE `id` = 30107;
UPDATE `bonk_mastery` SET `target` = 201, `description` = 'Call Pet calls one more beast.' WHERE `id` = 30108;
UPDATE `bonk_mastery` SET `target` = 202, `description` = 'Explosive Trap recharges 6% faster.' WHERE `id` = 30304;
UPDATE `bonk_mastery` SET `target` = 202, `description` = '+8% Explosive Trap damage.' WHERE `id` = 30305;

DELETE FROM `gameobject_template` WHERE `entry` IN (900009, 900010, 900011);
DROP TEMPORARY TABLE IF EXISTS `bonk_trap_template`;
CREATE TEMPORARY TABLE `bonk_trap_template` AS SELECT * FROM `gameobject_template` WHERE `entry` = 900007;
UPDATE `bonk_trap_template` SET `entry` = 900009, `displayId` = 3072, `name` = 'Explosive Trap', `size` = 1;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_trap_template`;
UPDATE `bonk_trap_template` SET `entry` = 900010, `displayId` = 3073, `name` = 'Frost Trap';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_trap_template`;
UPDATE `bonk_trap_template` SET `entry` = 900011, `displayId` = 3071, `name` = 'Freezing Trap';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_trap_template`;
DROP TEMPORARY TABLE `bonk_trap_template`;

DROP TEMPORARY TABLE IF EXISTS `bonk_pet_template`;
CREATE TEMPORARY TABLE `bonk_pet_template` SELECT * FROM `creature_template` WHERE `entry` = 69 AND `patch` = 0;
UPDATE `bonk_pet_template` SET `entry` = 900112, `name` = 'Wolf', `subname` = '', `faction` = 35, `npc_flags` = 0, `gossip_menu_id` = 0,
    `level_min` = 1, `level_max` = 1, `movement_type` = 0, `detection_range` = 0, `call_for_help_range` = 0,
    `loot_id` = 0, `pickpocket_loot_id` = 0, `skinning_loot_id` = 0, `gold_min` = 0, `gold_max` = 0, `spell_list_id` = 0,
    `auras` = NULL, `ai_name` = '', `script_name` = '', `static_flags1` = 0, `static_flags2` = 0, `flags_extra` = 0, `civilian` = 0;
DELETE FROM `creature_template` WHERE `entry` = 900112;
INSERT INTO `creature_template` SELECT * FROM `bonk_pet_template`;
DROP TEMPORARY TABLE `bonk_pet_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
