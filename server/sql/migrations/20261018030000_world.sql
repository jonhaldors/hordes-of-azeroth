DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018030000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018030000');

ALTER TABLE `bonk_weapon` ADD COLUMN `spec` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `bonk_mastery` ADD COLUMN `param` INT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `bonk_weapon` SET `spec` = 302 WHERE `id` IN (7, 37, 137, 203, 205);
UPDATE `bonk_weapon` SET `spec` = 303 WHERE `id` IN (38, 202, 204);
UPDATE `bonk_weapon` SET `spec` = 301 WHERE `id` IN (201, 211);
UPDATE `bonk_weapon` SET `spec` = 101 WHERE `id` IN (301, 302, 303);
UPDATE `bonk_weapon` SET `spec` = 102 WHERE `id` IN (304, 305, 306);
UPDATE `bonk_weapon` SET `spec` = 103 WHERE `id` IN (307, 308, 309, 310);
UPDATE `bonk_weapon` SET `spec` = 801 WHERE `id` IN (407, 408, 409);
UPDATE `bonk_weapon` SET `spec` = 802 WHERE `id` IN (403, 404, 405, 406);
UPDATE `bonk_weapon` SET `spec` = 803 WHERE `id` IN (400, 401, 402);

DELETE FROM `bonk_mastery` WHERE `class` IN (1, 3, 8);
DELETE FROM `bonk_mastery_tree` WHERE `class` IN (1, 3, 8);
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(101, 1, 'Arms', 'WarriorArms', 1),
(102, 1, 'Fury', 'WarriorFury', 2),
(103, 1, 'Protection', 'WarriorProtection', 3),
(301, 3, 'Beast Mastery', 'HunterBeastMastery', 1),
(302, 3, 'Marksmanship', 'HunterMarksmanship', 2),
(303, 3, 'Survival', 'HunterSurvival', 3),
(801, 8, 'Arcane', 'MageArcane', 1),
(802, 8, 'Fire', 'MageFire', 2),
(803, 8, 'Frost', 'MageFrost', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(30101, 3, 301, 1, 1, 'Ability_BullRush', 'Unleashed Fury', 'Call Pet and Pack Leader deal 3% more damage.', 5, 0, 0, 12, 301, 3, 0),
(30102, 3, 301, 1, 2, 'Ability_Hunter_BeastCall', 'Beast Training', 'Call Pet can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 201, 1, 0),
(30103, 3, 301, 1, 3, 'Spell_Nature_Reincarnation', 'Endurance Training', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(30104, 3, 301, 2, 1, 'INV_Misc_MonsterClaw_03', 'Frenzy', 'Call Pet summons 1 additional beast.', 3, 0, 0, 4, 201, 1, 0),
(30105, 3, 301, 2, 2, 'Spell_Nature_AbolishMagic', 'Bestial Discipline', 'While Pack Leader is with you, your pets inherit an additional 5% of your Power.', 3, 0, 0, 31, 211, 5, 0),
(30106, 3, 301, 3, 1, 'Ability_Druid_DemoralizingRoar', 'Spirit Bond', 'Each howl of Pack Leader heals you for 3% of your maximum health.', 1, 0, 0, 17, 211, 3, 0),
(30107, 3, 301, 3, 2, 'Ability_Druid_Enrage', 'The Beast Within', 'While Pack Leader''s howl sends your pets into a frenzy, you deal 15% more damage too.', 1, 0, 0, 32, 0, 15, 0),
(30108, 3, 301, 4, 1, 'INV_Misc_MonsterClaw_04', 'Ferocity', 'Your pets have 3% more critical strike chance.', 3, 0, 0, 30, 0, 3, 0),
(30109, 3, 301, 4, 2, 'Ability_Mount_JungleTiger', 'Pathfinding', '+2% movement speed.', 3, 0, 0, 0, 3, 2, 0),
(30110, 3, 301, 5, 2, 'Ability_Druid_FerociousBite', 'Bestial Wrath', 'Your pets are always in a frenzy: they deal 50% more damage, and their attacks strike all enemies in front of them. Your other spells deal 30% less damage.', 1, 0, 0, 38, 1, 50, 0),
(30201, 3, 302, 1, 1, 'INV_Weapon_Rifle_06', 'Ranged Weapon Specialization', 'Marksmanship spells deal 3% more damage.', 5, 0, 0, 12, 302, 3, 0),
(30202, 3, 302, 1, 2, 'Ability_UpgradeMoonGlaive', 'Lock and Load', 'Multi-Shot can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 37, 1, 0),
(30203, 3, 302, 1, 3, 'Ability_TownWatch', 'Hawk Eye', '+10% pickup range for experience orbs and turkey legs.', 3, 0, 0, 0, 8, 10, 0),
(30204, 3, 302, 2, 1, 'Ability_Hunter_SniperShot', 'Improved Hunter''s Mark', 'Marked enemies take an additional 2% damage.', 3, 0, 0, 29, 0, 2, 0),
(30205, 3, 302, 2, 2, 'Ability_Marksmanship', 'Barrage', 'Volley deals an additional 2% damage for each different debuff on the target.', 3, 0, 0, 15, 137, 2, 0),
(30206, 3, 302, 3, 1, 'Ability_ImpalingBolt', 'Improved Arcane Shot', 'Arcane Shot slows normal enemies it hits by 30% for 2 sec.', 1, 0, 0, 11, 7, 30, 0),
(30207, 3, 302, 3, 2, 'INV_Spear_07', 'Improved Aimed Shot', 'Aimed Shot places Hunter''s Mark on every enemy it passes through.', 1, 0, 0, 16, 203, 1, 9),
(30208, 3, 302, 4, 1, 'Ability_SearingArrow', 'Lethal Shots', '+3% critical strike chance against Marked enemies.', 3, 0, 0, 14, 9, 3, 0),
(30209, 3, 302, 4, 2, 'Ability_PierceDamage', 'Mortal Shots', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(30210, 3, 302, 5, 2, 'Ability_TrueShot', 'Trueshot', 'Your shots go for Marked enemies first and deal 40% more damage to them. Enemies that aren''t Marked take 25% less damage from you.', 1, 0, 0, 38, 2, 40, 0),
(30301, 3, 303, 1, 1, 'Spell_Holy_BlessingOfStamina', 'Killer Instinct', 'Survival spells deal 3% more damage.', 5, 0, 0, 12, 303, 3, 0),
(30302, 3, 303, 1, 2, 'Ability_Hunter_Quickshot', 'Improved Serpent Sting', 'Serpent Sting can be your starter spell once the quest Venomous unlocks it. Choose it at the Run Master.', 1, 0, 0, 5, 38, 1, 0),
(30303, 3, 303, 1, 3, 'Spell_Shadow_Twilight', 'Survivalist', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(30304, 3, 303, 2, 1, 'Ability_Creature_Poison_03', 'Noxious Stings', 'Your Poison deals 5% more damage.', 3, 0, 0, 0, 19, 5, 0),
(30305, 3, 303, 2, 2, 'Spell_Nature_TimeStop', 'Clever Traps', 'The fire of Explosive Trap and the ice of Frost Trap last 15% longer.', 3, 0, 0, 37, 0, 15, 0),
(30306, 3, 303, 3, 1, 'Spell_Nature_StrangleVines', 'Entrapment', 'When Frost Trap springs, normal enemies inside its ice field are Frozen. Each enemy can only be Frozen once every 6 sec.', 1, 0, 0, 36, 204, 1, 0),
(30307, 3, 303, 3, 2, 'Ability_Warrior_Challange', 'Counterattack', 'When you are struck, Explosive Trap places a trap at your feet. Can occur once every 5 sec.', 1, 0, 0, 21, 202, 5, 0),
(30308, 3, 303, 4, 1, 'Ability_Kick', 'Surefooted', '+2% chance to dodge enemy swings.', 3, 0, 0, 0, 14, 2, 0),
(30309, 3, 303, 4, 2, 'Spell_Nature_Invisibilty', 'Lightning Reflexes', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(30310, 3, 303, 5, 2, 'Ability_Ensnare', 'Trapmaster', 'Each dash leaves one of each of your traps where you started, armed at once. Your maximum health is reduced by 15%.', 1, 0, 0, 38, 3, 15, 0),
(10101, 1, 101, 1, 1, 'INV_Axe_09', 'Two-Handed Weapon Specialization', 'Arms spells deal 3% more damage.', 5, 0, 0, 12, 101, 3, 0),
(10102, 1, 101, 1, 2, 'Ability_Gouge', 'Improved Rend', 'Rend can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 301, 1, 0),
(10103, 1, 101, 1, 3, 'Ability_Parry', 'Deflection', '+2% chance to dodge enemy swings.', 3, 0, 0, 0, 14, 2, 0),
(10104, 1, 101, 2, 1, 'INV_Sword_17', 'Serrated Blades', 'Your Bleed deals 8% more damage.', 3, 0, 0, 13, 4, 8, 0),
(10105, 1, 101, 2, 2, 'Ability_Warrior_SavageBlow', 'Improved Mortal Strike', 'Mortal Strike deals an additional 1% damage for each stack of Bleed on the enemy.', 3, 0, 0, 15, 303, 1, 0),
(10106, 1, 101, 3, 1, 'Ability_Racial_BloodRage', 'Blood Frenzy', 'Cleave makes every enemy it hits Bleed.', 1, 0, 0, 16, 300, 1, 4),
(10107, 1, 101, 3, 2, 'Ability_Warrior_DecisiveStrike', 'Sudden Death', 'When Mortal Strike kills an enemy, it recharges at once.', 1, 0, 0, 18, 303, 1, 0),
(10108, 1, 101, 4, 1, 'Ability_SearingArrow', 'Impale', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(10109, 1, 101, 4, 2, 'INV_Sword_27', 'Sword Specialization', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(10110, 1, 101, 5, 2, 'Ability_Warrior_PunishingBlow', 'Weapon Master', 'Every 5th cast of each of your spells critically strikes every enemy it hits. Your Haste is reduced by 10%.', 1, 0, 0, 38, 4, 5, 0),
(10201, 1, 102, 1, 1, 'Ability_DualWield', 'Dual Wield Specialization', 'Fury spells deal 3% more damage.', 5, 0, 0, 12, 102, 3, 0),
(10202, 1, 102, 1, 2, 'Ability_Warrior_Cleave', 'Improved Cleave', 'Cleave can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 300, 1, 0),
(10203, 1, 102, 1, 3, 'Spell_Shadow_LifeDrain', 'Blood Craze', 'Regain 0.1% of your health every second.', 3, 0, 0, 0, 5, 0.1, 0),
(10204, 1, 102, 2, 1, 'Spell_Shadow_UnholyFrenzy', 'Enrage', 'Enrage lasts 1 sec longer.', 3, 0, 0, 22, 0, 1, 0),
(10205, 1, 102, 2, 2, 'Ability_GhoulFrenzy', 'Flurry', 'Enrage gives an additional 5% Haste.', 3, 0, 0, 23, 0, 5, 0),
(10206, 1, 102, 3, 1, 'Spell_Shadow_DeathPact', 'Death Wish', 'While you are Enraged, you deal 15% more damage.', 1, 0, 0, 24, 0, 15, 0),
(10207, 1, 102, 3, 2, 'INV_Sword_48', 'Improved Execute', 'Execute kills normal enemies below 25% health instead of 20%.', 1, 0, 0, 19, 305, 25, 0),
(10208, 1, 102, 4, 1, 'Ability_Rogue_Eviscerate', 'Cruelty', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(10209, 1, 102, 4, 2, 'Spell_Nature_StoneClawTotem', 'Unbridled Wrath', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(10210, 1, 102, 5, 2, 'Ability_Racial_Avatar', 'Berserker', 'You are always Enraged. Enemies deal 15% more damage to you.', 1, 0, 0, 38, 5, 15, 0),
(10301, 1, 103, 1, 1, 'INV_Shield_06', 'Shield Specialization', 'Protection spells deal 3% more damage.', 5, 0, 0, 12, 103, 3, 0),
(10302, 1, 103, 1, 2, 'Ability_ThunderClap', 'Improved Thunder Clap', 'Thunder Clap can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 308, 1, 0),
(10303, 1, 103, 1, 3, 'Spell_Magic_MageArmor', 'Iron Will', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(10304, 1, 103, 2, 1, 'Ability_Defend', 'Improved Shield Block', 'Shield Block gives an additional 2% of your maximum health as Shield.', 3, 0, 0, 25, 0, 2, 0),
(10305, 1, 103, 2, 2, 'Ability_Warrior_ShieldWall', 'Improved Shield Wall', 'Gain a Shield equal to 3% of your maximum health.', 3, 0, 0, 0, 17, 3, 0),
(10306, 1, 103, 3, 1, 'Ability_Warrior_Revenge', 'Improved Revenge', 'Revenge stuns normal enemies it hits for 1 sec. Each enemy can only be stunned once every 6 sec.', 1, 0, 0, 20, 309, 1, 0),
(10307, 1, 103, 3, 2, 'Spell_Holy_AshesToAshes', 'Last Stand', 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.', 1, 0, 0, 33, 0, 30, 0),
(10308, 1, 103, 4, 1, 'Spell_Holy_Devotion', 'Toughness', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(10309, 1, 103, 4, 2, 'Spell_Nature_MirrorImage', 'Anticipation', '+2% chance to dodge enemy swings.', 3, 0, 0, 0, 14, 2, 0),
(10310, 1, 103, 5, 2, 'Ability_Warrior_DefensiveStance', 'Juggernaut', 'Shield Block''s Shield builds up to 100% of your maximum health instead of 50%, and your Shield recharges 10% a second even while you are struck. You deal 15% less damage.', 1, 0, 0, 38, 6, 100, 0),
(80101, 8, 801, 1, 1, 'Spell_Holy_Devotion', 'Arcane Focus', 'Arcane spells deal 3% more damage.', 5, 0, 0, 12, 801, 3, 0),
(80102, 8, 801, 1, 2, 'Spell_Nature_StarFall', 'Improved Arcane Missiles', 'Arcane Missiles can be your starter spell, which turns your dash into Blink. Choose it at the Run Master.', 1, 0, 0, 5, 409, 1, 0),
(80103, 8, 801, 1, 3, 'Spell_Nature_AstralRecalGroup', 'Magic Absorption', 'Gain a Shield equal to 3% of your maximum health.', 3, 0, 0, 0, 17, 3, 0),
(80104, 8, 801, 2, 1, 'Spell_Arcane_Blink', 'Improved Blink', 'Your dash recharges 10% faster.', 3, 0, 0, 26, 0, 10, 0),
(80105, 8, 801, 2, 2, 'Spell_Shadow_ManaBurn', 'Arcane Concentration', 'Your spells have a 2% chance to recharge at once when cast.', 3, 0, 0, 9, 0, 2, 0),
(80106, 8, 801, 3, 1, 'Spell_Nature_WispSplode', 'Improved Arcane Explosion', 'Arcane Explosion slows normal enemies it hits by 30% for 2 sec.', 1, 0, 0, 11, 408, 30, 0),
(80107, 8, 801, 3, 2, 'Spell_Shadow_DetectLesserInvisibility', 'Improved Mana Shield', 'Each Blink gives you a Shield equal to 3% of your maximum health.', 1, 0, 0, 35, 0, 3, 0),
(80108, 8, 801, 4, 1, 'Spell_Shadow_Teleport', 'Arcane Instability', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(80109, 8, 801, 4, 2, 'Spell_Shadow_Charm', 'Arcane Mind', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(80110, 8, 801, 5, 2, 'Spell_Nature_Lightning', 'Arcane Surge', 'Your dash becomes Blink and recharges twice as fast. Each Blink costs 3% of your maximum health.', 1, 0, 0, 38, 7, 3, 0),
(80201, 8, 802, 1, 1, 'Spell_Fire_Immolation', 'Fire Power', 'Fire spells deal 3% more damage.', 5, 0, 0, 12, 802, 3, 0),
(80202, 8, 802, 1, 2, 'Spell_Fire_FlameBolt', 'Improved Fireball', 'Fireball can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 403, 1, 0),
(80203, 8, 802, 1, 3, 'Spell_Fire_FireArmor', 'Improved Fire Ward', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(80204, 8, 802, 2, 1, 'Spell_Fire_Fire', 'Burning Soul', 'Your Burning deals 8% more damage.', 3, 0, 0, 13, 3, 8, 0),
(80205, 8, 802, 2, 2, 'Spell_Fire_Fireball', 'Improved Fire Blast', 'Fire Blast deals an additional 2% damage for each stack of Burning on the target.', 3, 0, 0, 15, 406, 2, 0),
(80206, 8, 802, 3, 1, 'Spell_Fire_MeteorStorm', 'Impact', 'Pyroblast stuns normal enemies it hits for 1 sec. Each enemy can only be stunned once every 6 sec.', 1, 0, 0, 20, 405, 1, 0),
(80207, 8, 802, 3, 2, 'Spell_Fire_SealOfFire', 'Combustion', 'When a Burning enemy dies, its Burning spreads to 1 additional nearby enemy.', 1, 0, 0, 28, 3, 1, 0),
(80208, 8, 802, 4, 1, 'Spell_Nature_WispHeal', 'Critical Mass', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(80209, 8, 802, 4, 2, 'Spell_Fire_Flare', 'Flame Throwing', '+4% Area. Your area spells cover more ground.', 3, 0, 0, 0, 10, 4, 0),
(80210, 8, 802, 5, 2, 'Spell_Fire_Incinerate', 'Glass Cannon', 'Your critical strikes deal 100% more damage. Your maximum health is reduced by 50%.', 1, 0, 0, 38, 8, 100, 0),
(80301, 8, 803, 1, 1, 'Spell_Frost_FrostBolt', 'Piercing Ice', 'Frost spells deal 3% more damage.', 5, 0, 0, 12, 803, 3, 0),
(80302, 8, 803, 1, 2, 'Spell_Frost_FrostWard', 'Frost Warding', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(80303, 8, 803, 1, 3, 'Spell_Shadow_DarkRitual', 'Arctic Reach', '+4% Area. Your area spells cover more ground.', 3, 0, 0, 0, 10, 4, 0),
(80304, 8, 803, 2, 1, 'Spell_Frost_Wisp', 'Permafrost', 'Chill lasts 1 sec longer.', 3, 0, 0, 27, 0, 1, 0),
(80305, 8, 803, 2, 2, 'Spell_Frost_FrostBolt02', 'Improved Frostbolt', 'Frostbolt deals an additional 10% damage to Frozen enemies.', 3, 0, 0, 15, 400, 10, 0),
(80306, 8, 803, 3, 1, 'Spell_Frost_FreezingBreath', 'Improved Frost Nova', 'When you are struck, Frost Nova goes off around you. Can occur once every 6 sec.', 1, 0, 0, 21, 402, 6, 0),
(80307, 8, 803, 3, 2, 'Spell_Frost_Frost', 'Ice Block', 'Once per stage, when you drop below 20% health, you are encased in ice: you take no damage for 2 sec, and every enemy within 10 yd gains 5 stacks of Chill.', 1, 0, 0, 34, 0, 2, 0),
(80308, 8, 803, 4, 1, 'Spell_Frost_ChillingBlast', 'Winter''s Chill', '+3% critical strike chance against Chilled enemies.', 3, 0, 0, 14, 1, 3, 0),
(80309, 8, 803, 4, 2, 'Spell_Frost_Stun', 'Frost Channeling', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(80310, 8, 803, 5, 2, 'Spell_Frost_Glacier', 'Shatterlord', 'Your Chill freezes enemies at 3 stacks instead of 5. You deal 15% less damage to enemies that aren''t Frozen.', 1, 0, 0, 38, 9, 3, 0);

UPDATE `bonk_quest` SET `reward_type` = 1, `reward_value` = 3 WHERE `id` IN (141, 142, 143, 145, 146, 147, 148, 149, 150) AND `reward_type` = 6;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
