DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018210000');

UPDATE `bonk_weapon` SET `spell_id` = 133 WHERE `id` = 713;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
