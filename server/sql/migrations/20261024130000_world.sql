DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE markSpell INT DEFAULT 33540;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024130000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33540 AND 33583;
WHILE markSpell <= 33583 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_mark_look`;
    CREATE TEMPORARY TABLE `bonk_mark_look` SELECT * FROM `spell_template` WHERE `entry` = 33424;
    UPDATE `bonk_mark_look` SET `entry` = markSpell, `spellVisual1` = 9000 + markSpell - 33540, `name` = 'Boss Mark', `auraDescription` = '';
    INSERT INTO `spell_template` SELECT * FROM `bonk_mark_look`;
    DROP TEMPORARY TABLE `bonk_mark_look`;
    SET markSpell = markSpell + 1;
END WHILE;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
