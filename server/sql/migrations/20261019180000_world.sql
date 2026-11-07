DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019180000');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.0, `cooldown_ms` = 5000 WHERE `id` IN (502, 516, 517);
UPDATE `bonk_weapon` SET `damage_fraction` = 6.0 WHERE `id` IN (503, 518, 519);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.2, `cooldown_ms` = 3000 WHERE `id` IN (505, 522, 523);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.5 WHERE `id` IN (507, 526, 527);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (511, 534, 535);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
