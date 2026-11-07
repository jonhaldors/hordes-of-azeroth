DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020950000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020950000');

ALTER TABLE `bonk_weapon_upgrade` MODIFY `upgrade` tinyint(3) unsigned NOT NULL COMMENT 'BonkSpellUpgrade: 1 spell cleave, 2 hit twice, 3 Haste, 4 retired (radius), 5 duration, 6 Mark strength, 7 summon damage, 8 summon size, 9 +1 stack applied, 10 damage taken when slowed, 11 frenzy damage, 12 deploy range, 13 trap radius, 14 Shield size, 15 internal cooldown, 16 Echo, 17 melee reach';

INSERT IGNORE INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `id`, 17, 10 FROM `bonk_weapon`
WHERE NOT (`flags` & 0x4000000) AND `target` NOT IN (3, 7) AND `range` > 0 AND `range` <= 12 AND `damage_fraction` > 0;

UPDATE `bonk_passive` SET `description` = '+{10}% Area. Your AoE spells cover more ground.'
WHERE `id` = 11;

UPDATE `bonk_mastery` SET `description` = '+4% Area. Your AoE spells cover more ground.'
WHERE `description` = '+4% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.';

UPDATE `bonk_card` SET `description` = '+1 Count and +15% Area. Your spells fire 1 additional bolt, land 1 additional ground effect, cast again or affect 1 additional target, depending on the spell. Your AoE spells also cover more ground.'
WHERE `id` = 105;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
