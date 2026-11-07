DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE ringSpell INT DEFAULT 33510;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024050000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024050000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33510 AND 33531;
WHILE ringSpell <= 33531 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_hazard_look`;
    CREATE TEMPORARY TABLE `bonk_hazard_look` SELECT * FROM `spell_template` WHERE `entry` = 33424;
    UPDATE `bonk_hazard_look` SET `entry` = ringSpell, `spellVisual1` = 8950 + ringSpell - 33510, `name` = 'Lingering Hazard', `auraDescription` = '';
    INSERT INTO `spell_template` SELECT * FROM `bonk_hazard_look`;
    DROP TEMPORARY TABLE `bonk_hazard_look`;
    SET ringSpell = ringSpell + 1;
END WHILE;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
