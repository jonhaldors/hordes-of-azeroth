DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023230000');

UPDATE `bonk_weapon` SET `description` = 'Every sec, corrupts the 2 nearest enemies, enemies without Decay first, adding 1 stack of Decay (2 on a fresh enemy). Stacks build up while they stay near you, and each stack from Corruption is 2.5 times as strong.' WHERE `id` = 904;
UPDATE `bonk_weapon` SET `description` = 'Every 1.5 sec, curses the 2 enemies with the most health, enemies without Agony first, adding 1 stack of Agony (2 on a fresh enemy). Each stack deals more damage every sec it stays on, up to 3 times as much.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you every sec.' WHERE `id` = 909;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage for each of your afflictions on the target (Decay, Agony, Burning) and interrupts spells. Every 10 sec it removes one harmful effect from you.' WHERE `id` = 903;

UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 2 fel Firebolts at different enemies within 30 yards, leaving them burning. Each Firebolt jumps to 2 more enemies within 8 yards for 60% damage.' WHERE `id` = 911;
UPDATE `bonk_weapon` SET `description` = 'Summons an Imp that hurls volleys of 2 fel Firebolts at different enemies within 30 yards, leaving them burning. Enemies killed by its Firebolts call a lesser Imp that fights for 6 sec, up to 6 at once.' WHERE `id` = 912;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker. Each enemy that dies near it is consumed and it grows; after 8 it bursts in a void nova, dealing Shadow damage to every enemy around it, and shields you for 5% of your maximum health.' WHERE `id` = 913;
UPDATE `bonk_weapon` SET `description` = 'Summons a Voidwalker. Each enemy that dies near it is consumed and it grows; after 8 it bursts in a void nova, dealing Shadow damage to every enemy around it. Every 6 sec it slams the ground, dealing Shadow damage within 8 yards and knocking normal enemies away.' WHERE `id` = 914;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes every enemy around her, not just in front, and applies Shadow Vulnerability.' WHERE `id` = 915;
UPDATE `bonk_weapon` SET `description` = 'Summons a Succubus whose Lash of Pain strikes all enemies in a wide arc in front of her and applies Shadow Vulnerability. Every 8 sec she pulls the strongest normal enemy within 20 yards to her, and it takes double damage for 2 sec.' WHERE `id` = 916;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage for each of your afflictions on the target (Decay, Agony, Burning). Its bites interrupt every enemy casting within 8 yards of the target.' WHERE `id` = 917;
UPDATE `bonk_weapon` SET `description` = 'Summons a Felhunter whose Shadow Bite deals 10% more damage for each of your afflictions on the target (Decay, Agony, Burning). Its bites turn off an elite''s affixes for 6 sec, at most once every 10 sec.' WHERE `id` = 918;
UPDATE `bonk_weapon` SET `description` = 'Every sec, corrupts the 2 nearest enemies, enemies without Decay first, adding 1 stack of Decay. Corrupted enemies explode on death, dealing Shadow damage and 1 stack of Decay to enemies within 6 yards. Explosion kills explode too, up to 2 in a row.' WHERE `id` = 919;
UPDATE `bonk_weapon` SET `description` = 'Every sec, corrupts the 2 nearest enemies, enemies without Decay first, adding 1 stack of Decay. Every 6 sec, every corrupted enemy within 30 yards instantly takes the damage its Decay would deal over the next 3 sec, without losing its stacks.' WHERE `id` = 920;
UPDATE `bonk_weapon` SET `description` = 'Every 1.5 sec, curses the 2 enemies with the most health, enemies without Agony first, adding 1 stack of Agony. 10 sec after an enemy is first cursed, Doom strikes it for heavy Shadow damage; if it dies, a Doomguard rises and fights for 15 sec.' WHERE `id` = 921;
UPDATE `bonk_weapon` SET `description` = 'Every 1.5 sec, curses the 2 enemies with the most health, enemies without Agony first, adding 1 stack of Agony. When a cursed enemy dies, its Agony jumps to the nearest uncursed enemy and keeps every stack.' WHERE `id` = 922;
UPDATE `bonk_weapon` SET `description` = 'A tentacle of shadow drains the nearest enemy within 16 yards and heals you. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `description` = 'A tentacle of shadow drains the nearest enemy within 16 yards and heals you. Healing past full health makes your demons deal 30% more damage for 4 sec.' WHERE `id` = 924;
UPDATE `bonk_weapon` SET `description` = 'Fires a fel bolt at the nearest enemy. Every 4th bolt erupts, critically striking its target and every enemy within 8 yards for 150% damage. Nightfall: an enemy that dies with one of your afflictions fires a free bolt, at most 1 a sec.' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `description` = 'Fires a bolt of shadow at the nearest enemy. Nightfall: an enemy that dies with one of your afflictions fires a free Shadow Bolt, at most 1 a sec. Free bolts jump to 2 nearby enemies for half damage.' WHERE `id` = 926;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you every sec. The ring widens as you lose health, up to 60% wider.' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you every sec. Your demons burn with it, dealing half its damage to enemies within 6 yards of them.' WHERE `id` = 930;
UPDATE `bonk_weapon` SET `description` = 'Fel fire rains on the largest group of enemies for 4 sec, applying Burning. Each rain ends with an Infernal crashing down, dealing Fire damage and stunning normal enemies within 6 yards for 1 sec, then it fights for 8 sec.' WHERE `id` = 931;

UPDATE `bonk_weapon` SET `description` = 'Deals Nature damage to the enemy with the most Poison. It and every Poisoned enemy within 10 yards instantly take the damage their Poison would deal over the next 4 seconds, without losing stacks. For 5 seconds your hits apply 2 additional stacks of Poison.' WHERE `id` = 627;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and can set off Ambush again, once a second per enemy.' WHERE `id` = 610;
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards for 50% of their damage as Shadow damage. Extra hits can set off Ambush again, once a second per enemy.' WHERE `id` = 615;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and can set off Ambush again, once a second per enemy. The dance begins with a vanish: normal enemies within 10 yards lose you and stand dazed for 2 seconds.' WHERE `id` = 632;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and can set off Ambush again, once a second per enemy. The dance begins by striking the 5 strongest enemies within 20 yards with a shadow strike.' WHERE `id` = 633;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
