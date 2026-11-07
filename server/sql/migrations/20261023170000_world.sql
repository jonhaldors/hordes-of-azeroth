DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023170000');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` IN (908, 927, 928);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` IN (907, 925, 926);
UPDATE `bonk_weapon` SET `base_targets` = 1, `damage_fraction` = 1.4, `heal_pct` = 0.2 WHERE `id` IN (906, 923, 924);
UPDATE `bonk_weapon` SET `description` = 'A tentacle of shadow latches onto the nearest enemy within 20 yards, dealing Shadow damage every sec and healing you for 0.2% of your maximum health per enemy drained. It keeps draining while you move and always reaches for the closest enemies.' WHERE `id` = 906;
UPDATE `bonk_weapon` SET `description` = 'A tentacle drains the nearest enemy and heals you. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `description` = 'A tentacle drains the nearest enemy and heals you. Healing past full health makes your demons deal 30% more damage for 4 sec.' WHERE `id` = 924;
UPDATE `bonk_weapon` SET `description` = 'Fires a bolt of shadow at the nearest enemy. Nightfall: an enemy that dies with one of your afflictions on it fires a free Shadow Bolt, at most 1 a sec.' WHERE `id` = 907;
UPDATE `bonk_weapon` SET `description` = 'Fires a fel bolt at the nearest enemy, with Nightfall. Every 4th bolt erupts in fel fire, critically striking its target and every enemy within 8 yards.' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker. Each enemy that dies near it is consumed and it grows; after 8 it bursts in a void nova, dealing Shadow damage to every enemy around it, and shrinks back.' WHERE `id` = 901;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker that consumes enemies dying near it and bursts after 8 in a void nova. Each burst also shields you for 5% of your maximum health.' WHERE `id` = 913;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker that consumes enemies dying near it and bursts after 8. Every 6 sec it slams the ground, dealing Shadow damage to enemies within 8 yards and knocking normal enemies away.' WHERE `id` = 914;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
