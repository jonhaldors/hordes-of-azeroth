DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020999500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020999500');

REPLACE INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`,
    `pickup_range`, `luck`, `set_id`, `unlock_tier`) VALUES
(900125, 0, 4.8, 10, 0.4, 0, 0, 0, 2.4, 0, 0, 0, 0, 1, 0),
(900126, 0, 4.8, 9, 0.4, 0, 0, 0, 2.4, 0, 0, 0, 0, 1, 0),
(900127, 0, 4.8, 11, 0.4, 0, 0, 0, 2.4, 0, 0, 0, 0, 1, 0),
(900128, 0, 4.8, 10, 0.4, 0, 0, 0, 2.4, 0, 0, 0, 0, 1, 0),
(900129, 4.8, 0, 3, 0.8, 0, 1.6, 0, 0, 0, 0, 0, 0, 2, 0),
(900130, 4, 0, 3, 0.8, 0, 1.6, 0, 0, 0, 0, 0, 0, 2, 0),
(900131, 5.6, 0, 3, 0.8, 0, 1.6, 0, 0, 0, 0, 0, 0, 2, 0),
(900132, 4.8, 0, 3, 0.8, 0, 1.6, 0, 0, 0, 0, 0, 0, 2, 0);

DELETE FROM `item_template` WHERE `entry` BETWEEN 906125 AND 906132 OR `entry` BETWEEN 908125 AND 908132;
DELETE FROM `bonk_item_stat` WHERE `entry` BETWEEN 906125 AND 906132 OR `entry` BETWEEN 908125 AND 908132;

DROP TABLE IF EXISTS `bonk_tmp_keep`;
CREATE TABLE `bonk_tmp_keep` (`run` INT UNSIGNED, `keep` INT UNSIGNED, `label` VARCHAR(16));
INSERT INTO `bonk_tmp_keep` SELECT `entry`, `entry` + 1000, '' FROM `bonk_gear` WHERE `entry` BETWEEN 900430 AND 900437;
INSERT INTO `bonk_tmp_keep` SELECT `entry`, `entry` + 1000, 'Heroic' FROM `bonk_gear` WHERE `entry` BETWEEN 906430 AND 906437;
INSERT INTO `bonk_tmp_keep` SELECT `entry`, `entry` + 1000, 'Mythic' FROM `bonk_gear` WHERE `entry` BETWEEN 908430 AND 908437;

DELETE FROM `item_template` WHERE `entry` IN (SELECT `keep` FROM `bonk_tmp_keep`);
DROP TABLE IF EXISTS `bonk_tmp_template`;
CREATE TABLE `bonk_tmp_template` SELECT `t`.*, `k`.`label` AS `keep_label` FROM `item_template` `t` JOIN `bonk_tmp_keep` `k` ON `k`.`run` = `t`.`entry`;
UPDATE `bonk_tmp_template` SET `description` = IF(`keep_label` = '', '', CONCAT('Extracted from a ', `keep_label`, ' run.')), `entry` = `entry` + 1000;
ALTER TABLE `bonk_tmp_template` DROP COLUMN `keep_label`;
INSERT INTO `item_template` SELECT * FROM `bonk_tmp_template`;

DELETE FROM `bonk_item_stat` WHERE `entry` IN (SELECT `keep` FROM `bonk_tmp_keep`);
INSERT INTO `bonk_item_stat` (`entry`, `power`, `max_health`, `armor`, `dodge`, `hit`, `crit`, `crit_damage`, `shield`, `haste`, `area`,
    `pickup_range`, `luck`, `set_id`, `unlock_tier`)
SELECT `k`.`keep`, `s`.`power`, `s`.`max_health`, `s`.`armor`, `s`.`dodge`, `s`.`hit`, `s`.`crit`, `s`.`crit_damage`, `s`.`shield`, `s`.`haste`,
    `s`.`area`, `s`.`pickup_range`, `s`.`luck`, `s`.`set_id`, 0
FROM `bonk_item_stat` `s` JOIN `bonk_tmp_keep` `k` ON `k`.`run` = `s`.`entry`;

UPDATE `bonk_gear` `g` JOIN `bonk_tmp_keep` `k` ON `k`.`run` = `g`.`entry` SET `g`.`keep_entry` = `k`.`keep`;

DROP TABLE `bonk_tmp_keep`;
DROP TABLE `bonk_tmp_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
