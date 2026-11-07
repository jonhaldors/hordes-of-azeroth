DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031400004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031400004');

UPDATE `bonk_talent` SET `max_rank` = 30 WHERE `id` = 20;
UPDATE `bonk_talent` SET `max_rank` = 25 WHERE `id` = 21;
UPDATE `bonk_talent` SET `max_rank` = 20 WHERE `id` = 22;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
