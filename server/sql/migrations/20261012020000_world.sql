DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012020000');

CREATE TABLE IF NOT EXISTS `bonk_quest` (
    `id`           INT UNSIGNED     NOT NULL,
    `name`         VARCHAR(64)      NOT NULL,
    `description`  VARCHAR(255)     NOT NULL,
    `icon`         VARCHAR(64)      NOT NULL DEFAULT 'INV_Misc_Note_01' COMMENT 'Interface\\Icons file name',
    `type`         TINYINT UNSIGNED NOT NULL COMMENT '0 kills, 1 kills of a kind, 2 kills with a weapon, 3 stage on a tier, 4 level in one run, 5 Talent Shards found',
    `target`       INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'type 1: spawn kind (1 elite, 2 boss, 3 mini-boss); 2: bonk_weapon.id (its evolution counts); 3: bonk_tier.id',
    `amount`       INT UNSIGNED     NOT NULL COMMENT 'kills, stage, level or shards needed',
    `reward_type`  TINYINT UNSIGNED NOT NULL COMMENT '0 gold, 1 Talent Shards, 2 weapon, 3 passive, 4 talent, 5 upgrade',
    `reward_value` INT UNSIGNED     NOT NULL COMMENT 'copper, shards, or the id of what it unlocks',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk quests';

DELETE FROM `bonk_quest`;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`) VALUES
( 1, 'Pest Control',      'Kill 250 enemies.',                  'INV_Misc_Bone_HumanSkull_01',   0, 0,   250, 0, 10000),
( 2, 'Exterminator',      'Kill 2,500 enemies.',                'INV_Misc_Bone_ElfSkull_01',     0, 0,  2500, 3,     9),
( 3, 'Bonk Legend',       'Kill 10,000 enemies.',               'Ability_Warrior_BattleShout',   0, 0, 10000, 1,    10),
( 4, 'Elite Hunter',      'Kill 15 elites.',                    'Ability_Warrior_Challange',     1, 1,    15, 2,     4),
( 5, 'Big Game',          'Kill 10 mini-bosses.',               'INV_Misc_Head_Dragon_01',       1, 3,    10, 1,     3),
( 6, 'Boss Bonker',       'Defeat 5 stage bosses.',             'INV_Hammer_Unique_Sulfuras',    1, 2,     5, 4,     7),
( 7, 'Into the Wild',     'Reach stage 2 on Easy.',             'INV_Misc_Map_01',               3, 1,     2, 2,    16),
( 8, 'Seasoned',          'Reach stage 3 on Easy.',             'INV_Misc_Map_01',               3, 1,     3, 1,     2),
( 9, 'Rough Lands',       'Reach stage 3 on Medium.',           'INV_Misc_Map_01',               3, 3,     3, 5,     8),
(10, 'Into the Fire',     'Reach stage 2 on Hard.',             'Spell_Fire_LavaSpawn',          3, 2,     2, 2,    19),
(11, 'Growing Strong',    'Reach level 15 in a single run.',    'INV_Misc_Book_09',              4, 0,    15, 2,    11),
(12, 'Unstoppable',       'Reach level 30 in a single run.',    'Spell_Holy_WordFortitude',      4, 0,    30, 1,     5),
(13, 'Shard Seeker',      'Find 10 Talent Shards.',             'INV_Enchant_ShardBrilliantLarge', 5, 0,  10, 4,     6),
(20, 'Thunderous',        'Kill 500 enemies with Thunder Clap.',     'Spell_Nature_ThunderClap',  2,  1, 500, 1, 2),
(21, 'Hallowed Ground',   'Kill 500 enemies with Consecration.',     'Spell_Holy_InnerFire',      2,  3, 500, 1, 2),
(22, 'Smiter',            'Kill 500 enemies with Smite.',            'Spell_Holy_HolySmite',      2,  6, 500, 1, 2),
(23, 'Sharpshooter',      'Kill 500 enemies with Arcane Shot.',      'Ability_ImpalingBolt',      2,  7, 500, 1, 2),
(24, 'Knife Thrower',     'Kill 500 enemies with Throwing Knives.',  'INV_ThrowingKnife_02',      2,  9, 500, 1, 2),
(25, 'Stormcaller',       'Kill 500 enemies with Lightning Bolt.',   'Spell_Nature_Lightning',    2, 10, 500, 1, 2),
(26, 'Frostbitten',       'Kill 500 enemies with Frostbolt.',        'Spell_Frost_FrostBolt02',   2, 13, 500, 1, 2),
(27, 'Shadowcaster',      'Kill 500 enemies with Shadow Bolt.',      'Spell_Shadow_ShadowBolt',   2, 17, 500, 1, 2),
(28, 'Wrathful',          'Kill 500 enemies with Wrath.',            'Spell_Nature_AbolishMagic', 2, 20, 500, 1, 2);

DELETE FROM `creature_template` WHERE `entry` = 900005;
INSERT INTO `creature_template` (`entry`, `patch`, `name`, `subname`, `level_min`, `level_max`, `faction`, `npc_flags`,
    `display_id1`, `display_probability1`, `display_total_probability`, `type`, `unit_class`, `inhabit_type`,
    `static_flags1`, `script_name`) VALUES
(900005, 0, 'Marla Ledgerwick', 'Quests', 60, 60, 35, 1, 5647, 1, 1, 7, 1, 1, 262, 'npc_bonk_quests');

DELETE FROM `creature` WHERE `guid` = 900005;
INSERT INTO `creature` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`,
    `spawntimesecsmin`, `spawntimesecsmax`, `wander_distance`, `movement_type`) VALUES
(900005, 900005, 1, 16236.5, 16257.5, 14.844, 3.1416, 120, 120, 0, 0);

DELETE FROM `broadcast_text` WHERE `entry` = 900005;
INSERT INTO `broadcast_text` (`entry`, `male_text`, `female_text`) VALUES
(900005, 'Every hero who makes it back has a story. Finish a task on my board and I''ll see you''re rewarded - some of what I hand out can''t be had any other way.',
         'Every hero who makes it back has a story. Finish a task on my board and I''ll see you''re rewarded - some of what I hand out can''t be had any other way.');
DELETE FROM `npc_text` WHERE `ID` = 900005;
INSERT INTO `npc_text` (`ID`, `BroadcastTextID0`, `Probability0`) VALUES (900005, 900005, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
