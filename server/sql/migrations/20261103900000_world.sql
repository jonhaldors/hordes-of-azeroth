DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103900000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103900000');

UPDATE `bonk_passive` SET `description` = 'Your hits have a {10}% chance to heal you for 1% of your maximum health, up to {0.6}% per second.' WHERE `id` = 20;
UPDATE `bonk_passive_locale` SET `description` = REPLACE(`description`, '{0.3}', '{0.6}') WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
