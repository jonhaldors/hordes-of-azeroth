DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017065000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017065000');

UPDATE `bonk_weapon` SET `heal_pct` = 0.4, `description` = 'Strikes the 3 nearest enemies within 8 yards and heals you for 0.4% of your maximum health for each enemy hit. Its critical strikes Enrage you. Enrage gives you 25% Haste for 4 sec.' WHERE `id` = 304;
UPDATE `bonk_weapon` SET `heal_pct` = 0.4, `description` = 'Strikes the 3 nearest enemies within 8 yards, healing you 0.4% of your maximum health per enemy hit. Healing above your maximum health becomes a Blood Shield that explodes when it breaks, dealing 200% damage within 8 yards. Its critical strikes Enrage you.' WHERE `id` = 319;
UPDATE `bonk_weapon` SET `heal_pct` = 0.4, `description` = 'Strikes the 3 nearest enemies within 8 yards and heals you for 0.4% of your maximum health for each enemy hit. While you are below 50% health, it strikes all enemies within 8 yards instead, healing up to 4%. Its critical strikes Enrage you.' WHERE `id` = 320;
UPDATE `bonk_weapon` SET `heal_pct` = 0.3, `description` = 'Blasts all enemies within 8 yards of you with thunder. Enemies hit attack 20% slower and deal 20% less damage for 6 sec. Each blast heals you for 0.3% of your maximum health for each enemy hit, up to 2%.' WHERE `id` = 328;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
