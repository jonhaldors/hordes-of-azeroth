DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027810001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027810001');

UPDATE `bonk_mastery` SET `description` = 'Every 4th cast of each spell critically strikes every enemy it hits, and those critical strikes deal 25% more damage.' WHERE `id` = 10110;
UPDATE `bonk_mastery` SET `description` = 'Shield Block''s Shield holds up to 100% of your maximum health instead of 50% and recharges 10% per sec, even while you are struck. While your Shield is above half, you deal 20% more damage.' WHERE `id` = 10310;
UPDATE `bonk_mastery` SET `description` = 'Exorcism strikes 2 additional enemies, and Art of War can trigger it every 0.5 sec.' WHERE `id` = 20110;
UPDATE `bonk_mastery` SET `description` = 'While you stand in your Consecration, you take 20% less damage and deal 20% more damage.' WHERE `id` = 20210;
UPDATE `bonk_mastery` SET `description` = 'Every 4th Crusader Strike is a Templar''s Verdict, dealing triple damage to every enemy within 5 yards of the target.' WHERE `id` = 20310;
UPDATE `bonk_mastery` SET `description` = 'Your pets are always frenzied: +50% damage, and their attacks hit every enemy in front of them. Your other spells deal 15% less damage.' WHERE `id` = 30110;
UPDATE `bonk_mastery` SET `description` = 'Your shots Mark every enemy they hit and target Marked enemies first. Marked enemies take 30% more damage from you.' WHERE `id` = 30210;
UPDATE `bonk_mastery` SET `description` = 'Each dash leaves one of each of your traps behind, armed at once. Your dash recharges 30% faster.' WHERE `id` = 30310;
UPDATE `bonk_mastery` SET `description` = 'Your abilities apply 1 additional Poison stack per hit, even without Deadly Poison.' WHERE `id` = 40110;
UPDATE `bonk_mastery` SET `description` = 'Your single-target hits also strike 2 enemies within 8 yards for 60% damage, even without Blade Flurry.' WHERE `id` = 40210;
UPDATE `bonk_mastery` SET `description` = 'Ambush also hits every enemy within 8 yards of the target for full damage.' WHERE `id` = 40310;
UPDATE `bonk_mastery` SET `description` = 'While you have a Shield, you take 20% less damage and deal 20% more damage.' WHERE `id` = 50110;
UPDATE `bonk_mastery` SET `description` = 'Renew smites while you are above 80% health, not only at full. Smite and Halo cut 2 sec off Holy Word: Chastise.' WHERE `id` = 50210;
UPDATE `bonk_mastery` SET `description` = 'Your Decay deals 30% more damage, and your spells apply 1 more Decay stack.' WHERE `id` = 50310;
UPDATE `bonk_mastery` SET `description` = 'Static discharges at 3 stacks instead of 5.' WHERE `id` = 70110;
UPDATE `bonk_mastery` SET `description` = 'Windfury Weapon triggers Windfury every 2nd swing instead of every 3rd. Maelstrom Weapon needs 3 melee hits instead of 5.' WHERE `id` = 70210;
UPDATE `bonk_mastery` SET `description` = 'Each of your totem spells plants 1 additional totem.' WHERE `id` = 70310;
UPDATE `bonk_mastery` SET `description` = 'Your dash becomes Blink and recharges twice as fast. Each Blink sets off your Arcane Explosion where you land.' WHERE `id` = 80110;
UPDATE `bonk_mastery` SET `description` = 'Your critical strikes deal 100% more damage. Your maximum health is reduced by 35%.' WHERE `id` = 80210;
UPDATE `bonk_mastery` SET `description` = 'Chill freezes at 6 stacks instead of 10.' WHERE `id` = 80310;
UPDATE `bonk_mastery` SET `description` = 'When an enemy with your Decay or Agony dies, they jump to the nearest enemy without them, keeping every stack.' WHERE `id` = 90110;
UPDATE `bonk_mastery` SET `description` = 'Your demons deal 10% more damage for each different demon you command, up to 40%.' WHERE `id` = 90210;
UPDATE `bonk_mastery` SET `description` = 'Nightfall fires up to 3 free Shadow Bolts per sec instead of 1, and they deal 50% more damage.' WHERE `id` = 90310;
UPDATE `bonk_mastery` SET `description` = 'Starfall strikes in every form and hits 2 additional enemies.' WHERE `id` = 110110;
UPDATE `bonk_mastery` SET `description` = 'Cat Form: your critical strikes deal 25% more damage. Bear Form: take 20% less damage and move 15% faster.' WHERE `id` = 110210;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
