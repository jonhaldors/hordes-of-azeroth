DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE ringSpell INT DEFAULT 33425;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017130000');

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33424 AND 33451;

DROP TEMPORARY TABLE IF EXISTS `bonk_hero_look`;
CREATE TEMPORARY TABLE `bonk_hero_look` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_hero_look` SET `entry` = 33424, `spellVisual1` = 0, `name` = 'Ice Path', `auraDescription` = 'Ice around you slows nearby enemies.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
DROP TEMPORARY TABLE `bonk_hero_look`;

WHILE ringSpell <= 33446 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_hero_look`;
    CREATE TEMPORARY TABLE `bonk_hero_look` SELECT * FROM `spell_template` WHERE `entry` = 33424;
    UPDATE `bonk_hero_look` SET `entry` = ringSpell, `spellVisual1` = 8322 + ringSpell - 33425;
    INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
    DROP TEMPORARY TABLE `bonk_hero_look`;
    SET ringSpell = ringSpell + 1;
END WHILE;

DROP TEMPORARY TABLE IF EXISTS `bonk_hero_look`;
CREATE TEMPORARY TABLE `bonk_hero_look` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_hero_look` SET `entry` = 33447, `spellVisual1` = 8350, `name` = 'Spiked Shield', `auraDescription` = 'Spikes strike enemies near you while your Shield holds.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
UPDATE `bonk_hero_look` SET `entry` = 33448, `spellVisual1` = 8351, `name` = 'Steady Aim', `auraDescription` = 'Standing still. Steady Aim attacks more often.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
UPDATE `bonk_hero_look` SET `entry` = 33449, `spellVisual1` = 8352, `name` = 'Bladestorm', `auraDescription` = 'Spinning, striking all enemies near you.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
UPDATE `bonk_hero_look` SET `entry` = 33450, `spellVisual1` = 8353, `name` = 'Vengeance', `auraDescription` = 'Damage you take is stored for your next strike.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
UPDATE `bonk_hero_look` SET `entry` = 33451, `spellVisual1` = 8354, `name` = 'Vengeance', `auraDescription` = 'Your next strike releases a burst of stored damage.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
DROP TEMPORARY TABLE `bonk_hero_look`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
