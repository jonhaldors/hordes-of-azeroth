DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023200000');

DELETE FROM `spell_template` WHERE `entry` = 33504;
DROP TEMPORARY TABLE IF EXISTS `bonk_chaos_bolt`;
CREATE TEMPORARY TABLE `bonk_chaos_bolt` SELECT * FROM `spell_template` WHERE `entry` = 686;
UPDATE `bonk_chaos_bolt` SET `entry` = 33504, `name` = 'Chaos Bolt';
INSERT INTO `spell_template` SELECT * FROM `bonk_chaos_bolt`;
DROP TEMPORARY TABLE `bonk_chaos_bolt`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
