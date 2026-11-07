DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101850000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101850000');

UPDATE `bonk_weapon` SET `heal_pct` = 1 WHERE `id` IN (906, 923, 924);
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you for 1% of your maximum health per enemy drained.' WHERE `id` = 906;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
