DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016290000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016290000');

ALTER TABLE `bonk_powerup`
    ADD COLUMN IF NOT EXISTS `effect` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 spell, 1 magnet, 2 holy nova, 3 frost nova, 4 valor' AFTER `weight`,
    ADD COLUMN IF NOT EXISTS `value` FLOAT NOT NULL DEFAULT 0 COMMENT 'yards for the novas, chest prices for valor' AFTER `effect`;

DELETE FROM `gameobject_template` WHERE `entry` BETWEEN 900050 AND 900053;
DROP TEMPORARY TABLE IF EXISTS `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900004;
UPDATE `bonk_go_copy` SET `entry` = 900050, `displayId` = 2911, `name` = 'Goblin Magnet', `size` = 0.8;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
UPDATE `bonk_go_copy` SET `entry` = 900051, `displayId` = 2978, `name` = 'Holy Nova', `size` = 0.8;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
UPDATE `bonk_go_copy` SET `entry` = 900052, `displayId` = 2971, `name` = 'Frost Nova', `size` = 0.8;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
UPDATE `bonk_go_copy` SET `entry` = 900053, `displayId` = 6484, `name` = 'Valor Pouch', `size` = 0.8;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;

DELETE FROM `bonk_powerup` WHERE `entry` BETWEEN 900050 AND 900053;
INSERT INTO `bonk_powerup` (`entry`, `spell_id`, `weight`, `effect`, `value`) VALUES
(900050, 0,     1, 1, 0),
(900051, 15237, 1, 2, 40),
(900052, 122,   1, 3, 40),
(900053, 0,     2, 4, 0.5);
UPDATE `bonk_powerup` SET `weight` = 3 WHERE `entry` = 900004;
UPDATE `bonk_powerup` SET `weight` = 2 WHERE `entry` IN (900005, 900006);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
