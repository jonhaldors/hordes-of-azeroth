DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019510000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019510000');

UPDATE `bonk_passive` SET `description` = '+{8}% Haste. You attack and dots tick more often. Each point of Haste adds a little less than the one before, up to at most 75%.' WHERE `id` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
