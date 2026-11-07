DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030190000');

UPDATE `bonk_mastery` SET `description` = 'Your dash becomes Blink and its cooldown is halved. Each dash sets off your Arcane Explosion where you land. Stacks with the Blink spell.' WHERE `id` = 80110;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
