DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012180000');

ALTER TABLE `bonk_weapon`
    ADD COLUMN `base_targets` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'enemies fired at before ranks and passives' AFTER `tick_ms`,
    ADD COLUMN `alt_spell_id` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'what a behavior casts, or every alt_every-th cast' AFTER `base_targets`,
    ADD COLUMN `alt_every` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `alt_spell_id`,
    ADD COLUMN `alt_damage` FLOAT NOT NULL DEFAULT 1 COMMENT 'times the weapon''s damage for the alt spell' AFTER `alt_every`;

DELETE FROM `bonk_weapon` WHERE `id` IN (45, 145, 101, 102);
UPDATE `bonk_quest` SET `reward_value` = 163 WHERE `id` = 46 AND `reward_type` = 2 AND `reward_value` = 45;
UPDATE `bonk_mastery` SET `target` = 163, `name` = 'Improved Scorch', `description` = 'Scorch recharges 6% faster.' WHERE `id` = 80204;
UPDATE `bonk_mastery` SET `target` = 163, `description` = '+8% Scorch damage.' WHERE `id` = 80205;

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`,
    `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`,
    `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`) VALUES
(160, 'Arcane Missiles', 'Spell_Nature_StarFall',                 'Three arcane missiles at the nearest enemies.',
    7268,  0,  2000, 30, 0.35, 128, 0,   0, 0, 0,    0,  0,    0,   0, 3,     0, 0, 1),
(161, 'Flamestrike',     'Spell_Fire_SelfDestruct',               'A pillar of fire on the biggest pack of enemies that leaves the ground burning.',
    2120,  3,  6000, 30, 0.6,  128, 0,   0, 0, 0,    0,  0,    0,   0, 1,     0, 0, 1),
(162, 'Cone of Cold',    'Spell_Frost_Glacier',                   'A cone of frost in front of you that slows.',
    120,   1,  3000, 10, 0.5,  128, 0,   0, 0, 0,    0,  0,    0,   0, 1,     0, 0, 1),
(163, 'Scorch',          'Spell_Fire_SoulBurn',                   'A quick, short-range fire bolt; every hit makes the enemy take more fire damage.',
    2948,  0,  1000, 20, 0.3,  128, 0,   0, 0, 0,    0, 10,    0,   0, 1, 22959, 0, 1),
(164, 'Mana Shield',     'Spell_Shadow_DetectLesserInvisibility', 'Shields you for 8% of your maximum health every 10 seconds.',
    1463,  1, 10000,  0, 0.5,  128, 0,   0, 0, 0,    0,  4,    8,   0, 1,     0, 0, 1),
(170, 'Frozen Orb',      'Spell_Frost_Wisp',                      'A slow orb of frost rolls ahead, firing frostbolts at the enemies it passes.',
    116,   0,  4000, 12, 0.45,   0, 0,  13, 0, 6000, 0,  7,    0, 600, 1,     0, 0, 1),
(171, 'Pyroblast',       'Spell_Fire_Fireball02',                 'Fireballs, and every fourth cast a huge Pyroblast that burns on.',
    133,   0,  2400, 35, 0.85,   0, 0,  14, 0, 0,    0,  0,    0,   0, 1, 11366, 4, 3),
(172, 'Arcane Barrage',  'Spell_Arcane_StarFire',                 'A stream of arcane missiles at the nearest enemies.',
    7268,  0,   900, 30, 0.35,   0, 0, 160, 0, 0,    0,  0,    0,   0, 5,     0, 0, 1),
(173, 'Ice Barrier',     'Spell_Ice_Lament',                      'Freezes the enemies around you; each one shields you for 2% of your maximum health.',
    122,   1,  8000, 10, 0.3,    0, 0,  16, 0, 0,    0,  5,    2,   0, 1,     0, 0, 1),
(174, 'Absolute Zero',   'Spell_Frost_IceStorm',                  'Blizzard on the biggest pack of enemies; three seconds later everything in it freezes solid.',
    26607, 3,  5000, 28, 0.3,    0, 0,  22, 0, 6000, 0,  6, 3000,   0, 1, 12494, 0, 1),
(175, 'Arcane Nova',     'Spell_Nature_WispSplode',               'An arcane pulse around you, then a second, wider one.',
    1449,  1,  2500, 10, 0.45,   0, 0,  15, 0, 0,    0,  3,  500,   0, 1,     0, 0, 1),
(176, 'Meteor',          'Spell_Fire_MeteorStorm',                'Flamestrike, and a moment later a meteor crashes onto the same spot.',
    2120,  3,  6000, 30, 0.6,    0, 0, 161, 0, 0,    0,  6, 1000,   0, 1, 24340, 0, 3),
(177, 'Deep Freeze',     'Spell_Frost_ChainsOfIce',               'A cone of frost that freezes the enemies in front of you; frozen enemies take 50% more crit damage.',
    120,   1,  3000, 10, 0.55,   0, 0, 162, 0, 0,    0,  8,    0,   0, 1, 12494, 0, 1),
(178, 'Living Bomb',     'INV_Misc_Bomb_06',                      'Quick fire bolts; three seconds after a hit, the enemy explodes in flames.',
    2948,  0,  1000, 20, 0.3,    0, 0, 163, 0, 0,    0,  6, 3000,   0, 1,  2120, 0, 1.5),
(179, 'Arcane Ward',     'Spell_Arcane_ArcaneResilience',         'Shields you for 10% of your maximum health every 10 seconds; when it breaks, an arcane blast goes off around you.',
    1463,  1, 10000, 10, 0.5,    0, 0, 164, 0, 0,    0,  9,   10,   0, 1,  1449, 0, 2);

UPDATE `bonk_weapon` SET `name` = 'Shadowburn', `icon` = 'Spell_Shadow_ScourgeBuild',
    `description` = 'Shadow bolts that deal triple damage to enemies below 20% health.',
    `spell_id` = 686, `target` = 0, `cooldown_ms` = 1800, `range` = 30, `damage_fraction` = 0.6,
    `behavior` = 11, `behavior_value` = 20, `alt_damage` = 3
WHERE `id` = 103;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
