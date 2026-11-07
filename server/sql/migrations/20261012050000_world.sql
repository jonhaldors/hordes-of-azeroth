DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012050000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012050000');

ALTER TABLE `bonk_weapon`
    ADD COLUMN IF NOT EXISTS `target_every` TINYINT UNSIGNED NOT NULL DEFAULT 3 COMMENT '+1 target (projectile, enemy struck, damage over time) every this many levels; 0 = never' AFTER `duration_ms`,
    ADD COLUMN IF NOT EXISTS `chain_every` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '+1 jump, or enemy cleaved, every this many levels; 0 = never' AFTER `target_every`,
    ADD COLUMN IF NOT EXISTS `behavior` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 none, 1 cleave (melee: also hits enemies beside the target, reach grows), 2 spread (at max level or evolved: jumps on when an enemy carrying it dies)' AFTER `chain_every`,
    ADD COLUMN IF NOT EXISTS `behavior_value` FLOAT NOT NULL DEFAULT 0 COMMENT 'cleave: damage share for the enemies beside the target; spread: enemies it jumps to' AFTER `behavior`;

ALTER TABLE `bonk_passive`
    MODIFY COLUMN `effect` TINYINT UNSIGNED NOT NULL COMMENT '0 might, 1 cooldown, 2 amount, 3 move speed, 4 max health, 5 recovery, 6 greed, 7 growth, 8 magnet, 9 leech, 10 area, 11 duration, 12 defense';

UPDATE `bonk_weapon` SET `target_every` = 0, `chain_every` = 2 WHERE `id` IN (11, 104);
UPDATE `bonk_weapon` SET `target_every` = 0 WHERE `id` = 110;
UPDATE `bonk_weapon` SET `target_every` = 2, `behavior` = 2, `behavior_value` = 2,
    `description` = 'Shadow damage over time on random enemies. At max level it spreads when they die.' WHERE `id` = 18;
UPDATE `bonk_weapon` SET `target_every` = 2, `behavior` = 2, `behavior_value` = 2, `damage_fraction` = 0.35,
    `description` = 'Burns random enemies with moonlight. At max level it spreads when they die.' WHERE `id` = 21;

UPDATE `bonk_passive` SET `value_per_rank` = 1, `description` = 'Heal for 1% of the damage you deal, up to 0.4% of your health a second.' WHERE `id` = 10;
DELETE FROM `bonk_passive` WHERE `id` BETWEEN 11 AND 13;
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`) VALUES
(11, 'Reach',       'Spell_Nature_EarthQuake',         '+10% area, melee reach and spreading range.',              10, 10, 5),
(12, 'Persistence', 'Spell_Nature_TimeStop',           'Damage over time and ground spells last 10% longer.',      11, 10, 5),
(13, 'Toughness',   'Ability_Warrior_DefensiveStance', 'Take 4% less damage.',                                     12,  4, 5);

DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 30 AND 49 OR `id` BETWEEN 130 AND 149;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `max_level`, `evolves_from`, `evolve_passive`, `heal_pct`, `duration_ms`,
    `target_every`, `chain_every`, `behavior`, `behavior_value`) VALUES
(30, 'Cleave',             'Ability_Warrior_Cleave',          'Strikes the nearest enemy and cleaves the ones beside it. Long reach.',        12723, 0, 1600,  7, 0.55,    1, 0, 8, 0, 0, 0,    0, 3, 2, 1, 0.6),
(31, 'Whirlwind',          'Ability_Whirlwind',               'Spins, striking every enemy around you.',                                    15576, 1, 4000,  8, 0.60,    1, 0, 8, 0, 0, 0,    0, 3, 0, 0, 0),
(32, 'Rend',               'Ability_Gouge',                   'Makes random nearby enemies bleed. At max level it spreads when they die.',  13318, 2, 1500,  8, 0.25,    1, 0, 8, 0, 0, 0, 9000, 2, 0, 2, 2),
(33, 'Bloodthirst',        'Spell_Nature_BloodLust',          'A savage strike at the nearest enemy that heals you a little.',             23881, 0, 3000,  7, 1.10,    1, 0, 8, 0, 0, 1.0,  0, 4, 0, 0, 0),
(34, 'Sinister Strike',    'Spell_Shadow_RitualOfSacrifice',  'Quick strikes at the nearest enemies, nicking the ones beside them.',        14873, 0, 1000,  6, 0.40,    8, 0, 8, 0, 0, 0,    0, 2, 3, 1, 0.4),
(35, 'Garrote',            'Ability_Rogue_Garrote',           'Makes random nearby enemies bleed. At max level it spreads when they die.',  8818,  2, 1400,  8, 0.20,    8, 0, 8, 0, 0, 0, 9000, 2, 0, 2, 2),
(36, 'Eviscerate',         'Ability_Rogue_Eviscerate',        'A vicious finishing blow on the nearest enemy.',                            15691, 0, 3500,  7, 1.40,    8, 0, 8, 0, 0, 0,    0, 3, 0, 0, 0),
(37, 'Multi-Shot',         'Ability_UpgradeMoonGlaive',       'Shots that hit several enemies at once. Needs a bow or gun.',               2643,  0, 2500, 35, 0.45,    4, 0, 8, 0, 0, 0,    0, 0, 2, 0, 0),
(38, 'Serpent Sting',      'Ability_Hunter_Quickshot',        'Poisons random enemies. At max level it spreads when they die.',            1978,  2, 1300, 35, 0.15,    4, 0, 8, 0, 0, 0,    0, 2, 0, 2, 2),
(39, 'Crusader Strike',    'Spell_Holy_HolyBolt',             'A holy strike at the nearest enemy that also hits the ones beside it.',     2537,  0, 1500,  7, 0.60,    2, 0, 8, 0, 0, 0,    0, 3, 2, 1, 0.5),
(40, 'Holy Shock',         'Spell_Holy_Excorcism',            'A blast of holy power at the nearest enemy.',                               25912, 0, 1800, 25, 0.60,    2, 0, 8, 0, 0, 0,    0, 3, 0, 0, 0),
(41, 'Shadow Word: Pain',  'Spell_Shadow_ShadowWordPain',     'Shadow pain on random enemies. At max level it spreads when they die.',     589,   2, 1300, 30, 0.14,   16, 0, 8, 0, 0, 0,    0, 2, 0, 2, 2),
(42, 'Mind Blast',         'Spell_Shadow_UnholyFrenzy',       'A blast of shadow at the nearest enemy.',                                   8092,  0, 2400, 30, 1.00,   16, 0, 8, 0, 0, 0,    0, 3, 0, 0, 0),
(43, 'Flame Shock',        'Spell_Fire_FlameShock',           'Scorches random enemies and burns on. At max level it spreads when they die.', 8050, 2, 1600, 25, 0.40,  64, 0, 8, 0, 0, 0,    0, 2, 0, 2, 2),
(44, 'Stormstrike',        'Spell_Holy_SealOfMight',          'A storm-charged strike at the nearest enemy that also hits the ones beside it.', 17364, 0, 1500, 7, 0.55, 64, 0, 8, 0, 0, 0,   0, 3, 2, 1, 0.5),
(45, 'Fire Blast',         'Spell_Fire_Fireball',             'An instant blast of fire at the nearest enemy.',                            2136,  0, 1300, 20, 0.45,  128, 0, 8, 0, 0, 0,    0, 2, 0, 0, 0),
(46, 'Curse of Agony',     'Spell_Shadow_CurseOfSargeras',    'A long, painful curse on random enemies. At max level it spreads when they die.', 980, 2, 1500, 30, 0.08, 256, 0, 8, 0, 0, 0,   0, 2, 0, 2, 2),
(47, 'Searing Pain',       'Spell_Fire_SoulBurn',             'Sears the nearest enemy.',                                                  5676,  0, 1700, 30, 0.60,  256, 0, 8, 0, 0, 0,    0, 3, 0, 0, 0),
(48, 'Insect Swarm',       'Spell_Nature_InsectSwarm',        'A swarm of insects on random enemies. At max level it spreads when they die.', 5570, 2, 1400, 30, 0.12, 1024, 0, 8, 0, 0, 0,   0, 2, 0, 2, 2),
(49, 'Entangling Roots',   'Spell_Nature_StrangleVines',      'Roots random enemies in place and hurts them.',                             339,   2, 2500, 25, 0.15, 1024, 0, 8, 0, 0, 0,    0, 2, 0, 0, 0),
(130, 'Sweeping Blades',   'Ability_Warrior_PunishingBlow',   'Wide, sweeping strikes that cleave many enemies at once.',                  12723, 0, 1300,  8, 0.60,    0, 0, 8, 30, 11, 0,   0, 2, 1, 1, 0.8),
(131, 'Bladestorm',        'Ability_Warrior_Savageblow',      'A storm of steel around you, again and again.',                             15576, 1, 2200, 10, 0.65,    0, 0, 8, 31,  4, 0,   0, 3, 0, 0, 0),
(132, 'Deep Wounds',       'Ability_Warrior_Riposte',         'Wounds that bleed and spread from every enemy that dies.',                  12721, 2, 1200, 10, 0.25,    0, 0, 8, 32, 13, 0, 9000, 2, 0, 2, 3),
(133, 'Rampage',           'Ability_Warrior_InnerRage',       'Savage strikes at the nearest enemies that heal you.',                      23881, 0, 2200,  8, 1.20,    0, 0, 8, 33,  6, 1.5,  0, 2, 0, 0, 0),
(134, 'Blade Flurry',      'Ability_DualWield',               'A flurry of strikes that nicks everything nearby.',                         22482, 0,  700,  7, 0.45,    0, 0, 8, 34,  2, 0,   0, 2, 2, 1, 0.5),
(135, 'Rupture',           'Ability_Rogue_Rupture',           'Deep bleeds that spread from every enemy that dies.',                       14874, 2, 1000, 10, 0.25,    0, 0, 8, 35, 12, 0, 9000, 1, 0, 2, 3),
(136, 'Assassinate',       'Ability_BackStab',                'Fatal blows at the nearest enemies.',                                       10373, 0, 2500,  8, 1.60,    0, 0, 8, 36,  1, 0,   0, 2, 0, 0, 0),
(137, 'Barrage',           'Ability_Hunter_SniperShot',       'Rapid volleys that hit many enemies. Needs a bow or gun.',                  14290, 0, 1500, 35, 0.50,    0, 0, 8, 37,  2, 0,   0, 0, 1, 0, 0),
(138, 'Serpent''s Nest',   'Ability_Hunter_Pet_Spider',       'Poison that spreads from every enemy that dies.',                           25295, 2,  900, 35, 0.18,    0, 0, 8, 38, 12, 0,   0, 1, 0, 2, 3),
(139, 'Divine Storm',      'Spell_Holy_HolySmite',            'Holy strikes that cleave many enemies at once.',                            2537,  0, 1200,  9, 0.65,    0, 0, 8, 39, 11, 0,   0, 2, 1, 1, 0.8),
(140, 'Holy Barrage',      'Spell_Holy_SealOfMight',          'Blasts of holy power at the nearest enemies.',                              25902, 0, 1000, 25, 0.60,    0, 0, 8, 40,  3, 0,   0, 2, 0, 0, 0),
(141, 'Shadow Plague',     'Spell_Shadow_ShadowWordDominate', 'Shadow pain that spreads from every enemy that dies.',                      10894, 2,  900, 30, 0.16,    0, 0, 8, 41, 12, 0,   0, 1, 0, 2, 3),
(142, 'Mind Shatter',      'Spell_Shadow_Requiem',            'Blasts of shadow at the nearest enemies.',                                  10947, 0, 1600, 30, 1.10,    0, 0, 8, 42,  1, 0,   0, 2, 0, 0, 0),
(143, 'Living Flame',      'Spell_Fire_Immolation',           'Flames that spread from every enemy that dies.',                            10448, 2, 1000, 25, 0.45,    0, 0, 8, 43, 11, 0,   0, 1, 0, 2, 3),
(144, 'Windfury',          'Spell_Nature_Windfury',           'Blinding strikes that also hit the enemies beside the target.',             17364, 0,  800,  8, 0.55,    0, 0, 8, 44,  2, 0,   0, 2, 2, 1, 0.6),
(145, 'Fire Barrage',      'Spell_Fire_FireBolt02',           'Instant blasts of fire at the nearest enemies.',                            10199, 0,  900, 20, 0.50,    0, 0, 8, 45,  3, 0,   0, 1, 0, 0, 0),
(146, 'Seed of Corruption','Spell_Shadow_CurseOfMannoroth',   'Corruption that spreads from every enemy that dies.',                       172,   2, 1000, 30, 0.14,    0, 0, 8, 18, 10, 0,   0, 1, 0, 2, 3),
(147, 'Curse of Doom',     'Spell_Shadow_CurseOfTounges',     'A curse that spreads from every enemy that dies.',                          11713, 2, 1000, 30, 0.10,    0, 0, 8, 46, 12, 0,   0, 1, 0, 2, 3),
(148, 'Locust Swarm',      'Spell_Nature_NullWard',           'Insects that spread from every enemy that dies.',                           24977, 2,  900, 30, 0.14,    0, 0, 8, 48, 12, 0,   0, 1, 0, 2, 3),
(149, 'Moonfall',          'Spell_Arcane_StarFire',           'Moonlight that spreads from every enemy that dies.',                        8921,  2, 1200, 30, 0.40,    0, 0, 8, 21, 11, 0,   0, 1, 0, 2, 3);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 40 AND 50;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`) VALUES
(40, 'Whirling Steel',  'Kill 400 enemies with Cleave.',             'Ability_Whirlwind',               2, 30, 400, 2, 31),
(41, 'Cutthroat',       'Kill 400 enemies with Sinister Strike.',    'Ability_Rogue_Eviscerate',        2, 34, 400, 2, 36),
(42, 'Venomous',        'Kill 400 enemies with Multi-Shot.',         'Ability_Hunter_Quickshot',        2, 37, 400, 2, 38),
(43, 'Crusader',        'Kill 400 enemies with Crusader Strike.',    'Spell_Holy_Excorcism',            2, 39, 400, 2, 40),
(44, 'Shadow Touched',  'Kill 400 enemies with Shadow Word: Pain.',  'Spell_Shadow_UnholyFrenzy',       2, 41, 400, 2, 42),
(45, 'Stormbringer',    'Kill 400 enemies with Flame Shock.',        'Spell_Holy_SealOfMight',          2, 43, 400, 2, 44),
(46, 'Pyromaniac',      'Kill 400 enemies with Fireball.',           'Spell_Fire_Fireball',             2, 14, 400, 2, 45),
(47, 'Agony',           'Kill 400 enemies with Corruption.',         'Spell_Fire_SoulBurn',             2, 18, 400, 2, 47),
(48, 'Root and Branch', 'Kill 400 enemies with Insect Swarm.',       'Spell_Nature_StrangleVines',      2, 48, 400, 2, 49),
(49, 'Hardened',        'Kill 25 elites.',                           'Ability_Warrior_DefensiveStance', 1,  1,  25, 3, 13),
(50, 'Patience',        'Reach level 20 in a single run.',           'Spell_Nature_TimeStop',           4,  0,  20, 3, 12);

END IF;
END??
DELIMITER ;
CALL add_migration();
