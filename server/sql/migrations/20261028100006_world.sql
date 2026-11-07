DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028100006');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028100006');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.3 WHERE `id` = 600;
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (612, 613);
UPDATE `bonk_weapon` SET `behavior_value` = 2, `description` = 'Your single-target hits always strike 2 more enemies within 8 yards at 50% damage. The extra hits carry your poisons and openers.' WHERE `id` = 614;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
