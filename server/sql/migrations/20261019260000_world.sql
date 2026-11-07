DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019260000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019260000');

UPDATE `bonk_weapon` SET `range` = 16 WHERE `id` IN (502, 516, 517);
UPDATE `bonk_weapon` SET `description` = 'A ring of light deals Holy damage to every enemy between 5 and 16 yards from you, and heals you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 5 yards are not hit.' WHERE `id` = 502;
UPDATE `bonk_weapon` SET `description` = 'A ring of light goes off 3 times over 2 sec, each dealing Holy damage to every enemy between 5 and 16 yards from you and healing you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 5 yards are not hit.' WHERE `id` = 516;
UPDATE `bonk_weapon` SET `description` = 'A ring of light deals Holy damage to every enemy between 5 and 16 yards from you, up to 100% more the farther away they are, and heals you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 5 yards are not hit.' WHERE `id` = 517;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
