DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103997000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103997000');

UPDATE `bonk_weapon` SET `description` = 'Strikes the 3 nearest enemies within 10 yards and heals you for 0.5% of your maximum health per enemy hit, up to 2.5%. Its critical strikes Enrage you, granting 25% Haste for 4 sec.' WHERE `id` = 304;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 10 yards of you.' WHERE `id` = 300;
UPDATE `bonk_weapon` SET `description` = 'Wounds the 3 nearest enemies within 10 yards, applying 3 stacks of Bleed. Your Cleave hits also apply 1 stack of Bleed.' WHERE `id` = 301;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 10 yards of you, dealing 8% more damage per stack of Bleed on the target, up to 30 stacks. Bleeding enemies also take the damage their Bleed would deal over the next 2 sec, keeping their stacks.' WHERE `id` = 303;
UPDATE `bonk_weapon` SET `description` = 'Strikes all enemies within 10 yards of you. Normal enemies below 20% health die instantly; elites and bosses below 20% take triple damage. Its kills Enrage you, granting 25% Haste for 4 sec.' WHERE `id` = 305;
UPDATE `bonk_weapon` SET `description` = 'When you are struck, strikes all enemies within 10 yards of you, at most once every 2 sec.' WHERE `id` = 309;
UPDATE `bonk_weapon` SET `description` = 'Slams all enemies within 10 yards of you, dealing 2% more damage for each 1% of your maximum health in your Shield, up to 200% more.' WHERE `id` = 310;
UPDATE `bonk_weapon` SET `description` = 'Slams the 3 strongest enemies within 20 yards for Holy damage, with double critical strike chance. With Seal of Righteousness it deals 50% more damage, with Seal of Command it also hits enemies within 5 yards of each target for half, and with Seal of Light it heals you for 1% of your maximum health per enemy hit, up to 5%.' WHERE `id` = 801;
UPDATE `bonk_weapon` SET `description` = 'Hits from your other Paladin spells, splash included, deal 30% extra as Holy damage. Judgement deals 50% more damage instead. Consecration, Retribution Aura and Seal of Command are not affected.' WHERE `id` = 803;
UPDATE `bonk_weapon` SET `description` = 'Holy light bursts around you, dealing Holy damage to all enemies within 10 yards and healing you for 0.5% of your maximum health per enemy hit, up to 3%. Each enemy hit counts as a strike for Seal of Command, up to 5 bursts.' WHERE `id` = 806;
UPDATE `bonk_weapon` SET `description` = 'Hurls a hammer at the strongest enemy within 20 yards, dealing Holy damage and stunning it for 2 sec. Bosses and mini-bosses are not stunned.' WHERE `id` = 811;
UPDATE `bonk_weapon` SET `description` = 'Strikes up to 6 enemies within 18 yards in a cone toward the nearest enemy.' WHERE `id` = 37;
UPDATE `bonk_weapon` SET `description` = 'Rains arrows on the largest group of enemies within 20 yards for 4 sec, dealing 5% more damage for each different debuff on the target. Every 25 hits loads an Explosive Arrow into your Aimed Shot, up to 2.' WHERE `id` = 137;
UPDATE `bonk_weapon` SET `description` = 'Summons a cat that fights for you. Its attacks apply 1 stack of Bleed, its Claw applies 4 stacks, and its Swipe strikes all enemies in front of it.' WHERE `id` = 201;
UPDATE `bonk_weapon` SET `description` = 'Fires 3 holy bolts at the enemies that struck you in the last 5 sec, or else the nearest enemies, each dealing Holy damage and healing you for 0.5% of your maximum health. Healing past full health becomes a Shield, up to 6% of your maximum health.' WHERE `id` = 505;
UPDATE `bonk_weapon` SET `description` = 'Normal enemies within 8 yards flee in fear for 2 sec, taking Shadow damage every sec. Elites and bosses are unaffected.' WHERE `id` = 506;
UPDATE `bonk_weapon` SET `description` = 'Strikes the strongest enemy within 30 yards for Holy damage and binds it for 2 sec, dealing Holy damage every sec while bound. Bosses and mini-bosses are struck first but cannot be bound.' WHERE `id` = 507;
UPDATE `bonk_weapon` SET `description` = 'The Light strikes the strongest enemy within 30 yards for heavy Holy damage. Each Smite or Halo reduces its cooldown by 1 sec.' WHERE `id` = 503;
UPDATE `bonk_weapon` SET `description` = 'Summons a Shadowfiend whose attacks apply Decay and whose Shadow Cleave hits every enemy in front of it. Its melee attacks heal you for 0.5% of your maximum health.' WHERE `id` = 511;
UPDATE `bonk_weapon` SET `description` = 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, fires all 5 at once at the nearest enemies.' WHERE `id` = 409;
UPDATE `bonk_weapon` SET `description` = 'Corrupts 2 enemies within 30 yards, the nearest without Decay first, with 1 stack of Decay, or 2 on an enemy without Decay.' WHERE `id` = 904;
UPDATE `bonk_weapon` SET `description` = 'Curses 2 enemies within 30 yards, uncursed enemies with the most health first, with 1 stack of Agony, or 2 on an uncursed enemy. Your Shadow Bolts add 1 stack of Agony to cursed enemies.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `description` = 'Strikes 8 times over 1.4 sec, each strike hitting a random enemy within 10 yards for damage and carrying your poisons and openers. Each strike reduces the cooldown of Eviscerate by 0.5 sec.' WHERE `id` = 603;
UPDATE `bonk_weapon` SET `description` = 'Increases your dodge chance by 50% for 5 sec, up to 85%.' WHERE `id` = 611;
UPDATE `bonk_weapon` SET `description` = 'Every 3rd hit from your other Shaman spells and Feral Spirit bites hurls a free Lightning Bolt at the nearest enemy within 30 yards, or at the 3 nearest if you know Chain Lightning, dealing Nature damage and applying 1 stack of Static. Lightning Shield and totem hits don''t count.' WHERE `id` = 706;
UPDATE `bonk_weapon` SET `description` = 'Summons 2 spirit wolves whose bites apply 1 stack of Static. Every 3 sec, each wolf cleaves all enemies in front of it within 6 yards.' WHERE `id` = 707;
UPDATE `bonk_weapon` SET `description` = 'Press R to shift into your next form. Druid spells deal and heal 30% more in their form.|n|n|cffffffffMoonkin Form:|r Wrath strikes the nearest enemy for Nature damage, splashing enemies within 5 yards. Every 3 sec, Starfall strikes 3 enemies afflicted by Moonfire.|n|n|cffffffffCat Form:|r Claws the nearest enemy for Physical damage and 1 stack of Bleed, splashing enemies within 5 yards. Attacks 50% faster. Movement speed increased by 15%. Critical strikes apply 1 stack of Bleed.|n|n|cffffffffBear Form:|r Mauls the nearest enemy for Physical damage, splashing enemies within 5 yards. Damage taken reduced by 35%, but spells of other forms deal and heal 20% less. Swipe deals 8% more per enemy within 8 yards, up to 8 enemies. Every 6 sec, roars to Daze enemies within 10 yards and reduce their damage by 25% for 4 sec.|n|n|cffffffffTree of Life:|r Vines lash the 3 nearest enemies for Nature damage, splashing enemies within 5 yards, each hit healing you for 0.3% of your maximum health. Calls 1 additional Treant. Rejuvenation blooms 50% faster.  [DB version; character select keeps its ''(30/10/10/20 yd range)'' labels]' WHERE `id` = 1013;
UPDATE `bonk_weapon` SET `description` = 'Burns 2 enemies within 30 yards, those without Moonfire first, for Arcane damage and applies 1 stack of Moonfire. Empowered in Moonkin Form.' WHERE `id` = 1002;
UPDATE `bonk_weapon` SET `description` = 'Every sec, heals you for 0.3% of your maximum health and lashes the 3 nearest enemies within 10 yards for Nature damage. Healing past full health makes your attacks and dots tick 15% more often for 3 sec. Empowered in Tree of Life.' WHERE `id` = 1008;
UPDATE `bonk_weapon` SET `description` = 'Summons 2 Treants whose attacks apply 1 stack of Moonfire. Every 6 sec, each Treant roots its target and normal enemies within 5 yards for 2 sec. Empowered in Tree of Life, which calls 1 additional Treant.' WHERE `id` = 1009;
UPDATE `bonk_weapon` SET `description` = 'Entangles the 3 nearest enemies within 25 yards, dealing Nature damage and rooting normal enemies for 2 sec. Empowered in Tree of Life.' WHERE `id` = 1010;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
