DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011210000');

ALTER TABLE `bonk_weapon`
    ADD COLUMN `evolves_from` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'weapon this replaces once that is at max level; 0 = not an evolution',
    ADD COLUMN `evolve_passive` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'bonk_passive the player must own for the evolution';

DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 101 AND 110;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `max_level`, `evolves_from`, `evolve_passive`) VALUES
(101, 'Frostbolt Volley',   'Spell_Frost_IceStorm',        'Frost bolts at every enemy within 20 yards; they slow.',     22643, 1, 1800, 20, 0.45, 0, 0, 8, 13, 2),
(102, 'Fireball Volley',    'Spell_Fire_SelfDestruct',     'Fireballs at every enemy within 20 yards.',                  15285, 1, 2400, 20, 0.60, 0, 0, 8, 14, 1),
(103, 'Shadow Bolt Volley', 'Spell_Shadow_DeathCoil',      'Shadow bolts at every enemy within 30 yards.',               20741, 1, 2000, 30, 0.45, 0, 0, 8, 17, 3),
(104, 'Lightning Wave',     'Spell_Nature_CallStorm',      'Lightning that leaps between up to 10 enemies.',             24819, 0, 1800, 30, 0.60, 0, 0, 8, 10, 4),
(105, 'Starfire',           'Spell_Arcane_StarFire',       'Falling stars hit the closest enemies hard.',                 2912, 0, 1500, 35, 1.20, 0, 0, 8, 20, 8),
(106, 'Shockwave',          'Ability_WarStomp',            'Hits and stuns everything within 20 yards.',                 25425, 1, 4500, 20, 0.70, 0, 0, 8,  1, 5),
(107, 'Poisoned Blades',    'Spell_Nature_NullifyPoison',  'Poison bolts at every enemy within 30 yards; they burn on.', 24099, 1, 1800, 30, 0.30, 0, 0, 8,  9, 4),
(108, 'Arcane Barrage',     'Ability_Hunter_AimedShot',    'Arcane arrows twice as fast. Needs a bow or gun.',            3044, 0,  850, 35, 0.50, 0, 0, 8,  7, 3),
(109, 'Holy Fire',          'Spell_Holy_SearingLight',     'Holy flame that keeps burning the closest enemies.',         15261, 0, 1500, 30, 1.00, 0, 0, 8,  6, 6),
(110, 'Divine Wrath',       'Spell_Holy_Excorcism_02',     'Holy light that leaps between up to 50 enemies.',            23979, 0, 3000, 30, 0.45, 0, 0, 8,  3, 5);

DELETE FROM `bonk_passive` WHERE `id` = 9;
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`) VALUES
(9, 'Magnet', 'INV_Misc_Gem_Pearl_04', 'Experience orbs fly to you from 30% further away.', 8, 30, 5);

DROP TEMPORARY TABLE IF EXISTS `bonk_orb_template`;
CREATE TEMPORARY TABLE `bonk_orb_template` SELECT * FROM `creature_template` WHERE `entry` = 3681 AND `patch` = 0;
UPDATE `bonk_orb_template` SET `subname` = '', `faction` = 35, `npc_flags` = 0, `gossip_menu_id` = 0, `level_min` = 1, `level_max` = 1,
    `movement_type` = 0, `speed_walk` = 1, `speed_run` = 1, `detection_range` = 0, `call_for_help_range` = 0,
    `loot_id` = 0, `pickpocket_loot_id` = 0, `skinning_loot_id` = 0, `gold_min` = 0, `gold_max` = 0, `spell_list_id` = 0,
    `auras` = NULL, `ai_name` = '', `script_name` = '', `static_flags1` = 0, `static_flags2` = 0, `flags_extra` = 0, `civilian` = 0;

DELETE FROM `creature_template` WHERE `entry` BETWEEN 900100 AND 900102;
UPDATE `bonk_orb_template` SET `entry` = 900100, `name` = 'Experience Orb', `display_scale1` = 0.35;
INSERT INTO `creature_template` SELECT * FROM `bonk_orb_template`;
UPDATE `bonk_orb_template` SET `entry` = 900101, `name` = 'Large Experience Orb', `display_scale1` = 0.6;
INSERT INTO `creature_template` SELECT * FROM `bonk_orb_template`;
UPDATE `bonk_orb_template` SET `entry` = 900102, `name` = 'Huge Experience Orb', `display_scale1` = 0.9;
INSERT INTO `creature_template` SELECT * FROM `bonk_orb_template`;
DROP TEMPORARY TABLE `bonk_orb_template`;

CREATE TABLE IF NOT EXISTS `bonk_mob` (
    `entry`   INT UNSIGNED     NOT NULL COMMENT 'creature_template entry',
    `role`    TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 melee, 1 ranged: stops `range` yards away and casts, 2 exploder: blows up within `range` yards',
    `range`   FLOAT            NOT NULL DEFAULT 0,
    `comment` VARCHAR(255)     NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk enemy roles';

CREATE TABLE IF NOT EXISTS `bonk_mob_ability` (
    `entry`       INT UNSIGNED     NOT NULL COMMENT 'creature_template entry',
    `spell_id`    INT UNSIGNED     NOT NULL,
    `target`      TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 the player, 1 the enemy itself (areas around it, buffs)',
    `cooldown_ms` INT UNSIGNED     NOT NULL DEFAULT 8000,
    `first_ms`    INT UNSIGNED     NOT NULL DEFAULT 3000 COMMENT 'before the first cast',
    `min_range`   FLOAT            NOT NULL DEFAULT 0 COMMENT 'only when the player is at least this far...',
    `max_range`   FLOAT            NOT NULL DEFAULT 30 COMMENT '...and at most this far away',
    `damage`      FLOAT            NOT NULL DEFAULT 0 COMMENT 'hit damage in the enemy''s melee hits; 0 = the spell''s own',
    `comment`     VARCHAR(255)     NOT NULL DEFAULT '',
    PRIMARY KEY (`entry`, `spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk enemy abilities';

DELETE FROM `bonk_mob`;
INSERT INTO `bonk_mob` (`entry`, `role`, `range`, `comment`) VALUES
(  589, 1, 20,  'Defias Pillager: keeps its distance and casts'),
(  517, 1, 18,  'Murloc Oracle'),
(  596, 1, 18,  'Brainwashed Noble'),
(12265, 1, 20,  'Lava Spawn'),
(  480, 2, 3.5, 'Rusty Harvest Golem: blows up next to the player'),
(11669, 2, 3.5, 'Flame Imp'),
(12099, 2, 4,   'Firesworn');

DELETE FROM `bonk_mob_ability`;
INSERT INTO `bonk_mob_ability` (`entry`, `spell_id`, `target`, `cooldown_ms`, `first_ms`, `min_range`, `max_range`, `damage`, `comment`) VALUES
(  454,  6268, 1,  9000,  2000, 6,  30, 0,   'Young Goretusk: Rushing Charge (speed burst)'),
(  157,  6268, 1,  9000,  2000, 6,  30, 0,   'Goretusk: Rushing Charge'),
(  127, 11831, 1, 15000,  3000, 0,   8, 0.6, 'Murloc Tidehunter: Frost Nova'),
(  115,  7342, 0,  8000,  2000, 0,   5, 0,   'Harvest Reaper: Wide Slash'),
(  589,  9053, 0,  5000,  1500, 0,  30, 1.0, 'Defias Pillager: Fireball'),
(  517,  9672, 0,  5000,  2000, 0,  30, 0.8, 'Murloc Oracle: Frostbolt'),
(  480, 20602, 1,  1000,     0, 0,  10, 2.0, 'Rusty Harvest Golem: explodes (Fire Nova)'),
(  506,  3136, 1, 20000,  4000, 0,  30, 0,   'Sergeant Brashclaw: Frenzied Command'),
(  506,  5164, 0, 12000,  3000, 0,   5, 0,   'Sergeant Brashclaw: Knockdown'),
(  391,  3584, 0, 15000,  3000, 0,   5, 0,   'Old Murk-Eye: Volatile Infection'),
(  596,  9053, 0,  4000,  1500, 0,  30, 1.0, 'Brainwashed Noble: Fireball'),
(  573,  5568, 1,  8000,  3000, 0,   8, 0,   'Foe Reaper 4000: Trample'),
(  639,  3391, 1,  9000,  4000, 0,  10, 0,   'Edwin VanCleef: Thrash'),
(  647,  5208, 0, 10000,  3000, 6,  30, 1.2, 'Captain Greenskin: Poisoned Harpoon'),
(  647,  5532, 0,  7000,  2000, 0,   5, 0,   'Captain Greenskin: Cleave'),
(  644,  6304, 0, 12000,  4000, 0,   5, 1.5, 'Rhahk''Zor: Slam'),
(  646,  6432, 1, 15000,  6000, 0,  10, 0,   'Mr. Smite: Smite Stomp'),
(12265, 19391, 0,  4000,  1500, 0,  30, 0.9, 'Lava Spawn: Fireball'),
(11669, 20602, 1,  1000,     0, 0,  10, 1.5, 'Flame Imp: explodes (Fire Nova)'),
(12099, 19497, 1,  1000,     0, 0,  15, 2.5, 'Firesworn: Eruption'),
(11671, 22911, 0, 10000,  2000, 8,  25, 0,   'Core Hound: Charge'),
(12101, 22911, 0,  7000,  2000, 8,  25, 0,   'Lava Surger: Charge'),
(11673, 22911, 0,  8000,  2000, 8,  25, 0,   'Ancient Core Hound: Charge'),
(11667, 19630, 0,  8000,  3000, 0,  12, 1.2, 'Flameguard: Cone of Fire'),
(11661, 20277, 1, 14000,  4000, 0,   7, 0,   'Flamewaker: Fist of Ragnaros'),
(11658, 18944, 1, 10000,  4000, 0,   8, 1.5, 'Molten Giant: Smash'),
(12076, 19641, 0, 14000,  4000, 0,  15, 0.3, 'Lava Elemental: Pyroclast Barrage (per tick)'),
(11659, 19129, 1, 10000,  4000, 0,  10, 1.5, 'Molten Destroyer: Massive Tremor'),
(12119, 20605, 0,  6000,  2000, 0,   5, 0,   'Flamewaker Protector: Cleave'),
(12100, 20605, 0,  6000,  2000, 0,   5, 0,   'Lava Reaver: Cleave'),
(11982, 19408, 1, 30000, 15000, 0,  30, 0,   'Magmadar: Panic'),
(11982, 19451, 1, 25000, 10000, 0,  40, 0,   'Magmadar: Frenzy'),
(12057, 19496, 1, 15000,  6000, 0,  40, 0,   'Garr: Magma Shackles'),
(12118, 20603, 1,  9000,  4000, 0,  20, 1.2, 'Lucifron: Shadow Shock'),
(12118, 19702, 1, 25000,  8000, 0,  40, 1.5, 'Lucifron: Impending Doom'),
(12259, 19728, 0,  6000,  3000, 0,  35, 1.5, 'Gehennas: Shadow Bolt'),
(12259, 19716, 1, 25000,  8000, 0,  40, 0,   'Gehennas: Gehennas'' Curse');

DELETE FROM `bonk_map_creature` WHERE `bonk_map_id` = 1 AND `entry` IN (589, 517, 480);
INSERT INTO `bonk_map_creature` (`bonk_map_id`, `entry`, `kind`, `min_sec`, `max_sec`, `weight`, `health_multiplier`, `damage_multiplier`, `speed`, `scale`) VALUES
(1, 589, 0,  90, 0, 5, 0.8, 1.0, 0.70, 1.0),
(1, 517, 0, 180, 0, 4, 0.8, 1.0, 0.70, 1.0),
(1, 480, 0, 120, 0, 4, 0.5, 1.0, 0.95, 0.8);

DELETE FROM `bonk_map_event` WHERE `event` IN (4, 5);
INSERT INTO `bonk_map_event` (`bonk_map_id`, `second`, `event`, `count`) VALUES
(1, 150, 4, 16),
(1, 390, 5, 22),
(1, 510, 4, 24),
(2,  90, 4, 18),
(2, 210, 5, 25),
(2, 390, 4, 26),
(2, 510, 5, 32);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
