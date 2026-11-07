DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024000000');

UPDATE `bonk_weapon` SET `spec` = 901 WHERE `id` IN (904, 905, 906);
UPDATE `bonk_weapon` SET `spec` = 902 WHERE `id` IN (900, 901, 902, 903);
UPDATE `bonk_weapon` SET `spec` = 903 WHERE `id` IN (907, 908, 909, 910);

DELETE FROM `bonk_mastery` WHERE `class` = 9;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 9;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(901, 9, 'Affliction', 'WarlockCurses', 1),
(902, 9, 'Demonology', 'WarlockSummoning', 2),
(903, 9, 'Destruction', 'WarlockDestruction', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(90101, 9, 901, 1, 1, 'Spell_Shadow_UnsummonBuilding', 'Suppression', 'Affliction spells deal 3% more damage.', 5, 0, 0, 12, 901, 3, 0),
(90102, 9, 901, 1, 2, 'Spell_Shadow_AbominationExplosion', 'Improved Corruption', 'Corruption can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 904, 1, 0),
(90103, 9, 901, 1, 3, 'Spell_Shadow_ShadowWordPain', 'Shadow Mastery', 'Your Decay deals 8% more damage.', 3, 0, 0, 13, 13, 8, 0),
(90104, 9, 901, 2, 1, 'Spell_Shadow_CurseOfSargeras', 'Improved Curse of Agony', 'Your Agony deals 8% more damage.', 3, 0, 0, 13, 14, 8, 0),
(90105, 9, 901, 2, 2, 'Spell_Shadow_LifeDrain02', 'Improved Drain Life', 'Drain Life deals 5% more damage.', 3, 0, 0, 1, 906, 5, 0),
(90106, 9, 901, 3, 1, 'Spell_Shadow_CurseOfMannoroth', 'Grim Reach', 'Curse of Agony curses 1 additional enemy.', 1, 0, 0, 4, 905, 1, 0),
(90107, 9, 901, 3, 2, 'Spell_Shadow_GrimWard', 'Siphon Life', 'Corruption corrupts 1 additional enemy.', 1, 0, 0, 4, 904, 1, 0),
(90108, 9, 901, 4, 1, 'Spell_Shadow_Twilight', 'Nightmare', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(90109, 9, 901, 4, 2, 'Spell_Shadow_FingerOfDeath', 'Fel Concentration', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(90110, 9, 901, 5, 2, 'Spell_Shadow_DeathScream', 'Pandemic', 'When an enemy dies with your Decay or Agony on it, they jump to the nearest enemy without them and keep every stack. Your Power is reduced by 15%.', 1, 0, 0, 38, 22, 1, 0),
(90201, 9, 902, 1, 1, 'Spell_Shadow_Metamorphosis', 'Demonic Embrace', 'Demonology spells deal 3% more damage.', 5, 0, 0, 12, 902, 3, 0),
(90202, 9, 902, 1, 2, 'Spell_Shadow_SummonImp', 'Improved Imp', 'Imp can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 900, 1, 0),
(90203, 9, 902, 1, 3, 'Spell_Shadow_RagingScream', 'Demon Skin', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(90204, 9, 902, 2, 1, 'Spell_Shadow_SummonVoidWalker', 'Improved Voidwalker', 'Voidwalker deals 5% more damage.', 3, 0, 0, 1, 901, 5, 0),
(90205, 9, 902, 2, 2, 'Spell_Shadow_ShadowWordDominate', 'Unholy Power', 'Your demons have 3% more critical strike chance.', 3, 0, 0, 30, 0, 3, 0),
(90206, 9, 902, 3, 1, 'Spell_Shadow_SummonSuccubus', 'Improved Succubus', 'Succubus deals 15% more damage.', 1, 0, 0, 1, 902, 15, 0),
(90207, 9, 902, 3, 2, 'Spell_Shadow_SummonFelHunter', 'Improved Felhunter', 'Felhunter deals 15% more damage.', 1, 0, 0, 1, 903, 15, 0),
(90208, 9, 902, 4, 1, 'Spell_Shadow_PsychicScream', 'Demonic Sacrifice', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(90209, 9, 902, 4, 2, 'Spell_Shadow_ImpPhaseShift', 'Fel Intellect', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(90210, 9, 902, 5, 2, 'Spell_Shadow_ShadowPact', 'Master Demonologist', 'Each different demon you command makes all your demons deal 10% more damage, up to 40%. Your Power is reduced by 15%.', 1, 0, 0, 38, 23, 1, 0),
(90301, 9, 903, 1, 1, 'Spell_Fire_SealOfFire', 'Emberstorm', 'Destruction spells deal 3% more damage.', 5, 0, 0, 12, 903, 3, 0),
(90302, 9, 903, 1, 2, 'Spell_Shadow_ShadowBolt', 'Improved Shadow Bolt', 'Shadow Bolt deals 5% more damage.', 3, 0, 0, 1, 907, 5, 0),
(90303, 9, 903, 1, 3, 'Spell_Fire_FlameShock', 'Devastation', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(90304, 9, 903, 2, 1, 'Spell_Fire_Immolation', 'Improved Immolate', 'Your Burning deals 8% more damage.', 3, 0, 0, 13, 3, 8, 0),
(90305, 9, 903, 2, 2, 'Spell_Shadow_DeathPact', 'Bane', 'Shadow Bolt recharges 8% faster.', 3, 0, 0, 3, 907, 8, 0),
(90306, 9, 903, 3, 1, 'Spell_Shadow_RainOfFire', 'Improved Rain of Fire', 'Rain of Fire recharges 15% faster.', 1, 0, 0, 3, 910, 15, 0),
(90307, 9, 903, 3, 2, 'Spell_Fire_Fireball', 'Fire and Brimstone', 'Immolate strikes 1 additional enemy.', 1, 0, 0, 4, 908, 1, 0),
(90308, 9, 903, 4, 1, 'Spell_Shadow_ShadowWordPain', 'Shadow and Flame', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(90309, 9, 903, 4, 2, 'Spell_Fire_Fire', 'Aftermath', '+3% Area.', 3, 0, 0, 0, 10, 3, 0),
(90310, 9, 903, 5, 2, 'Spell_Shadow_ScourgeBuild', 'Ruin', 'Nightfall fires up to 3 free Shadow Bolts a sec instead of 1, and they deal 50% more damage. Your critical strike chance is reduced by 10%.', 1, 0, 0, 38, 24, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 280 AND 289;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(280, 'Initiate of the Coven', 'Win a run on Normal as a warlock.', 'Spell_Shadow_SummonImp', 3, 1, 0, 2, 6, 1, 9, 2),
(281, 'Shadowcaller', 'Kill 3,000 enemies with Shadow Bolt as a warlock.', 'Spell_Shadow_ShadowBolt', 2, 907, 0, 3000, 6, 1, 9, 2),
(282, 'Corruptor', 'Kill 3,000 enemies with Corruption as a warlock.', 'Spell_Shadow_AbominationExplosion', 2, 904, 0, 3000, 6, 1, 9, 2),
(283, 'Hellcaller', 'Kill 3,000 enemies with Rain of Fire as a warlock.', 'Spell_Shadow_RainOfFire', 2, 910, 0, 3000, 6, 1, 9, 2),
(284, 'Soul Harvester', 'Kill 60 elites as a warlock.', 'Spell_Shadow_LifeDrain02', 1, 1, 0, 60, 6, 1, 9, 2),
(285, 'Shadow Council', 'Reach level 50 in a single run as a warlock.', 'Spell_Shadow_Metamorphosis', 4, 0, 0, 50, 6, 1, 9, 2),
(286, 'Cultist of the Damned', 'Clear stage 1 on Heroic as a warlock.', 'Spell_Shadow_CurseOfSargeras', 3, 3, 0, 2, 6, 1, 9, 2),
(287, 'Doomcaller', 'Win a run on Heroic as a warlock.', 'Spell_Shadow_DeathScream', 3, 3, 0, 3, 6, 1, 9, 2),
(288, 'Dreadlord', 'Clear stage 1 on Mythic as a warlock.', 'Spell_Shadow_ShadowPact', 3, 2, 0, 2, 6, 1, 9, 2),
(289, 'Seasoned Warlock', 'Reach Mastery level 10 with a warlock.', 'Spell_Shadow_SummonFelHunter', 16, 9, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
