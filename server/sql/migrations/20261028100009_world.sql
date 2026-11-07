DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100009');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100009');

UPDATE `bonk_weapon` SET `damage_fraction` = 5 WHERE `id` = 1014;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.5 WHERE `id` = 1016;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.2 WHERE `id` = 1022;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.5 WHERE `id` = 423;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.1 WHERE `id` = 408;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2 WHERE `id` = 427;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.5 WHERE `id` = 409;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.55 WHERE `id` = 429;

UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` = 214;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.5 WHERE `id` = 218;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.7 WHERE `id` = 216;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.1 WHERE `id` IN (720, 721);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` IN (724, 725);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
