DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013014000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013014000');

UPDATE `bonk_weapon` SET `duration_ms` = 5000, `damage_fraction` = 0.14 WHERE `id` = 3;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.29 WHERE `id` = 22;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.29 WHERE `id` = 23;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.32 WHERE `id` = 24;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.32 WHERE `id` = 25;
UPDATE `bonk_weapon` SET `duration_ms` = 8000, `damage_fraction` = 0.15 WHERE `id` = 26;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.29 WHERE `id` = 137;
UPDATE `bonk_weapon` SET `duration_ms` = 5000, `damage_fraction` = 0.23 WHERE `id` = 161;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.35 WHERE `id` = 174;
UPDATE `bonk_weapon` SET `duration_ms` = 5000, `damage_fraction` = 0.23 WHERE `id` = 176;
UPDATE `bonk_weapon` SET `duration_ms` = 4000, `damage_fraction` = 0.19 WHERE `id` = 202;
UPDATE `bonk_weapon` SET `duration_ms` = 3000, `damage_fraction` = 0.47 WHERE `id` = 212;
UPDATE `bonk_weapon` SET `duration_ms` = 5000 WHERE `id` = 204;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
