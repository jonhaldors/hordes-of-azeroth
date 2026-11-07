DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810006');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810006');

DELETE FROM `spell_template` WHERE `entry` = 33461;
DROP TEMPORARY TABLE IF EXISTS `bonk_souls`;
CREATE TEMPORARY TABLE `bonk_souls` SELECT * FROM `spell_template` WHERE `entry` = 17941;
UPDATE `bonk_souls` SET `entry` = 33461, `name` = 'Souls', `auraDescription` = 'You deal 5% more damage for each soul.';
INSERT INTO `spell_template` SELECT * FROM `bonk_souls`;
DROP TEMPORARY TABLE `bonk_souls`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
