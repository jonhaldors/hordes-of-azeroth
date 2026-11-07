DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016250000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016250000');

ALTER TABLE `bonk_item_stat` ADD COLUMN IF NOT EXISTS `unlock_tier` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `set_id`;

DELETE FROM `item_template` WHERE `entry` BETWEEN 902000 AND 902199;
DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 902000 AND 902199;
DELETE FROM `npc_vendor` WHERE `entry` = 900004 AND `item` BETWEEN 902000 AND 902199;
DELETE FROM `bonk_item_set` WHERE `id` BETWEEN 3 AND 6;
DELETE FROM `bonk_item_set_bonus` WHERE `set_id` BETWEEN 3 AND 6;

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_copy`;
CREATE TEMPORARY TABLE `bonk_gear_copy` SELECT * FROM `item_template` WHERE `entry` BETWEEN 900101 AND 900132;
UPDATE `bonk_gear_copy` SET `entry` = `entry` + 1899, `name` = CONCAT('Heroic ', `name`), `buy_price` = `buy_price` * 3, `sell_price` = `sell_price` * 3;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_copy`;
DROP TEMPORARY TABLE `bonk_gear_copy`;
CREATE TEMPORARY TABLE `bonk_gear_copy` SELECT * FROM `item_template` WHERE `entry` BETWEEN 900101 AND 900132;
UPDATE `bonk_gear_copy` SET `entry` = `entry` + 1999, `name` = CONCAT('Mythic ', `name`), `buy_price` = `buy_price` * 8, `sell_price` = `sell_price` * 8;
INSERT INTO `item_template` SELECT * FROM `bonk_gear_copy`;
DROP TEMPORARY TABLE `bonk_gear_copy`;

DROP TEMPORARY TABLE IF EXISTS `bonk_stat_copy`;
CREATE TEMPORARY TABLE `bonk_stat_copy` SELECT * FROM `bonk_item_stat` WHERE `entry` BETWEEN 900101 AND 900132;
INSERT INTO `bonk_item_stat` (`entry`, `set_id`, `unlock_tier`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`)
SELECT `entry` + 1899, CASE `set_id` WHEN 1 THEN 3 WHEN 2 THEN 4 ELSE 0 END, 1,
    `power` * 1.5, `max_health` * 1.5, `armor` * 1.5, `dodge` * 1.5, `hit` * 1.5, `crit` * 1.5, `crit_damage` * 1.5, `shield` * 1.5, `haste` * 1.5,
    `area` * 1.5, `pickup_range` * 1.5, `luck` * 1.5
FROM `bonk_stat_copy`;
DROP TEMPORARY TABLE `bonk_stat_copy`;
CREATE TEMPORARY TABLE `bonk_stat_copy` SELECT * FROM `bonk_item_stat` WHERE `entry` BETWEEN 900101 AND 900132;
INSERT INTO `bonk_item_stat` (`entry`, `set_id`, `unlock_tier`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`)
SELECT `entry` + 1999, CASE `set_id` WHEN 1 THEN 5 WHEN 2 THEN 6 ELSE 0 END, 3,
    `power` * 2.25, `max_health` * 2.25, `armor` * 2.25, `dodge` * 2.25, `hit` * 2.25, `crit` * 2.25, `crit_damage` * 2.25, `shield` * 2.25, `haste` * 2.25,
    `area` * 2.25, `pickup_range` * 2.25, `luck` * 2.25
FROM `bonk_stat_copy`;
DROP TEMPORARY TABLE `bonk_stat_copy`;

INSERT INTO `bonk_item_set` (`id`, `name`) VALUES
(3, 'Heroic Battlegear of the Unbroken'), (4, 'Heroic Regalia of Slaughter'),
(5, 'Mythic Battlegear of the Unbroken'), (6, 'Mythic Regalia of Slaughter');
INSERT INTO `bonk_item_set_bonus` (`set_id`, `pieces`, `power`, `armor`, `passive_effect`, `passive_value`, `description`) VALUES
(3, 2, 0,     0,      4, 15,    '+15% maximum health.'),
(3, 4, 0,     18.75,  5, 1.5,   '+18.75 Armor, and regain 1.5% health every second.'),
(4, 2, 0,     0,      1, 12,    '+12% Haste.'),
(4, 4, 22.5,  0,      9, 4.5,   '+22.5% Power, and heal for 4.5% of the damage you deal.'),
(5, 2, 0,     0,      4, 22.5,  '+22.5% maximum health.'),
(5, 4, 0,     28.125, 5, 2.25,  '+28.1 Armor, and regain 2.25% health every second.'),
(6, 2, 0,     0,      1, 18,    '+18% Haste.'),
(6, 4, 33.75, 0,      9, 6.75,  '+33.75% Power, and heal for 6.75% of the damage you deal.');

DROP TEMPORARY TABLE IF EXISTS `bonk_vendor_copy`;
CREATE TEMPORARY TABLE `bonk_vendor_copy` SELECT * FROM `npc_vendor` WHERE `entry` = 900004 AND `item` BETWEEN 900101 AND 900132;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT 900004, `slot` + 32, `item` + 1899, 0, 0, 0, 0 FROM `bonk_vendor_copy`;
DROP TEMPORARY TABLE `bonk_vendor_copy`;
CREATE TEMPORARY TABLE `bonk_vendor_copy` SELECT * FROM `npc_vendor` WHERE `entry` = 900004 AND `item` BETWEEN 900101 AND 900132;
INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT 900004, `slot` + 64, `item` + 1999, 0, 0, 0, 0 FROM `bonk_vendor_copy`;
DROP TEMPORARY TABLE `bonk_vendor_copy`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
