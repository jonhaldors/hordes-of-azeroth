DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016320000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016320000');

CREATE TABLE IF NOT EXISTS `bonk_glyph` (
    `id`          INT UNSIGNED NOT NULL,
    `name`        VARCHAR(64) NOT NULL,
    `icon`        VARCHAR(64) NOT NULL DEFAULT 'INV_Misc_QuestionMark',
    `description` VARCHAR(255) NOT NULL DEFAULT '',
    `drawback`    VARCHAR(255) NOT NULL DEFAULT '' COMMENT 'empty: none',
    `rarity`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `effect`      TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `value1`      FLOAT NOT NULL DEFAULT 0,
    `value2`      FLOAT NOT NULL DEFAULT 0,
    `value3`      FLOAT NOT NULL DEFAULT 0,
    `card_id`     INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'a hidden bonk_card it gives (in_chests 0)',
    `starter`     TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'every account has it',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk Glyphs';

DELETE FROM `bonk_card` WHERE `id` BETWEEN 150 AND 159;
INSERT INTO `bonk_card` (`id`, `name`, `icon`, `description`, `rarity`, `stat1`, `stat1_value`, `stat2`, `stat2_value`, `effect`, `value1`, `value2`, `value3`, `cooldown_ms`, `max_copies`, `in_chests`) VALUES
(150, 'Glyph of the Scholar',         'INV_Misc_Book_11',               '+15% experience.',                      0, 7,   15,  255, 0, 0,  0,  0, 0, 0, 1, 0),
(151, 'Glyph of the Packrat',         'INV_Misc_Bag_10',                '+20% pickup range.',                    0, 8,   20,  255, 0, 0,  0,  0, 0, 0, 1, 0),
(152, 'Glyph of Hunter''s Mark',      'Ability_Hunter_SniperShot',      '+10% damage to elites and bosses.',     1, 255, 0,   255, 0, 18, 10, 0, 0, 0, 1, 0),
(153, 'Glyph of Windfury',            'Spell_Nature_Windfury',          '15% chance a spell goes off again.',    2, 255, 0,   255, 0, 13, 15, 0, 0, 0, 1, 0),
(154, 'Glyph of Goblin Engineering',  'INV_Misc_Bomb_04',               '+30% Valor.',                           1, 255, 0,   255, 0, 19, 30, 0, 0, 0, 1, 0),
(155, 'Glyph of Berserker Rage',      'Spell_Nature_AncestralGuardian', '+25% Power.',                           2, 0,   25,  255, 0, 0,  0,  0, 0, 0, 1, 0),
(156, 'Glyph of the Twisted Nether',  'Spell_Shadow_Twilight',          'Double experience.',                    3, 7,   100, 255, 0, 0,  0,  0, 0, 0, 1, 0);

DELETE FROM `bonk_glyph`;
INSERT INTO `bonk_glyph` (`id`, `name`, `icon`, `description`, `drawback`, `rarity`, `effect`, `value1`, `value2`, `value3`, `card_id`, `starter`) VALUES
(1,  'Glyph of the Scholar',        'INV_Misc_Book_11',               '+15% experience.', '', 0, 0, 0, 0, 0, 150, 1),
(2,  'Glyph of the Packrat',        'INV_Misc_Bag_10',                '+20% pickup range, and power-ups lie about 50% longer.', '', 0, 1, 50, 0, 0, 151, 1),
(3,  'Glyph of Thrift',             'INV_Misc_Coin_03',               'Chests cost 15% less Valor.', '', 0, 2, 15, 0, 0, 0, 1),
(4,  'Glyph of Hunter''s Mark',     'Ability_Hunter_SniperShot',      '+10% damage to elites, mini-bosses and bosses.', '', 1, 0, 0, 0, 0, 152, 1),
(5,  'Glyph of Second Wind',        'Spell_Nature_Rejuvenation',      'An elite, mini-boss or boss dying within 30 yards heals you for 2% of your maximum health.', '', 1, 3, 2, 30, 0, 0, 1),
(6,  'Glyph of the Ley Line',       'Spell_Nature_AstralRecal',       'Ley Lines capture twice as fast and offer 4 blessings.', '', 1, 4, 100, 1, 0, 0, 1),
(7,  'Glyph of Windfury',           'Spell_Nature_Windfury',          '15% chance for any spell to go off a second time.', '', 2, 0, 0, 0, 0, 153, 1),
(8,  'Glyph of Bloodlust',          'Spell_Nature_BloodLust',         'Every 50 kills: +30% Haste for 8 seconds.', '', 2, 5, 50, 30, 8000, 0, 1),
(9,  'Glyph of Goblin Engineering', 'INV_Misc_Bomb_04',               '+30% Valor.', '1 chest in 10 blows up in your face for 10% of your maximum health.', 1, 6, 10, 10, 0, 154, 0),
(10, 'Glyph of Berserker Rage',     'Spell_Nature_AncestralGuardian', '+25% Power.', 'Your Armor is halved.', 2, 7, 0, 0, 0, 155, 0),
(11, 'Glyph of Divine Shield',      'Spell_Holy_DivineIntervention',  'Once each stage, death instead brings you back at 40% health.', '', 3, 8, 40, 0, 0, 0, 0),
(12, 'Glyph of Soul Harvest',       'INV_Misc_Gem_Amethyst_02',       'Every 50 kills, your next hit deals triple damage.', '', 3, 9, 50, 3, 0, 0, 0),
(13, 'Glyph of Vengeance',          'Ability_Warrior_Revenge',        '+1% Power for every 2% of health you are missing.', '', 3, 10, 2, 0, 0, 0, 0),
(14, 'Glyph of the Twisted Nether', 'Spell_Shadow_Twilight',          'Double experience.', 'No turkey legs, and no Restoration power-ups.', 3, 11, 0, 0, 0, 156, 0),
(15, 'Glyph of the Gambler',        'Ability_Rogue_SliceDice',        'Spell ranks at level-ups roll one rarity higher.', 'Level-ups offer only 2 choices, and you can''t reroll.', 3, 12, 2, 0, 0, 0, 0),
(16, 'Glyph of the Windseeker',     'Spell_Nature_CallStorm',         'Every 5 seconds, lightning strikes up to 5 enemies near you. These strikes always crit.', '', 4, 13, 5000, 5, 2, 0, 0),
(17, 'Glyph of Ragnaros',           'Spell_Fire_Fireball02',          'Every 10 seconds, a meteor crashes into the thickest crowd of enemies near you.', '', 4, 14, 10000, 4, 8, 0, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 400 AND 408;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(400, 'Tinkerer',          'Buy 25 chests with Valor.',                         'INV_Misc_Bomb_04',               31, 0, 0,  25,    12, 9,  0, 3),
(401, 'Seeing Red',        'Kill 100 elites.',                                  'Spell_Nature_AncestralGuardian', 1,  1, 0,  100,   12, 10, 0, 3),
(402, 'Fallen Hero',       'Die 10 times.',                                     'Spell_Holy_DivineIntervention',  37, 0, 0,  10,    12, 11, 0, 3),
(403, 'Reaper',            'Kill 10,000 enemies.',                              'INV_Misc_Gem_Amethyst_02',       0,  0, 0,  10000, 12, 12, 0, 3),
(404, 'Last Stand',        'Kill a stage boss with your health below 25%.',     'Ability_Warrior_Revenge',        25, 2, 25, 1,     12, 13, 0, 3),
(405, 'Hungry for More',   'Reach level 50 in a single run.',                   'Spell_Shadow_Twilight',          4,  0, 0,  50,    12, 14, 0, 3),
(406, 'High Roller',       'Catch 10 treasure goblins.',                        'Ability_Rogue_SliceDice',        33, 1, 0,  10,    12, 15, 0, 3),
(407, 'Eye of the Storm',  'Clear Mythic.',                                     'Spell_Nature_CallStorm',         3,  2, 0,  4,     12, 16, 0, 3),
(408, 'Firelord''s Favor', 'Kill 25 stage bosses.',                             'Spell_Fire_Fireball02',          1,  2, 0,  25,    12, 17, 0, 3);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
