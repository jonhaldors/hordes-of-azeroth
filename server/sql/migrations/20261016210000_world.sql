DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016210000');

UPDATE `bonk_shop_tree` SET `name` = 'Mobility',   `background` = 'RogueCombat'      WHERE `id` = 1;
UPDATE `bonk_shop_tree` SET `name` = 'Fortune',    `background` = 'PaladinHoly'      WHERE `id` = 2;
UPDATE `bonk_shop_tree` SET `name` = 'Expedition', `background` = 'HunterSurvival'   WHERE `id` = 3;
DELETE FROM `bonk_shop_tree` WHERE `id` = 6;
INSERT INTO `bonk_shop_tree` (`id`, `shop`, `name`, `background`) VALUES (6, 1, 'Provisions', 'DruidRestoration');

DELETE FROM `bonk_upgrade` WHERE `id` IN (1, 2, 3, 9, 10, 11, 12, 13) OR `id` BETWEEN 16 AND 27;
UPDATE `bonk_upgrade` SET `tree` = 1, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 5;
UPDATE `bonk_upgrade` SET `tree` = 2, `tree_row` = 1, `tree_column` = 1 WHERE `id` = 6;
UPDATE `bonk_upgrade` SET `tree` = 2, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 15;
UPDATE `bonk_upgrade` SET `tree` = 2, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 14;

INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(16, 'Dash Range',       '+0.8 yards to your dash.',                                                       100, 0.8, 5, 4000,  1.4, 'Ability_Druid_Dash',               1, 1, 3, 0, 0),
(17, 'Dash Cooldown',    '-0.6 sec on your dash''s cooldown.',                                             101, 0.6, 5, 5000,  1.4, 'INV_Misc_PocketWatch_01',          1, 2, 3, 0, 0),
(18, 'Second Dash',      'Your dash holds a second charge.',                                                102, 1,   1, 40000, 1,   'Ability_Rogue_Sprint',             1, 3, 3, 17, 3),
(19, 'Haggle',           '-4% on Valor chests and the wandering vendor''s wares.',                          103, 4,   5, 5000,  1.4, 'INV_Misc_Coin_03',                 2, 2, 1, 0, 0),
(22, 'Insight',          'Level-ups offer one more card to choose from.',                                   106, 1,   1, 50000, 1,   'Spell_Holy_MindVision',            2, 2, 2, 15, 3),
(20, 'Scrapper',         '+10% Valor from salvaged gear.',                                                  104, 10,  5, 3500,  1.4, 'INV_Misc_Gear_01',                 2, 2, 3, 0, 0),
(21, 'Card Shark',       'Chests offer one more Darkmoon Card to choose from.',                             105, 1,   1, 30000, 1,   'INV_Misc_Ticket_Tarot_Heroism_01', 2, 3, 3, 0, 0),
(23, 'Bounty Hunter',    '+2 sec to catch a treasure goblin or kill a bounty, and a longer head start.',    107, 2,   5, 3500,  1.4, 'INV_Misc_Bone_HumanSkull_01',      3, 1, 2, 0, 0),
(24, 'Attunement',       '+8% capture speed at Ley Lines and +8% Moonwell time.',                           108, 8,   5, 4000,  1.4, 'Spell_Holy_PowerInfusion',         3, 1, 3, 0, 0),
(25, 'Hearthstone Lore', '+20% chance to find a Hearthstone; each rank also takes a second off its ring.',  109, 20,  5, 5000,  1.4, 'INV_Misc_Rune_01',                 3, 2, 2, 0, 0),
(26, 'Head Start',       '+1 to the level runs start at, with the picks it brings.',                        110, 1,   2, 15000, 2,   'INV_Scroll_03',                    6, 1, 2, 0, 0),
(27, 'Lucky Draw',       'Runs start with a random Darkmoon Card: a common one, an uncommon one at rank 2.', 111, 1,  2, 20000, 2,   'INV_Misc_Ticket_Tarot_BlueDragon_01', 6, 1, 3, 0, 0);

ALTER TABLE `bonk_item_stat` ADD COLUMN IF NOT EXISTS `max_health` FLOAT NOT NULL DEFAULT 0 AFTER `power`;
UPDATE `bonk_item_stat` SET `max_health` = 3 WHERE `entry` BETWEEN 900113 AND 900116;
UPDATE `bonk_item_stat` SET `max_health` = 5 WHERE `entry` BETWEEN 900117 AND 900120;
UPDATE `bonk_item_stat` SET `max_health` = 8 WHERE `entry` BETWEEN 900121 AND 900124;
UPDATE `bonk_item_stat` SET `max_health` = 6 WHERE `entry` BETWEEN 900125 AND 900128;

ALTER TABLE `bonk_talent` ADD COLUMN IF NOT EXISTS `rank_quests` VARCHAR(64) NOT NULL DEFAULT '' AFTER `required_rank`;
UPDATE `bonk_talent` SET `rank_quests` = '15,35,55' WHERE `id` = 10;
UPDATE `bonk_talent` SET `rank_quests` = '25,45'    WHERE `id` = 11;
UPDATE `bonk_quest` SET `reward_value` = 5  WHERE `id` = 256;
UPDATE `bonk_quest` SET `reward_value` = 9  WHERE `id` = 208;
UPDATE `bonk_quest` SET `reward_value` = 10 WHERE `id` = 209;
UPDATE `bonk_quest` SET `reward_value` = 6  WHERE `id` = 257;
UPDATE `bonk_quest` SET `reward_value` = 11 WHERE `id` = 210;

DROP TEMPORARY TABLE IF EXISTS `bonk_quest_amount`;
CREATE TEMPORARY TABLE `bonk_quest_amount` (`id` INT UNSIGNED NOT NULL PRIMARY KEY, `amount` INT UNSIGNED NOT NULL);
INSERT INTO `bonk_quest_amount` VALUES
    (1, 500), (2, 7500), (3, 30000),
    (212, 40000), (213, 40000), (214, 40000), (215, 40000), (216, 40000), (217, 40000), (218, 40000), (219, 40000), (220, 40000),
    (34, 10), (4, 30), (49, 60), (5, 15),
    (20, 2000), (21, 2000), (22, 2000), (23, 2000), (24, 2000), (25, 2000), (26, 2000), (27, 2000), (28, 2000),
    (30, 500), (31, 500), (33, 500),
    (40, 1500), (41, 1500), (42, 1500), (43, 1500), (44, 1500), (45, 1500), (46, 1500), (47, 1500), (48, 1500),
    (32, 20), (11, 30), (50, 40), (12, 50),
    (13, 25), (200, 2000), (201, 30000), (202, 5000),
    (221, 10000), (222, 10000), (223, 10000), (224, 10000), (225, 10000), (226, 10000), (227, 10000),
    (228, 1500), (230, 15), (231, 30), (232, 2000),
    (241, 15000), (242, 1500), (243, 15000), (244, 60), (245, 20), (254, 20000);
UPDATE `bonk_quest` AS `q` JOIN `bonk_quest_amount` AS `n` ON `n`.`id` = `q`.`id`
SET `q`.`description` = REPLACE(`q`.`description`, FORMAT(`q`.`amount`, 0), FORMAT(`n`.`amount`, 0)), `q`.`amount` = `n`.`amount`;
DROP TEMPORARY TABLE `bonk_quest_amount`;
UPDATE `bonk_quest` SET `amount` = 180, `description` = 'Go 3 minutes without being hit in a run.' WHERE `id` = 237;

UPDATE `bonk_quest` SET
    `description` = REPLACE(`description`, FORMAT(`amount`, 0), FORMAT(CASE `amount` WHEN 10 THEN 25 ELSE 60 END, 0)),
    `amount` = CASE `amount` WHEN 10 THEN 25 ELSE 60 END
WHERE `category` = 2 AND `type` = 1 AND `amount` IN (10, 25);
UPDATE `bonk_quest` SET
    `description` = REPLACE(`description`, FORMAT(`amount`, 0), FORMAT(CASE `amount` WHEN 750 THEN 2500 ELSE 3000 END, 0)),
    `amount` = CASE `amount` WHEN 750 THEN 2500 ELSE 3000 END
WHERE `category` = 2 AND `type` = 2 AND `amount` IN (750, 1000);
UPDATE `bonk_quest` SET `description` = REPLACE(`description`, '30', '50'), `amount` = 50
WHERE `category` = 2 AND `type` = 4 AND `amount` = 30;

UPDATE `item_template` SET `sell_price` = 10000 WHERE `entry` BETWEEN 901300 AND 901499 AND `quality` = 4;
UPDATE `item_template` SET `sell_price` = 50000 WHERE `entry` BETWEEN 901300 AND 901499 AND `quality` = 5;

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 300 AND 317;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(300, 'Field Medic',          'Heal 25,000 health, across all your runs.',                  'INV_Stone_04',                         7,  0, 0,  25000, 11, 1,  0, 5),
(301, 'Stone Skin',           'Reach 3,000 maximum health in a run.',                       'INV_Misc_Gem_Emerald_02',              22, 0, 0,  3000,  11, 3,  0, 3),
(302, 'Campfire Tales',       'Slay 1,500 enemies while standing still.',                   'Spell_Fire_Fire',                      19, 0, 0,  1500,  11, 6,  0, 3),
(303, 'Heroic Strikes',       'Land 3,000 critical strikes in a single run.',               'INV_Misc_Ticket_Tarot_Heroism_01',     6,  0, 0,  3000,  11, 8,  0, 3),
(304, 'Lifegiver',            'Heal 100,000 health, across all your runs.',                 'INV_Misc_Gem_Ruby_01',                 7,  0, 0,  100000, 11, 9, 0, 5),
(305, 'Reactive Plating',     'Let Armor take 20,000 damage off enemy hits.',               'INV_Shield_15',                        30, 0, 0,  20000, 11, 11, 0, 5),
(306, 'Clean Hands',          'Go 4 minutes without being hit in a run.',                   'INV_Jewelry_TrinketPVP_01',            26, 0, 0,  240,   11, 13, 0, 3),
(307, 'Second Life',          'Die 25 times.',                                              'Spell_Shadow_SoulGem',                 37, 0, 0,  25,    11, 15, 0, 5),
(308, 'Firelord',             'Slay 15,000 enemies with fire spells.',                      'INV_Hammer_Unique_Sulfuras',           18, 3, 0,  15000, 11, 16, 0, 0),
(309, 'Relentless',           'Fire 50,000 bolts.',                                         'INV_Hammer_09',                        36, 0, 0,  50000, 11, 17, 0, 5),
(310, 'Lightning Rod',        'Slay 10,000 enemies with nature spells.',                    'INV_Misc_Ticket_Tarot_Maelstrom_01',   18, 4, 0,  10000, 11, 18, 0, 0),
(311, 'Disintegrate',         'Kill a stage boss within 20 seconds of its arrival.',        'INV_Gizmo_08',                         23, 2, 20, 1,     11, 19, 0, 3),
(312, 'Bloodlust',            'Kill 60,000 enemies.',                                       'INV_Jewelry_Necklace_13',              0,  0, 0,  60000, 11, 20, 0, 0),
(313, 'Hero of Zandalar',     'Kill 100 elites.',                                           'INV_Jewelry_Talisman_10',              1,  1, 0,  100,   11, 21, 0, 0),
(314, 'Champion',             'Kill 25 mini-bosses.',                                       'INV_Jewelry_Talisman_07',              1,  3, 0,  25,    11, 24, 0, 0),
(315, 'Ground Breaker',       'Slay 10,000 enemies with physical attacks.',                 'INV_Jewelry_Talisman_04',              18, 1, 0,  10000, 11, 25, 0, 0),
(316, 'Magnetic Personality', 'Find 100 Darkmoon Tickets.',                                 'INV_Gizmo_02',                         5,  0, 0,  100,   11, 28, 0, 5),
(317, 'Lockpicker',           'Buy 100 chests.',                                            'INV_Misc_Key_14',                      31, 0, 0,  100,   11, 29, 0, 5);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
