DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018070000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018070000');

DELETE FROM `npc_vendor` WHERE `entry` = 900004 AND `item` BETWEEN 902200 AND 902299;
DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 902200 AND 902299;
DELETE FROM `item_template` WHERE `entry` BETWEEN 902200 AND 902299;

DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_kind`;
CREATE TEMPORARY TABLE `bonk_weapon_kind` (
    `kind` INT UNSIGNED NOT NULL PRIMARY KEY,
    `class` INT UNSIGNED NOT NULL,
    `subclass` INT UNSIGNED NOT NULL,
    `inv` VARCHAR(16) NOT NULL,
    `role` VARCHAR(8) NOT NULL,
    `noun` VARCHAR(32) NOT NULL
);
INSERT INTO `bonk_weapon_kind` VALUES
(0, 2, 7,  '13,21', 'one',    'Blade'),
(1, 2, 4,  '13,21', 'one',    'Mace'),
(2, 2, 15, '13',    'one',    'Dirk'),
(3, 2, 8,  '17',    'two',    'Greatsword'),
(4, 2, 5,  '17',    'two',    'Maul'),
(5, 2, 10, '17',    'two',    'Staff'),
(6, 2, 2,  '15',    'two',    'Longbow'),
(7, 4, 6,  '14',    'shield', 'Shield'),
(8, 4, 0,  '23',    'held',   'Orb');

DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_tier`;
CREATE TEMPORARY TABLE `bonk_weapon_tier` (
    `tier` INT UNSIGNED NOT NULL PRIMARY KEY,
    `prefix` VARCHAR(16) NOT NULL,
    `unlock_tier` INT UNSIGNED NOT NULL,
    `stat_scale` FLOAT NOT NULL,
    `price_scale` INT UNSIGNED NOT NULL
);
INSERT INTO `bonk_weapon_tier` VALUES
(0, '',        0, 1,    1),
(1, 'Heroic ', 1, 1.5,  3),
(2, 'Mythic ', 3, 2.25, 8);

DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_pick`;
CREATE TEMPORARY TABLE `bonk_weapon_pick` SELECT
    902200 + `t`.`tier` * 30 + `k`.`kind` * 3 + `q`.`quality` - 2 AS `entry`,
    `k`.`kind`, `k`.`role`, `q`.`quality`, `t`.`tier`, `t`.`unlock_tier`, `t`.`stat_scale`,
    CONCAT(`t`.`prefix`, CASE `q`.`quality` WHEN 2 THEN 'Scrapper''s ' WHEN 3 THEN 'Veteran''s ' ELSE 'Champion''s ' END, `k`.`noun`) AS `name`,
    `t`.`price_scale` * IF(`k`.`role` = 'two',
        CASE `q`.`quality` WHEN 2 THEN 5000 WHEN 3 THEN 25000 ELSE 90000 END,
        CASE `q`.`quality` WHEN 2 THEN 3000 WHEN 3 THEN 15000 ELSE 50000 END) AS `price`,
    (SELECT MIN(`i`.`entry`) FROM `item_template` `i`
        WHERE `i`.`entry` BETWEEN 900300 AND 900499 AND `i`.`class` = `k`.`class` AND `i`.`subclass` = `k`.`subclass`
          AND FIND_IN_SET(`i`.`inventory_type`, `k`.`inv`) AND `i`.`quality` = `q`.`quality`) AS `source`
    FROM `bonk_weapon_kind` `k`
    CROSS JOIN (SELECT 2 AS `quality` UNION ALL SELECT 3 UNION ALL SELECT 4) `q`
    CROSS JOIN `bonk_weapon_tier` `t`
    WHERE NOT (`t`.`tier` = 0 AND `q`.`quality` = 3);
DELETE FROM `bonk_weapon_pick` WHERE `source` IS NULL;

DROP TEMPORARY TABLE IF EXISTS `bonk_weapon_items`;
CREATE TEMPORARY TABLE `bonk_weapon_items` SELECT `i`.* FROM `item_template` `i` JOIN `bonk_weapon_pick` `p` ON `p`.`source` = `i`.`entry`;
ALTER TABLE `bonk_weapon_items` ADD COLUMN `bonk_target` INT UNSIGNED NOT NULL DEFAULT 0;
DELETE FROM `bonk_weapon_items`;
INSERT INTO `bonk_weapon_items` SELECT `i`.*, `p`.`entry` FROM `item_template` `i` JOIN `bonk_weapon_pick` `p` ON `p`.`source` = `i`.`entry`;
UPDATE `bonk_weapon_items` `i` JOIN `bonk_weapon_pick` `p` ON `p`.`entry` = `i`.`bonk_target` SET
    `i`.`entry` = `p`.`entry`,
    `i`.`name` = `p`.`name`,
    `i`.`description` = '',
    `i`.`buy_price` = `p`.`price`,
    `i`.`sell_price` = 0;
ALTER TABLE `bonk_weapon_items` DROP COLUMN `bonk_target`;
INSERT INTO `item_template` SELECT * FROM `bonk_weapon_items`;

INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `entry`,
    ROUND(4 * `stat_scale` * CASE `role`
        WHEN 'one'  THEN CASE `quality` WHEN 2 THEN 2   WHEN 3 THEN 3.5  ELSE 5 END
        WHEN 'two'  THEN CASE `quality` WHEN 2 THEN 4   WHEN 3 THEN 7    ELSE 10 END
        WHEN 'held' THEN CASE `quality` WHEN 2 THEN 1.5 WHEN 3 THEN 2.75 ELSE 4 END
        ELSE 0 END) / 4,
    0,
    ROUND(4 * `stat_scale` * CASE `role`
        WHEN 'two'    THEN CASE `quality` WHEN 2 THEN 2.5  WHEN 3 THEN 5 ELSE 7.5 END
        WHEN 'shield' THEN CASE `quality` WHEN 2 THEN 2.75 WHEN 3 THEN 5 ELSE 7.5 END
        ELSE CASE `quality` WHEN 2 THEN 1.25 WHEN 3 THEN 2.5 ELSE 3.75 END END) / 4,
    0, 0,
    ROUND(4 * `stat_scale` * IF(`role` = 'held', CASE `quality` WHEN 2 THEN 0.5 WHEN 3 THEN 0.75 ELSE 1 END, 0)) / 4,
    0,
    ROUND(4 * `stat_scale` * IF(`role` = 'shield', CASE `quality` WHEN 2 THEN 0 WHEN 3 THEN 2 ELSE 4 END, 0)) / 4,
    0, 0, 0, 0, 0, `unlock_tier`
FROM `bonk_weapon_pick`;

INSERT INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT 900004, 135 + `tier` * 30 + `kind` * 3 + `quality` - 2, `entry`, 0, 0, 0, 0 FROM `bonk_weapon_pick`;

DROP TEMPORARY TABLE `bonk_weapon_items`;
DROP TEMPORARY TABLE `bonk_weapon_pick`;
DROP TEMPORARY TABLE `bonk_weapon_tier`;
DROP TEMPORARY TABLE `bonk_weapon_kind`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
