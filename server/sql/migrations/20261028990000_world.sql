DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028990000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028990000');

ALTER TABLE `bonk_scaling` ADD COLUMN `health_normal` FLOAT NOT NULL DEFAULT 1 AFTER `health`;

UPDATE `bonk_scaling` SET `health_normal` = `health`;
UPDATE `bonk_scaling` SET `health_normal` = 1.0 WHERE `minute` = 0;
UPDATE `bonk_scaling` SET `health_normal` = 1.45 WHERE `minute` = 2;
UPDATE `bonk_scaling` SET `health_normal` = 2.25 WHERE `minute` = 4;
UPDATE `bonk_scaling` SET `health_normal` = 3.3 WHERE `minute` = 6;
UPDATE `bonk_scaling` SET `health_normal` = 4.2 WHERE `minute` = 8;
UPDATE `bonk_scaling` SET `health_normal` = 5.0 WHERE `minute` = 10;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
