DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100005');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100005');

UPDATE `bonk_weapon` SET `cooldown_ms` = 7000 WHERE `id` IN (506, 524, 525);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.2 WHERE `id` = 609;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.3 WHERE `id` = 630;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
