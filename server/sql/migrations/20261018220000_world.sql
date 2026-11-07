DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018220000');

DELETE FROM `bonk_mastery` WHERE `class` = 7;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 7;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(701, 7, 'Elemental', 'ShamanElementalCombat', 1),
(702, 7, 'Enhancement', 'ShamanEnhancement', 2),
(703, 7, 'Totemic', 'ShamanRestoration', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(70101, 7, 701, 1, 1, 'Spell_Fire_Fireball', 'Concussion', 'Elemental spells deal 3% more damage.', 5, 0, 0, 12, 701, 3, 0),
(70102, 7, 701, 1, 2, 'Spell_Nature_SpiritArmor', 'Elemental Warding', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(70103, 7, 701, 1, 3, 'Spell_Nature_WispSplode', 'Reverberation', '+4% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.', 3, 0, 0, 0, 10, 4, 0),
(70104, 7, 701, 2, 1, 'Spell_Nature_CallStorm', 'Call of Thunder', 'Static discharges deal 8% more damage.', 3, 0, 0, 13, 11, 8, 0),
(70105, 7, 701, 2, 2, 'Spell_Lightning_LightningBolt01', 'Lightning Mastery', 'Chain Lightning deals 5% more damage.', 3, 0, 0, 1, 701, 5, 0),
(70106, 7, 701, 3, 1, 'Spell_Nature_Earthquake', 'Improved Thunderstorm', 'When you are struck, Thunderstorm goes off around you. Can occur once every 6 sec.', 1, 0, 0, 21, 703, 6, 0),
(70107, 7, 701, 3, 2, 'Spell_Shadow_ManaBurn', 'Elemental Focus', 'When Lightning Bolt kills an enemy, it recharges at once.', 1, 0, 0, 18, 700, 1, 0),
(70108, 7, 701, 4, 1, 'Spell_Fire_Volcano', 'Elemental Fury', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(70109, 7, 701, 4, 2, 'Spell_Fire_ElementalDevastation', 'Elemental Devastation', '+3% critical strike chance against enemies with Static.', 3, 0, 0, 14, 11, 3, 0),
(70110, 7, 701, 5, 2, 'Spell_Nature_Lightning', 'Ascendance', 'Your Static discharges at 3 stacks instead of 5. You deal 15% less damage to enemies without Static.', 1, 0, 0, 38, 10, 1, 0),
(70201, 7, 702, 1, 1, 'Ability_Hunter_SwiftStrike', 'Weapon Mastery', 'Enhancement spells deal 3% more damage.', 5, 0, 0, 12, 702, 3, 0),
(70202, 7, 702, 1, 2, 'Spell_Nature_Cyclone', 'Improved Windfury Weapon', 'Windfury Weapon can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 704, 1, 0),
(70203, 7, 702, 1, 3, 'Spell_Shadow_GrimWard', 'Ancestral Knowledge', '+3% maximum health.', 3, 0, 0, 0, 4, 3, 0),
(70204, 7, 702, 2, 1, 'Spell_Fire_FlameTounge', 'Elemental Weapons', 'Windfury Weapon deals 5% more damage.', 3, 0, 0, 1, 704, 5, 0),
(70205, 7, 702, 2, 2, 'Ability_Parry', 'Spirit Weapons', 'Your spirit wolves and totems have 3% more critical strike chance.', 3, 0, 0, 30, 0, 3, 0),
(70206, 7, 702, 3, 1, 'Spell_Nature_UnyeildingStamina', 'Shamanistic Rage', 'When you are struck, Stormstrike lashes out at every enemy around you. Can occur once every 6 sec.', 1, 0, 0, 21, 705, 6, 0),
(70207, 7, 702, 3, 2, 'Spell_Shadow_UnholyFrenzy', 'Unleashed Rage', 'When Stormstrike kills an enemy, it recharges at once.', 1, 0, 0, 18, 705, 1, 0),
(70208, 7, 702, 4, 1, 'Ability_ThunderBolt', 'Thundering Strikes', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(70209, 7, 702, 4, 2, 'Spell_Nature_Windfury', 'Gale Winds', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(70210, 7, 702, 5, 2, 'Spell_Nature_BloodLust', 'Doomhammer', 'Windfury Weapon calls Windfury every 2nd swing instead of every 3rd, and Maelstrom Weapon needs 3 melee hits instead of 5. Your maximum health is reduced by 15%.', 1, 0, 0, 38, 11, 1, 0),
(70301, 7, 703, 1, 1, 'Spell_Nature_MoonGlow', 'Totemic Focus', 'Totemic spells deal 3% more damage.', 5, 0, 0, 12, 703, 3, 0),
(70302, 7, 703, 1, 2, 'Spell_Fire_SearingTotem', 'Improved Searing Totem', 'Searing Totem can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 708, 1, 0),
(70303, 7, 703, 1, 3, 'Spell_Nature_UndyingStrength', 'Ancestral Healing', 'Regain 0.1% of your health every second.', 3, 0, 0, 0, 5, 0.1, 0),
(70304, 7, 703, 2, 1, 'Spell_Fire_Immolation', 'Call of Flame', 'Your Burning deals 8% more damage.', 3, 0, 0, 13, 3, 8, 0),
(70305, 7, 703, 2, 2, 'Spell_Fire_SealOfFire', 'Improved Fire Totems', 'Searing Totem deals 5% more damage.', 3, 0, 0, 1, 708, 5, 0),
(70306, 7, 703, 3, 1, 'Spell_Nature_StoneClawTotem', 'Ancestral Fortitude', 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.', 1, 0, 0, 33, 0, 30, 0),
(70307, 7, 703, 3, 2, 'Spell_Fire_LavaSpawn', 'Lava Flows', 'When a Burning enemy dies, its Burning spreads to 1 additional nearby enemy.', 1, 0, 0, 28, 3, 1, 0),
(70308, 7, 703, 4, 1, 'Spell_Nature_StoneSkinTotem', 'Totemic Reach', '+4% Area. Your area spells, explosions, cones and melee swings cover more ground, and your pets grow larger.', 3, 0, 0, 0, 10, 4, 0),
(70309, 7, 703, 4, 2, 'Spell_Frost_ManaRecharge', 'Tidal Focus', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(70310, 7, 703, 5, 2, 'Spell_Nature_NullWard', 'Totemic Mastery', 'Each of your totem spells plants 1 additional totem. Your Power is reduced by 15%.', 1, 0, 0, 38, 12, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 169 AND 177 OR `id` = 258;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(169, 'Farseer', 'Win a run on Normal as a shaman.', 'Spell_Nature_BloodLust', 3, 1, 0, 2, 6, 1, 7, 2),
(170, 'Stormcaller', 'Kill 3,000 enemies with Lightning Bolt as a shaman.', 'Spell_Nature_Lightning', 2, 700, 0, 3000, 6, 1, 7, 2),
(171, 'Windwalker', 'Kill 3,000 enemies with Windfury Weapon as a shaman.', 'Spell_Nature_Cyclone', 2, 704, 0, 3000, 6, 1, 7, 2),
(172, 'Totem Carver', 'Kill 3,000 enemies with Searing Totem as a shaman.', 'Spell_Fire_SearingTotem', 2, 708, 0, 3000, 6, 1, 7, 2),
(173, 'Spiritwalker', 'Kill 60 elites as a shaman.', 'Spell_Nature_SpiritWolf', 1, 1, 0, 60, 6, 1, 7, 2),
(174, 'Seer', 'Reach level 50 in a single run as a shaman.', 'Spell_Nature_Farsight', 4, 0, 0, 50, 6, 1, 7, 2),
(175, 'Earthen Ring', 'Clear stage 1 on Heroic as a shaman.', 'Spell_Nature_EarthShock', 3, 3, 0, 2, 6, 1, 7, 2),
(176, 'Warchief''s Herald', 'Win a run on Heroic as a shaman.', 'Spell_Nature_StormReach', 3, 3, 0, 3, 6, 1, 7, 2),
(177, 'Stormlord', 'Clear stage 1 on Mythic as a shaman.', 'Spell_Nature_CallStorm', 3, 2, 0, 2, 6, 1, 7, 2),
(258, 'Seasoned Shaman', 'Reach Mastery level 10 with a shaman.', 'Spell_Nature_SpiritWolf', 16, 7, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
