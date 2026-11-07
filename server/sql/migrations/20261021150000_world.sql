DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021150000');

DELETE FROM `bonk_keyword` WHERE `id` = 14;
UPDATE `spell_template` SET `spellFamilyName` = 10, `spellFamilyFlags` = 1048576, `baseLevel` = 16, `customFlags` = `customFlags` | 256 WHERE `entry` = 20183;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 800 AND 814;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 800 AND 814;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(800, 'Crusader Strike', 'Spell_Holy_HolySmite', 'Strikes the nearest enemy with a heavy blow, also dealing 30% of its damage to enemies within 5 yards of the target.',
    17281, 0, 1500, 10, 2.4, 2, 2, 0, 0, 0, 0, 0, 105, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(801, 'Judgement', 'Spell_Holy_RighteousFury', 'A hammer of light slams the 3 strongest enemies within 20 yards for Holy damage. Releases your Seals: Righteousness adds 50% damage, Command strikes every enemy within 5 yards of each target for half damage, Light heals you for 1% of your maximum health for each enemy hit.',
    20271, 4, 8000, 20, 3.0, 2, 0, 0, 0, 0, 0, 0, 106, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(802, 'Seal of Command', 'Ability_Warrior_InnerRage', 'Every 3rd strike from your other Paladin spells releases a burst of light that deals Holy damage to its target and every enemy within 5 yards of it.',
    20424, 7, 1000, 0, 1.2, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(803, 'Seal of Righteousness', 'Ability_ThunderBolt', 'Every strike from your other Paladin spells also deals Holy damage.',
    20293, 7, 1000, 0, 0.4, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(804, 'Consecration', 'Spell_Holy_InnerFire', 'Consecrates the ground beneath you for 8 sec, dealing Holy damage every sec to enemies standing on it. While you stand on it, you deal 15% more damage.',
    26573, 1, 8000, 8, 0.3, 2, 0, 2, 0, 0, 0, 0, 108, 8, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 202),
(805, 'Exorcism', 'Spell_Holy_Excorcism_02', 'Strikes the strongest enemy within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double.',
    10314, 4, 6000, 30, 5.0, 2, 0, 0, 0, 0, 0, 0, 109, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201),
(806, 'Holy Wrath', 'Spell_Holy_Excorcism', 'Holy light erupts around you, dealing Holy damage to every enemy within 10 yards. Undead and Demons are stunned for 1 sec.',
    2812, 1, 8000, 10, 2.0, 2, 0, 2, 0, 0, 0, 0, 110, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 201),
(807, 'Seal of Light', 'Spell_Holy_HealingAura', 'Every strike from your other Paladin spells heals you for 0.5% of your maximum health, at most 6 times a sec.',
    20165, 7, 1000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201),
(808, 'Lay on Hands', 'Spell_Holy_LayOnHands', 'When you fall below 30% health, heals you to full. Can occur once every 90 sec.',
    633, 7, 90000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 114, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201),
(809, 'Divine Shield', 'Spell_Holy_DivineIntervention', 'Every 30 sec, protects you from all damage for 3 sec.',
    642, 7, 30000, 0, 0, 2, 0, 0, 0, 0, 3000, 0, 113, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 202),
(810, 'Retribution Aura', 'Spell_Holy_AuraOfLight', 'Every sec, deals Holy damage to every enemy within 8 yards of you. Enemies that strike you take twice as much.',
    7294, 1, 1000, 8, 0.25, 2, 0, 0, 0, 0, 0, 0, 111, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 202),
(811, 'Hammer of Justice', 'Spell_Holy_SealOfMight', 'Hurls a hammer at the strongest enemy within 20 yards, dealing Holy damage and stunning it for 2 sec. Bosses are not stunned.',
    853, 4, 10000, 20, 2.0, 2, 0, 0, 0, 0, 0, 0, 112, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 202),
(813, 'Hammer of Wrath', 'Ability_ThunderClap', 'Hurls hammers at up to 3 enemies below 20% health within 30 yards. Normal enemies are slain; elites and bosses take heavy Holy damage.',
    24239, 0, 6000, 30, 3.0, 2, 0, 0, 0, 0, 0, 0, 115, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(814, 'Holy Shock', 'Spell_Holy_SearingLight', 'Shocks the nearest enemy within 20 yards with holy light. While you are hurt, it also heals you for 0.5% of your maximum health.',
    25902, 0, 2000, 20, 1.2, 2, 0, 0, 0, 0, 0, 0, 116, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(800, 2, 10), (800, 3, 8),
(801, 2, 10), (801, 3, 8),
(804, 3, 8), (804, 5, 15),
(805, 2, 10), (805, 3, 8),
(806, 3, 8),
(808, 3, 8),
(809, 3, 8), (809, 5, 15),
(810, 3, 8),
(811, 2, 10), (811, 3, 8),
(813, 2, 10), (813, 3, 8),
(814, 2, 10), (814, 3, 8);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
