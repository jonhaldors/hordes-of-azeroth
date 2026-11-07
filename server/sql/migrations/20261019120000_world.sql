DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019120000');

UPDATE `bonk_scaling` SET `hit_share` = 3.5 WHERE `minute` = 0;
UPDATE `bonk_scaling` SET `hit_share` = 5, `health` = 1.45 WHERE `minute` = 2;
UPDATE `bonk_scaling` SET `hit_share` = 6.5, `health` = 2.25 WHERE `minute` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
