DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103998000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103998000');

UPDATE `bonk_weapon` SET `description` = 'Wounds the 3 nearest enemies within 10 yards, applying 3 stacks of Bleed. Your Cleave, Whirlwind and Thunder Clap hits also apply 1 stack of Bleed.' WHERE `id` = 301;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
