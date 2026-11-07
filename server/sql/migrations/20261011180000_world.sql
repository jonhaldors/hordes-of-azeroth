DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011180000');

CREATE TABLE IF NOT EXISTS `bonk_map` (
    `id`                         TINYINT UNSIGNED  NOT NULL,
    `key`                        VARCHAR(32)       NOT NULL COMMENT 'name used by .bonk start',
    `name`                       VARCHAR(64)       NOT NULL,
    `difficulty`                 TINYINT UNSIGNED  NOT NULL DEFAULT 0 COMMENT '0 easy, 1 normal, 2 hard',
    `map_id`                     SMALLINT UNSIGNED NOT NULL,
    `zone_id`                    SMALLINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'arena boundary; 0 = the whole map',
    `position_x`                 FLOAT             NOT NULL,
    `position_y`                 FLOAT             NOT NULL,
    `position_z`                 FLOAT             NOT NULL,
    `orientation`                FLOAT             NOT NULL DEFAULT 0,
    `duration_sec`               INT UNSIGNED      NOT NULL DEFAULT 600 COMMENT 'the boss arrives after this long',
    `level_offset`               TINYINT           NOT NULL DEFAULT 0 COMMENT 'mob level relative to the player',
    `health_multiplier`          FLOAT             NOT NULL DEFAULT 1,
    `damage_multiplier`          FLOAT             NOT NULL DEFAULT 1,
    `health_growth_per_min`      FLOAT             NOT NULL DEFAULT 0.1 COMMENT 'mob health grows by this share every minute',
    `spawn_interval_ms`          INT UNSIGNED      NOT NULL DEFAULT 2000,
    `spawn_batch`                FLOAT             NOT NULL DEFAULT 2 COMMENT 'mobs per wave at the start',
    `spawn_batch_growth_per_min` FLOAT             NOT NULL DEFAULT 0.5,
    `max_alive`                  SMALLINT UNSIGNED NOT NULL DEFAULT 80,
    `elite_interval_sec`         INT UNSIGNED      NOT NULL DEFAULT 90 COMMENT '0 = no elites',
    `gold_per_kill`              INT UNSIGNED      NOT NULL DEFAULT 10 COMMENT 'copper',
    `victory_gold`               INT UNSIGNED      NOT NULL DEFAULT 5000 COMMENT 'copper',
    PRIMARY KEY (`id`),
    UNIQUE KEY `key` (`key`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk arenas';

CREATE TABLE IF NOT EXISTS `bonk_map_creature` (
    `bonk_map_id`       TINYINT UNSIGNED NOT NULL,
    `entry`             INT UNSIGNED     NOT NULL COMMENT 'creature_template entry; only its looks are used',
    `kind`              TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 normal, 1 elite, 2 boss',
    `min_sec`           INT UNSIGNED     NOT NULL DEFAULT 0,
    `max_sec`           INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT '0 = until the end',
    `weight`            INT UNSIGNED     NOT NULL DEFAULT 1,
    `health_multiplier` FLOAT            NOT NULL DEFAULT 1,
    `damage_multiplier` FLOAT            NOT NULL DEFAULT 1,
    `speed`             FLOAT            NOT NULL DEFAULT 0.7 COMMENT 'run speed rate; the player runs at 1',
    `scale`             FLOAT            NOT NULL DEFAULT 1,
    PRIMARY KEY (`bonk_map_id`, `entry`, `kind`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk spawn pools';

CREATE TABLE IF NOT EXISTS `bonk_weapon` (
    `id`                 INT UNSIGNED     NOT NULL,
    `name`               VARCHAR(64)      NOT NULL,
    `icon`               VARCHAR(64)      NOT NULL COMMENT 'Interface\\Icons texture',
    `description`        VARCHAR(128)     NOT NULL DEFAULT '',
    `spell_id`           INT UNSIGNED     NOT NULL,
    `target`             TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 nearest enemies, 1 area around the player, 2 random enemies',
    `cooldown_ms`        INT UNSIGNED     NOT NULL DEFAULT 2000,
    `range`              FLOAT            NOT NULL DEFAULT 30 COMMENT 'targeting range, or radius for area weapons',
    `damage_fraction`    FLOAT            NOT NULL DEFAULT 0.5 COMMENT 'hit damage as a share of a same-level mob''s health',
    `class_mask`         INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'classes it can be offered to; 0 = all',
    `starter_class_mask` INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'classes that start every run with it',
    `max_level`          TINYINT UNSIGNED NOT NULL DEFAULT 8,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk auto-firing weapons';

CREATE TABLE IF NOT EXISTS `bonk_passive` (
    `id`             INT UNSIGNED     NOT NULL,
    `name`           VARCHAR(64)      NOT NULL,
    `icon`           VARCHAR(64)      NOT NULL,
    `description`    VARCHAR(128)     NOT NULL DEFAULT '',
    `effect`         TINYINT UNSIGNED NOT NULL COMMENT '0 might, 1 cooldown, 2 amount, 3 move speed, 4 max health, 5 recovery, 6 greed, 7 growth',
    `value_per_rank` FLOAT            NOT NULL,
    `max_rank`       TINYINT UNSIGNED NOT NULL DEFAULT 5,
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk passive upgrades';

DELETE FROM `bonk_map`;
INSERT INTO `bonk_map` (`id`, `key`, `name`, `difficulty`, `map_id`, `zone_id`, `position_x`, `position_y`, `position_z`, `orientation`,
    `duration_sec`, `level_offset`, `health_multiplier`, `damage_multiplier`, `health_growth_per_min`,
    `spawn_interval_ms`, `spawn_batch`, `spawn_batch_growth_per_min`, `max_alive`, `elite_interval_sec`, `gold_per_kill`, `victory_gold`) VALUES
(1, 'westfall',   'Westfall',     0,   0, 40, -10235.2, 1222.47,   43.6252, 6.2427,   600, 0, 1.0, 0.35, 0.15, 2000, 2, 0.8,  70, 90,  8,  2000),
(2, 'moltencore', 'Molten Core',  2, 409,  0,  1091.89, -466.985, -105.084, 3.14159, 900, 2, 1.6, 0.60, 0.25, 1600, 3, 1.2, 100, 60, 25, 10000);

DELETE FROM `bonk_map_creature`;
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `min_sec`, `max_sec`, `weight`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(1,    38, 0,   0, 240, 10, 1.0, 1.0, 0.70, 1.0),
(1,   117, 0,   0,   0,  8, 1.0, 1.0, 0.70, 1.0),
(1,   454, 0,   0, 300,  6, 0.8, 1.0, 0.80, 1.0),
(1,   199, 0,   0, 300,  6, 0.6, 0.8, 0.85, 1.0),
(1,   515, 0,  60,   0,  6, 1.0, 1.0, 0.75, 1.0),
(1,    36, 0, 120,   0,  5, 1.6, 1.2, 0.60, 1.0),
(1,   481, 0, 120,   0,  6, 1.0, 1.0, 0.75, 1.0),
(1,   124, 0, 240,   0,  6, 1.4, 1.2, 0.70, 1.0),
(1,   157, 0, 240,   0,  5, 1.2, 1.0, 0.80, 1.0),
(1,   115, 0, 360,   0,  4, 2.0, 1.4, 0.65, 1.0),
(1,   122, 0, 360,   0,  5, 1.3, 1.2, 0.75, 1.0),
(1,   127, 0, 420,   0,  4, 1.2, 1.2, 0.80, 1.0),
(1,   506, 1,   0,   0,  3, 1.0, 1.0, 0.75, 1.3),
(1,   391, 1, 120,   0,  2, 1.0, 1.0, 0.75, 1.3),
(1,   596, 1, 200,   0,  2, 1.0, 1.0, 0.75, 1.3),
(1,   573, 1, 300,   0,  3, 1.3, 1.2, 0.65, 1.0),
(1,   639, 2,   0,   0,  1, 1.0, 1.0, 0.85, 1.5),
(2, 12265, 0,   0,   0, 10, 0.6, 0.8, 0.75, 0.6),
(2, 11669, 0,   0,   0, 10, 0.5, 0.8, 0.90, 1.0),
(2, 12099, 0,   0,   0,  6, 1.0, 1.0, 0.70, 0.8),
(2, 11671, 0,  60,   0,  8, 1.2, 1.0, 0.80, 0.8),
(2, 12076, 0, 120,   0,  6, 1.8, 1.2, 0.60, 0.7),
(2, 11666, 0, 180,   0,  6, 1.5, 1.2, 0.70, 0.8),
(2, 11667, 0, 180,   0,  6, 1.5, 1.2, 0.70, 0.8),
(2, 12101, 0, 240,   0,  5, 1.2, 1.0, 0.90, 0.7),
(2, 11672, 0, 300,   0,  5, 1.6, 1.3, 0.70, 0.7),
(2, 11668, 0, 360,   0,  4, 2.0, 1.4, 0.70, 0.8),
(2, 11661, 0, 420,   0,  5, 1.5, 1.3, 0.75, 0.6),
(2, 11658, 0, 540,   0,  3, 3.0, 1.6, 0.55, 0.6),
(2, 11673, 1,   0,   0,  3, 1.0, 1.0, 0.80, 0.8),
(2, 11665, 1, 200,   0,  2, 1.0, 1.0, 0.75, 0.7),
(2, 11659, 1, 300,   0,  2, 1.2, 1.2, 0.65, 0.6),
(2, 12100, 1, 400,   0,  2, 1.0, 1.0, 0.75, 0.7),
(2, 12119, 1, 400,   0,  2, 1.0, 1.0, 0.75, 0.6),
(2, 11982, 2,   0,   0,  1, 1.0, 1.0, 0.85, 0.8);

DELETE FROM `bonk_weapon`;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `max_level`) VALUES
( 1, 'Thunder Clap',     'Spell_Nature_ThunderClap',         'Shockwave around you that slows enemies.',          6343, 1, 2500,  8, 0.45,    1,    1, 8),
( 2, 'Throwing Axe',     'INV_ThrowingAxe_01',               'Hurls an axe that stuns the closest enemy.',       16075, 0, 3000, 30, 0.70,    3,    0, 8),
( 3, 'Consecration',     'Spell_Holy_InnerFire',             'Consecrates the ground under you.',               26573, 1, 6000,  8, 0.15,    2,    2, 8),
( 4, 'Hammer of Wrath',  'Ability_ThunderClap',              'Hurls a holy hammer at the closest enemy.',       24239, 0, 2400, 30, 0.80,    2,    0, 8),
( 5, 'Holy Nova',        'Spell_Holy_HolyNova',              'Burst of holy light around you.',                 15237, 1, 3000, 10, 0.40,   18,    0, 8),
( 6, 'Smite',            'Spell_Holy_HolySmite',             'Smites the closest enemy.',                         585, 0, 1800, 30, 0.55,   16,   16, 8),
( 7, 'Arcane Shot',      'Ability_ImpalingBolt',             'Arcane arrow at the closest enemy. Needs a bow or gun.', 3044, 0, 1700, 35, 0.50, 4, 4, 8),
( 8, 'Axe Flurry',       'Ability_Whirlwind',                'Flings axes that stun.',                          24020, 0, 4000, 30, 0.60,   13,    0, 8),
( 9, 'Throwing Knives',  'INV_ThrowingKnife_02',             'Knife at the closest enemy. Needs a thrown weapon.', 10277, 0, 1100, 25, 0.35, 8,  8, 8),
(10, 'Lightning Bolt',   'Spell_Nature_Lightning',           'Strikes the closest enemy.',                        403, 0, 1800, 30, 0.55,   64,   64, 8),
(11, 'Chain Lightning',  'Spell_Nature_ChainLightning',      'Lightning that jumps between enemies.',             421, 0, 4000, 30, 0.60,   64,    0, 8),
(12, 'Fire Nova',        'Spell_Fire_SealOfFire',            'Ring of fire around you.',                         8349, 1, 3500, 10, 0.45,   64,    0, 8),
(13, 'Frostbolt',        'Spell_Frost_FrostBolt02',          'Frost bolt at the closest enemy; slows.',           116, 0, 1600, 30, 0.50,  128,  128, 8),
(14, 'Fireball',         'Spell_Fire_FlameBolt',             'Big fireball at the closest enemy.',                133, 0, 2600, 35, 0.85,  384,    0, 8),
(15, 'Arcane Explosion', 'Spell_Nature_WispSplode',          'Arcane burst around you.',                         1449, 1, 2500, 10, 0.40,  128,    0, 8),
(16, 'Frost Nova',       'Spell_Frost_FrostNova',            'Freezes nearby enemies in place.',                  122, 1, 8000, 10, 0.30,  128,    0, 8),
(17, 'Shadow Bolt',      'Spell_Shadow_ShadowBolt',          'Shadow bolt at the closest enemy.',                 686, 0, 1800, 30, 0.55,  256,  256, 8),
(18, 'Corruption',       'Spell_Shadow_AbominationExplosion','Shadow damage over time on random enemies.',        172, 2, 1500, 30, 0.12,  256,    0, 8),
(19, 'Hellfire',         'Spell_Fire_Incinerate',            'Burns everything around you.',                     5857, 1, 2000, 10, 0.30,  256,    0, 8),
(20, 'Wrath',            'Spell_Nature_AbolishMagic',        'Nature bolt at the closest enemy.',                5176, 0, 1700, 30, 0.50, 1024, 1024, 8),
(21, 'Moonfire',         'Spell_Nature_StarFall',            'Burns random enemies with moonlight.',             8921, 2, 2000, 30, 0.45, 1024,    0, 8);

DELETE FROM `bonk_passive`;
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`) VALUES
(1, 'Might',      'Spell_Holy_FistOfJustice',   '+10% weapon damage.',               0, 10,  5),
(2, 'Haste',      'INV_Misc_PocketWatch_01',    'Weapons fire 8% faster.',           1,  8,  5),
(3, 'Duplicator', 'INV_Misc_Gem_Variety_01',    '+1 projectile for bolt weapons.',   2,  1,  2),
(4, 'Swiftness',  'Ability_Rogue_Sprint',       '+10% movement speed.',              3, 10,  5),
(5, 'Vitality',   'Spell_Holy_WordFortitude',   '+15% maximum health.',              4, 15,  5),
(6, 'Recovery',   'Spell_Nature_Rejuvenation',  'Regain 0.5% health every second.',  5, 0.5, 5),
(7, 'Greed',      'INV_Misc_Bag_10',            '+20% gold.',                        6, 20,  5),
(8, 'Growth',     'INV_Misc_Book_09',           '+15% experience.',                  7, 15,  5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
