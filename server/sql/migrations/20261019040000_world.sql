DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019040000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019040000');

DELETE FROM `spell_effect_mod` WHERE `Id` = 14914 AND `EffectIndex` = 1;
INSERT INTO `spell_effect_mod` (`Id`, `EffectIndex`, `Effect`, `EffectApplyAuraName`, `Comment`) VALUES
(14914, 1, 0, 0, 'Holy Fire: burns through Burning');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 512 AND 535;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 512 AND 535;

DROP TEMPORARY TABLE IF EXISTS `bonk_priest_evolution`;
CREATE TEMPORARY TABLE `bonk_priest_evolution` (
    `id` INT UNSIGNED NOT NULL PRIMARY KEY,
    `base` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `icon` VARCHAR(64) NOT NULL,
    `description` VARCHAR(1024) NOT NULL,
    `spell_id` INT UNSIGNED NULL,
    `applies` INT UNSIGNED NULL,
    `apply_stacks` INT UNSIGNED NULL
);
INSERT INTO `bonk_priest_evolution` VALUES
(512, 500, 'Holy Fire', 'Spell_Holy_SearingLight', 'Smites the nearest enemy with holy fire, dealing Holy damage and applying 3 stacks of Burning. Each Smite takes 1 sec off Holy Word: Chastise.', 14914, 3, 3),
(513, 500, 'Searing Light', 'Spell_Holy_HolyBolt', 'Smites the nearest enemy with Holy damage. Every 4th Smite also strikes all enemies within 6 yards of its target and stuns normal enemies for 1 sec. Each Smite takes 1 sec off Holy Word: Chastise.', NULL, NULL, NULL),
(514, 501, 'Echo of Light', 'Spell_Holy_FlashHeal', 'Heals you for 1% of your maximum health every second. While you are at full health, each tick instead smites the nearest enemy within 30 yards for Holy damage. All healing past full health, from any source, also smites the nearest enemy, at most twice a second.', NULL, NULL, NULL),
(515, 501, 'Prayer of Mending', 'Spell_Holy_HealingAura', 'Heals you for 1% of your maximum health every second. While you are at full health, each tick instead smites the nearest enemy within 30 yards for Holy damage, and the smite jumps to 2 additional nearby enemies.', NULL, NULL, NULL),
(516, 502, 'Divine Hymn', 'Spell_Holy_Restoration', 'A ring of light goes off 3 times over 2 sec, each dealing Holy damage to every enemy between 8 and 25 yards from you and healing you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 8 yards are not hit.', NULL, NULL, NULL),
(517, 502, 'Light''s Edge', 'Spell_Holy_InnerFire', 'A ring of light deals Holy damage to every enemy between 8 and 25 yards from you, up to 100% more the farther away they are, and heals you for 0.5% of your maximum health for each enemy hit, up to 5%. Enemies closer than 8 yards are not hit.', NULL, NULL, NULL),
(518, 503, 'Holy Word: Sanctify', 'Spell_Holy_DivineSpirit', 'The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage, strikes all enemies within 8 yards of it for half as much and heals you for 5% of your maximum health. Smite and Halo take 1 sec off its cooldown each time they are cast.', NULL, NULL, NULL),
(519, 503, 'Apotheosis', 'Spell_Holy_PowerInfusion', 'The Light strikes the strongest enemy nearby, elites first, for heavy Holy damage, and the cooldowns of Smite and Halo reset. Smite and Halo take 1 sec off its cooldown each time they are cast.', NULL, NULL, NULL),
(520, 504, 'Reflective Shield', 'Spell_Holy_BlessingOfProtection', 'Shields you for 10% of your maximum health. The Shield does not build up; each cast tops it back up. While you have a Shield, you move 10% faster. Damage the Shield absorbs is dealt back to the attacker as Holy damage.', NULL, NULL, NULL),
(521, 504, 'Power Word: Barrier', 'Spell_Holy_PowerWordShield', 'Shields you for 10% of your maximum health and raises a dome at your feet for 5 sec; you take 25% less damage while inside. The Shield does not build up; each cast tops it back up. While you have a Shield, you move 10% faster.', NULL, NULL, NULL),
(522, 505, 'Rapture', 'Spell_Holy_GreaterHeal', 'Fires 3 holy bolts at the enemies that struck you most recently, or 5 while you have a Shield. Each bolt heals you for 0.5% of your maximum health; healing past full health becomes Shield.', NULL, NULL, NULL),
(523, 505, 'Contrition', 'Spell_Holy_Excorcism', 'Fires 3 holy bolts at the enemies that struck you most recently. Each bolt also strikes enemies within 4 yards of its target for half as much, and heals you for 0.5% of your maximum health; healing past full health becomes Shield.', NULL, NULL, NULL),
(524, 506, 'Psychic Horror', 'Spell_Shadow_DeathScream', 'Normal enemies within 8 yards flee in fear for 2 seconds. Frightened enemies take 20% more damage. Elites, mini-bosses and bosses do not flee.', NULL, NULL, NULL),
(525, 506, 'Shadow Terror', 'Spell_Shadow_Requiem', 'Normal enemies within 8 yards flee in fear for 2 seconds and gain 3 stacks of Decay. Elites, mini-bosses and bosses do not flee.', NULL, NULL, NULL),
(526, 507, 'Chains of Light', 'Spell_Holy_SealOfWrath', 'Binds the strongest enemy nearby, elites first, in chains of light for 2 seconds and deals Holy damage to it. A bound enemy takes 30% more damage. Bosses and mini-bosses cannot be bound but still take the damage.', NULL, NULL, NULL),
(527, 507, 'Mass Shackle', 'Spell_Nature_Slow', 'Binds the 3 strongest enemies nearby, elites first, in chains of light for 2 seconds and deals Holy damage to them. Bosses and mini-bosses cannot be bound but still take the damage.', NULL, NULL, NULL),
(528, 508, 'Vampiric Touch', 'Spell_Shadow_LifeDrain02', 'Afflicts the 3 enemies farthest from you within 35 yards, applying 4 stacks of Decay. Your Decay damage heals you for 2% of the damage dealt, up to 1% of your maximum health a second.', NULL, NULL, NULL),
(529, 508, 'Misery', 'Spell_Shadow_AbominationExplosion', 'Afflicts the 3 enemies farthest from you within 35 yards, applying 4 stacks of Decay and 1 stack of Shadow Vulnerability.', NULL, NULL, NULL),
(530, 509, 'Mind Sear', 'Spell_Shadow_GatherShadows', 'Flays the mind of the nearest enemy every 0.5 seconds, dealing Shadow damage to it and half as much to every enemy within 6 yards of it, applying 1 stack of Decay and slowing it by 30%.', NULL, NULL, NULL),
(531, 509, 'Insanity', 'Spell_Shadow_ImpPhaseShift', 'Flays the mind of the nearest enemy every 0.5 seconds, dealing Shadow damage, applying 1 stack of Decay and slowing it by 30%. When the target dies, its Decay jumps to the next enemy you flay.', NULL, NULL, NULL),
(532, 510, 'Mind Spike', 'Spell_Shadow_ShadowWordDominate', 'Blasts the enemy with the most stacks of Decay for Shadow damage, and its mind shatters: every enemy within 8 yards of it gains as many stacks of Decay as it has, up to 10. Then its own Decay deals all its remaining damage at once.', NULL, NULL, NULL),
(533, 510, 'Void Eruption', 'Spell_Shadow_Shadowform', 'Blasts the enemy with the most stacks of Decay for Shadow damage, and its mind shatters: every enemy within 8 yards of it takes half as much Shadow damage and gains as many stacks of Decay as it has, up to 10.', NULL, NULL, NULL),
(534, 511, 'Mindbender', 'Spell_Shadow_Possession', 'Summons a Shadowfiend whose attacks apply Decay, strike all enemies within 5 yards of its target and heal you for 0.5% of your maximum health.', NULL, NULL, NULL),
(535, 511, 'Void Tendrils', 'Spell_Shadow_Twilight', 'Summons a Shadowfiend whose attacks apply Decay and heal you for 0.5% of your maximum health. Every 6 seconds, it roots all normal enemies within 6 yards of it for 2 seconds.', NULL, NULL, NULL);

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`)
SELECT `e`.`id`, `e`.`name`, `e`.`icon`, `e`.`description`, COALESCE(`e`.`spell_id`, `b`.`spell_id`), `b`.`target`, `b`.`cooldown_ms`, `b`.`range`,
    `b`.`damage_fraction`, `b`.`class_mask`, 0, 0,
    `e`.`base`, `b`.`heal_pct`, `b`.`duration_ms`, `b`.`chains`, `b`.`behavior`, `b`.`behavior_value`, `b`.`tick_ms`,
    `b`.`base_targets`, `b`.`alt_spell_id`, `b`.`alt_every`, `b`.`alt_damage`, `b`.`base_jumps`, `b`.`kill_below_pct`,
    `b`.`flags`, COALESCE(`e`.`applies`, `b`.`applies`), COALESCE(`e`.`apply_stacks`, `b`.`apply_stacks`), `b`.`uses`, `b`.`uses_pct`, 0
FROM `bonk_priest_evolution` `e` JOIN `bonk_weapon` `b` ON `b`.`id` = `e`.`base`;

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `e`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_priest_evolution` `e` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `e`.`base`;
DROP TEMPORARY TABLE `bonk_priest_evolution`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
