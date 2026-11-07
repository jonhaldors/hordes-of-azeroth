DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019050000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019050000');

DELETE FROM `bonk_mastery` WHERE `class` = 5;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 5;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(501, 5, 'Discipline', 'PriestDiscipline', 1),
(502, 5, 'Holy', 'PriestHoly', 2),
(503, 5, 'Shadow', 'PriestShadow', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(50101, 5, 501, 1, 1, 'Spell_Nature_SlowingTotem', 'Force of Will', 'Discipline spells deal 3% more damage.', 5, 0, 0, 12, 501, 3, 0),
(50102, 5, 501, 1, 2, 'Spell_Holy_PowerWordShield', 'Improved Power Word: Shield', 'Power Word: Shield can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 504, 1, 0),
(50103, 5, 501, 1, 3, 'Spell_Holy_WordFortitude', 'Improved Power Word: Fortitude', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(50104, 5, 501, 2, 1, 'Spell_Nature_EnchantArmor', 'Mental Strength', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(50105, 5, 501, 2, 2, 'Spell_Holy_HolyBolt', 'Improved Penance', 'Penance deals 5% more damage.', 3, 0, 0, 1, 505, 5, 0),
(50106, 5, 501, 3, 1, 'Spell_Nature_Tranquility', 'Martyrdom', 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.', 1, 0, 0, 33, 0, 30, 0),
(50107, 5, 501, 3, 2, 'Spell_Frost_WindWalkOn', 'Inner Focus', 'When Penance kills an enemy, it recharges at once.', 1, 0, 0, 18, 505, 1, 0),
(50108, 5, 501, 4, 1, 'Ability_Hibernation', 'Mental Agility', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(50109, 5, 501, 4, 2, 'Spell_Nature_Slow', 'Improved Shackle', 'Shackle deals 10% more damage.', 3, 0, 0, 1, 507, 10, 0),
(50110, 5, 501, 5, 2, 'Spell_Holy_PowerInfusion', 'Pain Suppression', 'While you have a Shield, you take 20% less damage. Your Power is reduced by 15%.', 1, 0, 0, 38, 14, 1, 0),
(50201, 5, 502, 1, 1, 'Spell_Holy_SealOfSalvation', 'Holy Specialization', 'Holy spells deal 3% more damage.', 5, 0, 0, 12, 502, 3, 0),
(50202, 5, 502, 1, 2, 'Spell_Holy_Renew', 'Improved Renew', 'Renew heals and smites for 5% more.', 3, 0, 0, 1, 501, 5, 0),
(50203, 5, 502, 1, 3, 'Spell_Holy_HolyNova', 'Spiritual Guidance', '+4% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.', 3, 0, 0, 0, 10, 4, 0),
(50204, 5, 502, 2, 1, 'Spell_Holy_PrayerOfHealing02', 'Holy Reach', 'Halo deals 5% more damage.', 3, 0, 0, 1, 502, 5, 0),
(50205, 5, 502, 2, 2, 'Spell_Holy_HealingFocus', 'Healing Focus', 'Regain 0.1% of your health every second.', 3, 0, 0, 0, 5, 0.1, 0),
(50206, 5, 502, 3, 1, 'Spell_Holy_HolySmite', 'Surge of Light', 'When Smite kills an enemy, it recharges at once.', 1, 0, 0, 18, 500, 1, 0),
(50207, 5, 502, 3, 2, 'Spell_Holy_Excorcism_02', 'Improved Holy Word', 'When Holy Word: Chastise kills an enemy, it recharges at once.', 1, 0, 0, 18, 503, 1, 0),
(50208, 5, 502, 4, 1, 'Spell_Holy_GreaterHeal', 'Spiritual Healing', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(50209, 5, 502, 4, 2, 'Spell_Holy_SearingLight', 'Divine Fury', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(50210, 5, 502, 5, 2, 'Spell_Holy_Restoration', 'Archangel', 'Renew smites while you are above 80% health, not only at full health, and Smite and Halo take 2 sec off Holy Word: Chastise. Your maximum health is reduced by 15%.', 1, 0, 0, 38, 13, 1, 0),
(50301, 5, 503, 1, 1, 'Spell_Shadow_BurningSpirit', 'Shadow Focus', 'Shadow spells deal 3% more damage.', 5, 0, 0, 12, 503, 3, 0),
(50302, 5, 503, 1, 2, 'Spell_Shadow_ShadowWordPain', 'Improved Shadow Word: Pain', 'Shadow Word: Pain can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 508, 1, 0),
(50303, 5, 503, 1, 3, 'Spell_Shadow_Requiem', 'Spirit Tap', 'Regain 0.1% of your health every second.', 3, 0, 0, 0, 5, 0.1, 0),
(50304, 5, 503, 2, 1, 'Spell_Shadow_Twilight', 'Darkness', 'Your Decay deals 8% more damage.', 3, 0, 0, 13, 13, 8, 0),
(50305, 5, 503, 2, 2, 'Spell_Shadow_UnholyFrenzy', 'Improved Mind Blast', 'Mind Blast deals 5% more damage.', 3, 0, 0, 1, 510, 5, 0),
(50306, 5, 503, 3, 1, 'Spell_Shadow_BlackPlague', 'Shadow Weaving', 'When you are struck, Mind Blast goes off. Can occur once every 6 sec.', 1, 0, 0, 21, 510, 6, 0),
(50307, 5, 503, 3, 2, 'Spell_Shadow_GatherShadows', 'Blackout', 'Mind Flay stuns normal enemies it hits for 1 sec. Each enemy can only be stunned once every 6 sec.', 1, 0, 0, 20, 509, 1, 0),
(50308, 5, 503, 4, 1, 'Spell_Shadow_ChillTouch', 'Contagion', 'When a decaying enemy dies, its Decay spreads to 1 additional nearby enemy.', 1, 0, 0, 28, 13, 1, 0),
(50309, 5, 503, 4, 2, 'Spell_Shadow_ShadowWard', 'Shadow Power', '+3% critical strike chance against enemies with Decay.', 3, 0, 0, 14, 13, 3, 0),
(50310, 5, 503, 5, 2, 'Spell_Shadow_Shadowform', 'Shadowform', 'Your Decay deals 30% more damage. Your Haste is reduced by 10%.', 1, 0, 0, 38, 15, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 178 AND 186 OR `id` = 259;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(178, 'Acolyte', 'Win a run on Normal as a priest.', 'Spell_Holy_HolySmite', 3, 1, 0, 2, 6, 1, 5, 2),
(179, 'Lightbearer', 'Kill 3,000 enemies with Smite as a priest.', 'Spell_Holy_HolySmite', 2, 500, 0, 3000, 6, 1, 5, 2),
(180, 'Confessor', 'Kill 3,000 enemies with Penance as a priest.', 'Spell_Holy_HolyBolt', 2, 505, 0, 3000, 6, 1, 5, 2),
(181, 'Voidcaller', 'Kill 3,000 enemies with Shadow Word: Pain as a priest.', 'Spell_Shadow_ShadowWordPain', 2, 508, 0, 3000, 6, 1, 5, 2),
(182, 'Exorcist', 'Kill 60 elites as a priest.', 'Spell_Holy_Excorcism_02', 1, 1, 0, 60, 6, 1, 5, 2),
(183, 'Oracle', 'Reach level 50 in a single run as a priest.', 'Spell_Holy_MindVision', 4, 0, 0, 50, 6, 1, 5, 2),
(184, 'Scarlet Penitent', 'Clear stage 1 on Heroic as a priest.', 'Spell_Holy_PowerWordShield', 3, 3, 0, 2, 6, 1, 5, 2),
(185, 'High Priest', 'Win a run on Heroic as a priest.', 'Spell_Holy_Restoration', 3, 3, 0, 3, 6, 1, 5, 2),
(186, 'Prophet', 'Clear stage 1 on Mythic as a priest.', 'Spell_Shadow_Shadowform', 3, 2, 0, 2, 6, 1, 5, 2),
(259, 'Seasoned Priest', 'Reach Mastery level 10 with a priest.', 'Spell_Holy_WordFortitude', 16, 5, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
