DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101810000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101810000');

UPDATE `bonk_weapon` SET `cooldown_ms` = 1500, `damage_fraction` = 1.6 WHERE `id` IN (711, 734, 735);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` = 709;
UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` IN (730, 731);

UPDATE `bonk_weapon` SET `description` = 'Hurls a Magma Totem onto the biggest group of enemies within 25 yards. It pulses fire every 2 sec, dealing Fire damage and 1 stack of Burning to enemies within 8 yards, and is hurled again once none are in reach.' WHERE `id` = 709;
UPDATE `bonk_weapon` SET `description` = 'Hurls a Magma Totem onto the biggest group of enemies within 25 yards. It pulses fire every 2 sec, dealing Fire damage and 1 stack of Burning to enemies within 8 yards, and is hurled again once none are in reach. Each pulse also hurls 2 globs of magma at enemies within 12 yards.' WHERE `id` = 730;
UPDATE `bonk_weapon` SET `description` = 'Hurls a Magma Totem onto the biggest group of enemies within 25 yards. It pulses fire every 2 sec, dealing Fire damage and 1 stack of Burning to enemies within 8 yards and Dazing them, and is hurled again once none are in reach.' WHERE `id` = 731;
UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps the nearest enemy within 8 yards for Nature damage and 1 stack of Static, and each zap gives you a Shield of 0.5% of your maximum health, up to 5%. An enemy that strikes you spends a charge and is zapped too. One charge returns every 1.5 sec.' WHERE `id` = 711;
UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps the nearest enemy within 8 yards for Nature damage and 1 stack of Static, and each zap gives you a Shield of 1.5% of your maximum health, up to 15%. An enemy that strikes you spends a charge and is zapped too. One charge returns every 1.5 sec.' WHERE `id` = 734;
UPDATE `bonk_weapon` SET `description` = 'Surrounds you with up to 3 lightning charges. Every 1.5 sec it zaps the nearest enemy within 8 yards and enemies within 4 yards of it for Nature damage and 1 stack of Static, and each zap gives you a Shield of 0.5% of your maximum health, up to 5%. When an enemy strikes you or your melee hits land, a charge is spent on another zap. One charge returns every 1.5 sec.' WHERE `id` = 735;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
