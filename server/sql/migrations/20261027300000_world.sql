DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027300000');

UPDATE `bonk_scaling` SET `health` = 2.0 WHERE `minute` = 0;
UPDATE `bonk_scaling` SET `health` = 2.4 WHERE `minute` = 2;
UPDATE `bonk_scaling` SET `health` = 3.0 WHERE `minute` = 4;
UPDATE `bonk_scaling` SET `health` = 3.7 WHERE `minute` = 6;
UPDATE `bonk_scaling` SET `health` = 4.4 WHERE `minute` = 8;
UPDATE `bonk_scaling` SET `health` = 5.0 WHERE `minute` = 10;

UPDATE `bonk_wave` SET `crowd_start` = ROUND(`crowd_start` * 0.8), `crowd_end` = ROUND(`crowd_end` * 0.8)
WHERE `start_sec` >= 210 AND `name` NOT IN ('Brute Wave', 'Mini-boss');

UPDATE `bonk_tier` SET `max_alive` = 90;
UPDATE `bonk_tier` SET `min_alive_multiplier` = 1.0, `health_multiplier` = 3.2 WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
