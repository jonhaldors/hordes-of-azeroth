DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019000000');

UPDATE `bonk_pet_family` SET `scale` = 0.8 WHERE `id` IN (7, 8, 9);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
