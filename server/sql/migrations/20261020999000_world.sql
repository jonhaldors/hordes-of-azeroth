DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020999000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020999000');

ALTER TABLE `bonk_gear` ADD COLUMN `tier` INT UNSIGNED NOT NULL DEFAULT 0 AFTER `keep_entry`;

DROP TABLE IF EXISTS `bonk_tmp_item`;
CREATE TABLE `bonk_tmp_item` (`entry` INT UNSIGNED PRIMARY KEY, `slot` INT UNSIGNED, `quality` INT UNSIGNED)
    SELECT `entry`, MAX(`inventory_type`) AS `slot`, MAX(`quality`) AS `quality` FROM `item_template` GROUP BY `entry`;

DROP TABLE IF EXISTS `bonk_tmp_vendor`;
CREATE TABLE `bonk_tmp_vendor`
    SELECT `i`.`slot`, `i`.`quality`, `s`.`unlock_tier` AS `ut`,
        AVG(`s`.`power`) AS `power`, AVG(`s`.`max_health`) AS `max_health`, AVG(`s`.`armor`) AS `armor`, AVG(`s`.`dodge`) AS `dodge`,
        AVG(`s`.`hit`) AS `hit`, AVG(`s`.`crit`) AS `crit`, AVG(`s`.`crit_damage`) AS `crit_damage`, AVG(`s`.`shield`) AS `shield`,
        AVG(`s`.`haste`) AS `haste`, AVG(`s`.`area`) AS `area`, AVG(`s`.`pickup_range`) AS `pickup_range`, AVG(`s`.`luck`) AS `luck`
    FROM `bonk_item_stat` `s` JOIN `bonk_tmp_item` `i` ON `i`.`entry` = `s`.`entry`
    WHERE `s`.`entry` IN (SELECT `item` FROM `npc_vendor`)
        AND `s`.`entry` NOT IN (SELECT `entry` FROM `bonk_gear`) AND `s`.`entry` NOT IN (SELECT `keep_entry` FROM `bonk_gear`)
    GROUP BY `i`.`slot`, `i`.`quality`, `s`.`unlock_tier`;

DROP TABLE IF EXISTS `bonk_tmp_target`;
CREATE TABLE `bonk_tmp_target` SELECT `slot`, `quality`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`,
    `haste`, `area`, `pickup_range`, `luck` FROM `bonk_tmp_vendor` WHERE `ut` = 0;
INSERT INTO `bonk_tmp_target`
    SELECT `h`.`slot`, 4, `h`.`power` / 1.875, `h`.`max_health` / 1.875, `h`.`armor` / 1.875, `h`.`dodge` / 1.875, `h`.`hit` / 1.875,
        `h`.`crit` / 1.875, `h`.`crit_damage` / 1.875, `h`.`shield` / 1.875, `h`.`haste` / 1.875, `h`.`area` / 1.875,
        `h`.`pickup_range` / 1.875, `h`.`luck` / 1.875
    FROM `bonk_tmp_vendor` `h` WHERE `h`.`quality` = 4 AND `h`.`ut` = 1
        AND `h`.`slot` NOT IN (SELECT `n`.`slot` FROM `bonk_tmp_target` `n` WHERE `n`.`quality` = 4);
INSERT INTO `bonk_tmp_target`
    SELECT `slot`, 5, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`, `pickup_range`, `luck`
    FROM `bonk_tmp_vendor` WHERE `quality` = 4 AND `ut` = 3;

DROP TABLE IF EXISTS `bonk_tmp_run`;
CREATE TABLE `bonk_tmp_run` SELECT `g`.`entry` AS `item`, `i`.`slot`, `g`.`quality` FROM `bonk_gear` `g` JOIN `bonk_tmp_item` `i` ON `i`.`entry` = `g`.`entry`;
INSERT INTO `bonk_tmp_run` SELECT `g`.`keep_entry`, `i`.`slot`, `g`.`quality` FROM `bonk_gear` `g` JOIN `bonk_tmp_item` `i` ON `i`.`entry` = `g`.`entry`
    WHERE `g`.`keep_entry` <> 0;

UPDATE `bonk_item_stat` `s`
    JOIN `bonk_tmp_run` `r` ON `r`.`item` = `s`.`entry`
    LEFT JOIN `bonk_tmp_target` `t` ON `t`.`slot` = `r`.`slot` AND `t`.`quality` = `r`.`quality`
SET
    `s`.`power` = ROUND(GREATEST(`s`.`power`, IFNULL(`t`.`power`, 0)) * 1.15, 1),
    `s`.`max_health` = ROUND(GREATEST(`s`.`max_health`, IFNULL(`t`.`max_health`, 0)) * 1.15, 1),
    `s`.`armor` = ROUND(GREATEST(`s`.`armor`, IFNULL(`t`.`armor`, 0)) * 1.15, 1),
    `s`.`dodge` = ROUND(GREATEST(`s`.`dodge`, IFNULL(`t`.`dodge`, 0)) * 1.15, 1),
    `s`.`hit` = ROUND(GREATEST(`s`.`hit`, IFNULL(`t`.`hit`, 0)) * 1.15, 1),
    `s`.`crit` = ROUND(GREATEST(`s`.`crit`, IFNULL(`t`.`crit`, 0)) * 1.15, 1),
    `s`.`crit_damage` = ROUND(GREATEST(`s`.`crit_damage`, IFNULL(`t`.`crit_damage`, 0)) * 1.15, 1),
    `s`.`shield` = ROUND(GREATEST(`s`.`shield`, IFNULL(`t`.`shield`, 0)) * 1.15, 1),
    `s`.`haste` = ROUND(GREATEST(`s`.`haste`, IFNULL(`t`.`haste`, 0)) * 1.15, 1),
    `s`.`area` = ROUND(GREATEST(`s`.`area`, IFNULL(`t`.`area`, 0)) * 1.15, 1),
    `s`.`pickup_range` = ROUND(GREATEST(`s`.`pickup_range`, IFNULL(`t`.`pickup_range`, 0)) * 1.15, 1),
    `s`.`luck` = ROUND(GREATEST(`s`.`luck`, IFNULL(`t`.`luck`, 0)) * 1.15, 1);

UPDATE `bonk_gear` SET `tier` = 1 WHERE `quality` = 4;

DROP TABLE IF EXISTS `bonk_tmp_copy`;
CREATE TABLE `bonk_tmp_copy` (`item` INT UNSIGNED, `offset` INT UNSIGNED, `tier` INT UNSIGNED, `scale` FLOAT, `label` VARCHAR(16));
INSERT INTO `bonk_tmp_copy` SELECT `entry`, 6000, 3, 1.875, 'Heroic' FROM `bonk_gear` WHERE `quality` = 4;
INSERT INTO `bonk_tmp_copy` SELECT `keep_entry`, 6000, 3, 1.875, 'Heroic' FROM `bonk_gear` WHERE `quality` = 4 AND `keep_entry` <> 0;
INSERT INTO `bonk_tmp_copy` SELECT `entry`, 8000, 2, 2.8125, 'Mythic' FROM `bonk_gear` WHERE `quality` = 4;
INSERT INTO `bonk_tmp_copy` SELECT `keep_entry`, 8000, 2, 2.8125, 'Mythic' FROM `bonk_gear` WHERE `quality` = 4 AND `keep_entry` <> 0;

DELETE FROM `item_template` WHERE `entry` IN (SELECT `item` + `offset` FROM `bonk_tmp_copy`);
DROP TABLE IF EXISTS `bonk_tmp_template`;
CREATE TABLE `bonk_tmp_template` SELECT `t`.*, `c`.`offset` AS `copy_offset`, `c`.`label` AS `copy_label`
    FROM `item_template` `t` JOIN `bonk_tmp_copy` `c` ON `c`.`item` = `t`.`entry`;
UPDATE `bonk_tmp_template` SET `description` = CONCAT('Found during a ', `copy_label`, ' run. Put it in the Extraction Vault to keep it.')
    WHERE `description` = 'Found during a run. Put it in the Extraction Vault to keep it.';
UPDATE `bonk_tmp_template` SET `description` = CONCAT('Extracted from a ', `copy_label`, ' run.') WHERE `description` = '';
UPDATE `bonk_tmp_template` SET `entry` = `entry` + `copy_offset`;
ALTER TABLE `bonk_tmp_template` DROP COLUMN `copy_offset`, DROP COLUMN `copy_label`;
INSERT INTO `item_template` SELECT * FROM `bonk_tmp_template`;

DELETE FROM `bonk_item_stat` WHERE `entry` IN (SELECT `item` + `offset` FROM `bonk_tmp_copy`);
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`,
    `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `c`.`item` + `c`.`offset`, ROUND(`s`.`power` * `c`.`scale`, 1), ROUND(`s`.`max_health` * `c`.`scale`, 1), ROUND(`s`.`armor` * `c`.`scale`, 1),
    ROUND(`s`.`dodge` * `c`.`scale`, 1), ROUND(`s`.`hit` * `c`.`scale`, 1), ROUND(`s`.`crit` * `c`.`scale`, 1),
    ROUND(`s`.`crit_damage` * `c`.`scale`, 1), ROUND(`s`.`shield` * `c`.`scale`, 1), ROUND(`s`.`haste` * `c`.`scale`, 1),
    ROUND(`s`.`area` * `c`.`scale`, 1), ROUND(`s`.`pickup_range` * `c`.`scale`, 1), ROUND(`s`.`luck` * `c`.`scale`, 1),
    `s`.`set_id`, `s`.`unlock_tier`
FROM `bonk_item_stat` `s` JOIN `bonk_tmp_copy` `c` ON `c`.`item` = `s`.`entry`;

DELETE FROM `bonk_gear` WHERE `entry` IN (SELECT `item` + `offset` FROM `bonk_tmp_copy`);
INSERT INTO `bonk_gear` (`entry`, `quality`, `keep_entry`, `tier`)
SELECT `g`.`entry` + `c`.`offset`, `g`.`quality`, IF(`g`.`keep_entry` <> 0, `g`.`keep_entry` + `c`.`offset`, 0), `c`.`tier`
FROM `bonk_gear` `g` JOIN `bonk_tmp_copy` `c` ON `c`.`item` = `g`.`entry`;

DROP TABLE `bonk_tmp_item`;
DROP TABLE `bonk_tmp_vendor`;
DROP TABLE `bonk_tmp_target`;
DROP TABLE `bonk_tmp_run`;
DROP TABLE `bonk_tmp_copy`;
DROP TABLE `bonk_tmp_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
