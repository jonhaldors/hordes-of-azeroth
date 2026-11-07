DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016580000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016580000');

UPDATE `bonk_mastery` SET `name` = 'Arcane Precision' WHERE `id` = 30201;
UPDATE `bonk_mastery` SET `name` = 'Improved Arcane Shot' WHERE `id` = 30210;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
