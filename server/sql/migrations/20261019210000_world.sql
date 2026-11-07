DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019210000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019210000');

DELETE FROM `spell_mod` WHERE `Id` = 9484;
INSERT INTO `spell_mod` (`Id`, `AuraInterruptFlags`) VALUES (9484, 0);

UPDATE `bonk_weapon` SET `description` = 'Normal enemies within 8 yards flee in fear for 2 seconds, taking Shadow damage every second while they flee. Elites, mini-bosses and bosses do not flee.' WHERE `id` = 506;
UPDATE `bonk_weapon` SET `description` = 'Normal enemies within 8 yards flee in fear for 2 seconds, taking Shadow damage every second while they flee and 20% more damage from everything. Elites, mini-bosses and bosses do not flee.' WHERE `id` = 524;
UPDATE `bonk_weapon` SET `description` = 'Normal enemies within 8 yards flee in fear for 2 seconds and gain 3 stacks of Decay, taking Shadow damage every second while they flee. Elites, mini-bosses and bosses do not flee.' WHERE `id` = 525;
UPDATE `bonk_weapon` SET `description` = 'Binds the strongest enemy nearby, elites first, in chains of light for 2 seconds. It takes Holy damage when bound and every second while bound. Bosses and mini-bosses cannot be bound but still take the first hit.' WHERE `id` = 507;
UPDATE `bonk_weapon` SET `description` = 'Binds the strongest enemy nearby, elites first, in chains of light for 2 seconds. It takes Holy damage when bound and every second while bound, and 30% more damage from everything. Bosses and mini-bosses cannot be bound but still take the first hit.' WHERE `id` = 526;
UPDATE `bonk_weapon` SET `description` = 'Binds the 3 strongest enemies nearby, elites first, in chains of light for 2 seconds. They take Holy damage when bound and every second while bound. Bosses and mini-bosses cannot be bound but still take the first hit.' WHERE `id` = 527;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (507, 526, 527) AND `upgrade` = 5;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES (507, 5, 15), (526, 5, 15), (527, 5, 15);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
