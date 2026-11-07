DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012230000');

UPDATE `bonk_passive` SET `description` = '+8% Haste: spells fire and dots tick 8% more often.' WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `description` = '+3% Haste: spells fire and dots tick 3% more often.' WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
