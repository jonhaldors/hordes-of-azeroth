DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018160000');

UPDATE `bonk_weapon` SET `description` = 'Marks every enemy within 10 yards of the largest group for 8 sec. Marked enemies take 15% more damage. For 6 sec, each of your shots that hits an enemy in that area fires 1 additional shot at the nearest other enemy there.' WHERE `id` = 220;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
