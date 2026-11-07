DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120003');

UPDATE `bonk_weapon` SET `base_targets` = 5, `apply_stacks` = 5 WHERE `id` IN (301, 314);
UPDATE `bonk_weapon` SET `description` = 'Wounds the 5 nearest enemies within 10 yards with 5 stacks of Bleed.' WHERE `id` = 301;
UPDATE `bonk_weapon` SET `description` = 'Wounds the 5 nearest enemies within 10 yards with 5 stacks of Bleed. Bleeding enemies that die leave a pool of blood for 4 sec that adds 1 stack of Bleed every sec to enemies within 4 yards.' WHERE `id` = 314;

UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy with 2 stacks of Bleed, at most once every 0.5 sec per enemy. Your critical strike chance against a Bleeding enemy is increased by 1% per stack of Bleed, up to 20%.' WHERE `id` = 302;
UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy and every enemy within 4 yards of it with 2 stacks of Bleed, at most once every 0.5 sec per enemy. Your critical strike chance against a Bleeding enemy is increased by 1% per stack of Bleed, up to 20%.' WHERE `id` = 315;
UPDATE `bonk_weapon` SET `description` = 'Your critical strikes wound the enemy with 2 stacks of Bleed, at most once every 0.5 sec per enemy. Each time this Bleed deals damage, it deals 10% more, up to triple. Your critical strike chance against a Bleeding enemy is increased by 1% per stack of Bleed, up to 20%.' WHERE `id` = 316;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
