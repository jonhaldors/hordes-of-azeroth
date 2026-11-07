DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021110000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` = 801;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.0 WHERE `id` = 802;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.7, `range` = 12,
    `description` = 'Every sec, deals Holy damage to every Judged enemy within 12 yards of you.' WHERE `id` = 810;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` = 811;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
