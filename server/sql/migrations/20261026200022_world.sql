DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026200022');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026200022');

UPDATE `bonk_upgrade` SET `value_per_rank` = 2.5, `description` = '+2.5% Haste.' WHERE `id` = 41;
UPDATE `bonk_upgrade` SET `value_per_rank` = 1.2, `description` = '+1.2% critical strike chance.' WHERE `id` = 42;
UPDATE `bonk_upgrade` SET `value_per_rank` = 0.8, `description` = '+0.8% dodge chance.' WHERE `id` = 45;
UPDATE `bonk_upgrade` SET `value_per_rank` = 2.5, `description` = '+2.5% Area.' WHERE `id` = 47;
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
