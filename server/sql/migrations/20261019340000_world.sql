DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019340000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019340000');

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 612 AND 635;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 612 AND 635;

DROP TEMPORARY TABLE IF EXISTS `bonk_rogue_evolution`;
CREATE TEMPORARY TABLE `bonk_rogue_evolution` (
    `id` INT UNSIGNED NOT NULL PRIMARY KEY,
    `base` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL,
    `icon` VARCHAR(64) NOT NULL,
    `description` VARCHAR(1024) NOT NULL
);
INSERT INTO `bonk_rogue_evolution` VALUES
(612, 600, 'Main Gauche', 'Ability_Parry', 'Stabs the nearest enemy every 0.6 seconds for Physical damage, and every stab is followed by an off-hand stab at a different enemy within 8 yards.'),
(613, 600, 'Saber Slash', 'Ability_Warrior_DecisiveStrike', 'Stabs the nearest enemy every 0.6 seconds for Physical damage. When a stab kills, it stabs the next nearest enemy at once, up to 3 times in a row.'),
(614, 601, 'Endless Flurry', 'Ability_Warrior_Cleave', 'Your single-target Rogue hits always strike 1 additional enemy within 8 yards. The extra hits carry your poisons and openers.'),
(615, 601, 'Shadow Blades', 'Spell_Shadow_ShadowWordDominate', 'For 8 seconds, your single-target Rogue hits also strike 4 additional enemies within 8 yards for Shadow damage. Every extra hit counts as a first hit for Ambush.'),
(616, 602, 'Coup de Grace', 'Ability_Rogue_KidneyShot', 'Guts the 5 nearest enemies for heavy Physical damage, with double the critical strike chance.'),
(617, 602, 'Deadly Throw', 'Ability_Rogue_Trip', 'Throws a blade at the strongest enemy within 30 yards, elites first, for heavy Physical damage with double the critical strike chance. Normal enemies hit are slowed by 50% for 3 seconds.'),
(618, 603, 'Murderous Intent', 'Ability_Rogue_FeignDeath', 'Strikes 14 times over 3 seconds, each strike at a random enemy within 10 yards. Each kill during the spree adds 2 strikes, up to 20 more.'),
(619, 603, 'Grand Finale', 'Ability_Rogue_Sprint', 'Strikes 14 times over 3 seconds, each strike at a random enemy within 10 yards. The last strike also fires Eviscerate and Envenom, if you hold them, without touching their cooldowns.'),
(620, 604, 'Toxic Blade', 'Spell_Nature_NullifyPoison', 'Stabs the nearest enemy with both daggers, each stab applying 1 stack of Poison and 2 stacks of Nature Vulnerability. Deals 30% more damage to Poisoned enemies.'),
(621, 604, 'Blindside', 'Ability_Gouge', 'Stabs the nearest enemy with both daggers, or 3 times against enemies below 35% health, each stab applying 1 stack of Poison. Deals 30% more damage to Poisoned enemies.'),
(622, 605, 'Crippling Poison', 'Spell_Nature_Slow', 'Every Rogue hit applies 1 stack of Poison and slows normal enemies by 30%. Poisoned enemies take 15% more damage from you.'),
(623, 605, 'Instant Poison', 'Ability_PoisonSting', 'Every Rogue hit applies 1 stack of Poison and also deals 30% of its damage as Nature damage at once.'),
(624, 606, 'Caltrops', 'Spell_Nature_SlowPoison', 'Throws knives in every direction, striking all enemies within 10 yards and applying 1 stack of Poison, and scatters caltrops at your feet for 4 seconds. Enemies in the caltrops are slowed and gain 1 stack of Poison every second.'),
(625, 606, 'Deadly Fan', 'INV_Weapon_ShortBlade_14', 'Throws knives in every direction, striking all enemies within 10 yards and applying 1 stack of Poison. Also throws whenever Eviscerate or Envenom fires.'),
(626, 607, 'Venom Splash', 'Spell_Shadow_DeathScream', 'Deals Nature damage to the enemy with the most Poison and every Poisoned enemy within 8 yards of it, and for 5 seconds your Rogue hits apply 2 additional stacks of Poison.'),
(627, 607, 'Exsanguinate', 'Ability_Rogue_Rupture', 'Deals Nature damage to the enemy with the most Poison, and every Poisoned enemy within 10 yards of it takes 4 seconds of its Poison damage at once, without losing any stacks. For 5 seconds your Rogue hits apply 2 additional stacks of Poison.'),
(628, 608, 'Shuriken Storm', 'INV_Weapon_ShortBlade_17', 'Throws 4 shurikens at the nearest enemies you have not hit yet, within 30 yards. Each shuriken jumps to 2 additional nearby enemies, ones you have not hit yet first.'),
(629, 608, 'Shadowy Shuriken', 'Spell_Shadow_SealOfKings', 'Throws 4 shurikens at the nearest enemies you have not hit yet, within 30 yards. A shadow stays where each one hits and bursts 1.5 seconds later for Shadow damage to enemies within 5 yards.'),
(630, 609, 'Cheap Shot', 'Ability_CheapShot', 'Your first Rogue hit on each enemy is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance. Ambush stuns normal enemies for 1 second.'),
(631, 609, 'Find Weakness', 'Ability_Warrior_Challange', 'Your first Rogue hit on each enemy is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance. Ambushed enemies take 20% more damage from you for 6 seconds.'),
(632, 610, 'Vanish', 'Ability_Vanish', 'For 4 seconds, your hits deal 30% more damage and every Rogue hit counts as a first hit for Ambush. The dance begins with a vanish: normal enemies within 10 yards lose you and stand dazed for 2 seconds.'),
(633, 610, 'Symbols of Death', 'Spell_Shadow_AntiShadow', 'For 4 seconds, your hits deal 30% more damage and every Rogue hit counts as a first hit for Ambush. The dance begins by striking the 5 strongest enemies within 20 yards with a shadow strike.'),
(634, 611, 'Riposte', 'Ability_Warrior_Riposte', 'For 5 seconds, you dodge 50% more attacks. Every attack you dodge strikes the attacker back.'),
(635, 611, 'Smoke Bomb', 'INV_Misc_Bomb_08', 'For 5 seconds, you dodge 50% more attacks, and a cloud of smoke at your feet makes enemy attacks miss you half the time while you stand in it.');

INSERT INTO `bonk_weapon` (`id`, `name`, `icon`, `description`, `spell_id`, `target`, `cooldown_ms`, `range`, `damage_fraction`, `class_mask`, `starter_class_mask`, `starter_option_mask`,
    `evolves_from`, `heal_pct`, `duration_ms`, `chains`, `behavior`, `behavior_value`, `tick_ms`, `base_targets`, `alt_spell_id`, `alt_every`, `alt_damage`, `base_jumps`, `kill_below_pct`,
    `flags`, `applies`, `apply_stacks`, `uses`, `uses_pct`, `spec`)
SELECT `e`.`id`, `e`.`name`, `e`.`icon`, `e`.`description`, `b`.`spell_id`, `b`.`target`, `b`.`cooldown_ms`, `b`.`range`,
    `b`.`damage_fraction`, `b`.`class_mask`, 0, 0,
    `e`.`base`, `b`.`heal_pct`, `b`.`duration_ms`, `b`.`chains`, `b`.`behavior`, `b`.`behavior_value`, `b`.`tick_ms`,
    `b`.`base_targets`, `b`.`alt_spell_id`, `b`.`alt_every`, `b`.`alt_damage`, `b`.`base_jumps`, `b`.`kill_below_pct`,
    `b`.`flags`, `b`.`applies`, `b`.`apply_stacks`, `b`.`uses`, `b`.`uses_pct`, 0
FROM `bonk_rogue_evolution` `e` JOIN `bonk_weapon` `b` ON `b`.`id` = `e`.`base`;

INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `e`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_rogue_evolution` `e` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `e`.`base`;
DROP TEMPORARY TABLE `bonk_rogue_evolution`;

UPDATE `bonk_weapon` SET `behavior_value` = 1 WHERE `id` = 614;
UPDATE `bonk_weapon` SET `base_targets` = 5 WHERE `id` = 616;
UPDATE `bonk_weapon` SET `target` = 4, `range` = 30 WHERE `id` = 617;
UPDATE `bonk_weapon` SET `behavior_value` = 8 WHERE `id` IN (624, 635);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.6 WHERE `id` = 629;
UPDATE `bonk_weapon` SET `damage_fraction` = 3.0 WHERE `id` = 633;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.5 WHERE `id` = 634;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
