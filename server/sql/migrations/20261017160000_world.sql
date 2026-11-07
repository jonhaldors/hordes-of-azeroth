DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017160000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017160000');

UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy, applying 2 stacks of Bleed. Can occur once every 0.5 sec on each enemy. |cffff8040Only critical strikes trigger it.|r' WHERE `id` = 302;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 8 yards of you. Deals 8% more damage to each enemy for each stack of Bleed on it, counting up to 30 stacks.' WHERE `id` = 303;
UPDATE `bonk_weapon` SET `description` = 'Every 10 sec, adds a Shield of 10% of your maximum health. The Shield stays until it absorbs damage, building up to 50% of your maximum health.' WHERE `id` = 307;
UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy and every enemy within 4 yards of it, applying 2 stacks of Bleed to each. Can occur once every 0.5 sec on each enemy. |cffff8040Only critical strikes trigger it.|r' WHERE `id` = 315;
UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy, applying 2 stacks of Bleed. Each tick of this Bleed deals 10% more damage than the last, up to 200% more. Can occur once every 0.5 sec on each enemy. |cffff8040Only critical strikes trigger it.|r' WHERE `id` = 316;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 8 yards of you. Deals 8% more damage to each enemy for each stack of Bleed on it, counting up to 30 stacks. Each Bleeding enemy hit shortens its cooldown by 0.5 sec, down to 1 sec.' WHERE `id` = 317;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 8 yards of you, dealing 8% more damage for each stack of Bleed on them, up to 30 stacks. 1.5 sec later the ground where you struck erupts for 50% of that damage, applying 2 stacks of Bleed to each enemy within 8 yards.' WHERE `id` = 318;
UPDATE `bonk_weapon` SET `description` = 'Every 10 sec, adds a Shield of 10% of your maximum health that stays until it absorbs damage. Each hit your Shield absorbs sends out a shockwave that strikes all enemies within 6 yards of you. The shockwave can occur once every 0.5 sec.' WHERE `id` = 325;
UPDATE `bonk_weapon` SET `description` = 'Every 10 sec, adds a Shield of 10% of your maximum health that stays until it absorbs damage. While you hold any Shield, its spikes strike all enemies within 6 yards of you every 1 sec.' WHERE `id` = 326;
UPDATE `bonk_weapon` SET `description` = 'Blasts all enemies within 8 yards of you with thunder after every 20 hits by your other spells, instead of on a cooldown. Enemies hit attack 20% slower for 6 sec. Haste lowers the count, down to 10 hits.' WHERE `id` = 327;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
