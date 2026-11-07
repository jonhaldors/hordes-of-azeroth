DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016260000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016260000');

DROP TEMPORARY TABLE IF EXISTS `bonk_keep_copy`;
CREATE TEMPORARY TABLE `bonk_keep_copy` SELECT `i`.* FROM `item_template` `i` JOIN `bonk_gear` `g` ON `g`.`entry` = `i`.`entry` WHERE `g`.`quality` IN (2, 3);
UPDATE `bonk_keep_copy` SET `entry` = `entry` + 1000, `description` = '',
    `sell_price` = IF(`quality` = 2, 1000, 2500), `buy_price` = IF(`quality` = 3, 30000, 0);
DELETE FROM `item_template` WHERE `entry` IN (SELECT `entry` FROM `bonk_keep_copy`);
INSERT INTO `item_template` SELECT * FROM `bonk_keep_copy`;
DROP TEMPORARY TABLE `bonk_keep_copy`;

DROP TEMPORARY TABLE IF EXISTS `bonk_stat_copy`;
CREATE TEMPORARY TABLE `bonk_stat_copy` SELECT `s`.* FROM `bonk_item_stat` `s` JOIN `bonk_gear` `g` ON `g`.`entry` = `s`.`entry` WHERE `g`.`quality` IN (2, 3);
DELETE FROM `bonk_item_stat` WHERE `entry` IN (SELECT `entry` + 1000 FROM `bonk_stat_copy`);
INSERT INTO `bonk_item_stat` (`entry`, `set_id`, `unlock_tier`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`)
SELECT `entry` + 1000, `set_id`, `unlock_tier`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`
FROM `bonk_stat_copy`;
DROP TEMPORARY TABLE `bonk_stat_copy`;

UPDATE `bonk_gear` SET `keep_entry` = `entry` + 1000 WHERE `quality` IN (2, 3);

DELETE FROM `item_template` WHERE `entry` BETWEEN 900430 AND 900437;
DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 900430 AND 900437;
DELETE FROM `bonk_gear` WHERE `entry` BETWEEN 900430 AND 900437;
DROP TEMPORARY TABLE IF EXISTS `bonk_set_copy`;
CREATE TEMPORARY TABLE `bonk_set_copy` SELECT * FROM `item_template` WHERE `entry` BETWEEN 900125 AND 900132;
UPDATE `bonk_set_copy` SET `entry` = `entry` + 305, `buy_price` = 0, `sell_price` = 0;
INSERT INTO `item_template` SELECT * FROM `bonk_set_copy`;
DROP TEMPORARY TABLE `bonk_set_copy`;

DROP TEMPORARY TABLE IF EXISTS `bonk_stat_copy`;
CREATE TEMPORARY TABLE `bonk_stat_copy` SELECT * FROM `bonk_item_stat` WHERE `entry` BETWEEN 900125 AND 900132;
INSERT INTO `bonk_item_stat` (`entry`, `set_id`, `unlock_tier`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`)
SELECT `entry` + 305, `set_id`, 0, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`
FROM `bonk_stat_copy`;
DROP TEMPORARY TABLE `bonk_stat_copy`;

INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`)
SELECT `entry` + 305, 4, `entry` FROM `item_template` WHERE `entry` BETWEEN 900125 AND 900132;

UPDATE `item_template` SET `description` = 'Run gear: put it in the Extraction Vault to keep it.'
WHERE `entry` IN (SELECT `entry` FROM `bonk_gear`);

UPDATE `npc_vendor` SET `slot` = `slot` + 38 WHERE `entry` = 900004 AND `item` BETWEEN 902000 AND 902199;
DELETE FROM `npc_vendor` WHERE `entry` = 900004 AND `item` IN (SELECT `entry` + 1000 FROM `bonk_gear` WHERE `quality` = 3);
DROP TEMPORARY TABLE IF EXISTS `bonk_vendor_copy`;
CREATE TEMPORARY TABLE `bonk_vendor_copy` SELECT `entry` + 1000 AS `item`, ROW_NUMBER() OVER (ORDER BY `entry`) AS `n` FROM `bonk_gear` WHERE `quality` = 3;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT 900004, 32 + `n`, `item`, 0, 0, 0, 0 FROM `bonk_vendor_copy`;
DROP TEMPORARY TABLE `bonk_vendor_copy`;

DELETE FROM `gameobject_template` WHERE `entry` = 900041;
DROP TEMPORARY TABLE IF EXISTS `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900003;
UPDATE `bonk_go_copy` SET `entry` = 900041, `displayId` = 1287, `name` = 'Extraction Vault', `size` = 1.5, `script_name` = 'go_bonk_vault';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;

DELETE FROM `npc_text` WHERE `ID` IN (900010, 900011);
DELETE FROM `broadcast_text` WHERE `entry` IN (900010, 900011);
DROP TEMPORARY TABLE IF EXISTS `bonk_text_copy`;
CREATE TEMPORARY TABLE `bonk_text_copy` SELECT * FROM `broadcast_text` WHERE `entry` = 900002;
UPDATE `bonk_text_copy` SET `entry` = 900010,
    `male_text` = 'Nothing is in the Extraction Vault. Go home anyway? Every piece you found will be sold for gold.',
    `female_text` = 'Nothing is in the Extraction Vault. Go home anyway? Every piece you found will be sold for gold.';
INSERT INTO `broadcast_text` SELECT * FROM `bonk_text_copy`;
UPDATE `bonk_text_copy` SET `entry` = 900011,
    `male_text` = 'Bixi''s vault. Whatever you leave inside is waiting in your mailbox when you get home; the rest of your finds are sold.',
    `female_text` = 'Bixi''s vault. Whatever you leave inside is waiting in your mailbox when you get home; the rest of your finds are sold.';
INSERT INTO `broadcast_text` SELECT * FROM `bonk_text_copy`;
DROP TEMPORARY TABLE `bonk_text_copy`;
DROP TEMPORARY TABLE IF EXISTS `bonk_npc_text_copy`;
CREATE TEMPORARY TABLE `bonk_npc_text_copy` SELECT * FROM `npc_text` WHERE `ID` = 900002;
UPDATE `bonk_npc_text_copy` SET `ID` = 900010, `BroadcastTextID0` = 900010;
INSERT INTO `npc_text` SELECT * FROM `bonk_npc_text_copy`;
UPDATE `bonk_npc_text_copy` SET `ID` = 900011, `BroadcastTextID0` = 900011;
INSERT INTO `npc_text` SELECT * FROM `bonk_npc_text_copy`;
DROP TEMPORARY TABLE `bonk_npc_text_copy`;

DELETE FROM `bonk_upgrade` WHERE `id` = 28;
INSERT INTO `bonk_upgrade` (`id`, `name`, `description`, `effect`, `value_per_rank`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(28, 'Pack Mule', 'A second slot in the Extraction Vault: bring one more piece of run gear home.', 112, 1, 1, 250000, 1, 'INV_Misc_Bag_08', 3, 3, 2, 25, 5);
DELETE FROM `bonk_quest` WHERE `id` = 14;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(14, 'Beast of Burden', 'Clear Heroic.', 'INV_Misc_Bag_08', 3, 3, 0, 3, 5, 28, 0, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
