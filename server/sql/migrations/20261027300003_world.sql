DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300003');

UPDATE `bonk_glyph` SET `description` = REPLACE(REPLACE(`description`, 'stage', 'floor'), 'Stage', 'Floor') WHERE `description` LIKE '%stage%';
UPDATE `bonk_mastery` SET `description` = REPLACE(REPLACE(`description`, 'stage', 'floor'), 'Stage', 'Floor') WHERE `description` LIKE '%stage%';
UPDATE `bonk_talent` SET `description` = REPLACE(REPLACE(`description`, 'stage', 'floor'), 'Stage', 'Floor') WHERE `description` LIKE '%stage%';
UPDATE `bonk_quest` SET `description` = REPLACE(REPLACE(`description`, 'stage', 'floor'), 'Stage', 'Floor') WHERE `description` LIKE '%stage%';
UPDATE `bonk_map` SET `description` = REPLACE(REPLACE(`description`, 'stage', 'floor'), 'Stage', 'Floor') WHERE `description` LIKE '%stage%';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
