DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025180000');

UPDATE `bonk_weapon` SET `cooldown_ms` = 2000, `base_targets` = 2, `damage_fraction` = 4.0,
    `description` = 'Moonkin form spell. Every 2 sec, burns the 2 nearest enemies with moonlight, applying 1 stack of Moonfire. Enemies without Moonfire are chosen first.'
    WHERE `id` = 1002;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
