DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012220000');

UPDATE `bonk_talent` SET `description` = '+25 Valor at the start of a run.' WHERE `id` = 8;
UPDATE `bonk_talent` SET `description` = 'Skip an upgrade choice once per run for a little Valor.' WHERE `id` = 9;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
