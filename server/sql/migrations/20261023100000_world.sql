DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023100000');

UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 8 yards of you. Deals 8% more damage to each enemy for each stack of Bleed on it, counting up to 30 stacks. Each Bleeding enemy hit shortens its cooldown by 0.5 sec, at most 1 sec a strike, down to 3 sec.' WHERE `id` = 317;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 8 yards of you, dealing 8% more damage for each stack of Bleed on them, up to 30 stacks. 1.5 sec later the ground where you struck erupts for 30% of that damage, applying 1 stack of Bleed to each enemy within 8 yards.' WHERE `id` = 318;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
