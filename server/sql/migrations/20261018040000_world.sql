DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018040000');

UPDATE `bonk_quest` SET `reward_type` = 6, `reward_value` = 1 WHERE `id` IN (141, 142, 143, 145, 146, 147, 148, 149, 150);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 151 AND 168;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(151, 'Battle-Hardened', 'Win a run on Normal as a warrior.', 'Ability_Warrior_BattleShout', 3, 1, 0, 2, 6, 1, 1, 2),
(152, 'Mortal Wounds', 'Kill 2,500 enemies with Mortal Strike as a warrior.', 'Ability_Warrior_SavageBlow', 2, 303, 0, 2500, 6, 1, 1, 2),
(153, 'Bloodthirsty', 'Kill 3,000 enemies with Bloodthirst as a warrior.', 'Spell_Nature_BloodLust', 2, 304, 0, 3000, 6, 1, 1, 2),
(154, 'Thunderstruck', 'Kill 3,000 enemies with Thunder Clap as a warrior.', 'Ability_ThunderClap', 2, 308, 0, 3000, 6, 1, 1, 2),
(155, 'Giant Slayer', 'Kill 60 elites as a warrior.', 'Ability_Warrior_Challange', 1, 1, 0, 60, 6, 1, 1, 2),
(156, 'Veteran', 'Reach level 50 in a single run as a warrior.', 'Ability_Warrior_InnerRage', 4, 0, 0, 50, 6, 1, 1, 2),
(157, 'Warbringer', 'Clear stage 1 on Heroic as a warrior.', 'Ability_Warrior_Charge', 3, 3, 0, 2, 6, 1, 1, 2),
(158, 'Warlord', 'Win a run on Heroic as a warrior.', 'Ability_Warrior_OffensiveStance', 3, 3, 0, 3, 6, 1, 1, 2),
(159, 'Unstoppable', 'Clear stage 1 on Mythic as a warrior.', 'Ability_Warrior_PunishingBlow', 3, 2, 0, 2, 6, 1, 1, 2),
(160, 'Magister', 'Win a run on Normal as a mage.', 'INV_Staff_13', 3, 1, 0, 2, 6, 1, 8, 2),
(161, 'Frostweaver', 'Kill 3,000 enemies with Frostbolt as a mage.', 'Spell_Frost_FrostBolt02', 2, 400, 0, 3000, 6, 1, 8, 2),
(162, 'Pyromancer', 'Kill 3,000 enemies with Fireball as a mage.', 'Spell_Fire_FlameBolt', 2, 403, 0, 3000, 6, 1, 8, 2),
(163, 'Arcanist', 'Kill 3,000 enemies with Arcane Explosion as a mage.', 'Spell_Nature_WispSplode', 2, 408, 0, 3000, 6, 1, 8, 2),
(164, 'Spellbreaker', 'Kill 60 elites as a mage.', 'Spell_Frost_IceShock', 1, 1, 0, 60, 6, 1, 8, 2),
(165, 'Scholar', 'Reach level 50 in a single run as a mage.', 'INV_Misc_Book_09', 4, 0, 0, 50, 6, 1, 8, 2),
(166, 'Elementalist', 'Clear stage 1 on Heroic as a mage.', 'Spell_Fire_Fire', 3, 3, 0, 2, 6, 1, 8, 2),
(167, 'Kirin Tor', 'Win a run on Heroic as a mage.', 'Spell_Arcane_PortalIronForge', 3, 3, 0, 3, 6, 1, 8, 2),
(168, 'Grand Magus', 'Clear stage 1 on Mythic as a mage.', 'Spell_Nature_Lightning', 3, 2, 0, 2, 6, 1, 8, 2);

UPDATE `bonk_talent` SET `cost` = 8, `cost_growth` = 1 WHERE `id` = 9;
UPDATE `bonk_talent` SET `max_rank` = 5, `cost` = 2, `cost_growth` = 0.5 WHERE `id` = 8;
UPDATE `bonk_talent` SET `cost` = 8, `cost_growth` = 1 WHERE `id` = 5;
UPDATE `bonk_talent` SET `cost` = 12, `cost_growth` = 1 WHERE `id` = 10;
UPDATE `bonk_talent` SET `cost` = 20, `cost_growth` = 1 WHERE `id` = 11;
UPDATE `bonk_talent` SET `cost` = 10, `cost_growth` = 0.5 WHERE `id` = 6;
UPDATE `bonk_talent` SET `max_rank` = 2, `cost` = 30, `cost_growth` = 1, `tree_row` = 3, `tree_column` = 2 WHERE `id` = 7;
UPDATE `bonk_talent` SET `cost` = 30, `tree_row` = 3, `tree_column` = 3 WHERE `id` = 12;
UPDATE `bonk_talent` SET `cost` = 8 WHERE `id` IN (1, 3);
UPDATE `bonk_talent` SET `cost` = 12 WHERE `id` IN (2, 4);

DELETE FROM `bonk_talent` WHERE `id` BETWEEN 13 AND 17;
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`) VALUES
(13, 'Mystic Insight', '+5% experience in runs.', 12, 5, 0, 3, 6, 1, 'INV_Misc_Book_07', 4, 1, 4, 0, 0, ''),
(14, 'Premonition', 'Evolutions can be offered 1 rank earlier.', 13, 1, 0, 2, 25, 1, 'Spell_Nature_CrystalBall', 4, 3, 1, 0, 0, ''),
(15, 'Cursed Ground', 'Healing you receive is reduced by 50%. +20% gold.', 14, 50, 20, 1, 12, 0, 'Spell_Shadow_CurseOfTounges', 5, 3, 2, 0, 0, ''),
(16, 'Doom Clock', 'The stage boss arrives 60 sec earlier. +15% gold.', 15, 60, 15, 1, 12, 0, 'INV_Misc_PocketWatch_01', 5, 3, 3, 0, 0, ''),
(17, 'Empowered Elites', 'Elites have 1 additional affix. +20% gold.', 16, 1, 20, 1, 15, 0, 'Spell_Shadow_UnholyStrength', 5, 4, 2, 0, 0, '');

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
