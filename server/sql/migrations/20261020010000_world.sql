DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020010000');

UPDATE `bonk_tier` SET `mastery_xp_minute` = 20, `mastery_xp_miniboss` = 30, `mastery_xp_boss` = 80 WHERE `id` = 3;
UPDATE `bonk_tier` SET `mastery_xp_minute` = 35, `mastery_xp_miniboss` = 52, `mastery_xp_boss` = 140 WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
