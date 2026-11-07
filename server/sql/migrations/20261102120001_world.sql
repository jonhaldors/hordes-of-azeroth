DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120001');

DELETE FROM `spell_template` WHERE `entry` = 33700;
DROP TEMPORARY TABLE IF EXISTS `bonk_avengers_shield`;
CREATE TEMPORARY TABLE `bonk_avengers_shield` SELECT * FROM `spell_template` WHERE `entry` = 24239;
UPDATE `bonk_avengers_shield` SET `entry` = 33700, `name` = 'Avenger''s Shield';
INSERT INTO `spell_template` SELECT * FROM `bonk_avengers_shield`;
DROP TEMPORARY TABLE IF EXISTS `bonk_avengers_shield`;

UPDATE `bonk_weapon` SET `spell_id` = 33700 WHERE `id` IN (813, 839, 840);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
