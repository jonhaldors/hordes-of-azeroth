DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103600000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103600000');

ALTER TABLE `bonk_archetype` ADD COLUMN `threat` FLOAT NOT NULL DEFAULT 1;

UPDATE `bonk_archetype` SET `threat` = 1.0 WHERE `id` IN (0, 1);
UPDATE `bonk_archetype` SET `threat` = 1.5 WHERE `id` = 2;
UPDATE `bonk_archetype` SET `threat` = 1.2 WHERE `id` = 3;
UPDATE `bonk_archetype` SET `threat` = 1.3 WHERE `id` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
