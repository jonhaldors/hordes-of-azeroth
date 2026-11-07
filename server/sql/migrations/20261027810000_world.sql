DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810000');

UPDATE `bonk_mastery` SET `description` = 'You are always Enraged, and Enrage is 50% stronger. You take 15% more damage.' WHERE `id` = 10210;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
