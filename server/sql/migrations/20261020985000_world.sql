DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020985000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020985000');

UPDATE `bonk_card` SET `value1` = 0.01, `value2` = 5, `description` = '+0.01% Power for each kill, up to +5%.' WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
