DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012090000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012090000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `mastery_xp_minute`   INT UNSIGNED NOT NULL DEFAULT 10 COMMENT 'Class Mastery experience per minute survived',
    ADD COLUMN `mastery_xp_miniboss` INT UNSIGNED NOT NULL DEFAULT 15 COMMENT '... per mini-boss killed',
    ADD COLUMN `mastery_xp_boss`     INT UNSIGNED NOT NULL DEFAULT 40 COMMENT '... per stage boss killed';
UPDATE `bonk_tier` SET `mastery_xp_minute` = 10, `mastery_xp_miniboss` = 15, `mastery_xp_boss` = 40 WHERE `key` = 'easy';
UPDATE `bonk_tier` SET `mastery_xp_minute` = 15, `mastery_xp_miniboss` = 22, `mastery_xp_boss` = 60 WHERE `key` = 'medium';
UPDATE `bonk_tier` SET `mastery_xp_minute` = 20, `mastery_xp_miniboss` = 30, `mastery_xp_boss` = 80 WHERE `key` = 'hard';

ALTER TABLE `bonk_quest`
    MODIFY COLUMN `reward_type` TINYINT UNSIGNED NOT NULL COMMENT '0 gold, 1 Talent Shards, 2 weapon, 3 passive, 4 talent, 5 upgrade, 6 Mastery Points (class quests)',
    ADD COLUMN `class` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'class id: only counts while that class is played; 0 = any hero';

CREATE TABLE IF NOT EXISTS `bonk_mastery_tree` (
    `id`         INT UNSIGNED     NOT NULL,
    `class`      TINYINT UNSIGNED NOT NULL COMMENT 'class id',
    `name`       VARCHAR(32)      NOT NULL,
    `background` VARCHAR(64)      NOT NULL COMMENT 'Interface\\TalentFrame art',
    `order`      TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'left to right',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk Class Mastery trees';

CREATE TABLE IF NOT EXISTS `bonk_mastery` (
    `id`             INT UNSIGNED     NOT NULL,
    `class`          TINYINT UNSIGNED NOT NULL COMMENT 'class id',
    `tree`           INT UNSIGNED     NOT NULL COMMENT 'bonk_mastery_tree.id',
    `row`            TINYINT UNSIGNED NOT NULL COMMENT '1-7; row r needs (r - 1) * 3 points in the tree',
    `column`         TINYINT UNSIGNED NOT NULL COMMENT '1-4',
    `icon`           VARCHAR(64)      NOT NULL,
    `name`           VARCHAR(64)      NOT NULL,
    `description`    VARCHAR(255)     NOT NULL COMMENT 'what one rank does',
    `max_rank`       TINYINT UNSIGNED NOT NULL DEFAULT 1,
    `required_id`    INT UNSIGNED     NOT NULL DEFAULT 0,
    `required_rank`  TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `effect`         TINYINT UNSIGNED NOT NULL COMMENT '0 passive, 1 spell damage, 2 school damage, 3 spell cooldown, 4 spell targets, 5 start spell, 6 shatter, 7 opener, 8 execute, 9 clearcasting, 10 soul siphon',
    `target`         INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'passive effect, bonk_weapon.id or spell school mask',
    `value_per_rank` FLOAT            NOT NULL DEFAULT 0,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk Class Mastery nodes';

DELETE FROM `bonk_mastery_tree` WHERE `class` IN (8, 9);
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(801, 8, 'Arcane',      'MageArcane',         1),
(802, 8, 'Fire',        'MageFire',           2),
(803, 8, 'Frost',       'MageFrost',          3),
(901, 9, 'Affliction',  'WarlockCurses',      1),
(902, 9, 'Demonology',  'WarlockSummoning',   2),
(903, 9, 'Destruction', 'WarlockDestruction', 3);

DELETE FROM `bonk_mastery` WHERE `class` IN (8, 9);
INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`) VALUES
(80101, 8, 801, 1, 2, 'Spell_Holy_Devotion',          'Arcane Focus',             '+5% Arcane Explosion damage.',                         5, 0, 0, 1, 15, 5),
(80102, 8, 801, 1, 3, 'Spell_Nature_StarFall',        'Arcane Subtlety',          'Spells recharge 2% faster.',                           3, 0, 0, 0, 1, 2),
(80103, 8, 801, 2, 1, 'Spell_Nature_AstralRecalGroup','Magic Absorption',         '-2% damage taken.',                                    3, 0, 0, 0, 12, 2),
(80104, 8, 801, 2, 2, 'Spell_Nature_WispSplode',      'Improved Arcane Explosion','Arcane Explosion recharges 6% faster.',                3, 0, 0, 3, 15, 6),
(80105, 8, 801, 2, 3, 'Spell_Shadow_Charm',           'Arcane Mind',              '+4% area.',                                            3, 0, 0, 0, 10, 4),
(80106, 8, 801, 3, 2, 'Spell_Nature_EnchantArmor',    'Arcane Initiate',          'Start every run with Arcane Explosion.',               1, 0, 0, 5, 15, 1),
(80107, 8, 801, 3, 3, 'Spell_Shadow_SiphonMana',      'Arcane Meditation',        'Regain 0.1% health every second.',                     3, 0, 0, 0, 5, 0.1),
(80108, 8, 801, 4, 2, 'Spell_Shadow_Teleport',        'Arcane Instability',       '+3% damage.',                                          3, 0, 0, 0, 0, 3),
(80109, 8, 801, 5, 2, 'Spell_Nature_Lightning',       'Arcane Power',             'Every spell cast has a 10% chance to be ready again at once.', 1, 80108, 3, 9, 0, 10),
(80201, 8, 802, 1, 2, 'Spell_Fire_FlameBolt',         'Improved Fireball',        '+5% Fireball damage.',                                 5, 0, 0, 1, 14, 5),
(80202, 8, 802, 1, 3, 'Spell_Fire_Incinerate',        'Ignite',                   '+2% fire damage.',                                     5, 0, 0, 2, 4, 2),
(80203, 8, 802, 2, 1, 'Spell_Fire_Fire',              'Burning Soul',             '+4% maximum health.',                                  3, 0, 0, 0, 4, 4),
(80204, 8, 802, 2, 2, 'Spell_Fire_Fireball',          'Improved Fire Blast',      'Fire Blast recharges 6% faster.',                      3, 0, 0, 3, 45, 6),
(80205, 8, 802, 2, 3, 'Spell_Fire_FlameShock',        'Incinerate',               '+8% Fire Blast damage.',                               3, 0, 0, 1, 45, 8),
(80206, 8, 802, 3, 2, 'Spell_Fire_Fireball02',        'Pyromancer',               'Start every run with Fireball.',                       1, 0, 0, 5, 14, 1),
(80207, 8, 802, 3, 3, 'Spell_Fire_SoulBurn',          'Flame Throwing',           'Fireball recharges 5% faster.',                        3, 0, 0, 3, 14, 5),
(80208, 8, 802, 4, 2, 'Spell_Fire_MasterOfElements',  'Master of Elements',       'Fireball hits one more enemy.',                        1, 0, 0, 4, 14, 1),
(80209, 8, 802, 5, 2, 'Spell_Fire_SealOfFire',        'Combustion',               'Fire spells deal 30% more damage to enemies above 80% health.', 1, 80208, 1, 7, 4, 30),
(80301, 8, 803, 1, 2, 'Spell_Frost_FrostBolt02',      'Improved Frostbolt',       '+5% Frostbolt damage.',                                5, 0, 0, 1, 13, 5),
(80302, 8, 803, 1, 3, 'Spell_Frost_IceShard',         'Ice Shards',               '+2% frost damage.',                                    5, 0, 0, 2, 16, 2),
(80303, 8, 803, 2, 1, 'Spell_Frost_FrostWard',        'Frost Warding',            '-2% damage taken.',                                    3, 0, 0, 0, 12, 2),
(80304, 8, 803, 2, 2, 'Spell_Frost_FreezingBreath',   'Improved Frost Nova',      'Frost Nova recharges 8% faster.',                      3, 0, 0, 3, 16, 8),
(80305, 8, 803, 2, 3, 'Spell_Frost_IceStorm',         'Winter''s Chill',          '+8% Blizzard damage.',                                 3, 0, 0, 1, 22, 8),
(80306, 8, 803, 3, 2, 'Spell_Frost_WizardMark',       'Cold Snap',                'Start every run with Frost Nova, once a quest has unlocked it.', 1, 0, 0, 5, 16, 1),
(80307, 8, 803, 3, 3, 'Spell_Frost_Stun',             'Arctic Reach',             '+4% area.',                                            3, 0, 0, 0, 10, 4),
(80308, 8, 803, 4, 2, 'Spell_Frost_Frostbolt',        'Piercing Ice',             'Frostbolt hits one more enemy.',                       1, 0, 0, 4, 13, 1),
(80309, 8, 803, 5, 2, 'Spell_Frost_FrostShock',       'Shatter',                  '+25% damage to slowed or rooted enemies.',             1, 80308, 1, 6, 0, 25),
(90101, 9, 901, 1, 2, 'Spell_Shadow_AbominationExplosion', 'Improved Corruption', '+5% Corruption damage.',                               5, 0, 0, 1, 18, 5),
(90102, 9, 901, 1, 3, 'Spell_Shadow_ShadeTrueSight',  'Shadow Mastery',           '+2% shadow damage.',                                   5, 0, 0, 2, 32, 2),
(90103, 9, 901, 2, 1, 'Spell_Shadow_FingerOfDeath',   'Fel Concentration',        'Spells last 5% longer.',                               3, 0, 0, 0, 11, 5),
(90104, 9, 901, 2, 2, 'Spell_Shadow_CurseOfSargeras', 'Improved Curse of Agony',  '+8% Curse of Agony damage.',                           3, 0, 0, 1, 46, 8),
(90105, 9, 901, 2, 3, 'Spell_Shadow_UnsummonBuilding','Suppression',              'Corruption recharges 6% faster.',                      3, 0, 0, 3, 18, 6),
(90106, 9, 901, 3, 2, 'Spell_Shadow_Contagion',       'Amplify Curse',            'Start every run with Curse of Agony.',                 1, 0, 0, 5, 46, 1),
(90107, 9, 901, 3, 3, 'Spell_Shadow_Twilight',        'Nightfall',                'Regain 0.1% health every second.',                     3, 0, 0, 0, 5, 0.1),
(90108, 9, 901, 4, 2, 'Spell_Shadow_CallofBone',      'Grim Reach',               'Corruption reaches one more enemy.',                   1, 0, 0, 4, 18, 1),
(90109, 9, 901, 5, 2, 'Spell_Shadow_Requiem',         'Soul Siphon',              'A kill with a shadow spell heals 0.5% of your maximum health, at most 3% a second.', 1, 90108, 1, 10, 32, 0.5),
(90201, 9, 902, 1, 2, 'Spell_Shadow_Metamorphosis',   'Demonic Embrace',          '+4% maximum health.',                                  5, 0, 0, 0, 4, 4),
(90202, 9, 902, 1, 3, 'INV_Stone_04',                 'Improved Healthstone',     'Regain 0.1% health every second.',                     3, 0, 0, 0, 5, 0.1),
(90203, 9, 902, 2, 1, 'Spell_Shadow_AntiShadow',      'Fel Stamina',              '-2% damage taken.',                                    3, 0, 0, 0, 12, 2),
(90204, 9, 902, 2, 2, 'Spell_Shadow_ShadowWordDominate', 'Unholy Power',          '+3% damage.',                                          3, 0, 0, 0, 0, 3),
(90205, 9, 902, 2, 3, 'Spell_Shadow_ImpPhaseShift',   'Master Summoner',          '+3% movement speed.',                                  2, 0, 0, 0, 3, 3),
(90206, 9, 902, 3, 2, 'Spell_Shadow_PsychicScream',   'Demonic Pact',             'Start every run with Corruption.',                     1, 0, 0, 5, 18, 1),
(90207, 9, 902, 3, 3, 'Spell_Shadow_RitualOfSacrifice', 'Fel Domination',        '+10% Hellfire damage.',                                3, 0, 0, 1, 19, 10),
(90208, 9, 902, 4, 2, 'Spell_Shadow_SummonImp',       'Demonic Knowledge',        '+5% area.',                                            2, 0, 0, 0, 10, 5),
(90209, 9, 902, 5, 2, 'Spell_Shadow_GatherShadows',   'Soul Link',                '-8% damage taken.',                                    1, 90208, 2, 0, 12, 8),
(90301, 9, 903, 1, 2, 'Spell_Shadow_ShadowBolt',      'Improved Shadow Bolt',     '+5% Shadow Bolt damage.',                              5, 0, 0, 1, 17, 5),
(90302, 9, 903, 1, 3, 'Spell_Fire_SelfDestruct',      'Emberstorm',               '+2% fire damage.',                                     5, 0, 0, 2, 4, 2),
(90303, 9, 903, 2, 1, 'Spell_Shadow_CorpseExplode',   'Destructive Reach',        '+4% area.',                                            3, 0, 0, 0, 10, 4),
(90304, 9, 903, 2, 2, 'Spell_Shadow_DeathPact',       'Bane',                     'Shadow Bolt recharges 5% faster.',                     3, 0, 0, 3, 17, 5),
(90305, 9, 903, 2, 3, 'Spell_Fire_SoulBurn',          'Improved Searing Pain',    '+8% Searing Pain damage.',                             3, 0, 0, 1, 47, 8),
(90306, 9, 903, 3, 2, 'Spell_Fire_Volcano',           'Devastation',              'Start every run with Searing Pain, once a quest has unlocked it.', 1, 0, 0, 5, 47, 1),
(90307, 9, 903, 3, 3, 'Spell_Shadow_RainOfFire',      'Aftermath',                '+8% Rain of Fire damage.',                             3, 0, 0, 1, 23, 8),
(90308, 9, 903, 4, 2, 'Spell_Nature_AbolishMagic',    'Cataclysm',                'Shadow Bolt hits one more enemy.',                     1, 0, 0, 4, 17, 1),
(90309, 9, 903, 5, 2, 'Spell_Shadow_ShadowWordPain',  'Ruin',                     '+25% damage to enemies below 30% health.',             1, 90308, 1, 8, 0, 25);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 101 AND 120;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`, `class`) VALUES
(101, 'Apprentice Magus',  'Clear stage 1 on Easy as a mage.',                       'Spell_Holy_MagicalSentry',   3,  1,    2, 6, 1, 8),
(102, 'Frostweaver',       'Kill 1,000 enemies with Frostbolt as a mage.',           'Spell_Frost_FrostBolt02',    2, 13, 1000, 6, 1, 8),
(103, 'Flamecaller',       'Kill 1,000 enemies with Fireball as a mage.',            'Spell_Fire_FlameBolt',       2, 14, 1000, 6, 1, 8),
(104, 'Spellstorm',        'Kill 1,000 enemies with Arcane Explosion as a mage.',    'Spell_Nature_WispSplode',    2, 15, 1000, 6, 1, 8),
(105, 'Winter''s Fury',    'Kill 750 enemies with Blizzard as a mage.',              'Spell_Frost_IceStorm',       2, 22,  750, 6, 1, 8),
(106, 'Elite Arcanist',    'Kill 25 elites as a mage.',                              'Spell_Nature_StarFall',      1,  1,   25, 6, 1, 8),
(107, 'Archmage',          'Reach level 30 in a single run as a mage.',              'Spell_Holy_Devotion',        4,  0,   30, 6, 1, 8),
(108, 'Arcane Conqueror','Clear three stages on Easy as a mage.',                  'Spell_Nature_EnchantArmor',  3,  1,    4, 6, 1, 8),
(109, 'Proven Magus',    'Clear two stages on Medium as a mage.',                  'Spell_Fire_SealOfFire',      3,  3,    3, 6, 1, 8),
(110, 'Hard-Won Wisdom', 'Clear stage 1 on Hard as a mage.',              'Spell_Fire_Volcano',         3,  2,    2, 6, 1, 8),
(111, 'Novice of the Coven','Clear stage 1 on Easy as a warlock.',                   'Spell_Shadow_ShadeTrueSight',3,  1,    2, 6, 1, 9),
(112, 'Shadowbolter',      'Kill 1,000 enemies with Shadow Bolt as a warlock.',      'Spell_Shadow_ShadowBolt',    2, 17, 1000, 6, 1, 9),
(113, 'Corruptor',         'Kill 1,000 enemies with Corruption as a warlock.',       'Spell_Shadow_AbominationExplosion', 2, 18, 1000, 6, 1, 9),
(114, 'Agonizer',          'Kill 1,000 enemies with Curse of Agony as a warlock.',   'Spell_Shadow_CurseOfSargeras', 2, 46, 1000, 6, 1, 9),
(115, 'Rain of Ruin',      'Kill 750 enemies with Rain of Fire as a warlock.',       'Spell_Shadow_RainOfFire',    2, 23,  750, 6, 1, 9),
(116, 'Soul Collector',    'Kill 10 mini-bosses as a warlock.',                      'Spell_Shadow_Requiem',       1,  3,   10, 6, 1, 9),
(117, 'Dreadlord',         'Reach level 30 in a single run as a warlock.',           'Spell_Shadow_Metamorphosis', 4,  0,   30, 6, 1, 9),
(118, 'Shadow Conqueror', 'Clear three stages on Easy as a warlock.',               'Spell_Shadow_GatherShadows', 3,  1,    4, 6, 1, 9),
(119, 'Proven Warlock',   'Clear two stages on Medium as a warlock.',               'Spell_Fire_SelfDestruct',    3,  3,    3, 6, 1, 9),
(120, 'Hard-Won Power','Clear stage 1 on Hard as a warlock.',                    'Spell_Shadow_DeathPact',     3,  2,    2, 6, 1, 9);

DELETE FROM `creature_template` WHERE `entry` = 900008;
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900008, 0, 'Theron Ashveil', 'Class Mastery', 60, 60, 35, 1, 1484, 1, 1, 7, 8, 1, 262, 'npc_bonk_mastery');

DELETE FROM `creature` WHERE `guid` = 900008;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900008, 900008, 1, 16216.0, 16250.0, 12.842, 0.507, 120, 120, 0, 0);

DELETE FROM `broadcast_text` WHERE `entry` IN (900008, 900009);
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900008, 'Every class walks its own road, $n. Bring me what your runs have taught you, and I will make it mastery - for this class, and this class alone.',
         'Every class walks its own road, $n. Bring me what your runs have taught you, and I will make it mastery - for this class, and this class alone.'),
(900009, 'Your class''s teachings are still being written down. Keep fighting: every run already counts toward your Mastery, and none of it will be lost.',
         'Your class''s teachings are still being written down. Keep fighting: every run already counts toward your Mastery, and none of it will be lost.');
DELETE FROM `npc_text` WHERE `ID` IN (900008, 900009);
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900008, 900008, 1), (900009, 900009, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
