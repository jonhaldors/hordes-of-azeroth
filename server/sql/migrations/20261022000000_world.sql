DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022000000');

UPDATE `bonk_weapon` SET `behavior_value` = 10 WHERE `id` = 804;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 815 AND 840;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 815 AND 840;

DROP TEMPORARY TABLE IF EXISTS `bonk_paladin_evolution`;
CREATE TEMPORARY TABLE `bonk_paladin_evolution` (
    `id` INT UNSIGNED NOT NULL PRIMARY KEY,
    `base` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `icon` VARCHAR(64) NOT NULL,
    `description` VARCHAR(1024) NOT NULL
);
INSERT INTO `bonk_paladin_evolution` VALUES
(815, 800, 'Crusader''s Zeal', 'Spell_Holy_SealOfFury', 'Strikes the 2 nearest enemies with a heavy blow, each strike also dealing 50% of its damage to enemies within 5 yards of the target.'),
(816, 800, 'Avenging Crusader', 'Spell_Holy_Power', 'Strikes the nearest enemy with a heavy blow, also dealing 30% of its damage to enemies within 5 yards of the target. Each strike has a 15% chance to hurl a Hammer of Wrath at the target, dealing the strike''s damage again. Normal enemies below 20% health are slain by it.'),
(817, 801, 'Judgement of Light', 'Spell_Holy_Heal', 'A hammer of light slams the 3 strongest enemies within 20 yards for Holy damage, and critically strikes twice as often. Heals you for 1% of your maximum health for each enemy hit, up to 5%, with or without Seal of Light. Releases your other Seals as Judgement does.'),
(818, 801, 'Judgement of the Crusader', 'Spell_Holy_HolySmite', 'A hammer of light slams the 3 strongest enemies within 20 yards for Holy damage, and critically strikes twice as often. Judged enemies take 20% more damage from you for 6 seconds. Releases your Seals as Judgement does.'),
(819, 802, 'Seal of the Crusader', 'Spell_Holy_SealOfValor', 'Every 2nd strike from your other Paladin spells releases a burst of light that deals Holy damage to its target and every enemy within 5 yards of it.'),
(820, 802, 'Seal of Justice', 'Spell_Holy_SealOfSacrifice', 'Every 3rd strike from your other Paladin spells releases a burst of light that deals Holy damage to its target and every enemy within 5 yards of it, and stuns normal and elite enemies for 1 second.'),
(821, 803, 'Seal of the Templar', 'Spell_Holy_RighteousnessAura', 'Every hit from your other Paladin spells, including splash and area hits, also deals 40% of its damage as Holy damage.'),
(822, 803, 'Seal of Vengeance', 'Spell_Holy_Retribution', 'Every hit from your other Paladin spells, including splash and area hits, also deals 20% of its damage as Holy damage. Each hit on the same enemy makes this Holy damage 20% stronger, up to 5 times.'),
(823, 804, 'Hallowed Ground', 'Spell_Holy_PowerInfusion', 'Consecrates the ground beneath you for 12 sec, dealing Holy damage every sec to enemies standing on it. Up to 3 grounds at once. While you stand on it, you deal 25% more damage.'),
(824, 804, 'Blessed Ground', 'Spell_Holy_Restoration', 'Consecrates the ground beneath you for 8 sec, dealing Holy damage every sec to enemies standing on it. While you stand on it, you deal 15% more damage and heal for 0.5% of your maximum health every sec.'),
(825, 805, 'Mass Exorcism', 'Spell_Holy_Excorcism', 'Strikes the 3 strongest enemies within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double. When another Paladin spell critically strikes, Mass Exorcism strikes at once, at most once every 1 sec.'),
(826, 805, 'The Art of War', 'Spell_Holy_SearingLight', 'Strikes the strongest enemy within 30 yards for heavy Holy damage, and every enemy within 5 yards of it for half. Undead and Demons take triple damage, elites and bosses double. When another Paladin spell critically strikes, it strikes at once, at most once every 0.5 sec.'),
(827, 806, 'Divine Tempest', 'Spell_Holy_HolyNova', 'A storm of holy light bursts around you, dealing Holy damage to every enemy within 14 yards. Heals you for 0.5% of your maximum health for each enemy hit, up to 5%.'),
(828, 806, 'Wake of Ashes', 'Spell_Holy_AshesToAshes', 'A storm of holy light bursts around you, dealing Holy damage to every enemy within 10 yards and slowing normal enemies by 50%. Undead and Demons are stunned for 1 second. Heals you for 0.5% of your maximum health for each enemy hit, up to 3%.'),
(829, 807, 'Lay on Hands', 'Spell_Holy_LayOnHands', 'Every strike from your other Paladin spells heals you for 0.5% of your maximum health, at most 6 times a sec. When you fall below 30% health, you are healed to full. Can occur once every 90 sec.'),
(830, 807, 'Illumination', 'Spell_Holy_GreaterHeal', 'Every strike from your other Paladin spells heals you for 0.5% of your maximum health, at most 6 times a sec. Critical strikes heal three times as much.'),
(831, 809, 'Ardent Defender', 'Spell_Holy_BlessingOfProtection', 'Every 30 sec, protects you from all damage for 3 sec. Also protects you at once when you fall below 30% health, at most once every 30 sec.'),
(832, 809, 'Holy Shield', 'Spell_Holy_SealOfProtection', 'Every 30 sec, protects you from all damage for 3 sec. While protected, enemies that strike you take Holy damage.'),
(833, 810, 'Sanctity Aura', 'Spell_Holy_MindVision', 'Every sec, deals Holy damage to every enemy within 14 yards of you. Enemies that strike you take twice as much.'),
(834, 810, 'Devotion Aura', 'Spell_Holy_DevotionAura', 'Every sec, deals Holy damage to every enemy within 10 yards of you. Enemies that strike you take twice as much. You take 10% less damage.'),
(835, 811, 'Hammer of the Righteous', 'INV_Hammer_04', 'Hurls a hammer at the strongest enemy within 20 yards, dealing Holy damage to it and every enemy within 6 yards of it, and stunning the target for 2 sec. Bosses are not stunned.'),
(836, 811, 'Repentance', 'Spell_Holy_TurnUndead', 'Hurls hammers at the 3 strongest enemies within 20 yards, dealing Holy damage and stunning them for 2 sec. Bosses are not stunned.'),
(837, 812, 'Shake the Heavens', 'INV_Hammer_01', 'Every 3 sec, hammers of light fall from the sky on 5 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards of where it lands.'),
(838, 812, 'Hammer of Light', 'Spell_Holy_HolyBolt', 'Hammers of light fall from the sky on 3 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards of where it lands. Every 3rd time, a giant hammer also falls on the largest group of enemies, dealing triple damage within 10 yards.'),
(839, 813, 'Executioner', 'Spell_Holy_BlessingOfStrength', 'Hurls hammers at up to 3 enemies below 35% health within 30 yards. Normal enemies are slain; elites and bosses take heavy Holy damage.'),
(840, 813, 'Sanctified Wrath', 'Spell_Holy_ElunesGrace', 'Hurls hammers at up to 3 enemies below 20% health within 30 yards. Normal enemies are slain; elites and bosses take heavy Holy damage. Each hammer bursts on impact, dealing half its damage to enemies within 5 yards.');

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`)
SELECT `e`.`id`, `e`.`name`, `e`.`icon`, `e`.`description`, `b`.`spell_id`, `b`.`target`, `b`.`cooldown_ms`, `b`.`range`,
    `b`.`damage_fraction`, `b`.`class_mask`, 0, 0,
    `e`.`base`, `b`.`heal_pct`, `b`.`duration_ms`, `b`.`chains`, `b`.`behavior`, `b`.`behavior_value`, `b`.`tick_ms`,
    `b`.`base_targets`, `b`.`alt_spell_id`, `b`.`alt_every`, `b`.`alt_damage`, `b`.`base_jumps`, `b`.`kill_below_pct`,
    `b`.`flags`, `b`.`applies`, `b`.`apply_stacks`, `b`.`uses`, `b`.`uses_pct`, 0
FROM `bonk_paladin_evolution` `e` JOIN `bonk_weapon` `b` ON `b`.`id` = `e`.`base`;

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `e`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_paladin_evolution` `e` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `e`.`base`;
DROP TEMPORARY TABLE `bonk_paladin_evolution`;

UPDATE `bonk_weapon` SET `base_targets` = 2 WHERE `id` = 815;
UPDATE `bonk_weapon` SET `base_targets` = 3 WHERE `id` IN (825, 836);
UPDATE `bonk_weapon` SET `range` = 14 WHERE `id` IN (827, 833);
UPDATE `bonk_weapon` SET `damage_fraction` = 1.0 WHERE `id` = 832;
UPDATE `bonk_weapon` SET `base_targets` = 5, `cooldown_ms` = 3000 WHERE `id` = 837;

DELETE FROM `bonk_mastery` WHERE `class` = 2;
DELETE FROM `bonk_mastery_tree` WHERE `class` = 2;
INSERT INTO `bonk_mastery_tree` (`id`, `class`, `name`, `background`, `order`) VALUES
(201, 2, 'Holy', 'PaladinHoly', 1),
(202, 2, 'Protection', 'PaladinProtection', 2),
(203, 2, 'Retribution', 'PaladinCombat', 3);

INSERT INTO `bonk_mastery` (`id`, `class`, `tree`, `row`, `column`, `icon`, `name`, `description`, `max_rank`, `required_id`, `required_rank`, `effect`, `target`, `value_per_rank`, `param`) VALUES
(20101, 2, 201, 1, 1, 'Spell_Holy_HolyBolt', 'Healing Light', 'Holy spells deal 3% more damage.', 5, 0, 0, 12, 201, 3, 0),
(20102, 2, 201, 1, 2, 'Spell_Holy_Excorcism_02', 'Improved Exorcism', 'Exorcism deals 5% more damage.', 3, 0, 0, 1, 805, 5, 0),
(20103, 2, 201, 1, 3, 'Spell_Holy_ElunesGrace', 'Divine Intellect', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(20104, 2, 201, 2, 1, 'Spell_Holy_FistOfJustice', 'Improved Light''s Hammer', 'Light''s Hammer recharges 8% faster.', 3, 0, 0, 3, 812, 8, 0),
(20105, 2, 201, 2, 2, 'Spell_Holy_HealingAura', 'Spiritual Focus', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(20106, 2, 201, 3, 1, 'Spell_Holy_Purify', 'Divine Favor', 'Light''s Hammer drops 1 additional hammer.', 1, 0, 0, 4, 812, 1, 0),
(20107, 2, 201, 3, 2, 'Spell_Holy_TurnUndead', 'Holy Guidance', 'Exorcism recharges 15% faster.', 1, 0, 0, 3, 805, 15, 0),
(20108, 2, 201, 4, 1, 'Spell_Holy_PowerInfusion', 'Sanctified Light', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(20109, 2, 201, 4, 2, 'Spell_Holy_Restoration', 'Purifying Power', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(20110, 2, 201, 5, 2, 'Spell_Holy_SearingLight', 'Divine Illumination', 'Exorcism strikes 2 additional enemies, and Art of War can fire it every 0.5 sec. Your Power is reduced by 15%.', 1, 0, 0, 38, 19, 1, 0),
(20201, 2, 202, 1, 1, 'Spell_Holy_DevotionAura', 'Redoubt', 'Protection spells deal 3% more damage.', 5, 0, 0, 12, 202, 3, 0),
(20202, 2, 202, 1, 2, 'Spell_Holy_InnerFire', 'Improved Consecration', 'Consecration can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 804, 1, 0),
(20203, 2, 202, 1, 3, 'Spell_Holy_Devotion', 'Toughness', '+3 Armor.', 3, 0, 0, 0, 12, 3, 0),
(20204, 2, 202, 2, 1, 'Spell_Holy_AuraOfLight', 'Improved Retribution Aura', 'Retribution Aura deals 5% more damage.', 3, 0, 0, 1, 810, 5, 0),
(20205, 2, 202, 2, 2, 'Spell_Holy_SealOfMight', 'Improved Hammer of Justice', 'Hammer of Justice recharges 8% faster.', 3, 0, 0, 3, 811, 8, 0),
(20206, 2, 202, 3, 1, 'Spell_Holy_DivineIntervention', 'Improved Divine Shield', 'Divine Shield recharges 15% faster.', 1, 0, 0, 3, 809, 15, 0),
(20207, 2, 202, 3, 2, 'Spell_Holy_BlessingOfProtection', 'Blessing of Sanctuary', 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.', 1, 0, 0, 33, 0, 30, 0),
(20208, 2, 202, 4, 1, 'Spell_Holy_MagicalSentry', 'Anticipation', '+2% chance to dodge enemy swings.', 3, 0, 0, 0, 14, 2, 0),
(20209, 2, 202, 4, 2, 'Spell_Holy_MindVision', 'Sacred Duty', '+3% Area.', 3, 0, 0, 0, 10, 3, 0),
(20210, 2, 202, 5, 2, 'Spell_Holy_SealOfProtection', 'Guardian of the Light', 'While you stand on your Consecration, you take 20% less damage. Your Power is reduced by 15%.', 1, 0, 0, 38, 20, 1, 0),
(20301, 2, 203, 1, 1, 'Spell_Holy_RighteousFury', 'Conviction', 'Retribution spells deal 3% more damage.', 5, 0, 0, 12, 203, 3, 0),
(20302, 2, 203, 1, 2, 'Spell_Holy_SealOfWrath', 'Improved Divine Storm', 'Divine Storm can be your starter spell. Choose it at the Run Master.', 1, 0, 0, 5, 806, 1, 0),
(20303, 2, 203, 1, 3, 'Spell_Holy_BlessingOfStrength', 'Vengeance', '+2% critical strike chance.', 3, 0, 0, 0, 15, 2, 0),
(20304, 2, 203, 2, 1, 'Spell_Holy_HolySmite', 'Improved Crusader Strike', 'Crusader Strike deals 5% more damage.', 3, 0, 0, 1, 800, 5, 0),
(20305, 2, 203, 2, 2, 'Spell_Holy_RighteousnessAura', 'Improved Judgement', 'Judgement recharges 8% faster.', 3, 0, 0, 3, 801, 8, 0),
(20306, 2, 203, 3, 1, 'Ability_Warrior_InnerRage', 'Improved Seal of Command', 'Seal of Command deals 15% more damage.', 1, 0, 0, 1, 802, 15, 0),
(20307, 2, 203, 3, 2, 'Spell_Holy_SealOfFury', 'Crusade', 'Crusader Strike strikes 1 additional enemy.', 1, 0, 0, 4, 800, 1, 0),
(20308, 2, 203, 4, 1, 'Spell_Holy_Retribution', 'Fanaticism', 'Your critical strikes deal 10% more damage.', 3, 0, 0, 0, 16, 10, 0),
(20309, 2, 203, 4, 2, 'Spell_Holy_SealOfValor', 'Swift Retribution', '+2% Haste.', 3, 0, 0, 0, 1, 2, 0),
(20310, 2, 203, 5, 2, 'Spell_Holy_Power', 'Templar''s Verdict', 'Every 5th Crusader Strike is a Templar''s Verdict: triple damage that hits every enemy within 5 yards of the target in full. Your critical strike chance is reduced by 10%.', 1, 0, 0, 38, 21, 1, 0);

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 270 AND 279;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(270, 'Squire', 'Win a run on Normal as a paladin.', 'Spell_Holy_HolySmite', 3, 1, 0, 2, 6, 1, 2, 2),
(271, 'Crusader', 'Kill 3,000 enemies with Crusader Strike as a paladin.', 'Spell_Holy_HolySmite', 2, 800, 0, 3000, 6, 1, 2, 2),
(272, 'Hammer of the Light', 'Kill 3,000 enemies with Light''s Hammer as a paladin.', 'Spell_Holy_FistOfJustice', 2, 812, 0, 3000, 6, 1, 2, 2),
(273, 'Consecrator', 'Kill 3,000 enemies with Consecration as a paladin.', 'Spell_Holy_InnerFire', 2, 804, 0, 3000, 6, 1, 2, 2),
(274, 'Exorcist', 'Kill 60 elites as a paladin.', 'Spell_Holy_Excorcism_02', 1, 1, 0, 60, 6, 1, 2, 2),
(275, 'Knight of the Silver Hand', 'Reach level 50 in a single run as a paladin.', 'Spell_Holy_SealOfValor', 4, 0, 0, 50, 6, 1, 2, 2),
(276, 'Argent Initiate', 'Clear stage 1 on Heroic as a paladin.', 'Spell_Holy_DevotionAura', 3, 3, 0, 2, 6, 1, 2, 2),
(277, 'Champion of the Light', 'Win a run on Heroic as a paladin.', 'Spell_Holy_Power', 3, 3, 0, 3, 6, 1, 2, 2),
(278, 'Highlord', 'Clear stage 1 on Mythic as a paladin.', 'Spell_Holy_DivineIntervention', 3, 2, 0, 2, 6, 1, 2, 2),
(279, 'Seasoned Paladin', 'Reach Mastery level 10 with a paladin.', 'Spell_Holy_SealOfMight', 16, 2, 0, 10, 1, 5, 0, 2);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
