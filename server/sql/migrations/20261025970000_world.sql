DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025970000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025970000');

UPDATE `bonk_mastery` SET `description` = REGEXP_REPLACE(`description`, '^(.+) can be your starter spell\\. Choose it at the Run Master\\.$', 'Unlocks \\1 as a starter spell.');
UPDATE `bonk_mastery` SET `description` = REGEXP_REPLACE(`description`, '^\\+([0-9.]+)% chance to dodge enemy swings\\.$', '+\\1% dodge chance.');
UPDATE `bonk_mastery` SET `description` = REPLACE(`description`, ' Your AoE spells cover more ground.', '');
UPDATE `bonk_mastery` SET `description` = REGEXP_REPLACE(`description`, '^(.+) stuns normal enemies it hits for 1 sec\\. Each enemy can only be stunned once every 6 sec\\.$', '\\1 stuns normal enemies for 1 sec. Once per enemy every 6 sec.');
UPDATE `bonk_mastery` SET `description` = REGEXP_REPLACE(`description`, '^When (.+) kills an enemy, it recharges at once\\.$', '\\1 recharges instantly when it kills an enemy.');
UPDATE `bonk_mastery` SET `description` = 'Once per stage, dropping below 20% health grants a Shield of 30% of your maximum health.'
WHERE `description` = 'Once per stage, when you drop below 20% health, you gain a Shield equal to 30% of your maximum health.';

UPDATE `bonk_mastery` SET `description` = 'Mortal Strike deals 1% more damage per Bleed stack on the target.' WHERE `id` = 10105;
UPDATE `bonk_mastery` SET `description` = 'Cleave applies Bleed to every enemy it hits.' WHERE `id` = 10106;
UPDATE `bonk_mastery` SET `description` = 'Every 5th cast of each spell critically strikes every enemy it hits. Your Haste is reduced by 10%.' WHERE `id` = 10110;
UPDATE `bonk_mastery` SET `description` = 'Enrage grants 5% more Haste.' WHERE `id` = 10205;
UPDATE `bonk_mastery` SET `description` = '+15% damage while Enraged.' WHERE `id` = 10206;
UPDATE `bonk_mastery` SET `description` = 'Execute kills normal enemies below 25% health, up from 20%.' WHERE `id` = 10207;
UPDATE `bonk_mastery` SET `description` = 'You are always Enraged. You take 15% more damage.' WHERE `id` = 10210;
UPDATE `bonk_mastery` SET `description` = 'Shield Block grants 2% more of your maximum health as Shield.' WHERE `id` = 10304;
UPDATE `bonk_mastery` SET `description` = 'Gain a Shield of 3% of your maximum health.' WHERE `id` IN (10305, 80103);
UPDATE `bonk_mastery` SET `description` = 'Shield Block''s Shield holds up to 100% of your maximum health instead of 50% and recharges 10% per sec, even while you are struck. You deal 15% less damage.' WHERE `id` = 10310;

UPDATE `bonk_mastery` SET `description` = 'Exorcism strikes 2 additional enemies, and Art of War can trigger it every 0.5 sec. Your Power is reduced by 15%.' WHERE `id` = 20110;
UPDATE `bonk_mastery` SET `description` = 'Take 20% less damage while standing in your Consecration. Your Power is reduced by 15%.' WHERE `id` = 20210;
UPDATE `bonk_mastery` SET `description` = 'Every 5th Crusader Strike is a Templar''s Verdict, dealing triple damage to every enemy within 5 yards of the target. Your critical strike chance is reduced by 10%.' WHERE `id` = 20310;

UPDATE `bonk_mastery` SET `description` = 'Your pets inherit 5% more of your Power while Pack Leader is out.' WHERE `id` = 30105;
UPDATE `bonk_mastery` SET `description` = 'Pack Leader''s howls heal you for 3% of your maximum health.' WHERE `id` = 30106;
UPDATE `bonk_mastery` SET `description` = '+15% damage while Pack Leader''s howl has your pets frenzied.' WHERE `id` = 30107;
UPDATE `bonk_mastery` SET `description` = '+3% pet critical strike chance.' WHERE `id` = 30108;
UPDATE `bonk_mastery` SET `description` = 'Your pets are always frenzied: +50% damage, and their attacks hit every enemy in front of them. Your other spells deal 30% less damage.' WHERE `id` = 30110;
UPDATE `bonk_mastery` SET `description` = '+10% pickup range.' WHERE `id` = 30203;
UPDATE `bonk_mastery` SET `description` = 'Marked enemies take 2% more damage.' WHERE `id` = 30204;
UPDATE `bonk_mastery` SET `description` = 'Volley deals 2% more damage per different debuff on the target.' WHERE `id` = 30205;
UPDATE `bonk_mastery` SET `description` = 'Arcane Shot slows normal enemies by 30% for 2 sec.' WHERE `id` = 30206;
UPDATE `bonk_mastery` SET `description` = 'Aimed Shot marks every enemy it passes through.' WHERE `id` = 30207;
UPDATE `bonk_mastery` SET `description` = 'Your shots target Marked enemies first and deal 40% more damage to them. Unmarked enemies take 25% less damage from you.' WHERE `id` = 30210;
UPDATE `bonk_mastery` SET `description` = 'Explosive Trap fire and Frost Trap ice last 15% longer.' WHERE `id` = 30305;
UPDATE `bonk_mastery` SET `description` = 'Frost Trap freezes normal enemies in its ice when it springs. Once per enemy every 6 sec.' WHERE `id` = 30306;
UPDATE `bonk_mastery` SET `description` = 'Taking damage drops an Explosive Trap at your feet. Once every 5 sec.' WHERE `id` = 30307;
UPDATE `bonk_mastery` SET `description` = 'Each dash leaves one of each of your traps behind, armed at once. Your maximum health is reduced by 15%.' WHERE `id` = 30310;

UPDATE `bonk_mastery` SET `description` = 'Your abilities apply 1 additional Poison stack per hit, even without Deadly Poison. Your Power is reduced by 15%.' WHERE `id` = 40110;
UPDATE `bonk_mastery` SET `description` = 'Your single-target hits also strike 1 enemy within 8 yards for 50% damage, even without Blade Flurry. Your critical strike chance is reduced by 10%.' WHERE `id` = 40210;
UPDATE `bonk_mastery` SET `description` = '+5% damage to enemies above 80% health.' WHERE `id` = 40305;
UPDATE `bonk_mastery` SET `description` = 'Ambush also hits every enemy within 5 yards of the target for 50% damage. Your maximum health is reduced by 15%.' WHERE `id` = 40310;

UPDATE `bonk_mastery` SET `description` = 'Take 20% less damage while you have a Shield. Your Power is reduced by 15%.' WHERE `id` = 50110;
UPDATE `bonk_mastery` SET `description` = 'Renew smites while you are above 80% health, not only at full. Smite and Halo cut 2 sec off Holy Word: Chastise. Your maximum health is reduced by 15%.' WHERE `id` = 50210;
UPDATE `bonk_mastery` SET `description` = 'Taking damage triggers Mind Blast. Once every 6 sec.' WHERE `id` = 50306;

UPDATE `bonk_mastery` SET `description` = 'Static discharges at 3 stacks instead of 5. You deal 15% less damage to enemies without Static.' WHERE `id` = 70110;
UPDATE `bonk_mastery` SET `description` = '+3% critical strike chance for your spirit wolves and totems.' WHERE `id` = 70205;
UPDATE `bonk_mastery` SET `description` = 'Taking damage makes Stormstrike hit every enemy around you. Once every 6 sec.' WHERE `id` = 70206;
UPDATE `bonk_mastery` SET `description` = 'Windfury Weapon triggers Windfury every 2nd swing instead of every 3rd. Maelstrom Weapon needs 3 melee hits instead of 5. Your maximum health is reduced by 15%.' WHERE `id` = 70210;

UPDATE `bonk_mastery` SET `description` = 'Unlocks Arcane Missiles as a starter spell, with Blink as your dash.' WHERE `id` = 80102;
UPDATE `bonk_mastery` SET `description` = 'Your spells have a 2% chance to recharge instantly.' WHERE `id` = 80105;
UPDATE `bonk_mastery` SET `description` = 'Arcane Explosion slows normal enemies by 30% for 2 sec.' WHERE `id` = 80106;
UPDATE `bonk_mastery` SET `description` = 'Each Blink grants a Shield of 3% of your maximum health.' WHERE `id` = 80107;
UPDATE `bonk_mastery` SET `description` = 'Fire Blast deals 2% more damage per Burning stack on the target.' WHERE `id` = 80205;
UPDATE `bonk_mastery` SET `description` = 'Frostbolt deals 10% more damage to Frozen enemies.' WHERE `id` = 80305;
UPDATE `bonk_mastery` SET `description` = 'Taking damage triggers Frost Nova around you. Once every 6 sec.' WHERE `id` = 80306;
UPDATE `bonk_mastery` SET `description` = 'Once per stage, dropping below 20% health encases you in ice: no damage taken for 2 sec, and enemies within 10 yards gain 10 Chill stacks.' WHERE `id` = 80307;
UPDATE `bonk_mastery` SET `description` = 'Chill freezes at 6 stacks instead of 10. You deal 15% less damage to enemies that aren''t Frozen.' WHERE `id` = 80310;

UPDATE `bonk_mastery` SET `description` = 'When an enemy with your Decay or Agony dies, they jump to the nearest enemy without them, keeping every stack. Your Power is reduced by 15%.' WHERE `id` = 90110;
UPDATE `bonk_mastery` SET `description` = '+3% demon critical strike chance.' WHERE `id` = 90205;
UPDATE `bonk_mastery` SET `description` = 'Your demons deal 10% more damage for each different demon you command, up to 40%. Your Power is reduced by 15%.' WHERE `id` = 90210;
UPDATE `bonk_mastery` SET `description` = 'Nightfall fires up to 3 free Shadow Bolts per sec instead of 1, and they deal 50% more damage. Your critical strike chance is reduced by 10%.' WHERE `id` = 90310;

UPDATE `bonk_mastery` SET `description` = 'Cat Form: take 20% less damage. Bear Form: +15% movement speed, and critical strikes cause Bleed. Your Power is reduced by 15%.' WHERE `id` = 110210;
UPDATE `bonk_mastery` SET `description` = 'You can''t change forms. Your Shapeshift spell keeps attacking, always with Wrath, for 35% less damage. Your other Druid spells deal and heal 15% more for each different talent tree they come from, up to 45%.' WHERE `id` = 110310;

UPDATE `bonk_talent` SET `description` = '+1 reroll per run.' WHERE `id` = 5;
UPDATE `bonk_talent` SET `description` = '+1 banish per run. Banished choices don''t return that run.' WHERE `id` = 6;
UPDATE `bonk_talent` SET `description` = 'Once per run, fatal damage revives you at 50% health.' WHERE `id` = 7;
UPDATE `bonk_talent` SET `description` = 'Start runs with +25 Valor.' WHERE `id` = 8;
UPDATE `bonk_talent` SET `description` = '+1 skip per run. Skipping pays a quarter of a chest''s price in Valor.' WHERE `id` = 9;
UPDATE `bonk_talent` SET `description` = '+1 passive slot in runs.' WHERE `id` = 10;
UPDATE `bonk_talent` SET `description` = '+1 spell slot in runs.' WHERE `id` = 11;
UPDATE `bonk_talent` SET `description` = 'Evolution offers let you pick any evolution of that spell.' WHERE `id` = 12;
UPDATE `bonk_talent` SET `description` = 'Take 50% less healing. +20% gold.' WHERE `id` = 15;

UPDATE `bonk_upgrade` SET `description` = '+10% pickup range.' WHERE `id` = 14;
UPDATE `bonk_upgrade` SET `description` = '+3 Luck.' WHERE `id` = 15;
UPDATE `bonk_upgrade` SET `description` = '+0.8 yd dash distance.' WHERE `id` = 16;
UPDATE `bonk_upgrade` SET `description` = '-0.6 sec dash cooldown.' WHERE `id` = 17;
UPDATE `bonk_upgrade` SET `description` = '+1 dash charge.' WHERE `id` = 18;
UPDATE `bonk_upgrade` SET `description` = 'Chests and vendor wares cost 4% less Valor.' WHERE `id` = 19;
UPDATE `bonk_upgrade` SET `description` = 'Chests offer 1 more Darkmoon Card.' WHERE `id` = 21;
UPDATE `bonk_upgrade` SET `description` = '+2 sec on timed events, such as treasure goblins and bounties.' WHERE `id` = 23;
UPDATE `bonk_upgrade` SET `description` = '+20% Hearthstone find chance. Stand in its ring 1 sec less.' WHERE `id` = 25;
UPDATE `bonk_upgrade` SET `description` = '+1 starting level in runs, with its level-up choice.' WHERE `id` = 26;
UPDATE `bonk_upgrade` SET `description` = '+1 Extraction Vault slot. The Hearthstone''s vault still holds 1.' WHERE `id` = 28;
UPDATE `bonk_upgrade` SET `description` = '+1 Darkmoon Card or Glyph you can switch off in the Spellbook. Switched-off ones are never offered.' WHERE `id` = 29;
UPDATE `bonk_upgrade` SET `description` = 'Choose an extra Glyph at the start of every run.' WHERE `id` = 30;
UPDATE `bonk_upgrade` SET `description` = 'Zixil can restock 1 more time per visit.' WHERE `id` = 31;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
