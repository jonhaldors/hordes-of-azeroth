DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020975000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020975000');

DELETE FROM `bonk_quest` WHERE `id` = 42 AND `reward_type` = 2 AND `reward_value` = 38;
UPDATE `bonk_mastery` SET `description` = 'Serpent Sting can be your starter spell. Choose it at the Run Master.' WHERE `id` = 30302;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
