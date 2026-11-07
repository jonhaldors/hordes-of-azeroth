DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100016');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100016');

UPDATE `bonk_card` SET `value2` = 400, `description` = 'Your spells have a 4% chance to gain +400% Power for that cast.' WHERE `id` = 19;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
