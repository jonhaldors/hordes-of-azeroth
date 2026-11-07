DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103700000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103700000');

UPDATE `bonk_level` SET `epic_chance` = 25, `blue_chance` = 75, `legendary_chance` = 3.5, `reward` = 1.9 WHERE `tier` = 2 AND `level` BETWEEN 11 AND 19;
UPDATE `bonk_level` SET `epic_chance` = 30, `blue_chance` = 70, `legendary_chance` = 4.5, `reward` = 2.0 WHERE `tier` = 2 AND `level` BETWEEN 20 AND 29;
UPDATE `bonk_level` SET `epic_chance` = 35, `blue_chance` = 65, `legendary_chance` = 5.5, `reward` = 2.1 WHERE `tier` = 2 AND `level` = 30;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
