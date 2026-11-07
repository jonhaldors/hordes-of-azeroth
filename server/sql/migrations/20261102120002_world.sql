DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120002');

UPDATE `bonk_weapon` SET `cooldown_ms` = 4000, `range` = 20, `radius` = 8, `damage_fraction` = 0.6 WHERE `id` IN (605, 622, 623);
UPDATE `bonk_weapon` SET `description` = 'Your other abilities apply 1 stack of Poison with every hit. Also throws a vial at the largest group of enemies within 20 yards, dealing Nature damage and applying 4 stacks of Poison to every enemy within 8 yards.' WHERE `id` = 605;
UPDATE `bonk_weapon` SET `description` = 'Your other abilities apply 1 stack of Poison with every hit and slow normal enemies by 30%. Poisoned enemies take 15% more damage from you. Also throws a vial at the largest group of enemies within 20 yards, dealing Nature damage and applying 4 stacks of Poison to every enemy within 8 yards.' WHERE `id` = 622;
UPDATE `bonk_weapon` SET `description` = 'Your other abilities apply 1 stack of Poison with every hit and deal 30% extra as Nature damage. Also throws a vial at the largest group of enemies within 20 yards, dealing Nature damage and applying 4 stacks of Poison to every enemy within 8 yards.' WHERE `id` = 623;
INSERT IGNORE INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`) VALUES (605, 3, 8), (622, 3, 8), (623, 3, 8);

UPDATE `bonk_weapon` SET `description` = 'Stabs the nearest enemy with both daggers for damage, each stab applying 1 stack of Poison, plus 1 for every 5 stacks it already has. Deals 30% more to Poisoned enemies.' WHERE `id` = 604;
UPDATE `bonk_weapon` SET `description` = 'Stabs the nearest enemy with both daggers for damage, each stab applying 1 stack of Poison, plus 1 for every 5 stacks it already has, and 2 stacks of Nature Vulnerability. Deals 30% more to Poisoned enemies.' WHERE `id` = 620;
UPDATE `bonk_weapon` SET `description` = 'Stabs the nearest enemy with both daggers for damage, 3 times below 35% health, each stab applying 1 stack of Poison, plus 1 for every 5 stacks it already has. Deals 30% more to Poisoned enemies.' WHERE `id` = 621;

UPDATE `bonk_weapon` SET `base_targets` = 3 WHERE `id` IN (607, 626, 627);
UPDATE `bonk_weapon` SET `description` = 'Strikes the 3 enemies with the most Poison for Nature damage plus all the damage their Poison would still deal, keeping their stacks. Your hits apply 2 more stacks of Poison for 5 sec.' WHERE `id` = 607;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 3 enemies with the most Poison for Nature damage plus all the damage their Poison would still deal, keeping their stacks, and every Poisoned enemy within 8 yards of them for Nature damage. Your hits apply 2 more stacks of Poison for 5 sec.' WHERE `id` = 626;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 3 enemies with the most Poison for Nature damage plus all the damage their Poison would still deal, keeping their stacks. They and every Poisoned enemy within 10 yards also take the damage their Poison would deal over the next 4 sec. Your hits apply 2 more stacks of Poison for 5 sec.' WHERE `id` = 627;

UPDATE `bonk_weapon` SET `description` = 'Guts the nearest enemy for heavy damage, with double critical strike chance. A kill carries the blow to the next enemy within 8 yards, up to 3 times.' WHERE `id` = 602;
UPDATE `bonk_weapon` SET `description` = 'Guts the 5 nearest enemies for heavy damage, with double critical strike chance. A kill carries the blow to the next enemy within 8 yards, up to 3 times.' WHERE `id` = 616;
UPDATE `bonk_weapon` SET `description` = 'Throws a blade at the strongest enemy within 30 yards, elites first, for heavy damage with double critical strike chance. Normal enemies hit are slowed by 50% for 3 sec. A kill carries the blow to the next enemy within 8 yards, up to 3 times.' WHERE `id` = 617;

UPDATE `bonk_weapon` SET `damage_fraction` = 1.6 WHERE `id` IN (603, 618, 619);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
