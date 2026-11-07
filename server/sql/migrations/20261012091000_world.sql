DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012091000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012091000');

UPDATE `bonk_passive` SET `description` = '+1 target for spells aimed at enemies.' WHERE `id` = 3;
UPDATE `bonk_upgrade` SET `description` = '+1 target for spells aimed at enemies.' WHERE `id` = 8;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
