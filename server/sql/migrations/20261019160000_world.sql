DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019160000');

DELETE FROM `creature_template` WHERE `entry` = 900135;
DROP TEMPORARY TABLE IF EXISTS `bonk_heal_sparkle`;
CREATE TEMPORARY TABLE `bonk_heal_sparkle` SELECT * FROM `creature_template` WHERE `entry` = 900129;
UPDATE `bonk_heal_sparkle` SET `entry` = 900135, `name` = '', `auras` = '33455';
INSERT INTO `creature_template` SELECT * FROM `bonk_heal_sparkle`;
DROP TEMPORARY TABLE `bonk_heal_sparkle`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
