DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016100000');

UPDATE `bonk_card` SET `max_copies` = 5 WHERE `max_copies` = 0;
UPDATE `bonk_card` SET `max_copies` = 3 WHERE `id` = 15;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
