DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023185500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023185500');

DROP TABLE IF EXISTS `bonk_tmp_mythic`;
CREATE TABLE `bonk_tmp_mythic`
    SELECT `t`.`inventory_type` AS `slot`,
        AVG(`s`.`power`) AS `power`, AVG(`s`.`max_health`) AS `max_health`, AVG(`s`.`armor`) AS `armor`, AVG(`s`.`dodge`) AS `dodge`,
        AVG(`s`.`hit`) AS `hit`, AVG(`s`.`crit`) AS `crit`, AVG(`s`.`crit_damage`) AS `crit_damage`, AVG(`s`.`shield`) AS `shield`,
        AVG(`s`.`haste`) AS `haste`, AVG(`s`.`area`) AS `area`, AVG(`s`.`pickup_range`) AS `pickup_range`, AVG(`s`.`luck`) AS `luck`
    FROM `bonk_gear` `g` JOIN `item_template` `t` ON `t`.`entry` = `g`.`entry` JOIN `bonk_item_stat` `s` ON `s`.`entry` = `g`.`entry`
    WHERE `g`.`tier` = 2 AND `g`.`quality` = 4
    GROUP BY `t`.`inventory_type`;

DROP TABLE IF EXISTS `bonk_tmp_legendary`;
CREATE TABLE `bonk_tmp_legendary` (`item` INT UNSIGNED PRIMARY KEY, `slot` INT UNSIGNED)
    SELECT `g`.`entry` AS `item`, IF(`t`.`inventory_type` = 21, 13, `t`.`inventory_type`) AS `slot`
    FROM `bonk_gear` `g` JOIN `item_template` `t` ON `t`.`entry` = `g`.`entry` WHERE `g`.`quality` = 5;
INSERT INTO `bonk_tmp_legendary`
    SELECT `g`.`keep_entry`, IF(`t`.`inventory_type` = 21, 13, `t`.`inventory_type`)
    FROM `bonk_gear` `g` JOIN `item_template` `t` ON `t`.`entry` = `g`.`entry` WHERE `g`.`quality` = 5 AND `g`.`keep_entry` <> 0;

UPDATE `bonk_item_stat` `s`
    JOIN `bonk_tmp_legendary` `l` ON `l`.`item` = `s`.`entry`
    JOIN `bonk_tmp_mythic` `m` ON `m`.`slot` = `l`.`slot`
SET
    `s`.`power` = GREATEST(`s`.`power`, ROUND(`m`.`power` * 1.15, 1)),
    `s`.`max_health` = GREATEST(`s`.`max_health`, ROUND(`m`.`max_health` * 1.15, 1)),
    `s`.`armor` = GREATEST(`s`.`armor`, ROUND(`m`.`armor` * 1.15, 1)),
    `s`.`dodge` = GREATEST(`s`.`dodge`, ROUND(`m`.`dodge` * 1.15, 1)),
    `s`.`hit` = GREATEST(`s`.`hit`, ROUND(`m`.`hit` * 1.15, 1)),
    `s`.`crit` = GREATEST(`s`.`crit`, ROUND(`m`.`crit` * 1.15, 1)),
    `s`.`crit_damage` = GREATEST(`s`.`crit_damage`, ROUND(`m`.`crit_damage` * 1.15, 1)),
    `s`.`shield` = GREATEST(`s`.`shield`, ROUND(`m`.`shield` * 1.15, 1)),
    `s`.`haste` = GREATEST(`s`.`haste`, ROUND(`m`.`haste` * 1.15, 1)),
    `s`.`area` = GREATEST(`s`.`area`, ROUND(`m`.`area` * 1.15, 1)),
    `s`.`pickup_range` = GREATEST(`s`.`pickup_range`, ROUND(`m`.`pickup_range` * 1.15, 1)),
    `s`.`luck` = GREATEST(`s`.`luck`, ROUND(`m`.`luck` * 1.15, 1));

UPDATE `bonk_item_stat` SET `haste` = GREATEST(`haste`, 11), `crit` = GREATEST(`crit`, 9.1) WHERE `entry` IN (900420, 901420);
UPDATE `bonk_item_stat` SET `crit` = GREATEST(`crit`, 9.1), `crit_damage` = GREATEST(`crit_damage`, 44.6) WHERE `entry` IN (900425, 901425);
UPDATE `bonk_item_stat` SET `armor` = GREATEST(`armor`, 11), `haste` = GREATEST(`haste`, 11), `max_health` = GREATEST(`max_health`, 23.9) WHERE `entry` IN (900426, 901426);
UPDATE `bonk_item_stat` SET `crit` = GREATEST(`crit`, 9.1), `hit` = GREATEST(`hit`, 17.8) WHERE `entry` IN (900423, 901423);
UPDATE `bonk_item_stat` SET `max_health` = GREATEST(`max_health`, 23.9), `crit_damage` = GREATEST(`crit_damage`, 44.6) WHERE `entry` IN (900421, 901421);
UPDATE `bonk_item_stat` SET `area` = GREATEST(`area`, 29.8), `crit` = GREATEST(`crit`, 9.1) WHERE `entry` IN (900422, 901422);
UPDATE `bonk_item_stat` SET `area` = GREATEST(`area`, 29.8), `haste` = GREATEST(`haste`, 11) WHERE `entry` IN (900424, 901424);
UPDATE `bonk_item_stat` SET `haste` = GREATEST(`haste`, 11) WHERE `entry` IN (900427, 901427);

DROP TABLE `bonk_tmp_mythic`;
DROP TABLE `bonk_tmp_legendary`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
