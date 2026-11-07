DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025350000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025350000');

DELETE FROM `bonk_mastery` WHERE `class` = 11;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 11;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(1101, 11, 'Balance', 'DruidBalance', 1),
(1102, 11, 'Feral', 'DruidFeralCombat', 2),
(1103, 11, 'Restoration', 'DruidRestoration', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(110101, 11, 1101, 1, 1, 'Spell_Nature_MoonGlow', 'Moonfury', 'Balance spells deal 3% more damage.', 5, 0, 0, 12, 1101, 3, 0),
(110102, 11, 1101, 1, 2, 'Spell_Nature_StarFall', 'Lunar Calling', 'Moonfire can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 1002, 1, 0),
(110103, 11, 1101, 1, 3, 'Spell_Nature_Sentinal', 'Improved Moonfire', 'Your Moonfire deals 8% more damage.', 3, 0, 0, 13, 15, 8, 0),
(110104, 11, 1101, 2, 1, 'Spell_Arcane_StarFire', 'Improved Starfire', 'Starfire deals 5% more damage.', 3, 0, 0, 1, 1001, 5, 0),
(110105, 11, 1101, 2, 2, 'Spell_Nature_Cyclone', 'Improved Hurricane', 'Hurricane deals 5% more damage.', 3, 0, 0, 1, 1003, 5, 0),
(110106, 11, 1101, 3, 1, 'Spell_Holy_ElunesGrace', 'Celestial Focus', 'Moonfire burns 1 additional enemy.', 1, 0, 0, 4, 1002, 1, 0),
(110107, 11, 1101, 3, 2, 'Spell_Nature_StormReach', 'Gale Winds', 'Hurricane recharges 15% faster.', 1, 0, 0, 3, 1003, 15, 0),
(110108, 11, 1101, 4, 1, 'Spell_Nature_Lightning', 'Vengeance', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(110109, 11, 1101, 4, 2, 'Spell_Nature_NaturesWrath', 'Nature''s Grace', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(110110, 11, 1101, 5, 2, 'Spell_Nature_MoonKey', 'Celestial Alignment', 'Starfall falls in every form, not only in Moonkin Form, and strikes 2 additional enemies. Your Power is reduced by 15%.', 1, 0, 0, 38, 25, 1, 0),
(110201, 11, 1102, 1, 1, 'Ability_Druid_DemoralizingRoar', 'Ferocity', 'Feral spells deal 3% more damage.', 5, 0, 0, 12, 1102, 3, 0),
(110202, 11, 1102, 1, 2, 'Ability_Druid_Disembowel', 'Predatory Instincts', 'Rake can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 1004, 1, 0),
(110203, 11, 1102, 1, 3, 'Spell_Nature_StoneSkinTotem', 'Thick Hide', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(110204, 11, 1102, 2, 1, 'Ability_GhoulFrenzy', 'Blood Frenzy', 'Your Bleed deals 8% more damage.', 3, 0, 0, 13, 4, 8, 0),
(110205, 11, 1102, 2, 2, 'Ability_Druid_ChallangingRoar', 'Savage Fury', 'Swipe deals 5% more damage.', 3, 0, 0, 1, 1006, 5, 0),
(110206, 11, 1102, 3, 1, 'Ability_Druid_SupriseAttack', 'Sharpened Claws', 'Rake rakes 1 additional enemy.', 1, 0, 0, 4, 1004, 1, 0),
(110207, 11, 1102, 3, 2, 'Ability_Druid_Bash', 'Feral Instinct', 'Swipe recharges 15% faster.', 1, 0, 0, 3, 1006, 15, 0),
(110208, 11, 1102, 4, 1, 'Ability_Hunter_Pet_Cat', 'Primal Precision', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(110209, 11, 1102, 4, 2, 'Ability_Hunter_Pet_Bear', 'Improved Frenzied Regeneration', 'Frenzied Regeneration heals 0.05% more per enemy.', 3, 0, 0, 17, 1007, 0.05, 0),
(110210, 11, 1102, 5, 2, 'Ability_Racial_BearForm', 'Primal Fury', 'In Cat Form you also take 20% less damage. In Bear Form you also move 15% faster, and your critical strikes apply 1 stack of Bleed. Your Power is reduced by 15%.', 1, 0, 0, 38, 26, 1, 0),
(110301, 11, 1103, 1, 1, 'Spell_Nature_ProtectionformNature', 'Gift of Nature', 'Restoration spells deal 3% more damage.', 5, 0, 0, 12, 1103, 3, 0),
(110302, 11, 1103, 1, 2, 'Spell_Nature_Rejuvenation', 'Improved Rejuvenation', 'Rejuvenation can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 1008, 1, 0),
(110303, 11, 1103, 1, 3, 'Spell_Nature_HealingTouch', 'Furor', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(110304, 11, 1103, 2, 1, 'Spell_Nature_Tranquility', 'Improved Tranquility', 'Tranquility deals 5% more damage.', 3, 0, 0, 1, 1011, 5, 0),
(110305, 11, 1103, 2, 2, 'Spell_Nature_NatureTouchGrow', 'Nature''s Focus', 'Force of Nature deals 5% more damage.', 3, 0, 0, 1, 1009, 5, 0),
(110306, 11, 1103, 3, 1, 'Spell_Nature_StrangleVines', 'Improved Entangling Roots', 'Entangling Roots grasp 1 additional enemy.', 1, 0, 0, 4, 1010, 1, 0),
(110307, 11, 1103, 3, 2, 'Spell_Nature_HealingWaveGreater', 'Wild Growth', 'Rejuvenation lashes 1 additional enemy.', 1, 0, 0, 4, 1008, 1, 0),
(110308, 11, 1103, 4, 1, 'Spell_Nature_HealingWay', 'Natural Shapeshifter', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(110309, 11, 1103, 4, 2, 'Spell_Nature_ResistNature', 'Natural Perfection', '+3% Area.', 3, 0, 0, 0, 10, 3, 0),
(110310, 11, 1103, 5, 2, 'Spell_Nature_Reincarnation', 'Heart of the Wild', 'You give up your forms. Shapeshift hurls Wrath in your own form, and every Druid spell deals and heals 15% more. Form bonuses and form traits no longer apply.', 1, 0, 0, 38, 27, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 320 AND 329;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(320, 'Initiate of the Grove', 'Win a run on Normal as a druid.', 'Spell_Nature_Rejuvenation', 3, 1, 0, 2, 6, 1, 11, 2),
(321, 'Starcaller', 'Kill 3,000 enemies with Hurricane as a druid.', 'Spell_Nature_Cyclone', 2, 1003, 0, 3000, 6, 1, 11, 2),
(322, 'Claw of the Wild', 'Kill 3,000 enemies with Swipe as a druid.', 'INV_Misc_MonsterClaw_03', 2, 1006, 0, 3000, 6, 1, 11, 2),
(323, 'Keeper of the Grove', 'Kill 3,000 enemies with Tranquility as a druid.', 'Spell_Nature_Tranquility', 2, 1011, 0, 3000, 6, 1, 11, 2),
(324, 'Wildheart', 'Kill 60 elites as a druid.', 'Ability_Druid_CatForm', 1, 1, 0, 60, 6, 1, 11, 2),
(325, 'Archdruid', 'Reach level 50 in a single run as a druid.', 'Spell_Nature_ProtectionformNature', 4, 0, 0, 50, 6, 1, 11, 2),
(326, 'Guardian of Cenarius', 'Clear stage 1 on Heroic as a druid.', 'Ability_Racial_BearForm', 3, 3, 0, 2, 6, 1, 11, 2),
(327, 'Cenarion Champion', 'Win a run on Heroic as a druid.', 'Spell_Nature_StarFall', 3, 3, 0, 3, 6, 1, 11, 2),
(328, 'Avatar of the Wild', 'Clear stage 1 on Mythic as a druid.', 'Spell_Nature_Reincarnation', 3, 2, 0, 2, 6, 1, 11, 2),
(329, 'Seasoned Druid', 'Reach Mastery level 10 with a druid.', 'Spell_Nature_NatureTouchGrow', 16, 11, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
