DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015020000');

DELETE FROM `bonk_map_event` WHERE `event` = 4;
ALTER TABLE `bonk_map_event`
    MODIFY COLUMN `event` TINYINT UNSIGNED NOT NULL COMMENT '0 mini-boss, 1 elites, 2 swarm of normal enemies, 3 chests that cost Valor, 4 ring (now a mini-event), 5 rush from one side';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
