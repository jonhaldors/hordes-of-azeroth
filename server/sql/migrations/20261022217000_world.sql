DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022217000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022217000');

DELETE FROM `creature_template` WHERE `entry` IN (900145, 900146);
DROP TEMPORARY TABLE IF EXISTS `bonk_warlock_pet`;
CREATE TEMPORARY TABLE `bonk_warlock_pet` SELECT * FROM `creature_template` WHERE `entry` = 900134;
UPDATE `bonk_warlock_pet` SET `entry` = 900145, `name` = 'Doomguard', `display_id1` = 1912, `display_scale1` = 0.8;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
UPDATE `bonk_warlock_pet` SET `entry` = 900146, `name` = 'Infernal', `display_id1` = 169, `display_scale1` = 0.8;
INSERT INTO `creature_template` SELECT * FROM `bonk_warlock_pet`;
DROP TEMPORARY TABLE `bonk_warlock_pet`;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 911 AND 932;
DELETE FROM `bonk_weapon` WHERE `id` BETWEEN 911 AND 932;
DROP TEMPORARY TABLE IF EXISTS `bonk_warlock_evolution`;
CREATE TEMPORARY TABLE `bonk_warlock_evolution` SELECT * FROM `bonk_weapon` WHERE `id` BETWEEN 900 AND 910;
UPDATE `bonk_warlock_evolution` SET `evolves_from` = `id`, `id` = 911 + 2 * (`id` - 900), `starter_class_mask` = 0, `starter_option_mask` = 0;
INSERT INTO `bonk_weapon` SELECT * FROM `bonk_warlock_evolution`;
UPDATE `bonk_warlock_evolution` SET `id` = `id` + 1;
INSERT INTO `bonk_weapon` SELECT * FROM `bonk_warlock_evolution`;
DROP TEMPORARY TABLE `bonk_warlock_evolution`;

UPDATE `bonk_weapon` SET `name` = 'Fel Imps', `icon` = 'Spell_Fire_FireBolt',
    `description` = 'Summons an Imp that hurls volleys of 3 fel Firebolts at enemies within 30 yards. Each Firebolt jumps to 2 additional nearby enemies for 60% damage.' WHERE `id` = 911;
UPDATE `bonk_weapon` SET `name` = 'Imp Swarm', `icon` = 'Spell_Shadow_ImpPhaseShift',
    `description` = 'Summons an Imp that hurls volleys of 3 fel Firebolts. An enemy killed by its Firebolts calls a lesser Imp that fights for 6 sec, up to 6 at once.' WHERE `id` = 912;
UPDATE `bonk_weapon` SET `name` = 'Sacrifice', `icon` = 'Spell_Shadow_SacrificialShield',
    `description` = 'Summons a Voidwalker that consumes enemies dying near it and bursts after 5 in a void nova. Each burst also shields you for 5% of your maximum health.' WHERE `id` = 913;
UPDATE `bonk_weapon` SET `name` = 'Void Slam', `icon` = 'Spell_Shadow_GatherShadows',
    `description` = 'Summons a Voidwalker that consumes enemies dying near it and bursts after 5. Every 6 sec it slams the ground, dealing Shadow damage to enemies within 8 yards and knocking normal enemies away.' WHERE `id` = 914;
UPDATE `bonk_weapon` SET `name` = 'Painful Lash', `icon` = 'Spell_Shadow_Curse',
    `description` = 'Summons a Succubus whose Lash of Pain strikes every enemy around her and applies Shadow Vulnerability.' WHERE `id` = 915;
UPDATE `bonk_weapon` SET `name` = 'Seduction', `icon` = 'Spell_Shadow_MindSteal',
    `description` = 'Summons a Succubus that lashes the enemies in front of her. Every 8 sec she draws the strongest normal enemy within 20 yards to her, and it takes double damage for 2 sec.' WHERE `id` = 916;
UPDATE `bonk_weapon` SET `name` = 'Spell Lock', `icon` = 'Spell_Shadow_MindRot',
    `description` = 'Summons a Felhunter whose Shadow Bite grows with your afflictions. When it interrupts a caster, every enemy casting within 8 yards is interrupted too.' WHERE `id` = 917;
UPDATE `bonk_weapon` SET `name` = 'Devour Affix', `icon` = 'Spell_Nature_Purge',
    `description` = 'Summons a Felhunter whose Shadow Bite grows with your afflictions. Its bites strip an elite''s affixes for 6 sec, at most once every 10 sec.' WHERE `id` = 918;
UPDATE `bonk_weapon` SET `name` = 'Seed of Corruption', `icon` = 'Spell_Shadow_CorpseExplode',
    `description` = 'Every sec, corrupts the 5 nearest enemies with 1 stack of Decay. A corrupted enemy explodes when it dies, dealing Shadow damage to enemies within 6 yards and corrupting them; the chain stops 2 deep.' WHERE `id` = 919;
UPDATE `bonk_weapon` SET `name` = 'Dark Harvest', `icon` = 'Spell_Shadow_Requiem',
    `description` = 'Every sec, corrupts the 5 nearest enemies with 1 stack of Decay. Every 6 sec, every corrupted enemy within 30 yards takes 3 sec of its Decay at once.' WHERE `id` = 920;
UPDATE `bonk_weapon` SET `name` = 'Curse of Doom', `icon` = 'Spell_Shadow_AuraOfDarkness',
    `description` = 'Every 1.5 sec, adds 1 stack of Agony to the 5 enemies with the most health. 10 sec after an enemy is first cursed, Doom strikes it for heavy Shadow damage; if it dies, a Doomguard rises and fights for 15 sec.' WHERE `id` = 921;
UPDATE `bonk_weapon` SET `name` = 'Agony''s Echo', `icon` = 'Spell_Shadow_CurseOfMannoroth',
    `description` = 'Every 1.5 sec, adds 1 stack of Agony to the 5 enemies with the most health. When a cursed enemy dies, its Agony jumps to the nearest uncursed enemy and keeps every stack.' WHERE `id` = 922;
UPDATE `bonk_weapon` SET `name` = 'Drain Soul', `icon` = 'Spell_Shadow_Haunting',
    `description` = 'Tentacles drain up to 3 enemies and heal you. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `name` = 'Dark Pact', `icon` = 'Spell_Shadow_DarkRitual',
    `description` = 'Tentacles drain up to 3 enemies and heal you. Healing past full health makes your demons deal 30% more damage for 4 sec.' WHERE `id` = 924;
UPDATE `bonk_weapon` SET `name` = 'Chaos Bolt', `icon` = 'Spell_Fire_FlameShock',
    `description` = 'Fires a bolt of shadow at the nearest enemy, with Nightfall. Every 4th bolt erupts in fel fire, critically striking its target and every enemy within 8 yards.' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `name` = 'Shadow Barrage', `icon` = 'Spell_Shadow_Twilight',
    `description` = 'Fires a bolt of shadow at the nearest enemy. Nightfall bolts jump to 2 additional nearby enemies for half damage.' WHERE `id` = 926;
UPDATE `bonk_weapon` SET `name` = 'Conflagrate', `icon` = 'Spell_Fire_Fireball',
    `description` = 'Fel fire strikes the 2 nearest enemies and applies 2 stacks of Burning. The fire erupts, striking every enemy within 5 yards of each target for half damage and leaving them burning.' WHERE `id` = 927;
UPDATE `bonk_weapon` SET `name` = 'Shadowflame', `icon` = 'Spell_Fire_ImmolationAttack',
    `description` = 'Fel fire strikes the 2 nearest enemies and applies 2 stacks of Burning and 1 stack of Decay.' WHERE `id` = 928;
UPDATE `bonk_weapon` SET `name` = 'Inferno', `icon` = 'Spell_Fire_Volcano',
    `description` = 'Fel fire burns every enemy within 10 yards every sec and burns you a little. The ring widens as your health drops, up to 60% wider.' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `name` = 'Demonic Immolation', `icon` = 'Spell_Fire_SealOfFire',
    `description` = 'Fel fire burns every enemy within 10 yards every sec and burns you a little. Your demons burn with it, dealing half its damage to enemies within 6 yards of them.' WHERE `id` = 930;
UPDATE `bonk_weapon` SET `name` = 'Summon Infernal', `icon` = 'Spell_Shadow_SummonInfernal',
    `description` = 'Fel fire rains on the largest group of enemies for 4 sec. Each rain ends with an Infernal crashing down: Fire damage and a 1 sec stun to normal enemies within 6 yards, then it fights for 8 sec.' WHERE `id` = 931;
UPDATE `bonk_weapon` SET `name` = 'Rain of Chaos', `icon` = 'Spell_Fel_RainOfFelfire', `damage_fraction` = 0.2,
    `description` = 'Fel fire rains on the 3 largest groups of enemies at once for 4 sec, dealing Fire damage and applying 1 stack of Burning every sec.' WHERE `id` = 932;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` BETWEEN 900 AND 932;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES
(900, 7, 15), (900, 8, 10), (900, 3, 8),
(901, 7, 15), (901, 8, 10), (901, 3, 8),
(902, 7, 15), (902, 8, 10), (902, 3, 8),
(903, 7, 15), (903, 8, 10), (903, 3, 8),
(904, 3, 8), (904, 5, 15), (904, 9, 1),
(905, 3, 8), (905, 5, 15), (905, 9, 1),
(906, 3, 8), (906, 2, 10),
(907, 1, 10), (907, 2, 10), (907, 3, 8),
(908, 1, 10), (908, 3, 8), (908, 9, 1),
(909, 3, 8), (909, 16, 1),
(910, 3, 8), (910, 5, 15), (910, 9, 1), (910, 16, 1);
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT `w`.`id`, `u`.`upgrade`, `u`.`step` FROM `bonk_weapon` `w` JOIN `bonk_weapon_upgrade` `u` ON `u`.`weapon_id` = `w`.`evolves_from`
WHERE `w`.`id` BETWEEN 911 AND 932;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
