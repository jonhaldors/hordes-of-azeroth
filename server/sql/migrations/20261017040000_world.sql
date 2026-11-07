DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017040000');

ALTER TABLE `bonk_weapon_upgrade` MODIFY `upgrade` tinyint(3) unsigned NOT NULL COMMENT 'BonkSpellUpgrade: 1 spell cleave, 2 hit twice, 3 Haste, 4 retired (radius), 5 duration, 6 Mark strength, 7 summon damage, 8 summon size, 9 +1 stack applied, 10 damage taken when slowed, 11 frenzy damage, 12 deploy range, 13 trap radius, 14 Shield size, 15 internal cooldown';

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 300 AND 310;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 300 AND 310;
INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`, `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`) VALUES
(300, 'Cleave', 'Ability_Warrior_Cleave', 'Strikes all enemies within 5 yards of you.', 12723, 1, 1500, 5, 0.55, 1, 1, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(301, 'Rend', 'Ability_Gouge', 'Wounds the 3 nearest enemies within 10 yards, applying 3 stacks of Bleed to each.', 13318, 0, 1500, 10, 0, 1, 0, 0, 0, 0, 0, 0, 0, 0, 3, 0, 0, 1, 0, 0, 32768, 4, 3, 0, 0),
(302, 'Deep Wounds', 'Ability_CriticalStrike', 'Your critical strikes wound the enemy, applying 2 stacks of Bleed. Can occur once every 0.5 sec on each enemy.', 12162, 7, 500, 0, 0, 1, 0, 0, 0, 0, 0, 33, 0, 0, 1, 0, 0, 1, 0, 0, 0, 4, 2, 0, 0),
(303, 'Mortal Strike', 'Ability_Warrior_SavageBlow', 'Strikes all enemies within 8 yards of you. Deals 8% more damage to each enemy for each stack of Bleed on it, counting up to 25 stacks.', 13446, 1, 6000, 8, 2, 1, 0, 0, 0, 0, 0, 0, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 4, 8),
(304, 'Bloodthirst', 'Spell_Shadow_BloodBoil', 'Strikes the 3 nearest enemies within 8 yards and heals you for 1% of your maximum health for each enemy hit. Its critical strikes Enrage you. Enrage gives you 25% Haste for 4 sec.', 23881, 0, 2000, 8, 1, 1, 0, 0, 1, 0, 0, 34, 0, 0, 3, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(305, 'Execute', 'INV_Sword_48', 'Strikes all enemies within 8 yards of you. Normal enemies below 20% health die instantly; elites and bosses below 20% health take triple damage instead. Each kill Enrages you, or refreshes your Enrage. Enrage gives you 25% Haste for 4 sec.', 24316, 1, 2500, 8, 0.7, 1, 0, 0, 0, 0, 0, 11, 20, 0, 1, 0, 0, 3, 0, 20, 0, 0, 0, 0, 0),
(306, 'Whirlwind', 'Ability_DualWield', 'Spins, striking all enemies within 8 yards of you. While you are Enraged, it spins twice. Bloodthirst and Execute Enrage you, giving you 25% Haste for 4 sec.', 15576, 1, 4000, 8, 1.1, 1, 0, 0, 0, 0, 0, 35, 400, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(307, 'Shield Block', 'Ability_Defend', 'Every 10 sec, gives you a Shield that absorbs damage equal to 10% of your maximum health. Your Shield from spells holds up to 50% of your maximum health.', 2565, 7, 10000, 0, 0, 1, 0, 0, 0, 0, 0, 4, 10, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(308, 'Thunder Clap', 'Spell_Nature_ThunderClap', 'Blasts all enemies within 8 yards of you with thunder. Enemies hit attack 20% slower for 6 sec.', 6343, 1, 3000, 8, 0.7, 1, 0, 0, 0, 6000, 0, 37, 20, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(309, 'Revenge', 'Ability_Warrior_Riposte', 'When you are struck, strikes all enemies within 6 yards of you. Can occur once every 2 sec.', 19632, 1, 2000, 6, 0.9, 1, 0, 0, 0, 0, 0, 17, 0, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0),
(310, 'Shield Slam', 'INV_Shield_05', 'Slams all enemies within 6 yards of you. Deals 2% more damage for each 1% of your maximum health held in your Shield, up to 200% more.', 20240, 1, 5000, 6, 1.4, 1, 0, 0, 0, 0, 0, 36, 2, 0, 1, 0, 0, 1, 0, 0, 0, 0, 0, 0, 0);

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(300, 3, 8), (300, 2, 10),
(301, 9, 1), (301, 5, 15), (301, 3, 8),
(302, 15, 8), (302, 9, 1), (302, 5, 15),
(303, 3, 8), (303, 2, 10),
(304, 3, 8), (304, 2, 10),
(305, 3, 8), (305, 2, 10),
(306, 3, 8), (306, 2, 10),
(307, 14, 15), (307, 3, 8),
(308, 3, 8), (308, 2, 10),
(309, 15, 8), (309, 2, 10),
(310, 3, 8), (310, 2, 10);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
