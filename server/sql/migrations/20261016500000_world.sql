DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016500000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016500000');

UPDATE `bonk_quest` SET `amount` = 5, `description` = 'Reach stage 5 on Mythic, the second Endless stage.' WHERE `id` = 407;
UPDATE `bonk_quest` SET `amount` = 60, `description` = 'Reach level 60 in a single run.' WHERE `id` = 405;
UPDATE `bonk_quest` SET `amount` = 250, `description` = 'Kill 250 elites.' WHERE `id` = 401;
UPDATE `bonk_quest` SET `amount` = 25, `description` = 'Die 25 times.' WHERE `id` = 402;
UPDATE `bonk_quest` SET `amount` = 5000, `description` = 'Kill 5,000 enemies while standing still.' WHERE `id` = 302;
UPDATE `bonk_quest` SET `amount` = 25000, `description` = 'Kill 25,000 enemies with Nature spells.' WHERE `id` = 310;
UPDATE `bonk_quest` SET `amount` = 25000, `description` = 'Kill 25,000 enemies with physical attacks.' WHERE `id` = 315;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
