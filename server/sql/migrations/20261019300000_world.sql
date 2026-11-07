DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019300000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019300000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 600 AND 611;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 600 AND 611;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(600, 'Sinister Strike', 'Spell_Shadow_RitualOfSacrifice', 'Stabs the nearest enemy every 0.6 seconds for Physical damage. The fastest attack in the game.',
    1752, 0, 600, 6, 0.4, 8, 8, 0, 0, 0, 0, 0, 93, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 402),
(601, 'Blade Flurry', 'Ability_Warrior_PunishingBlow', 'For 6 seconds, your single-target Rogue hits also strike 2 additional enemies within 8 yards. The extra hits carry your poisons and openers.',
    13877, 7, 15000, 0, 0, 8, 0, 0, 0, 0, 6000, 0, 94, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 402),
(602, 'Eviscerate', 'Ability_Rogue_Eviscerate', 'Guts the nearest enemy for heavy Physical damage, with double the critical strike chance.',
    2098, 0, 5000, 8, 3.0, 8, 0, 0, 0, 0, 0, 0, 95, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 402),
(603, 'Killing Spree', 'Ability_Rogue_SliceDice', 'Strikes 10 times over 2 seconds, each strike at a random enemy within 10 yards. Every strike carries your poisons and openers.',
    24192, 2, 15000, 10, 0.6, 8, 0, 0, 0, 0, 0, 0, 96, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 402),
(604, 'Mutilate', 'Ability_BackStab', 'Stabs the nearest enemy with both daggers, each stab applying 1 stack of Poison. Deals 30% more damage to Poisoned enemies.',
    25300, 0, 1200, 6, 0.5, 8, 0, 8, 0, 0, 0, 0, 97, 0, 0, 1, 0, 0, 1, 0, 0, 0, 5, 1, 0, 0, 401),
(605, 'Deadly Poison', 'Ability_Rogue_DualWeild', 'Every Rogue hit applies 1 stack of Poison.',
    2818, 7, 1000, 0, 0, 8, 0, 0, 0, 0, 0, 0, 98, 0, 0, 1, 0, 0, 1, 0, 0, 0, 5, 1, 0, 0, 401),
(606, 'Fan of Knives', 'INV_ThrowingKnife_04', 'Throws knives in every direction, striking all enemies within 10 yards for Physical damage and applying 1 stack of Poison. Every knife carries your poisons and openers.',
    24649, 1, 4000, 10, 0.8, 8, 0, 0, 0, 0, 0, 0, 99, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 5, 1, 0, 0, 401),
(607, 'Envenom', 'Ability_Creature_Poison_06', 'Deals Nature damage to the enemy with the most Poison, and for 5 seconds your Rogue hits apply 2 additional stacks of Poison.',
    29653, 0, 6000, 20, 2.0, 8, 0, 0, 0, 0, 5000, 0, 100, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 5, 0, 401),
(608, 'Shuriken Toss', 'INV_ThrowingAxe_06', 'Throws a shuriken at the nearest enemy you have not hit yet, within 30 yards, or the nearest enemy when you have hit them all.',
    16075, 0, 800, 30, 0.5, 8, 0, 8, 0, 0, 0, 0, 101, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 403),
(609, 'Ambush', 'Ability_Rogue_Ambush', 'Your first Rogue hit on each enemy is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance.',
    8676, 7, 1000, 0, 1.2, 8, 0, 0, 0, 0, 0, 0, 102, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 403),
(610, 'Shadow Dance', 'Spell_Shadow_Charm', 'For 4 seconds, your hits deal 30% more damage and every Rogue hit counts as a first hit for Ambush.',
    11327, 7, 20000, 0, 0, 8, 0, 0, 0, 0, 4000, 0, 103, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 403),
(611, 'Evasion', 'Spell_Shadow_ShadowWard', 'For 5 seconds, you dodge 50% more attacks.',
    5277, 7, 20000, 0, 0, 8, 0, 0, 0, 0, 5000, 0, 104, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 403);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(600, 1, 10), (600, 2, 10), (600, 3, 8),
(601, 3, 8), (601, 5, 15),
(602, 1, 10), (602, 2, 10), (602, 3, 8),
(603, 2, 10), (603, 3, 8),
(604, 2, 10), (604, 3, 8), (604, 9, 1),
(605, 5, 15), (605, 9, 1),
(606, 3, 8), (606, 9, 1), (606, 16, 1),
(607, 2, 10), (607, 3, 8), (607, 5, 15),
(608, 1, 10), (608, 2, 10), (608, 3, 8),
(609, 1, 10), (609, 2, 10),
(610, 3, 8), (610, 5, 15),
(611, 3, 8), (611, 5, 15);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
