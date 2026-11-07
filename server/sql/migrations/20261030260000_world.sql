DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030260000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030260000');

DROP TEMPORARY TABLE IF EXISTS `bonk_tier_rows`;
CREATE TEMPORARY TABLE `bonk_tier_rows` (
    `entry` INT UNSIGNED NOT NULL PRIMARY KEY,
    `tier` INT UNSIGNED NOT NULL,
    `power` FLOAT NOT NULL,
    `max_health` FLOAT NOT NULL,
    `armor` FLOAT NOT NULL
);
INSERT INTO `bonk_tier_rows`
SELECT s.`entry`, ((s.`entry` - 903000) MOD 160) DIV 8 + 1, b.`power`, b.`max_health`, b.`armor`
FROM `bonk_item_stat` s JOIN `bonk_item_stat` b ON b.`entry` = s.`entry` - (((s.`entry` - 903000) MOD 160) DIV 8) * 8
WHERE s.`entry` BETWEEN 903000 AND 904439;
INSERT INTO `bonk_tier_rows`
SELECT s.`entry`, (s.`entry` - 904500) MOD 20 + 1, b.`power`, b.`max_health`, b.`armor`
FROM `bonk_item_stat` s JOIN `bonk_item_stat` b ON b.`entry` = s.`entry` - (s.`entry` - 904500) MOD 20
WHERE s.`entry` BETWEEN 904500 AND 904899;
INSERT INTO `bonk_tier_rows`
SELECT s.`entry`, (s.`entry` - 905000) MOD 20 + 1, b.`power`, b.`max_health`, b.`armor`
FROM `bonk_item_stat` s JOIN `bonk_item_stat` b ON b.`entry` = s.`entry` - (s.`entry` - 905000) MOD 20
WHERE s.`entry` BETWEEN 905000 AND 905159;
UPDATE `bonk_item_stat` s JOIN `bonk_tier_rows` r ON r.`entry` = s.`entry`
SET s.`power` = ROUND(r.`power` * (1 + 0.25 * (r.`tier` - 1)), 1),
    s.`max_health` = ROUND(r.`max_health` * (1 + 0.25 * (r.`tier` - 1)), 1),
    s.`armor` = ROUND(r.`armor` * (1 + 0.25 * (r.`tier` - 1)), 1);
DROP TEMPORARY TABLE `bonk_tier_rows`;

UPDATE `item_template` SET `quality` = 3 WHERE `entry` BETWEEN 903000 AND 904439 OR `entry` BETWEEN 904500 AND 904899;

DELETE FROM `item_template` WHERE `entry` BETWEEN 910000 AND 911899;
DROP TEMPORARY TABLE IF EXISTS `bonk_epic_items`;
CREATE TEMPORARY TABLE `bonk_epic_items` AS
SELECT * FROM `item_template` WHERE `entry` BETWEEN 903000 AND 904439 OR `entry` BETWEEN 904500 AND 904899;
UPDATE `bonk_epic_items` SET `entry` = `entry` + 7000, `quality` = 4;
INSERT INTO `item_template` SELECT * FROM `bonk_epic_items`;
DROP TEMPORARY TABLE `bonk_epic_items`;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 910000 AND 911899;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `entry` + 7000, ROUND(`power` * 1.45, 1), ROUND(`max_health` * 1.45, 1), ROUND(`armor` * 1.45, 1),
    ROUND(`dodge` * 1.2, 1), ROUND(`crit` * 1.2, 1), ROUND(`crit_damage` * 1.2, 1), ROUND(`shield` * 1.2, 1),
    ROUND(`haste` * 1.2, 1), ROUND(`area` * 1.2, 1), `pickup_range`, `luck`, `set_id`, `unlock_tier`
FROM `bonk_item_stat` WHERE `entry` BETWEEN 903000 AND 904439 OR `entry` BETWEEN 904500 AND 904899;

INSERT IGNORE INTO `bonk_item_card` (`entry`, `card_id`)
SELECT DISTINCT i.`entry`, c.`card_id`
FROM `item_template` i JOIN `bonk_item_card` c ON c.`entry` = 901420 + (i.`entry` - 905000) DIV 20
WHERE i.`entry` BETWEEN 905000 AND 905159;

DROP TEMPORARY TABLE IF EXISTS `bonk_green_drops`;
CREATE TEMPORARY TABLE `bonk_green_drops` (`entry` INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT IGNORE INTO `bonk_green_drops` SELECT `entry` FROM `bonk_gear` WHERE `quality` = 2;
INSERT IGNORE INTO `bonk_green_drops` SELECT `keep_entry` FROM `bonk_gear` WHERE `quality` = 2 AND `keep_entry` <> 0;

DELETE FROM `item_template` WHERE `entry` BETWEEN 912000 AND 915999;
DROP TEMPORARY TABLE IF EXISTS `bonk_low_items`;
CREATE TEMPORARY TABLE `bonk_low_items` AS
SELECT * FROM `item_template` WHERE `entry` IN (SELECT `entry` FROM `bonk_green_drops`);
UPDATE `bonk_low_items` SET `entry` = `entry` + 12000, `quality` = 0, `name` = CONCAT('Tattered ', `name`),
    `buy_price` = ROUND(`buy_price` * 0.5), `sell_price` = ROUND(`sell_price` * 0.5);
INSERT INTO `item_template` SELECT * FROM `bonk_low_items`;
DROP TEMPORARY TABLE `bonk_low_items`;
CREATE TEMPORARY TABLE `bonk_low_items` AS
SELECT * FROM `item_template` WHERE `entry` IN (SELECT `entry` FROM `bonk_green_drops`);
UPDATE `bonk_low_items` SET `entry` = `entry` + 14000, `quality` = 1, `name` = CONCAT('Sturdy ', `name`),
    `buy_price` = ROUND(`buy_price` * 0.75), `sell_price` = ROUND(`sell_price` * 0.75);
INSERT INTO `item_template` SELECT * FROM `bonk_low_items`;
DROP TEMPORARY TABLE `bonk_low_items`;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 912000 AND 915999;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `entry` + 12000, ROUND(`power` * 0.5, 1), ROUND(`max_health` * 0.5, 1), ROUND(`armor` * 0.5, 1),
    ROUND(`dodge` * 0.5, 1), ROUND(`crit` * 0.5, 1), ROUND(`crit_damage` * 0.5, 1), ROUND(`shield` * 0.5, 1),
    ROUND(`haste` * 0.5, 1), ROUND(`area` * 0.5, 1), ROUND(`pickup_range` * 0.5, 1), ROUND(`luck` * 0.5, 1), 0, `unlock_tier`
FROM `bonk_item_stat` WHERE `entry` IN (SELECT `entry` FROM `bonk_green_drops`);
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `entry` + 14000, ROUND(`power` * 0.75, 1), ROUND(`max_health` * 0.75, 1), ROUND(`armor` * 0.75, 1),
    ROUND(`dodge` * 0.75, 1), ROUND(`crit` * 0.75, 1), ROUND(`crit_damage` * 0.75, 1), ROUND(`shield` * 0.75, 1),
    ROUND(`haste` * 0.75, 1), ROUND(`area` * 0.75, 1), ROUND(`pickup_range` * 0.75, 1), ROUND(`luck` * 0.75, 1), 0, `unlock_tier`
FROM `bonk_item_stat` WHERE `entry` IN (SELECT `entry` FROM `bonk_green_drops`);

DELETE FROM `bonk_gear` WHERE `entry` BETWEEN 912000 AND 915999;
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`, `tier`)
SELECT g.`entry` + 12000, 0, IF(g.`keep_entry` <> 0, g.`keep_entry` + 12000, 0), 0 FROM `bonk_gear` g WHERE g.`quality` = 2;
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`, `tier`)
SELECT g.`entry` + 14000, 1, IF(g.`keep_entry` <> 0, g.`keep_entry` + 14000, 0), 0 FROM `bonk_gear` g WHERE g.`quality` = 2 AND g.`entry` < 912000;
DROP TEMPORARY TABLE `bonk_green_drops`;

DROP TEMPORARY TABLE IF EXISTS `bonk_shop_greens`;
CREATE TEMPORARY TABLE `bonk_shop_greens` (`entry` INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO `bonk_shop_greens` SELECT DISTINCT v.`item` FROM `npc_vendor` v JOIN `item_template` i ON i.`entry` = v.`item`
WHERE v.`entry` = 900004 AND i.`quality` = 2;
DROP TEMPORARY TABLE IF EXISTS `bonk_shop_blues`;
CREATE TEMPORARY TABLE `bonk_shop_blues` (`entry` INT UNSIGNED NOT NULL PRIMARY KEY);
INSERT INTO `bonk_shop_blues` SELECT DISTINCT v.`item` FROM `npc_vendor` v JOIN `item_template` i ON i.`entry` = v.`item`
WHERE v.`entry` = 900004 AND i.`quality` = 3;

DELETE FROM `item_template` WHERE `entry` BETWEEN 920000 AND 925999;
DROP TEMPORARY TABLE IF EXISTS `bonk_shop_items`;
CREATE TEMPORARY TABLE `bonk_shop_items` AS
SELECT * FROM `item_template` WHERE `entry` IN (SELECT `entry` FROM `bonk_shop_greens`);
UPDATE `bonk_shop_items` SET `entry` = `entry` + 20000, `quality` = 0, `name` = CONCAT('Tattered ', `name`),
    `buy_price` = 1000, `sell_price` = 250;
INSERT INTO `item_template` SELECT * FROM `bonk_shop_items`;
DROP TEMPORARY TABLE `bonk_shop_items`;

DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 920000 AND 925999;
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `entry` + 20000, ROUND(`power` * 0.5, 1), ROUND(`max_health` * 0.5, 1), ROUND(`armor` * 0.5, 1),
    ROUND(`dodge` * 0.5, 1), ROUND(`crit` * 0.5, 1), ROUND(`crit_damage` * 0.5, 1), ROUND(`shield` * 0.5, 1),
    ROUND(`haste` * 0.5, 1), ROUND(`area` * 0.5, 1), ROUND(`pickup_range` * 0.5, 1), ROUND(`luck` * 0.5, 1), 0, 0
FROM `bonk_item_stat` WHERE `entry` IN (SELECT `entry` FROM `bonk_shop_greens`);
UPDATE `bonk_item_stat` SET `unlock_tier` = 1 WHERE `entry` IN (SELECT `entry` FROM `bonk_shop_greens`);

INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT v.`entry`, v.`slot`, v.`item` + 20000, v.`maxcount`, v.`incrtime`, v.`itemflags`, v.`condition_id`
FROM `npc_vendor` v WHERE v.`entry` = 900004 AND v.`item` IN (SELECT `entry` FROM `bonk_shop_greens`);
DELETE FROM `npc_vendor` WHERE `entry` = 900004 AND `item` IN (SELECT `entry` FROM `bonk_shop_blues`);
DROP TEMPORARY TABLE `bonk_shop_greens`;
DROP TEMPORARY TABLE `bonk_shop_blues`;

UPDATE `bonk_map` SET `gold_per_kill` = ROUND(`gold_per_kill` * 0.5), `stage_gold` = ROUND(`stage_gold` * 0.5);
UPDATE `bonk_tier` SET `shard_chance_normal` = `shard_chance_normal` * 0.5, `shard_chance_elite` = `shard_chance_elite` * 0.5,
    `shards_boss` = GREATEST(1, `shards_boss` - 1), `shards_miniboss` = 1;
UPDATE `bonk_tier` SET `late_health_growth` = 0.10, `last_health_growth` = 0.10 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
