DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024200000');

DELETE FROM `bonk_keyword` WHERE `id` = 15;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(15, 'Moonfire', 'Spell_Nature_StarFall', 8921, 30, 0.04, 1000, 6000, 1,
 'Each stack deals Arcane damage every sec. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a moonfired enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards.');

DELETE FROM `creature_template` WHERE `entry` = 900148;
DROP TEMPORARY TABLE IF EXISTS `bonk_druid_pet`;
CREATE TEMPORARY TABLE `bonk_druid_pet` SELECT * FROM `creature_template` WHERE `entry` = 900142;
UPDATE `bonk_druid_pet` SET `entry` = 900148, `name` = 'Treant', `display_id1` = 864, `display_scale1` = 1.0;
INSERT INTO `creature_template` SELECT * FROM `bonk_druid_pet`;
DROP TEMPORARY TABLE `bonk_druid_pet`;

DELETE FROM `bonk_pet_ability` WHERE `family` = 16;
DELETE FROM `bonk_pet_family` WHERE `id` = 16;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`, `description`) VALUES
(16, 'Treant', 900148, 0.5, 1500, 0, 0, '');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 1000 AND 1012;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 1000 AND 1012;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(1000, 'Wrath', 'Spell_Nature_AbolishMagic', 'Hurls a bolt of Nature energy at the nearest enemy. Each Wrath brings Lunar Eclipse closer, twice as fast against moonfired enemies. Lunar Eclipse lasts 8 sec: Starfire always critically strikes and Moonfire applies 1 additional stack.',
    5176, 0, 1500, 30, 1.2, 1024, 1024, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1101),
(1001, 'Starfire', 'Spell_Arcane_StarFire', 'Calls down a bolt of starlight on the strongest enemy within 30 yards. Each Starfire brings Solar Eclipse closer, twice as fast against moonfired enemies. Solar Eclipse lasts 8 sec: your Nature spells deal 50% more damage.',
    2912, 4, 4000, 30, 3.6, 1024, 0, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1101),
(1002, 'Moonfire', 'Spell_Nature_StarFall', 'Every sec, burns the 5 nearest enemies with moonlight, applying 1 stack of Moonfire. Enemies without Moonfire are chosen first.',
    8921, 0, 1000, 30, 2.0, 1024, 0, 1024, 0, 0, 0, 0, 121, 0, 0, 5, 0, 0, 1, 0, 0, 0, 15, 1, 0, 0, 1101),
(1003, 'Hurricane', 'Spell_Nature_Cyclone', 'A storm rages over the largest group of enemies for 4 sec, dealing Nature damage every sec to enemies within 8 yards and leaving them Dazed.',
    16914, 3, 6000, 30, 0.35, 1024, 0, 0, 0, 0, 0, 0, 130, 8, 0, 1, 0, 0, 1, 0, 0, 67108864, 10, 1, 0, 0, 1101),
(1004, 'Rake', 'Ability_Druid_Disembowel', 'Rakes the 3 nearest enemies within 10 yards and applies 2 stacks of Bleed.',
    1822, 0, 1500, 10, 0.8, 1024, 0, 1024, 0, 0, 0, 0, 122, 0, 0, 3, 0, 0, 1, 0, 0, 0, 4, 2, 0, 0, 1102),
(1005, 'Shred', 'Spell_Shadow_VampiricAura', 'Shreds the enemy within 10 yards that bleeds the most, dealing 5% more damage for each stack of Bleed on it.',
    5221, 0, 1200, 10, 1.6, 1024, 0, 0, 0, 0, 0, 0, 123, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 5, 1102),
(1006, 'Swipe', 'INV_Misc_MonsterClaw_03', 'Swipes every enemy within 10 yards.',
    779, 1, 2000, 10, 0.8, 1024, 0, 0, 0, 0, 0, 0, 124, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 1102),
(1007, 'Frenzied Regeneration', 'Ability_BullRush', 'Every sec, heals you for 0.25% of your maximum health for each enemy within 8 yards, up to 5 enemies.',
    22842, 7, 1000, 0, 0, 1024, 0, 0, 0, 0.25, 0, 0, 125, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1102),
(1008, 'Rejuvenation', 'Spell_Nature_Rejuvenation', 'Every sec, heals you for 0.3% of your maximum health, and its thorny bloom lashes the 3 nearest enemies within 10 yards for Nature damage.',
    774, 0, 1000, 10, 0.35, 1024, 0, 1024, 0, 0.3, 0, 0, 126, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1103),
(1009, 'Force of Nature', 'Spell_Nature_ForceOfNature', 'Summons 2 Treants that fight at your side.',
    7993, 7, 3000, 0, 1.0, 1024, 0, 0, 0, 0, 0, 0, 20, 1, 1500, 2, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1103),
(1010, 'Entangling Roots', 'Spell_Nature_StrangleVines', 'Roots grasp the 3 nearest enemies within 25 yards, dealing Nature damage and rooting normal enemies for 2 sec.',
    339, 0, 5000, 25, 1.5, 1024, 0, 0, 0, 0, 0, 0, 127, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1103),
(1011, 'Tranquility', 'Spell_Nature_Tranquility', 'Every 8 sec, calms the air around you for 4 sec: every sec, Nature damage to every enemy within 10 yards, and heals you for 0.5% of your maximum health.',
    740, 1, 8000, 10, 0.6, 1024, 0, 0, 0, 0.5, 0, 0, 128, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 1103),
(1012, 'Thorns', 'Spell_Nature_Thorns', 'Thorns cover you. Enemies that strike you take Nature damage, at most 5 times a sec.',
    467, 7, 1000, 0, 0.6, 1024, 0, 0, 0, 0, 0, 0, 129, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 1103);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(1000, 1, 10), (1000, 2, 10), (1000, 3, 8),
(1001, 1, 10), (1001, 2, 10), (1001, 3, 8),
(1002, 3, 8), (1002, 5, 15), (1002, 9, 1),
(1003, 3, 8), (1003, 5, 15), (1003, 16, 1),
(1004, 3, 8), (1004, 9, 1), (1004, 17, 10),
(1005, 2, 10), (1005, 3, 8), (1005, 17, 10),
(1006, 3, 8), (1006, 16, 1),
(1007, 3, 8),
(1008, 2, 10), (1008, 3, 8),
(1009, 7, 15), (1009, 8, 10), (1009, 3, 8),
(1010, 2, 10), (1010, 3, 8),
(1011, 3, 8), (1011, 5, 15), (1011, 16, 1),
(1012, 2, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
