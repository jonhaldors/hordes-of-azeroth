DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261107102000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261107102000');

DELETE FROM `creature_template` WHERE `entry` = 900170;
DROP TEMPORARY TABLE IF EXISTS `bonk_transmogrifier`;
CREATE TEMPORARY TABLE `bonk_transmogrifier` SELECT * FROM `creature_template` WHERE `entry` = 900160;
UPDATE `bonk_transmogrifier` SET `entry` = 900170, `name` = 'Esmeralda Glimmerstitch', `subname` = 'Transmogrifier', `npc_flags` = 1, `display_id1` = 8769,
  `display_id2` = 0, `display_id3` = 0, `display_id4` = 0, `equipment_id` = 0, `gossip_menu_id` = 0, `script_name` = '';
INSERT INTO `creature_template` SELECT * FROM `bonk_transmogrifier`;
DROP TEMPORARY TABLE IF EXISTS `bonk_transmogrifier`;

DELETE FROM `creature` WHERE `guid` = 900191;
DROP TEMPORARY TABLE IF EXISTS `bonk_transmogrifier_spawn`;
CREATE TEMPORARY TABLE `bonk_transmogrifier_spawn` SELECT * FROM `creature` WHERE `guid` = 900012;
UPDATE `bonk_transmogrifier_spawn` SET `guid` = 900191, `id` = 900170, `position_x` = 16224.0, `position_y` = 16299.22, `position_z` = 29.28, `orientation` = 0.65;
INSERT INTO `creature` SELECT * FROM `bonk_transmogrifier_spawn`;
DROP TEMPORARY TABLE IF EXISTS `bonk_transmogrifier_spawn`;

DELETE FROM `item_template` WHERE `entry` = 939000;
DROP TEMPORARY TABLE IF EXISTS `bonk_blank_tabard`;
CREATE TEMPORARY TABLE `bonk_blank_tabard` SELECT * FROM `item_template` WHERE `entry` = 5976;
UPDATE `bonk_blank_tabard` SET `entry` = 939000, `name` = 'Blank Tabard', `description` = '', `buy_price` = 5000, `sell_price` = 0, `bonding` = 1, `display_id` = 3864;
INSERT INTO `item_template` SELECT * FROM `bonk_blank_tabard`;
DROP TEMPORARY TABLE IF EXISTS `bonk_blank_tabard`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
