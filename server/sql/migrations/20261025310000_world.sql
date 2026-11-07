DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
DECLARE ringSpell INT DEFAULT 33600;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025310000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025310000');

ALTER TABLE `bonk_weapon` MODIFY `description` VARCHAR(2048) NOT NULL DEFAULT '';

DELETE FROM `spell_template` WHERE `entry` BETWEEN 33600 AND 33621;
WHILE ringSpell <= 33621 DO
    DROP TEMPORARY TABLE IF EXISTS `bonk_nature_ring`;
    CREATE TEMPORARY TABLE `bonk_nature_ring` SELECT * FROM `spell_template` WHERE `entry` = 33424;
    UPDATE `bonk_nature_ring` SET `entry` = ringSpell, `spellVisual1` = 9050 + ringSpell - 33600, `name` = 'Efflorescence', `auraDescription` = '';
    INSERT INTO `spell_template` SELECT * FROM `bonk_nature_ring`;
    DROP TEMPORARY TABLE `bonk_nature_ring`;
    SET ringSpell = ringSpell + 1;
END WHILE;

DELETE FROM `creature_template` WHERE `entry` = 900149;
DROP TEMPORARY TABLE IF EXISTS `bonk_druid_pet`;
CREATE TEMPORARY TABLE `bonk_druid_pet` SELECT * FROM `creature_template` WHERE `entry` = 900148;
UPDATE `bonk_druid_pet` SET `entry` = 900149, `name` = 'Ancient of War', `display_id1` = 2429, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_druid_pet`;
DROP TEMPORARY TABLE `bonk_druid_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` = 17;
DELETE FROM `bonk_pet_family` WHERE `id` = 17;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(17, 'Ancient of War', 900149, 0.35, 2000, 15, 1, '');
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `kit`, `comment`) VALUES
(17, 20549, 3, 3000, 2.5, 1, 8, 5089, 'Ancient of War: War Stomp, 8 yd, 2.5 bites worth, 1 Moonfire');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 1014 AND 1039;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 1014 AND 1039;
DROP TEMPORARY TABLE IF EXISTS `bonk_druid_evolution`;
CREATE TEMPORARY TABLE `bonk_druid_evolution` SELECT * FROM `bonk_weapon` WHERE `id` BETWEEN 1001 AND 1013;
UPDATE `bonk_druid_evolution` SET `evolves_from` = `id`, `id` = 1014 + 2 * (`id` - 1001), `starter_class_mask` = 0, `starter_option_mask` = 0;
INSERT INTO `bonk_weapon` SELECT * FROM `bonk_druid_evolution`;
UPDATE `bonk_druid_evolution` SET `id` = `id` + 1;
INSERT INTO `bonk_weapon` SELECT * FROM `bonk_druid_evolution`;
DROP TEMPORARY TABLE `bonk_druid_evolution`;

UPDATE `bonk_weapon` SET `name` = 'Starburst', `icon` = 'Spell_Holy_ElunesGrace',
    `description` = 'Calls down starlight on the strongest enemy within 30 yards for heavy Arcane damage. Empowered in Moonkin Form. The starlight bursts, dealing 50% damage to enemies within 8 yards of the target and applying 1 stack of Moonfire to every enemy hit.' WHERE `id` = 1014;
UPDATE `bonk_weapon` SET `name` = 'Shooting Stars', `icon` = 'Spell_Arcane_TeleportMoonglade',
    `description` = 'Calls down starlight on the strongest enemy within 30 yards for heavy Arcane damage. Empowered in Moonkin Form. Every sec, each enemy with Moonfire within 30 yards has a 3% chance to be struck by a Shooting Star for 50% damage, at most 2 a sec.' WHERE `id` = 1015;
UPDATE `bonk_weapon` SET `name` = 'Sunfire', `icon` = 'Spell_Fire_SunKey',
    `description` = 'Burns the 2 nearest enemies with moonlight for Arcane damage and 1 stack of Moonfire, choosing enemies without Moonfire first. Empowered in Moonkin Form. The fire spreads, applying 1 stack of Moonfire to every enemy within 5 yards of each target.' WHERE `id` = 1016;
UPDATE `bonk_weapon` SET `name` = 'Full Moon', `icon` = 'Spell_Nature_MoonGlow',
    `description` = 'Burns the 2 nearest enemies with moonlight for Arcane damage and 1 stack of Moonfire, choosing enemies without Moonfire first. Empowered in Moonkin Form. Each time an enemy reaches 10, 20 or 30 stacks of Moonfire, a full moon erupts on it, dealing Arcane damage to it and to enemies within 6 yards.' WHERE `id` = 1017;
UPDATE `bonk_weapon` SET `name` = 'Typhoon', `icon` = 'Spell_Nature_ThunderClap',
    `description` = 'A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec to enemies within 8 yards and leaving them Dazed. Empowered in Moonkin Form. When the storm ends, it bursts for double damage and knocks normal enemies away from you.' WHERE `id` = 1018;
UPDATE `bonk_weapon` SET `name` = 'Moonstorm', `icon` = 'Spell_Nature_StormReach',
    `description` = 'A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec to enemies within 8 yards and leaving them Dazed. Empowered in Moonkin Form. Every sec, the storm also applies 1 stack of Moonfire to every enemy inside it.' WHERE `id` = 1019;
UPDATE `bonk_weapon` SET `name` = 'Thrash', `icon` = 'Ability_Druid_Ravage', `damage_fraction` = 0.8,
    `description` = 'Thrashes every enemy within 8 yards for damage and 2 stacks of Bleed. Empowered in Cat Form.' WHERE `id` = 1020;
UPDATE `bonk_weapon` SET `name` = 'Tiger''s Fury', `icon` = 'Ability_Mount_JungleTiger',
    `description` = 'Rakes the 3 nearest enemies within 10 yards for damage and 2 stacks of Bleed. Empowered in Cat Form. Each Rake gives you 5% Haste per enemy hit for 4 sec, up to 25%.' WHERE `id` = 1021;
UPDATE `bonk_weapon` SET `name` = 'Mangle', `icon` = 'Ability_Druid_Mangle',
    `description` = 'Shreds the enemy within 10 yards with the most stacks of Bleed for damage, 3% more per stack of Bleed on it, up to 30 stacks. Empowered in Cat Form. The blow also mangles every enemy within 5 yards of it for 50% damage, each with its own Bleed bonus.' WHERE `id` = 1022;
UPDATE `bonk_weapon` SET `name` = 'Ferocious Bite', `icon` = 'Ability_Druid_FerociousBite',
    `description` = 'Shreds the enemy within 10 yards with the most stacks of Bleed for damage, 3% more per stack of Bleed on it, up to 30 stacks. Empowered in Cat Form. When it kills its target, it bites the next enemy with the most stacks of Bleed at once, up to 3 times.' WHERE `id` = 1023;
UPDATE `bonk_weapon` SET `name` = 'Lacerate', `icon` = 'Ability_Druid_Swipe',
    `description` = 'Swipes every enemy within 10 yards for damage. Empowered in Bear Form. Every enemy hit also gains 1 stack of Bleed.' WHERE `id` = 1024;
UPDATE `bonk_weapon` SET `name` = 'Ursol''s Vortex', `icon` = 'Spell_Nature_EarthBind', `behavior_value` = 8,
    `description` = 'Swipes every enemy within 10 yards for damage. Empowered in Bear Form. Each Swipe leaves a vortex where you stand for 3 sec; every sec it deals 50% damage to enemies within 8 yards of it and leaves them Dazed.' WHERE `id` = 1025;
UPDATE `bonk_weapon` SET `name` = 'Bloody Frenzy', `icon` = 'Ability_Druid_Enrage', `damage_fraction` = 1.0,
    `description` = 'Heals you for 0.25% of your maximum health per enemy within 8 yards, up to 5 enemies. Empowered in Bear Form. Every sec, it also mauls up to 5 enemies within 8 yards for damage, even while you are at full health.' WHERE `id` = 1026;
UPDATE `bonk_weapon` SET `name` = 'Barkskin', `icon` = 'Spell_Nature_StoneClawTotem',
    `description` = 'Heals you for 0.25% of your maximum health per enemy within 8 yards, up to 5 enemies. Empowered in Bear Form. Each heal also gives you a Shield of the same amount, even at full health, up to 10% of your maximum health.' WHERE `id` = 1027;
UPDATE `bonk_weapon` SET `name` = 'Lifebloom', `icon` = 'Spell_Nature_WispHeal',
    `description` = 'Heals you for 0.3% of your maximum health, and its thorny bloom lashes the 3 nearest enemies within 10 yards for Nature damage. Empowered in Tree of Life. Every 4th bloom bursts, healing you for 1% of your maximum health and dealing double damage to every enemy within 10 yards.' WHERE `id` = 1028;
UPDATE `bonk_weapon` SET `name` = 'Efflorescence', `icon` = 'Spell_Nature_NaturesBlessing', `behavior_value` = 10,
    `description` = 'Plants a ring of flowers where you stand for 4 sec, and a new one when it fades. While you stand inside it, it heals you for 0.3% of your maximum health every sec. Every sec, it lashes every enemy within 10 yards of it for Nature damage. Empowered in Tree of Life.' WHERE `id` = 1029;
UPDATE `bonk_weapon` SET `name` = 'Ancient of War', `icon` = 'Spell_Nature_AncestralGuardian', `base_targets` = 1,
    `description` = 'Summons an Ancient of War that fights at your side. Every 3 sec it stomps the ground, dealing Nature damage to every enemy within 8 yards of it and applying 1 stack of Moonfire. Empowered in Tree of Life.' WHERE `id` = 1030;
UPDATE `bonk_weapon` SET `name` = 'Fungal Growth', `icon` = 'Spell_Nature_NullifyDisease',
    `description` = 'Summons 2 Treants that fight at your side. Their swings apply 1 stack of Moonfire, and every 6 sec a Treant''s strike roots its target and normal enemies within 5 yards for 2 sec. Empowered in Tree of Life, which also calls 1 additional Treant. Each rooting strike plants a mushroom under its target that bursts 3 sec later, dealing Nature damage to enemies within 8 yards.' WHERE `id` = 1031;
UPDATE `bonk_weapon` SET `name` = 'Mass Entanglement', `icon` = 'Spell_Nature_EarthBindTotem',
    `description` = 'Roots grasp the 3 nearest enemies within 25 yards for Nature damage and root normal enemies for 2 sec. Empowered in Tree of Life. The roots spread to normal enemies within 5 yards of each rooted enemy.' WHERE `id` = 1032;
UPDATE `bonk_weapon` SET `name` = 'Strangling Vines', `icon` = 'Spell_Nature_CorrosiveBreath',
    `description` = 'Roots grasp the 3 nearest enemies within 25 yards for Nature damage and root normal enemies for 2 sec. Empowered in Tree of Life. Rooted enemies are drained every sec for Nature damage, and the drain heals you for 0.05% of your maximum health per enemy, up to 0.5% a sec.' WHERE `id` = 1033;
UPDATE `bonk_weapon` SET `name` = 'Widening Calm', `icon` = 'Spell_Nature_Sleep',
    `description` = 'Calms the air around you for 4 sec. Every sec, deals Nature damage to every enemy within 10 yards and heals you for 0.5% of your maximum health. Empowered in Tree of Life. Each pulse reaches 3 yards further than the last.' WHERE `id` = 1034;
UPDATE `bonk_weapon` SET `name` = 'Overgrowth', `icon` = 'Spell_Nature_Regenerate',
    `description` = 'Calms the air around you for 4 sec. Every sec, deals Nature damage to every enemy within 10 yards and heals you for 0.5% of your maximum health. Empowered in Tree of Life. Healing above your maximum health erupts as Nature damage on every enemy within 10 yards, up to double damage at full health.' WHERE `id` = 1035;
UPDATE `bonk_weapon` SET `name` = 'Brambles', `icon` = 'Spell_Nature_SpiritArmor',
    `description` = 'Enemies that strike you take Nature damage, at most 5 times a sec. Empowered in Bear Form. The thorns also lash every other enemy within 8 yards of you for 50% damage.' WHERE `id` = 1036;
UPDATE `bonk_weapon` SET `name` = 'Nature''s Grasp', `icon` = 'Spell_Nature_NaturesWrath',
    `description` = 'Enemies that strike you take Nature damage, at most 5 times a sec. Empowered in Bear Form. Normal enemies that strike you are rooted for 1 sec.' WHERE `id` = 1037;
UPDATE `bonk_weapon` SET `name` = 'Shifting Surge', `icon` = 'Spell_Nature_WispSplode',
    `description` = CONCAT(`description`, '|n|n|cffffffffShifting Surge:|r Entering a form unleashes it, at most once every 6 sec per form. Moonkin: Starfall strikes 5 enemies with Moonfire. Cat: every enemy within 8 yards gains 2 stacks of Bleed. Bear: you roar at once. Tree: normal enemies within 8 yards are rooted for 1 sec, and you heal 2% of your maximum health.') WHERE `id` = 1038;
UPDATE `bonk_weapon` SET `name` = 'Spirit Forms', `icon` = 'Spell_Nature_SpiritWolf',
    `description` = CONCAT(`description`, '|n|n|cffffffffSpirit Forms:|r When you leave a form, its spirit stays behind for 6 sec and keeps attacking with that form''s attack for 50% damage, at most once every 6 sec per form.') WHERE `id` = 1039;

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `w`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_weapon` `w` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `w`.`evolves_from`
WHERE `w`.`id` BETWEEN 1014 AND 1039;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
