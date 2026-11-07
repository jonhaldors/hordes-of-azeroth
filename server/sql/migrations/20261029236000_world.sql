DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029236000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029236000');

UPDATE `bonk_card` SET `max_copies` = 1 WHERE `id` IN (1, 13);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
