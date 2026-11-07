DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120000');

UPDATE `bonk_weapon` SET `name` = 'Avenger''s Shield', `icon` = 'Spell_Holy_SealOfProtection', `spell_id` = 20925, `cooldown_ms` = 5000, `range` = 25, `radius` = 0, `damage_fraction` = 2.2, `base_targets` = 1, `base_jumps` = 4,
    `description` = 'Hurls a holy shield at the nearest enemy within 25 yards for Holy damage. It jumps to 4 more enemies within 10 yards, never the same one twice. Each hit counts as a Paladin strike.' WHERE `id` = 813;
UPDATE `bonk_weapon` SET `name` = 'Grand Crusader', `icon` = 'Spell_Holy_HolyBolt', `spell_id` = 20925, `cooldown_ms` = 5000, `range` = 25, `radius` = 0, `damage_fraction` = 2.2, `base_targets` = 1, `base_jumps` = 8,
    `description` = 'Hurls a holy shield at the nearest enemy within 25 yards for Holy damage. It jumps to 8 more enemies within 10 yards, never the same one twice. Each hit counts as a Paladin strike.' WHERE `id` = 839;
UPDATE `bonk_weapon` SET `name` = 'Shield of the Righteous', `icon` = 'Spell_Holy_InnerFire', `spell_id` = 20925, `cooldown_ms` = 5000, `range` = 25, `radius` = 5, `damage_fraction` = 2.2, `base_targets` = 1, `base_jumps` = 4,
    `description` = 'Hurls a holy shield at the nearest enemy within 25 yards for Holy damage. It jumps to 4 more enemies within 10 yards, never the same one twice. Each hit also deals half its damage to enemies within 5 yards of the target and counts as a Paladin strike.' WHERE `id` = 840;
DELETE FROM `bonk_weapon_locale` WHERE `id` IN (813, 839, 840);

UPDATE `bonk_mastery` SET `description` = 'Judgement critical strikes reset the cooldown of Avenger''s Shield.' WHERE `id` = 20325;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.35 WHERE `id` IN (806, 827, 828);

UPDATE `bonk_weapon` SET `damage_fraction` = 1.8 WHERE `id` IN (802, 819, 820);
UPDATE `bonk_weapon` SET `description` = 'Every 2nd strike from your other Paladin spells releases a burst of light, dealing Holy damage to the target and every enemy within 5 yards of it.' WHERE `id` = 802;
UPDATE `bonk_weapon` SET `description` = 'Every strike from your other Paladin spells releases a burst of light, dealing Holy damage to the target and every enemy within 5 yards of it.' WHERE `id` = 819;
UPDATE `bonk_weapon` SET `description` = 'Every 2nd strike from your other Paladin spells releases a burst of light, dealing Holy damage to the target and every enemy within 5 yards of it and stunning normal and elite enemies for 1 sec.' WHERE `id` = 820;

UPDATE `bonk_weapon` SET `description` = 'Every hit from your other Paladin spells, splash and area hits included, deals 30% extra as Holy damage.' WHERE `id` = 803;
UPDATE `bonk_weapon` SET `description` = 'Every hit from your other Paladin spells, splash and area hits included, deals 60% extra as Holy damage.' WHERE `id` = 821;
UPDATE `bonk_weapon` SET `description` = 'Every hit from your other Paladin spells, splash and area hits included, deals 30% extra as Holy damage, 20% more for each hit on the same enemy, up to 5 times.' WHERE `id` = 822;

UPDATE `bonk_weapon` SET `damage_fraction` = 6.5 WHERE `id` = 826;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
