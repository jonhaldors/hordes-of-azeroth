DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021100000');

DELETE FROM `bonk_keyword` WHERE `id` = 14;
INSERT INTO `bonk_keyword` (`id`, `name`, `icon`, `spell_id`, `max_stacks`, `value_per_stack`, `tick_ms`, `duration_ms`, `spreads_on_death`, `description`) VALUES
(14, 'Judged', 'Spell_Holy_RighteousFury', 20183, 1, 0, 0, 10000, 0,
    'Judged by a Paladin for 10 sec. The Paladin''s Seals decide what the brand does. When a Judged enemy dies, the brand passes to the 2 nearest enemies within 10 yards. At most 30 enemies can be Judged at once.');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 800 AND 812;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 800 AND 812;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`) VALUES
(800, 'Crusader Strike', 'Spell_Holy_SealOfFury', 'Strikes the nearest enemy with a heavy blow, also dealing 30% of its damage to enemies within 5 yards of the target.',
    17281, 0, 1500, 10, 2.4, 2, 0, 2, 0, 0, 0, 0, 105, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 203),
(801, 'Judgement', 'Spell_Holy_RighteousFury', 'Passes judgement on the largest group of enemies within 25 yards, dealing Holy damage to every enemy within 8 yards of its center and leaving them Judged for 10 sec.',
    20271, 1, 6000, 25, 1.6, 2, 2, 0, 0, 0, 0, 0, 106, 8, 0, 1, 0, 0, 1, 0, 0, 67108864, 14, 0, 0, 0, 203),
(802, 'Seal of Command', 'Ability_Warrior_InnerRage', 'Your Crusader Strike and Exorcism also strike every Judged enemy within 15 yards for Holy damage.',
    20424, 7, 1000, 0, 0.6, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 14, 0, 203),
(803, 'Seal of Righteousness', 'Spell_Holy_RighteousnessAura', 'Judged enemies take 25% more damage from you.',
    20293, 7, 1000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 14, 0, 203),
(804, 'Consecration', 'Spell_Holy_InnerFire', 'Consecrates the ground beneath you for 8 sec, dealing Holy damage every sec to enemies standing on it. While you stand on it, you deal 15% more damage.',
    26573, 1, 8000, 8, 0.3, 2, 0, 2, 0, 0, 0, 0, 108, 8, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 0, 0, 201),
(805, 'Exorcism', 'Spell_Holy_Excorcism_02', 'Strikes the strongest enemy within 30 yards for heavy Holy damage. Undead and Demons take triple damage, elites and bosses double.',
    10314, 4, 6000, 30, 5.0, 2, 0, 0, 0, 0, 0, 0, 109, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201),
(806, 'Holy Wrath', 'Spell_Holy_Excorcism', 'Holy light erupts from every Judged enemy within 30 yards, dealing Holy damage to it and to every enemy within 5 yards of it.',
    2812, 1, 8000, 30, 1.6, 2, 0, 0, 0, 0, 0, 0, 110, 5, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 14, 0, 201),
(807, 'Seal of Light', 'Spell_Holy_HealingAura', 'Each hit on a Judged enemy heals you for 0.2% of your maximum health, and your Crusader Strike and Exorcism heal you for 0.5%.',
    20165, 7, 1000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 14, 0, 201),
(808, 'Lay on Hands', 'Spell_Holy_LayOnHands', 'When you fall below 30% health, heals you to full. Can occur once every 90 sec.',
    633, 7, 90000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 114, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 201),
(809, 'Divine Shield', 'Spell_Holy_DivineIntervention', 'Every 30 sec, protects you from all damage for 3 sec.',
    642, 7, 30000, 0, 0, 2, 0, 0, 0, 0, 3000, 0, 113, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0, 202),
(810, 'Sanctity Aura', 'Spell_Holy_MindVision', 'Every sec, deals Holy damage to every Judged enemy within 10 yards of you.',
    20218, 1, 1000, 10, 0.35, 2, 0, 0, 0, 0, 0, 0, 111, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 14, 0, 202),
(811, 'Hammer of Justice', 'Spell_Holy_SealOfMight', 'Hurls a hammer at every Judged enemy within 20 yards, dealing Holy damage and stunning them for 1 sec. Bosses are not stunned.',
    853, 1, 10000, 20, 0.8, 2, 0, 0, 0, 0, 0, 0, 112, 0, 0, 1, 0, 0, 1, 0, 0, 67108864, 0, 0, 14, 0, 202),
(812, 'Seal of Justice', 'Spell_Holy_SealOfWrath', 'Judged enemies are slowed by 30% and deal 20% less damage to you.',
    20164, 7, 1000, 0, 0, 2, 0, 0, 0, 0, 0, 0, 107, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 14, 0, 202);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(800, 2, 10), (800, 3, 8),
(801, 3, 8), (801, 5, 15),
(802, 2, 10),
(804, 3, 8), (804, 5, 15),
(805, 1, 10), (805, 2, 10), (805, 3, 8),
(806, 3, 8),
(808, 3, 8),
(809, 3, 8), (809, 5, 15),
(810, 3, 8),
(811, 3, 8);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
