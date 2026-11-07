DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200006');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200006');

UPDATE `bonk_account` SET `talent_reset` = 1 WHERE `account` IN (SELECT DISTINCT `account` FROM `bonk_account_mastery_node` WHERE `node` BETWEEN 30100 AND 30399);
DELETE FROM `bonk_account_mastery_node` WHERE `node` BETWEEN 30100 AND 30399;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
