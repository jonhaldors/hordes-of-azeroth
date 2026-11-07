DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103950000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103950000');

UPDATE `bonk_mob_ability` SET `impact_kit` = 282 WHERE `spell_id` = 8078 AND `shape` = 16 AND `impact_kit` = 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;