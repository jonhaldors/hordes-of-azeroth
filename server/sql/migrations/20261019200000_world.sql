DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019200000');

UPDATE `bonk_weapon` SET `damage_fraction` = 2.5 WHERE `id` IN (502, 516);
UPDATE `bonk_weapon` SET `damage_fraction` = 8.0 WHERE `id` IN (503, 518, 519);
UPDATE `bonk_weapon` SET `damage_fraction` = 2.0 WHERE `id` IN (505, 522);
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` IN (511, 535);

UPDATE `bonk_weapon` SET `apply_stacks` = 6 WHERE `id` IN (508, 528, 529);
UPDATE `bonk_weapon` SET `description` = 'Afflicts the 3 enemies farthest from you within 35 yards, applying 6 stacks of Decay.' WHERE `id` = 508;
UPDATE `bonk_weapon` SET `description` = 'Afflicts the 3 enemies farthest from you within 35 yards, applying 6 stacks of Decay. Your Decay damage heals you for 2% of the damage dealt, up to 1% of your maximum health a second.' WHERE `id` = 528;
UPDATE `bonk_weapon` SET `description` = 'Afflicts the 3 enemies farthest from you within 35 yards, applying 6 stacks of Decay and 1 stack of Shadow Vulnerability.' WHERE `id` = 529;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.5, `cooldown_ms` = 10000 WHERE `id` IN (506, 524);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.0, `cooldown_ms` = 10000 WHERE `id` = 525;
UPDATE `bonk_weapon` SET `description` = 'Deals Shadow damage to all enemies within 8 yards. Normal enemies also flee in fear for 2 seconds; elites, mini-bosses and bosses do not flee.' WHERE `id` = 506;
UPDATE `bonk_weapon` SET `description` = 'Deals Shadow damage to all enemies within 8 yards. Normal enemies also flee in fear for 2 seconds and take 20% more damage while frightened; elites, mini-bosses and bosses do not flee.' WHERE `id` = 524;
UPDATE `bonk_weapon` SET `description` = 'Deals Shadow damage to all enemies within 8 yards. Normal enemies also flee in fear for 2 seconds and gain 3 stacks of Decay; elites, mini-bosses and bosses do not flee.' WHERE `id` = 525;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
