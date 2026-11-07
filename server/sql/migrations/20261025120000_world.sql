DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025120000');

UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls 2 Firebolts at a time at enemies within 30 yards, leaving them burning.' WHERE `id` = 900;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker that consumes enemies dying near it. After 8 it bursts in a void nova that hits every enemy around it.' WHERE `id` = 901;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability.' WHERE `id` = 902;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts spells. Every 10 sec it removes a harmful effect from you.' WHERE `id` = 903;
UPDATE `bonk_weapon` SET `description` = 'Corrupts the 2 nearest enemies with 1 stack of Decay, or 2 on an enemy without Decay.' WHERE `id` = 904;
UPDATE `bonk_weapon` SET `description` = 'Curses the 2 enemies with the most health with 1 stack of Agony, or 2 on an uncursed enemy. Agony grows every sec it stays on, up to 3 times as strong.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you for 0.2% of your maximum health per enemy drained.' WHERE `id` = 906;
UPDATE `bonk_weapon` SET `description` = 'Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec.' WHERE `id` = 907;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 2 nearest enemies with fel fire, dealing damage and applying 2 stacks of Burning.' WHERE `id` = 908;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you, dealing damage.' WHERE `id` = 909;
UPDATE `bonk_weapon` SET `description` = 'Rains fel fire on the largest group of enemies for 4 sec, dealing damage and applying 1 stack of Burning every sec.' WHERE `id` = 910;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls 2 Firebolts at a time at enemies within 30 yards, leaving them burning. Firebolts jump to 2 more enemies within 8 yards for 60% damage.' WHERE `id` = 911;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls 2 Firebolts at a time at enemies within 30 yards, leaving them burning. Enemies its Firebolts kill call a lesser Imp for 6 sec, up to 6 at once.' WHERE `id` = 912;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker that consumes enemies dying near it. After 8 it bursts in a void nova that hits every enemy around it and shields you for 5% of your maximum health.' WHERE `id` = 913;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker that consumes enemies dying near it. After 8 it bursts in a void nova that hits every enemy around it. Every 6 sec it slams the ground within 8 yards, knocking normal enemies away.' WHERE `id` = 914;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes every enemy around her and applies Shadow Vulnerability.' WHERE `id` = 915;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability. Every 8 sec she pulls the strongest normal enemy within 20 yards to her; it takes double damage for 2 sec.' WHERE `id` = 916;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and interrupts every caster within 8 yards of it.' WHERE `id` = 917;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage per affliction on the target and turns off an elite''s affixes for 6 sec, at most once every 10 sec.' WHERE `id` = 918;
UPDATE `bonk_weapon` SET `description` = 'Corrupts the 2 nearest enemies with 1 stack of Decay. Corrupted enemies explode on death, adding 1 stack of Decay to enemies within 6 yards. Explosion kills explode too, up to 2 in a row.' WHERE `id` = 919;
UPDATE `bonk_weapon` SET `description` = 'Corrupts the 2 nearest enemies with 1 stack of Decay. Every 6 sec, each corrupted enemy within 30 yards takes 3 sec of its Decay damage at once and keeps its stacks.' WHERE `id` = 920;
UPDATE `bonk_weapon` SET `description` = 'Curses the 2 enemies with the most health with 1 stack of Agony. 10 sec after the first curse, Doom strikes for heavy Shadow damage; if it kills, a Doomguard fights for 15 sec.' WHERE `id` = 921;
UPDATE `bonk_weapon` SET `description` = 'Curses the 2 enemies with the most health with 1 stack of Agony. When a cursed enemy dies, its Agony moves with every stack to the nearest uncursed enemy.' WHERE `id` = 922;
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `description` = 'Drains the nearest enemy within 16 yards, dealing damage every sec and healing you. Healing past full health makes your demons deal 30% more damage for 4 sec.' WHERE `id` = 924;
UPDATE `bonk_weapon` SET `description` = 'Fires a Chaos Bolt at the nearest enemy, dealing damage. Every 4th bolt crits its target and every enemy within 8 yards for 150% damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec.' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `description` = 'Fires a Shadow Bolt at the nearest enemy, dealing damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec, that jumps to 2 nearby enemies for half damage.' WHERE `id` = 926;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 2 nearest enemies with fel fire, dealing damage and applying 2 stacks of Burning. The fire spreads to every enemy within 5 yards of each, for half damage and 1 stack of Burning.' WHERE `id` = 927;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 2 nearest enemies with fel fire, dealing damage and applying 2 stacks of Burning and 1 stack of Decay.' WHERE `id` = 928;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you, dealing damage. The ring widens as you lose health, up to 60% wider.' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you, dealing damage. Your demons burn too, hitting enemies within 6 yards of them for half damage.' WHERE `id` = 930;
UPDATE `bonk_weapon` SET `description` = 'Rains fel fire on the largest group of enemies for 4 sec, applying Burning. Each rain ends with an Infernal crashing down, dealing damage and stunning normal enemies within 6 yards for 1 sec; it then fights for 8 sec.' WHERE `id` = 931;
UPDATE `bonk_weapon` SET `description` = 'Rains fel fire on the 3 largest groups of enemies for 4 sec, dealing damage and applying 1 stack of Burning every sec.' WHERE `id` = 932;

UPDATE `bonk_keyword` SET `description` = 'Each stack deals Shadow damage every sec, growing every sec it stays on the enemy, up to 3 times as much. One curse per enemy.' WHERE `id` = 14;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
