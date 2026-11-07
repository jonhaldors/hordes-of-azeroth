DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012032000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012032000');

UPDATE `bonk_passive` SET `description` = '+10% damage.' WHERE `id` = 1;
UPDATE `bonk_upgrade` SET `description` = '+5% damage.' WHERE `id` = 1;

UPDATE `bonk_passive` SET `description` = 'Heal for 2% of the damage you deal.' WHERE `id` = 10;
UPDATE `bonk_item_set_bonus` SET `description` = '+15% Power, and heal for 3% of the damage you deal.' WHERE `set_id` = 2 AND `pieces` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
