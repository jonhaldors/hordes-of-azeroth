DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017180000');

DELETE FROM `creature_template` WHERE `entry` = 900128;
DROP TEMPORARY TABLE IF EXISTS `bonk_hydra`;
CREATE TEMPORARY TABLE `bonk_hydra` AS SELECT * FROM `creature_template` WHERE `entry` = 900125;
UPDATE `bonk_hydra` SET `entry` = 900128, `name` = 'Hydra', `display_id1` = 2423, `display_scale1` = 1, `type` = 1, `damage_school` = 0;
INSERT INTO `creature_template` SELECT * FROM `bonk_hydra`;
DROP TEMPORARY TABLE `bonk_hydra`;

DELETE FROM `bonk_pet_ability` WHERE `family` = 5;
DELETE FROM `bonk_pet_family` WHERE `id` = 5;
INSERT INTO `bonk_pet_family` (`id`, `name`, `entry`, `scale`, `attack_ms`, `applies`, `apply_stacks`) VALUES
(5, 'Hydra', 900128, 0.45, 60000, 0, 0);
INSERT INTO `bonk_pet_ability` (`family`, `spell_id`, `kind`, `cooldown_ms`, `damage`, `stacks`, `value`, `comment`) VALUES
(5, 205,   0, 2000, 1, 1, 30, 'Hydra frost head: Frostbolt from 30 yd, 1 Chill'),
(5, 9487,  0, 2000, 1, 2, 30, 'Hydra fire head: Fireball from 30 yd, 2 Burning'),
(5, 13901, 0, 2000, 1, 0, 30, 'Hydra arcane head: Arcane Bolt from 30 yd');

DELETE FROM `spell_template` WHERE `entry` IN (33452, 33453);
DROP TEMPORARY TABLE IF EXISTS `bonk_hero_look`;
CREATE TEMPORARY TABLE `bonk_hero_look` SELECT * FROM `spell_template` WHERE `entry` = 33401;
UPDATE `bonk_hero_look` SET `entry` = 33452, `spellVisual1` = 8355, `name` = 'Arcane Power', `auraDescription` = 'Your spells deal 30% more damage.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
UPDATE `bonk_hero_look` SET `entry` = 33453, `spellVisual1` = 8356, `name` = 'Phase Rush', `auraDescription` = 'Immune to damage.';
INSERT INTO `spell_template` SELECT * FROM `bonk_hero_look`;
DROP TEMPORARY TABLE `bonk_hero_look`;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 411 AND 432;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 411 AND 432;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(411, 'Ice Shards', 'Spell_Frost_IceShard', 'Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more damage to Frozen enemies. The bolt then jumps to the next Frozen enemy within 12 yards, up to 6 times. Your Frost spells always critically strike Frozen enemies.', 116, 0, 1500, 30, 1, 128, 0, 400, 0, 0, 0, 58, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 50),
(412, 'Shatter', 'Spell_Frost_FrostShock', 'Launches a bolt of frost at the nearest enemy, dealing Frost damage and applying 1 stack of Chill. Deals 50% more damage to Frozen enemies. A bolt that hits a Frozen enemy shatters it, dealing the bolt''s damage to all other enemies within 5 yards. Your Frost spells always critically strike Frozen enemies.', 116, 0, 1500, 30, 1, 128, 0, 400, 0, 0, 0, 59, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 1, 2, 50),
(413, 'Deep Freeze', 'Spell_Frost_Glacier', 'Ice shards pelt the largest group of enemies for 4 sec, dealing Frost damage and applying 1 stack of Chill every sec. Normal enemies Frozen inside the storm stay Frozen until it ends, up to 4 sec.', 26607, 3, 5000, 20, 0.3, 128, 0, 401, 0, 4000, 0, 60, 0, 1000, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
(414, 'Frostbite', 'Spell_Frost_FreezingBreath', 'Ice shards pelt the largest group of enemies for 4 sec, dealing Frost damage and applying 1 stack of Chill every sec. Each time an enemy is Frozen inside the storm, it loses 15% of its maximum health (elites 5%, bosses 1%).', 26607, 3, 5000, 20, 0.3, 128, 0, 401, 0, 4000, 0, 61, 0, 1000, 1, 0, 0, 1, 0, 0, 0, 1, 1, 0, 0),
(415, 'Ice Nova', 'Spell_Frost_ChillingBlast', 'Frost bursts around the enemy your Frostbolt hit last, or the nearest enemy within 30 yards, dealing Frost damage and applying 3 stacks of Chill to all enemies within 10 yards of it.', 122, 1, 4000, 10, 0.6, 128, 0, 402, 0, 0, 0, 62, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 3, 0, 0),
(416, 'Ice Barrier', 'Spell_Ice_Lament', 'Blasts all enemies within 10 yards of you with frost, dealing Frost damage and applying 3 stacks of Chill. Each enemy it Freezes gives you a Shield of 1% of your maximum health, up to 15% per cast. The Shield stays until it absorbs damage.', 122, 1, 4000, 10, 0.6, 128, 0, 402, 0, 0, 0, 63, 0, 0, 1, 0, 0, 1, 0, 0, 0, 1, 3, 0, 0),
(417, 'Wildfire', 'Spell_Fire_Fire', 'Hurls a fiery ball at the nearest enemy, dealing Fire damage and applying 2 stacks of Burning. For 6 sec, while the target lives, its Burning jumps to a nearby enemy that isn''t burning every sec.', 133, 0, 2000, 35, 0.9, 128, 0, 403, 0, 0, 0, 64, 0, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(418, 'Living Bomb', 'Spell_Fire_SoulBurn', 'Hurls a fiery ball at the nearest enemy, dealing Fire damage and applying 2 stacks of Burning. It plants a bomb on the target that explodes after 2 sec, dealing 50% of the damage to all enemies within 6 yards and applying 2 stacks of Burning to each.', 133, 0, 2000, 35, 0.9, 128, 0, 403, 0, 0, 0, 65, 0, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(419, 'Firewalk', 'Spell_Fire_FlameShock', 'Calls down 3 pillars of fire in a row through the largest group of enemies, one after another. Each deals Fire damage and applies 2 stacks of Burning.', 2120, 3, 5000, 20, 0.8, 128, 0, 404, 0, 1500, 0, 66, 0, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(420, 'Burning Ground', 'Spell_Fire_Immolation', 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 2 stacks of Burning. The ground burns for 6 sec; enemies within 8 yards of it gain 1 stack of Burning every sec.', 2120, 3, 5000, 20, 0.8, 128, 0, 404, 0, 1500, 0, 67, 8, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(421, 'Meteor', 'Spell_Fire_Volcano', 'A meteor falls on the largest group of enemies, dealing heavy Fire damage and applying 2 stacks of Burning to all enemies within 8 yards. It leaves a burning crater for 4 sec; enemies within 5 yards of it gain 1 stack of Burning every sec.', 11366, 0, 8000, 35, 4, 128, 0, 405, 0, 0, 0, 68, 5, 0, 1, 0, 0, 1, 0, 0, 0, 3, 2, 0, 0),
(422, 'Meteor Shower', 'Spell_Fire_MeteorStorm', '7 meteors fall on enemies in the largest group, each dealing Fire damage to all enemies within 3 yards. Each meteor deals 10% more damage to an enemy for each stack of Burning on it, counting up to 30 stacks.', 11366, 0, 8000, 35, 4, 128, 0, 405, 0, 0, 0, 69, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(423, 'Blast Wave', 'Spell_Holy_Excorcism_02', 'A wave of fire blasts all enemies within 10 yards of you, dealing Fire damage, 10% more for each stack of Burning on the target, counting up to 30 stacks. Every Burning enemy it reaches erupts, dealing 40% of the damage to all enemies within 5 yards of it.', 2136, 1, 3000, 10, 0.8, 128, 0, 406, 0, 0, 0, 70, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 3, 10),
(424, 'Hot Streak', 'Spell_Fire_Incinerate', 'Blasts the 3 enemies with the most stacks of Burning, dealing Fire damage, 10% more for each stack of Burning on the target, counting up to 30 stacks. Its first critical strike in each cast fires your Pyroblast at once, or hurls a Pyroblast at the target if you have none.', 2136, 0, 3000, 30, 0.8, 128, 0, 406, 0, 0, 0, 71, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 3, 10),
(425, 'Phase Rush', 'Spell_Magic_LesserInvisibilty', 'Your dash becomes Blink: it gains 1 charge and recharges 30% faster. Each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to all enemies within 10 yards, strikes every enemy along the line you crossed, and makes you immune to damage for 1 sec.', 8437, 1, 1000, 10, 1, 128, 0, 407, 0, 0, 0, 72, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(426, 'Shimmer', 'Spell_Arcane_StarFire', 'Your dash becomes Blink: it gains 3 charges and recharges 30% faster. Each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to all enemies within 10 yards, and resets the cooldown of your Arcane Explosion spell.', 8437, 1, 1000, 10, 1, 128, 0, 407, 0, 0, 0, 73, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(427, 'Slow Time', 'Spell_Nature_TimeStop', 'Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. It also goes off where you land after each Blink. Each blast leaves a time bubble for 4 sec: normal enemies inside move 60% slower, and all enemies inside take 15% more damage.', 1449, 1, 2500, 10, 0.7, 128, 0, 408, 0, 0, 0, 74, 0, 0, 1, 0, 0, 1, 0, 0, 4194304, 0, 0, 0, 0),
(428, 'Presence of Mind', 'Spell_Nature_EnchantArmor', 'Blasts all enemies within 10 yards of you with arcane energy, dealing Arcane damage. It also goes off where you land after each Blink. Each blast instantly casts one of your other spells, at most once every 0.5 sec.', 1449, 1, 2500, 10, 0.7, 128, 0, 408, 0, 0, 0, 75, 0, 0, 1, 0, 0, 1, 0, 0, 4194304, 0, 0, 0, 0),
(429, 'Arcane Barrage', 'Spell_Shadow_ManaBurn', 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. While you move, the missiles pile up instead, up to 40. Your next Blink fires them all at once at the nearest enemies, together with its own volley. Your dash becomes Blink.', 7268, 0, 2500, 30, 0.3, 128, 0, 409, 0, 0, 0, 76, 5, 0, 1, 0, 0, 1, 0, 0, 12582912, 0, 0, 0, 0),
(430, 'Arcane Power', 'Spell_Nature_Lightning', 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once at the nearest enemies, and all your spells deal 30% more damage for 4 sec. Your dash becomes Blink.', 7268, 0, 2500, 30, 0.3, 128, 0, 409, 0, 0, 0, 77, 5, 0, 1, 0, 0, 1, 0, 0, 12582912, 0, 0, 0, 0),
(431, 'Hydra', 'INV_Misc_Head_Dragon_Bronze', 'Summons a three-headed hydra that stays where it stands and spits Frost, Fire and Arcane bolts at enemies within 30 yards. Its frost head applies Chill and its fire head applies Burning. When you move far away, it follows you.', 17162, 7, 3000, 0, 1.2, 128, 0, 410, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 16777216, 0, 0, 0, 0),
(432, 'Elemental Shift', 'Spell_Fire_ElementalDevastation', 'Summons an elemental to fight for you that changes school every 5 sec: a Water Elemental that applies Chill, then a Fire Elemental that applies Burning, then an Arcane Elemental.', 17162, 7, 3000, 0, 1.2, 128, 0, 410, 0, 0, 0, 20, 1, 1500, 1, 0, 0, 1, 0, 0, 33554432, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(411, 1, 10), (411, 9, 1), (411, 2, 10), (411, 3, 8),
(412, 1, 10), (412, 9, 1), (412, 2, 10), (412, 3, 8),
(413, 5, 15), (413, 9, 1), (413, 3, 8),
(414, 5, 15), (414, 9, 1), (414, 3, 8),
(415, 9, 1), (415, 2, 10), (415, 3, 8),
(416, 9, 1), (416, 14, 10), (416, 2, 10), (416, 3, 8),
(417, 1, 10), (417, 9, 1), (417, 2, 10), (417, 3, 8),
(418, 1, 10), (418, 9, 1), (418, 2, 10), (418, 3, 8),
(419, 9, 1), (419, 2, 10), (419, 3, 8),
(420, 5, 15), (420, 9, 1), (420, 2, 10), (420, 3, 8),
(421, 5, 15), (421, 2, 10), (421, 3, 8),
(422, 2, 10), (422, 3, 8),
(423, 2, 10), (423, 3, 8),
(424, 1, 10), (424, 2, 10), (424, 3, 8),
(425, 2, 10), (425, 3, 8),
(426, 2, 10), (426, 3, 8),
(427, 5, 15), (427, 2, 10), (427, 3, 8),
(428, 2, 10), (428, 3, 8),
(429, 1, 10), (429, 2, 10), (429, 3, 8),
(430, 1, 10), (430, 2, 10), (430, 3, 8),
(431, 7, 15), (431, 8, 10), (431, 3, 8),
(432, 7, 15), (432, 8, 10), (432, 3, 8);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
