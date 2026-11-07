DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100002');

UPDATE `bonk_mastery` SET `description` = 'Ambush also hits every enemy within 8 yards of the target for half damage.' WHERE `id` = 40310;

UPDATE `bonk_weapon` SET `damage_fraction` = 2.8 WHERE `id` IN (506, 524);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.9 WHERE `id` = 525;
UPDATE `bonk_weapon` SET `damage_fraction` = 4.2 WHERE `id` = 505;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.3 WHERE `id` = 522;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 523;

UPDATE `bonk_weapon` SET `damage_fraction` = 0.95 WHERE `id` IN (720, 721);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2 WHERE `id` = 706;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.3 WHERE `id` IN (724, 725);

UPDATE `bonk_weapon` SET `damage_fraction` = 1.3 WHERE `id` IN (202, 224);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.17 WHERE `id` = 225;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
