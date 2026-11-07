DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016470000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016470000');

UPDATE `bonk_quest` SET `class` = 11, `amount` = 40, `description` = 'Reach level 40 in a single run as a druid.' WHERE `id` = 32;
UPDATE `bonk_quest` SET `class` = 7,  `amount` = 40, `description` = 'Reach level 40 in a single run as a shaman.' WHERE `id` = 11;
UPDATE `bonk_quest` SET `class` = 2,  `amount` = 40, `description` = 'Kill 40 elites as a paladin.' WHERE `id` = 4;
UPDATE `bonk_quest` SET `class` = 4,  `amount` = 25, `description` = 'Kill 25 elites as a rogue.' WHERE `id` = 34;
UPDATE `bonk_quest` SET `class` = 8,  `description` = 'Win a run on Normal as a mage.' WHERE `id` = 7;
UPDATE `bonk_quest` SET `class` = 9,  `description` = 'Clear stage 1 on Mythic as a warlock.' WHERE `id` = 10;
UPDATE `bonk_quest` SET `class` = 1  WHERE `id` = 40;
UPDATE `bonk_quest` SET `class` = 2  WHERE `id` = 43;
UPDATE `bonk_quest` SET `class` = 3  WHERE `id` = 42;
UPDATE `bonk_quest` SET `class` = 4  WHERE `id` = 41;
UPDATE `bonk_quest` SET `class` = 5  WHERE `id` = 44;
UPDATE `bonk_quest` SET `class` = 7  WHERE `id` IN (33, 45);
UPDATE `bonk_quest` SET `class` = 8  WHERE `id` IN (30, 46);
UPDATE `bonk_quest` SET `class` = 9  WHERE `id` IN (31, 47);
UPDATE `bonk_quest` SET `class` = 11 WHERE `id` = 48;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
