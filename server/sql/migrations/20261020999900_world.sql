DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020999900');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020999900');

UPDATE `bonk_tier` SET `mastery_xp_minute` = 15, `mastery_xp_miniboss` = 23, `mastery_xp_boss` = 60 WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `mastery_xp_minute` = 20, `mastery_xp_miniboss` = 30, `mastery_xp_boss` = 80 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
