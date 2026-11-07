DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017075000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017075000');

UPDATE `bonk_weapon` SET `heal_pct` = 0.5, `description` = 'Strikes the 3 nearest enemies within 8 yards and heals you for 0.5% of your maximum health for each enemy hit, up to 2.5% per strike. Its critical strikes Enrage you. Enrage gives you 25% Haste for 4 sec.' WHERE `id` = 304;
UPDATE `bonk_weapon` SET `heal_pct` = 0.5, `description` = 'Strikes the 3 nearest enemies within 8 yards, healing you 0.5% of your maximum health per enemy hit, up to 2.5% per strike. Healing above your maximum health becomes a Blood Shield that explodes when it breaks, dealing 200% damage within 8 yards.' WHERE `id` = 319;
UPDATE `bonk_weapon` SET `heal_pct` = 0.5, `description` = 'Strikes the 3 nearest enemies within 8 yards and heals you for 0.5% of your maximum health for each enemy hit, up to 2.5% per strike. While you are below 50% health, it strikes all enemies within 8 yards instead, healing up to 4%.' WHERE `id` = 320;
UPDATE `bonk_passive` SET `description` = 'Your hits have a 10% chance to heal you for 1% of your maximum health, healing at most 0.3% of your maximum health per second for each rank.' WHERE `id` = 20;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
