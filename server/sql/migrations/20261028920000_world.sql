DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028920000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028920000');

UPDATE `bonk_mastery` SET `icon` = 'Ability_Gouge', `name` = 'Lethal Wounds', `description` = 'Your Bleed can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 4, `value_per_rank` = 1, `param` = 0 WHERE `id` = 10125;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Shadow_UnholyFrenzy', `name` = 'Bloodcraze', `description` = 'Killing an enemy with Execute makes you Enraged.', `max_rank` = 1, `effect` = 45, `target` = 103, `value_per_rank` = 1, `param` = 0 WHERE `id` = 10214;
UPDATE `bonk_mastery` SET `icon` = 'Ability_ThunderClap', `name` = 'Thunder Ward', `description` = 'Each enemy Thunder Clap hits gives you a Shield of 1% of your maximum health, up to 5% per cast.', `max_rank` = 1, `effect` = 45, `target` = 104, `value_per_rank` = 1, `param` = 0 WHERE `id` = 10314;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Holy_SearingLight', `name` = 'Glimmer of Light', `description` = 'Enemies struck by Light''s Hammer take 8% more damage from you for 4 sec.', `max_rank` = 1, `effect` = 45, `target` = 105, `value_per_rank` = 8, `param` = 0 WHERE `id` = 20127;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Holy_AuraOfLight', `name` = 'Consecrated Wrath', `description` = 'Enemies standing in your Consecration take your Retribution Aura''s damage every second, at half strength.', `max_rank` = 1, `effect` = 45, `target` = 106, `value_per_rank` = 50, `param` = 0 WHERE `id` = 20211;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Warrior_InnerRage', `name` = 'Righteous Command', `description` = 'Judgement critical strikes set off Seal of Command''s burst on their target.', `max_rank` = 1, `effect` = 45, `target` = 107, `value_per_rank` = 1, `param` = 0 WHERE `id` = 20327;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Druid_Rake', `name` = 'Savage Bite', `description` = 'Your Bleed can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 4, `value_per_rank` = 1, `param` = 0 WHERE `id` = 30114;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Hunter_SniperShot', `name` = 'Hunt the Pack', `description` = 'When a Marked enemy dies, Hunter''s Mark moves to the nearest unmarked enemy within 20 yards.', `max_rank` = 1, `effect` = 45, `target` = 108, `value_per_rank` = 1, `param` = 0 WHERE `id` = 30214;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_NullifyPoison', `name` = 'Lethal Venom', `description` = 'Your Poison can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 5, `value_per_rank` = 1, `param` = 0 WHERE `id` = 30327;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Poisons', `name` = 'Lethality', `description` = 'Your Poison can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 5, `value_per_rank` = 1, `param` = 0 WHERE `id` = 40114;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Rogue_SliceDice', `name` = 'Ruthless Spree', `description` = 'Killing Spree''s strikes always critically strike.', `max_rank` = 1, `effect` = 45, `target` = 109, `value_per_rank` = 1, `param` = 0 WHERE `id` = 40211;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Rogue_Ambush', `name` = 'Shadow Strikes', `description` = 'Shuriken Toss critical strikes set off Ambush on their target. Once per enemy every 6 sec.', `max_rank` = 1, `effect` = 45, `target` = 110, `value_per_rank` = 1, `param` = 0 WHERE `id` = 40325;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Holy_PowerWordShield', `name` = 'Penitent Ward', `description` = 'Penance critical strikes give you a Shield of 1% of your maximum health.', `max_rank` = 1, `effect` = 45, `target` = 111, `value_per_rank` = 1, `param` = 0 WHERE `id` = 50126;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Holy_Renew', `name` = 'Renewed Hope', `description` = 'Renew''s overhealing becomes a Shield, up to 5% of your maximum health.', `max_rank` = 1, `effect` = 45, `target` = 112, `value_per_rank` = 5, `param` = 0 WHERE `id` = 50228;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Shadow_ShadowWordPain', `name` = 'Twisted Faith', `description` = 'Your Decay can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 13, `value_per_rank` = 1, `param` = 0 WHERE `id` = 50328;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_Lightning', `name` = 'Charged Bolts', `description` = 'Lightning Bolt critical strikes apply 1 stack of Static.', `max_rank` = 1, `effect` = 45, `target` = 113, `value_per_rank` = 1, `param` = 0 WHERE `id` = 70127;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_Cyclone', `name` = 'Stormlash', `description` = 'Stormstrike critical strikes trigger Windfury.', `max_rank` = 1, `effect` = 45, `target` = 114, `value_per_rank` = 1, `param` = 0 WHERE `id` = 70211;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Fire_SearingTotem', `name` = 'Searing Heat', `description` = 'Your Burning can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 3, `value_per_rank` = 1, `param` = 0 WHERE `id` = 70312;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_StarFall', `name` = 'Arcane Splinters', `description` = 'Arcane Missiles'' critical strikes also hit 1 nearby enemy.', `max_rank` = 1, `effect` = 45, `target` = 115, `value_per_rank` = 1, `param` = 0 WHERE `id` = 80114;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Fire_SoulBurn', `name` = 'Critical Mass', `description` = 'Your Burning can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 3, `value_per_rank` = 1, `param` = 0 WHERE `id` = 80214;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Frost_ChillingBlast', `name` = 'Lingering Frost', `description` = 'Frozen enemies gain 3 stacks of Chill when they thaw.', `max_rank` = 1, `effect` = 45, `target` = 116, `value_per_rank` = 3, `param` = 0 WHERE `id` = 80327;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Shadow_Requiem', `name` = 'Malefic Grasp', `description` = 'Your Decay and Agony can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 13, `value_per_rank` = 1, `param` = 14 WHERE `id` = 90126;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Shadow_SummonFelHunter', `name` = 'Fel Cleave', `description` = 'When a demon kills an enemy, it strikes every enemy within 5 yards for 50% of its damage.', `max_rank` = 1, `effect` = 45, `target` = 117, `value_per_rank` = 50, `param` = 0 WHERE `id` = 90214;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Fire_Immolation', `name` = 'Molten Core', `description` = 'Your Burning can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 3, `value_per_rank` = 1, `param` = 0 WHERE `id` = 90326;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_MoonGlow', `name` = 'Lunar Shower', `description` = 'Your Moonfire can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 15, `value_per_rank` = 1, `param` = 0 WHERE `id` = 110125;
UPDATE `bonk_mastery` SET `icon` = 'Ability_Druid_Disembowel', `name` = 'Rip and Tear', `description` = 'Your Bleed can critically strike for half the critical strike bonus.', `max_rank` = 1, `effect` = 47, `target` = 4, `value_per_rank` = 1, `param` = 0 WHERE `id` = 110227;
UPDATE `bonk_mastery` SET `icon` = 'Spell_Nature_StrangleVines', `name` = 'Creeping Vines', `description` = 'When a rooted enemy dies, its roots grasp the nearest enemy within 8 yards for 2 sec.', `max_rank` = 1, `effect` = 45, `target` = 118, `value_per_rank` = 1, `param` = 0 WHERE `id` = 110326;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;