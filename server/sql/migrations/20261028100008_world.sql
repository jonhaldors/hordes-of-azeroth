DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100008');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100008');

UPDATE `bonk_weapon` SET `description` = 'A wave of fire blasts all enemies within 10 yards of you, dealing Fire damage, 10% more per Burning stack, up to 30 stacks. Every Burning enemy it hits erupts for 40% damage on up to 3 enemies within 5 yards.' WHERE `id` = 423;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
