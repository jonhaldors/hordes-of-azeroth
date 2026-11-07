DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019390000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019390000');

UPDATE `bonk_weapon` SET `description` = 'Stabs the nearest enemy every 0.6 seconds for Physical damage.' WHERE `id` = 600;
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards. The extra hits carry your poisons and openers.' WHERE `id` = 601;
UPDATE `bonk_weapon` SET `description` = 'Every hit with your other abilities applies 1 stack of Poison.' WHERE `id` = 605;
UPDATE `bonk_weapon` SET `description` = 'Deals Nature damage to the enemy with the most Poison, and for 5 seconds your hits apply 2 additional stacks of Poison.' WHERE `id` = 607;
UPDATE `bonk_weapon` SET `description` = 'Your first hit on each enemy with your other abilities is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance.' WHERE `id` = 609;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush.' WHERE `id` = 610;
UPDATE `bonk_weapon` SET `description` = 'Your single-target hits always strike 1 additional enemy within 8 yards. The extra hits carry your poisons and openers.', `icon` = 'INV_Weapon_ShortBlade_10' WHERE `id` = 614;
UPDATE `bonk_weapon` SET `description` = 'For 8 seconds, your single-target hits also strike 4 additional enemies within 8 yards for Shadow damage. Every extra hit counts as a first hit for Ambush.' WHERE `id` = 615;
UPDATE `bonk_weapon` SET `description` = 'Every hit with your other abilities applies 1 stack of Poison and slows normal enemies by 30%. Poisoned enemies take 15% more damage from you.' WHERE `id` = 622;
UPDATE `bonk_weapon` SET `description` = 'Every hit with your other abilities applies 1 stack of Poison and also deals 30% of its damage as Nature damage at once.' WHERE `id` = 623;
UPDATE `bonk_weapon` SET `description` = 'Deals Nature damage to the enemy with the most Poison and every Poisoned enemy within 8 yards of it, and for 5 seconds your hits apply 2 additional stacks of Poison.' WHERE `id` = 626;
UPDATE `bonk_weapon` SET `description` = 'Deals Nature damage to the enemy with the most Poison, and every Poisoned enemy within 10 yards of it takes 4 seconds of its Poison damage at once, without losing any stacks. For 5 seconds your hits apply 2 additional stacks of Poison.' WHERE `id` = 627;
UPDATE `bonk_weapon` SET `description` = 'Your first hit on each enemy with your other abilities is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance. Ambush stuns normal enemies for 1 second.' WHERE `id` = 630;
UPDATE `bonk_weapon` SET `description` = 'Your first hit on each enemy with your other abilities is followed by an Ambush strike for heavy Physical damage, with double the critical strike chance. Ambushed enemies take 20% more damage from you for 6 seconds.' WHERE `id` = 631;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush. The dance begins with a vanish: normal enemies within 10 yards lose you and stand dazed for 2 seconds.' WHERE `id` = 632;
UPDATE `bonk_weapon` SET `description` = 'For 4 seconds, your hits deal 30% more damage and every hit counts as a first hit for Ambush. The dance begins by striking the 5 strongest enemies within 20 yards with a shadow strike.' WHERE `id` = 633;
UPDATE `bonk_mastery` SET `description` = 'Every hit with your abilities applies 1 additional stack of Poison, even without Deadly Poison. Your Power is reduced by 15%.' WHERE `id` = 40110;
UPDATE `bonk_mastery` SET `description` = 'Your single-target hits strike 1 additional enemy within 8 yards, with or without Blade Flurry. Your critical strike chance is reduced by 10%.' WHERE `id` = 40210;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
