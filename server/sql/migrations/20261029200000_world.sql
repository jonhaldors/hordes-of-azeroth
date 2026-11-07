DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029200000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `knee_health_step` FLOAT NOT NULL DEFAULT 1,
    ADD COLUMN `knee2_health_step` FLOAT NOT NULL DEFAULT 1;

UPDATE `bonk_tier` SET `knee_health_step` = 1.4, `knee2_health_step` = 1.6 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
