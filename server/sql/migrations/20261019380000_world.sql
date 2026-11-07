DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019380000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019380000');

DELETE FROM `bonk_mastery` WHERE `class` = 4;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 4;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(401, 4, 'Assassination', 'RogueAssassination', 1),
(402, 4, 'Combat', 'RogueCombat', 2),
(403, 4, 'Subtlety', 'RogueSubtlety', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(40101, 4, 401, 1, 1, 'Ability_Racial_BloodRage', 'Malice', 'Assassination spells deal 3% more damage.', 5, 0, 0, 12, 401, 3, 0),
(40102, 4, 401, 1, 2, 'Ability_BackStab', 'Improved Mutilate', 'Mutilate can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 604, 1, 0),
(40103, 4, 401, 1, 3, 'Spell_Nature_NullifyPoison_02', 'Vile Poisons', 'Your Poison deals 8% more damage.', 3, 0, 0, 13, 5, 8, 0),
(40104, 4, 401, 2, 1, 'INV_ThrowingKnife_04', 'Improved Fan of Knives', 'Fan of Knives deals 5% more damage.', 3, 0, 0, 1, 606, 5, 0),
(40105, 4, 401, 2, 2, 'Ability_Creature_Poison_06', 'Improved Envenom', 'Envenom deals 5% more damage.', 3, 0, 0, 1, 607, 5, 0),
(40106, 4, 401, 3, 1, 'Ability_Poisons', 'Improved Poisons', 'When a Poisoned enemy dies, its Poison spreads to 1 additional nearby enemy.', 1, 0, 0, 28, 5, 1, 0),
(40107, 4, 401, 3, 2, 'Spell_Shadow_ChillTouch', 'Seal Fate', 'Mutilate stabs 1 additional enemy.', 1, 0, 0, 4, 604, 1, 0),
(40108, 4, 401, 4, 1, 'Ability_CriticalStrike', 'Lethality', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(40109, 4, 401, 4, 2, 'Ability_Rogue_Garrote', 'Murder', '+3% critical strike chance against Poisoned enemies.', 3, 0, 0, 14, 5, 3, 0),
(40110, 4, 401, 5, 2, 'Ability_Rogue_Disguise', 'Master Poisoner', 'Every Rogue hit applies 1 additional stack of Poison, even without Deadly Poison. Your Power is reduced by 15%.', 1, 0, 0, 38, 16, 1, 0),
(40201, 4, 402, 1, 1, 'INV_Sword_27', 'Weapon Expertise', 'Combat spells deal 3% more damage.', 5, 0, 0, 12, 402, 3, 0),
(40202, 4, 402, 1, 2, 'Spell_Shadow_RitualOfSacrifice', 'Improved Sinister Strike', 'Sinister Strike deals 5% more damage.', 3, 0, 0, 1, 600, 5, 0),
(40203, 4, 402, 1, 3, 'Spell_Nature_Invisibilty', 'Lightning Reflexes', '+2% chance to dodge enemy swings.', 3, 0, 0, 0, 14, 2, 0),
(40204, 4, 402, 2, 1, 'Ability_Warrior_PunishingBlow', 'Improved Blade Flurry', 'Blade Flurry recharges 8% faster.', 3, 0, 0, 3, 601, 8, 0),
(40205, 4, 402, 2, 2, 'Ability_Rogue_Eviscerate', 'Improved Eviscerate', 'Eviscerate deals 5% more damage.', 3, 0, 0, 1, 602, 5, 0),
(40206, 4, 402, 3, 1, 'Ability_Rogue_SliceDice', 'Improved Killing Spree', 'Killing Spree recharges 15% faster.', 1, 0, 0, 3, 603, 15, 0),
(40207, 4, 402, 3, 2, 'INV_Weapon_ShortBlade_05', 'Dual Wield Specialization', 'Sinister Strike stabs 1 additional enemy.', 1, 0, 0, 4, 600, 1, 0),
(40208, 4, 402, 4, 1, 'Ability_Racial_Avatar', 'Aggression', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(40209, 4, 402, 4, 2, 'Ability_Ambush', 'Dagger Specialization', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(40210, 4, 402, 5, 2, 'Ability_DualWield', 'Blade Dancer', 'Your single-target Rogue hits strike 1 additional enemy within 8 yards, with or without Blade Flurry. Your critical strike chance is reduced by 10%.', 1, 0, 0, 38, 17, 1, 0),
(40301, 4, 403, 1, 1, 'Ability_Warrior_WarCry', 'Opportunity', 'Subtlety spells deal 3% more damage.', 5, 0, 0, 12, 403, 3, 0),
(40302, 4, 403, 1, 2, 'INV_ThrowingKnife_02', 'Improved Shuriken Toss', 'Shuriken Toss can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 608, 1, 0),
(40303, 4, 403, 1, 3, 'Ability_Stealth', 'Master of Deception', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(40304, 4, 403, 2, 1, 'Ability_Rogue_Ambush', 'Improved Ambush', 'Ambush deals 5% more damage.', 3, 0, 0, 1, 609, 5, 0),
(40305, 4, 403, 2, 2, 'Spell_Shadow_Fumble', 'Initiative', 'You deal 5% more damage to enemies above 80% health.', 3, 0, 0, 7, 0, 5, 0),
(40306, 4, 403, 3, 1, 'Spell_Magic_LesserInvisibilty', 'Elusiveness', 'Evasion recharges 15% faster.', 1, 0, 0, 3, 611, 15, 0),
(40307, 4, 403, 3, 2, 'Spell_Shadow_ShadeTrueSight', 'Cheat Death', 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.', 1, 0, 0, 33, 0, 30, 0),
(40308, 4, 403, 4, 1, 'Spell_Nature_MirrorImage', 'Setup', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(40309, 4, 403, 4, 2, 'Spell_Shadow_Curse', 'Heightened Senses', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(40310, 4, 403, 5, 2, 'Spell_Shadow_Possession', 'Master of Subtlety', 'Your Ambush strikes also hit every enemy within 5 yards of the target for half their damage. Your maximum health is reduced by 15%.', 1, 0, 0, 38, 18, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 260 AND 269;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(260, 'Footpad', 'Win a run on Normal as a rogue.', 'Spell_Shadow_RitualOfSacrifice', 3, 1, 0, 2, 6, 1, 4, 2),
(261, 'Cutthroat', 'Kill 3,000 enemies with Sinister Strike as a rogue.', 'Spell_Shadow_RitualOfSacrifice', 2, 600, 0, 3000, 6, 1, 4, 2),
(262, 'Poisoner', 'Kill 3,000 enemies with Fan of Knives as a rogue.', 'INV_ThrowingKnife_04', 2, 606, 0, 3000, 6, 1, 4, 2),
(263, 'Shadowstalker', 'Kill 3,000 enemies with Ambush as a rogue.', 'Ability_Rogue_Ambush', 2, 609, 0, 3000, 6, 1, 4, 2),
(264, 'Assassin', 'Kill 60 elites as a rogue.', 'Ability_Rogue_Eviscerate', 1, 1, 0, 60, 6, 1, 4, 2),
(265, 'Nightblade', 'Reach level 50 in a single run as a rogue.', 'Ability_Stealth', 4, 0, 0, 50, 6, 1, 4, 2),
(266, 'Ravenholdt Initiate', 'Clear stage 1 on Heroic as a rogue.', 'Ability_Rogue_Disguise', 3, 3, 0, 2, 6, 1, 4, 2),
(267, 'Master Thief', 'Win a run on Heroic as a rogue.', 'INV_Misc_Bag_11', 3, 3, 0, 3, 6, 1, 4, 2),
(268, 'Shadow of Ravenholdt', 'Clear stage 1 on Mythic as a rogue.', 'Spell_Shadow_Possession', 3, 2, 0, 2, 6, 1, 4, 2),
(269, 'Seasoned Rogue', 'Reach Mastery level 10 with a rogue.', 'Ability_Rogue_SliceDice', 16, 4, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
