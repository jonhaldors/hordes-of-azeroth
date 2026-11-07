DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120005');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120005');

UPDATE `bonk_weapon` SET `damage_fraction` = 0.4, `applies` = 3, `apply_stacks` = 1 WHERE `id` IN (909, 929, 930);
UPDATE `bonk_weapon` SET `description` = 'Fire burns every enemy within 8 yards of you, dealing damage and 1 stack of Burning.' WHERE `id` = 909;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you, dealing damage and 1 stack of Burning. The ring widens as you lose health, up to 60% wider.' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards of you, dealing damage and 1 stack of Burning. Your demons burn too, hitting enemies within 6 yards of them for half damage.' WHERE `id` = 930;

UPDATE `bonk_weapon` SET `base_targets` = 3 WHERE `id` IN (906, 923, 924);
UPDATE `bonk_weapon` SET `description` = 'Drains the 3 nearest enemies within 16 yards, dealing damage every sec and healing you for 1% of your maximum health per enemy drained.' WHERE `id` = 906;
UPDATE `bonk_weapon` SET `description` = 'Drains the 3 nearest enemies within 16 yards, dealing damage every sec and healing you. Each enemy that dies while drained gives you a soul: 5% more damage for 10 sec, up to 10 souls.' WHERE `id` = 923;
UPDATE `bonk_weapon` SET `description` = 'Drains the 3 nearest enemies within 16 yards, dealing damage every sec and healing you. Healing past full health makes your demons deal 30% more damage for 4 sec.' WHERE `id` = 924;

UPDATE `bonk_weapon` SET `damage_fraction` = 2.0, `uses` = 13, `uses_pct` = 4 WHERE `id` IN (907, 925, 926);
UPDATE `bonk_weapon` SET `description` = 'Fires a Shadow Bolt at the nearest enemy, dealing damage, 4% more per stack of Decay on the target, up to 30 stacks. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec.' WHERE `id` = 907;
UPDATE `bonk_weapon` SET `description` = 'Fires a Chaos Bolt at the nearest enemy, dealing damage, 4% more per stack of Decay on the target, up to 30 stacks. Every 4th bolt crits its target and every enemy within 8 yards for 150% damage. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec.' WHERE `id` = 925;
UPDATE `bonk_weapon` SET `description` = 'Fires a Shadow Bolt at the nearest enemy, dealing damage, 4% more per stack of Decay on the target, up to 30 stacks. Nightfall: enemies that die with your afflictions on them fire a free bolt, at most 1 a sec, that jumps to 2 nearby enemies for half damage.' WHERE `id` = 926;

UPDATE `bonk_weapon` SET `base_targets` = 3 WHERE `id` IN (905, 921, 922);
UPDATE `bonk_weapon` SET `description` = 'Curses the 3 enemies with the most health with 1 stack of Agony, or 2 on an uncursed enemy.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `description` = 'Curses the 3 enemies with the most health with 1 stack of Agony. 10 sec after the first curse, Doom strikes for heavy Shadow damage; if it kills, a Doomguard fights for 15 sec.' WHERE `id` = 921;
UPDATE `bonk_weapon` SET `description` = 'Curses the 3 enemies with the most health with 1 stack of Agony. When a cursed enemy dies, its Agony moves with every stack to the nearest uncursed enemy.' WHERE `id` = 922;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
