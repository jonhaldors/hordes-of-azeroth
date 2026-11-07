DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019250000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019250000');

UPDATE `bonk_wave` SET `bruiser` = 6, `max_bruisers` = 1 WHERE `start_sec` IN (150, 180);
UPDATE `bonk_wave` SET `bruiser` = 6, `max_bruisers` = 2 WHERE `start_sec` IN (195, 210);
UPDATE `bonk_wave` SET `bruiser` = 8, `max_bruisers` = 3 WHERE `start_sec` IN (315, 360);
UPDATE `bonk_wave` SET `bruiser` = 6, `max_bruisers` = 3 WHERE `start_sec` = 420;
UPDATE `bonk_wave` SET `bruiser` = 8, `max_bruisers` = 3 WHERE `start_sec` = 600;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
