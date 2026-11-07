DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE ringSpell INT DEFAULT 33402;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017120000');

DELETE FROM `creature_display_info_addon` WHERE `display_id` BETWEEN 18507 AND 18528;

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33402 AND 33423;
WHILE ringSpell <= 33423 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_blood_aura_ring`;
    CREATE TEMPORARY TABLE `bonk_blood_aura_ring` SELECT * FROM `spell_template` WHERE `entry` = 33401;
    UPDATE `bonk_blood_aura_ring` SET `entry` = ringSpell, `spellVisual1` = 8300 + ringSpell - 33402;
    INSERT INTO `spell_template` SELECT * FROM `bonk_blood_aura_ring`;
    DROP TEMPORARY TABLE `bonk_blood_aura_ring`;
    SET ringSpell = ringSpell + 1;
END WHILE;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
