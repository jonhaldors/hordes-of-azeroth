DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013003000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013003000');

UPDATE `bonk_passive` SET `description` = '+8% Haste: you attack and dots tick 8% more often.' WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `description` = '+3% Haste: you attack and dots tick 3% more often.' WHERE `id` = 2;
UPDATE `bonk_weapon` SET `description` = 'Launches explosive traps into the biggest pack of enemies; they go off there and leave the ground burning.' WHERE `id` = 212;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
