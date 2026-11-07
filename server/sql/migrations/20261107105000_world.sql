DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261107105000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261107105000');

DELETE FROM `item_template` WHERE `entry` BETWEEN 939001 AND 939007;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 23710 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939001, `patch` = 0, `name` = 'Darkmoon Tabard', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 11364 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939002, `patch` = 0, `name` = 'Tabard of Stormwind', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 23705 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939003, `patch` = 0, `name` = 'Tabard of Flame', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 23709 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939004, `patch` = 0, `name` = 'Tabard of Frost', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 7725 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939005, `patch` = 0, `name` = 'Tabard of the Scarlet Crusade', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 22999 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939006, `patch` = 0, `name` = 'Tabard of the Argent Dawn', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;
CREATE TEMPORARY TABLE `bonk_tabard_copy` SELECT * FROM `item_template` WHERE `entry` = 20132 ORDER BY `patch` DESC LIMIT 1;
UPDATE `bonk_tabard_copy` SET `entry` = 939007, `patch` = 0, `name` = 'Arathor Battle Tabard', `description` = '', `buy_price` = 0, `sell_price` = 0, `bonding` = 1, `required_reputation_faction` = 0, `required_reputation_rank` = 0, `required_level` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_tabard_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_tabard_copy`;

DELETE FROM `bonk_talent` WHERE `id` = 24;
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`, `rank_levels`) VALUES
(24, 'Darkmoon Tabard', 'Gives you a Darkmoon Tabard.', 22, 939001, 0, 1, 30, 0, 'INV_Shirt_GuildTabard_01', 8, 1, 4, 0, 0, '', '');

DELETE FROM `bonk_quest` WHERE `id` IN (577, 578, 579);
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(577, 'For the King', 'Clear Heroic 5.', 'INV_Shirt_GuildTabard_01', 3, 0, 0, 9, 15, 939002, 0, 1),
(578, 'Heart of the Mountain', 'Clear the Molten Core dungeon or its invasion.', 'INV_Shirt_GuildTabard_01', 41, 2, 0, 1, 15, 939003, 0, 3),
(579, 'Winter''s Edge', 'Clear Mythic 20.', 'INV_Shirt_GuildTabard_01', 3, 0, 0, 29, 15, 939004, 0, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
