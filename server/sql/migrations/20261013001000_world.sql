DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013001000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013001000');

ALTER TABLE `bonk_map`
    ADD COLUMN `map_type` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 open zone, 1 enclosed raid, 2 arena' AFTER `tier`;
UPDATE `bonk_map` SET `map_type` = 1 WHERE `key` IN ('molten_core', 'zulgurub', 'ruins_of_ahnqiraj') OR `map_id` IN (309, 409, 509);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
