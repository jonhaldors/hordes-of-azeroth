DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810007');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810007');

DELETE FROM `spell_template` WHERE `entry` = 33462;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33462`;
CREATE TEMPORARY TABLE `bonk_look_33462` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_look_33462` d JOIN (SELECT `spellVisual1`, `spellIconId`, `stackAmount`, `durationIndex` FROM `spell_template` WHERE `entry` = 12686 LIMIT 1) s SET d.`entry` = 33462, d.`name` = 'Enrage', d.`auraDescription` = 'Haste increased.', d.`spellVisual1` = s.`spellVisual1`, d.`spellIconId` = s.`spellIconId`, d.`stackAmount` = s.`stackAmount`, d.`durationIndex` = s.`durationIndex`;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33462`;
DROP TEMPORARY TABLE `bonk_look_33462`;

DELETE FROM `spell_template` WHERE `entry` = 33463;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33463`;
CREATE TEMPORARY TABLE `bonk_look_33463` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_look_33463` d JOIN (SELECT `spellVisual1`, `spellIconId`, `stackAmount`, `durationIndex` FROM `spell_template` WHERE `entry` = 642 LIMIT 1) s SET d.`entry` = 33463, d.`name` = 'Divine Shield', d.`auraDescription` = 'A golden bubble protects you.', d.`spellVisual1` = s.`spellVisual1`, d.`spellIconId` = s.`spellIconId`, d.`stackAmount` = s.`stackAmount`, d.`durationIndex` = s.`durationIndex`;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33463`;
DROP TEMPORARY TABLE `bonk_look_33463`;

DELETE FROM `spell_template` WHERE `entry` = 33464;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33464`;
CREATE TEMPORARY TABLE `bonk_look_33464` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_look_33464` d JOIN (SELECT `spellVisual1`, `spellIconId`, `stackAmount`, `durationIndex` FROM `spell_template` WHERE `entry` = 139 LIMIT 1) s SET d.`entry` = 33464, d.`name` = 'Renew', d.`auraDescription` = 'Renew heals you every second. At full health it smites a nearby enemy instead.', d.`spellVisual1` = s.`spellVisual1`, d.`spellIconId` = s.`spellIconId`, d.`stackAmount` = s.`stackAmount`, d.`durationIndex` = s.`durationIndex`;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33464`;
DROP TEMPORARY TABLE `bonk_look_33464`;

DELETE FROM `spell_template` WHERE `entry` = 33465;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33465`;
CREATE TEMPORARY TABLE `bonk_look_33465` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_look_33465` d JOIN (SELECT `spellVisual1`, `spellIconId`, `stackAmount`, `durationIndex` FROM `spell_template` WHERE `entry` = 324 LIMIT 1) s SET d.`entry` = 33465, d.`name` = 'Lightning Shield', d.`auraDescription` = 'Enemies that strike you are zapped for Nature damage and gain 1 stack of Static. Each charge zaps once.', d.`spellVisual1` = s.`spellVisual1`, d.`spellIconId` = s.`spellIconId`, d.`stackAmount` = s.`stackAmount`, d.`durationIndex` = s.`durationIndex`;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33465`;
DROP TEMPORARY TABLE `bonk_look_33465`;

DELETE FROM `spell_template` WHERE `entry` = 33466;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33466`;
CREATE TEMPORARY TABLE `bonk_look_33466` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_look_33466` d JOIN (SELECT `spellVisual1`, `spellIconId`, `stackAmount`, `durationIndex` FROM `spell_template` WHERE `entry` = 13877 LIMIT 1) s SET d.`entry` = 33466, d.`name` = 'Blade Flurry', d.`auraDescription` = 'Your single-target hits also strike more enemies nearby.', d.`spellVisual1` = s.`spellVisual1`, d.`spellIconId` = s.`spellIconId`, d.`stackAmount` = s.`stackAmount`, d.`durationIndex` = s.`durationIndex`;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33466`;
DROP TEMPORARY TABLE `bonk_look_33466`;

DELETE FROM `spell_template` WHERE `entry` = 33467;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33467`;
CREATE TEMPORARY TABLE `bonk_look_33467` SELECT * FROM `spell_template` WHERE `entry` = 19263;
UPDATE `bonk_look_33467` SET `entry` = 33467, `name` = 'Deterrence', `auraDescription` = 'Dodge chance increased by 50%.';
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33467`;
DROP TEMPORARY TABLE `bonk_look_33467`;

DELETE FROM `spell_template` WHERE `entry` = 33468;
DROP TEMPORARY TABLE IF EXISTS `bonk_look_33468`;
CREATE TEMPORARY TABLE `bonk_look_33468` SELECT * FROM `spell_template` WHERE `entry` = 1022;
UPDATE `bonk_look_33468` SET `entry` = 33468, `name` = 'Revived', `auraDescription` = 'Immune to physical damage.', `effect2` = 0, `effectApplyAuraName2` = 0, `effectBasePoints2` = 0;
INSERT INTO `spell_template` SELECT * FROM `bonk_look_33468`;
DROP TEMPORARY TABLE `bonk_look_33468`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
