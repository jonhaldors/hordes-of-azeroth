DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019190000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019190000');

UPDATE `bonk_keyword` SET `value_per_stack` = 0.04 WHERE `id` IN (3, 4, 5, 13);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
