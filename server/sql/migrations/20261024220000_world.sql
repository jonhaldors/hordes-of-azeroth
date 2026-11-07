DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024220000');

UPDATE `bonk_card` SET `value1` = 1, `description` = 'After standing still for 1 sec, regain 1% of your health every second. Copies stack up to 3%.' WHERE `id` = 6;
UPDATE `bonk_card` SET `description` = 'Healing past full health becomes a Shield, up to 20% of your maximum health. Health regeneration does not count.' WHERE `id` = 9;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
