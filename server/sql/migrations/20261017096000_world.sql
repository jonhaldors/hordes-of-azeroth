DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017096000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017096000');

UPDATE `bonk_weapon` SET `apply_stacks` = 2, `description` = 'Every 1 sec, all enemies within 6 yards of you gain 2 stacks of Bleed.' WHERE `id` = 313;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
