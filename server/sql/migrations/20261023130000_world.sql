DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE ringSpell INT DEFAULT 33471;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023130000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33471 AND 33492;
WHILE ringSpell <= 33492 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_time_bubble_look`;
    CREATE TEMPORARY TABLE `bonk_time_bubble_look` SELECT * FROM `spell_template` WHERE `entry` = 33424;
    UPDATE `bonk_time_bubble_look` SET `entry` = ringSpell, `spellVisual1` = 8900 + ringSpell - 33471, `name` = 'Time Bubble', `auraDescription` = '';
    INSERT INTO `spell_template` SELECT * FROM `bonk_time_bubble_look`;
    DROP TEMPORARY TABLE `bonk_time_bubble_look`;
    SET ringSpell = ringSpell + 1;
END WHILE;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
