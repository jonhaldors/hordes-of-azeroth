DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023140000');

DELETE FROM `creature_template` WHERE `entry` = 900147;
DROP TEMPORARY TABLE IF EXISTS `bonk_hybrid_elemental`;
CREATE TEMPORARY TABLE `bonk_hybrid_elemental` SELECT * FROM `creature_template` WHERE `entry` = 900125;
UPDATE `bonk_hybrid_elemental` SET `entry` = 900147, `name` = 'Hybrid Elemental';
INSERT INTO `creature_template` SELECT * FROM `bonk_hybrid_elemental`;
DROP TEMPORARY TABLE `bonk_hybrid_elemental`;

UPDATE `bonk_weapon` SET `description` = 'Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. It also goes off where you land after each Blink. A blast leaves a time bubble for 10 sec: normal enemies inside move 60% slower, and all enemies inside take 15% more damage. The next blast after it fades leaves a new one.' WHERE `id` = 427;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
