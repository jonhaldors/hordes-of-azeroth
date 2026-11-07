DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100001');

UPDATE `bonk_weapon` SET `damage_fraction` = 3.75 WHERE `id` = 609;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.2 WHERE `id` IN (630, 631);

UPDATE `bonk_weapon` SET `damage_fraction` = 3.6 WHERE `id` = 505;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.8 WHERE `id` = 522;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.7 WHERE `id` = 523;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.1 WHERE `id` IN (506, 524);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` = 525;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.5 WHERE `id` IN (507, 526);
UPDATE `bonk_weapon` SET `damage_fraction` = 3.2 WHERE `id` = 527;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.1 WHERE `id` IN (202, 224);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.14 WHERE `id` = 225;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` = 226;

UPDATE `bonk_weapon` SET `damage_fraction` = 0.9 WHERE `id` = 704;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` IN (720, 721);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.3 WHERE `id` = 705;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (722, 723);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` = 707;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` IN (726, 727);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
