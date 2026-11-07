DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021237000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021237000');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.9 WHERE `id` = 800;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.4 WHERE `id` = 812;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.2, `base_targets` = 2,
    `description` = 'Smites the 2 nearest enemies with Holy damage. Each Smite takes 1 sec off Holy Word: Chastise.'
    WHERE `id` = 500;
UPDATE `bonk_weapon` SET `description` = REPLACE(REPLACE(`description`, 'between 5 and 16 yards from you', 'within 16 yards of you'), ' Enemies closer than 5 yards are not hit.', '')
    WHERE `id` IN (502, 516, 517);
UPDATE `bonk_weapon` SET `cooldown_ms` = 4000 WHERE `id` = 502;
UPDATE `bonk_weapon` SET `cooldown_ms` = 12000 WHERE `id` = 503;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.6 WHERE `id` = 505;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.8 WHERE `id` = 510;

UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 600;
UPDATE `bonk_weapon` SET `cooldown_ms` = 8000 WHERE `id` = 603;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.6, `base_targets` = 3,
    `description` = REPLACE(`description`, 'Throws 2 shurikens', 'Throws 3 shurikens')
    WHERE `id` = 608;
UPDATE `bonk_weapon` SET `damage_fraction` = 5.0 WHERE `id` = 609;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` = 700;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2, `cooldown_ms` = 2000 WHERE `id` = 701;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2 WHERE `id` IN (702, 703);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` = 704;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` = 705;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.4 WHERE `id` = 709;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
