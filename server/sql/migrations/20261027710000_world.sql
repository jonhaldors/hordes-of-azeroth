DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027710000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027710000');

UPDATE `bonk_card` SET `max_copies` = 0 WHERE `in_chests` = 1;

UPDATE `bonk_card` SET `stat1_value` = 0.4, `description` = 'Regain 0.4% of your health every second.' WHERE `id` = 2;
UPDATE `bonk_card` SET `stat1_value` = 16, `description` = '+16% maximum health.' WHERE `id` = 4;
UPDATE `bonk_card` SET `value1` = 1.35, `value2` = 4, `description` = 'After 4 sec without being hit, regain 1.35% of your health every second.' WHERE `id` = 5;
UPDATE `bonk_card` SET `value1` = 15, `value2` = 30, `description` = 'Turkey legs drop 15% more often and heal 30% more.' WHERE `id` = 7;
UPDATE `bonk_card` SET `value1` = 50, `value2` = 50, `value3` = 4000, `cooldown_ms` = 20000,
    `description` = 'When you drop below 50% health, run 50% faster for 4 sec. 20 sec cooldown.' WHERE `id` = 14;
UPDATE `bonk_card` SET `value1` = 20, `description` = '+20% Valor.' WHERE `id` = 26;
UPDATE `bonk_card` SET `stat1_value` = 11, `description` = '+11% movement speed.' WHERE `id` = 30;
UPDATE `bonk_card` SET `rarity` = 0, `value1` = 11, `description` = 'Chests have an 11% chance to cost nothing.' WHERE `id` = 29;
UPDATE `bonk_card` SET `rarity` = 0, `stat1_value` = 13, `icon` = 'INV_Misc_Ticket_Tarot_Elemental_01', `description` = '+13% experience.' WHERE `id` = 27;

UPDATE `bonk_card` SET `stat1_value` = 8, `description` = '+8 Armor.' WHERE `id` = 10;
UPDATE `bonk_card` SET `stat1_value` = 4, `description` = '+4% critical strike chance.' WHERE `id` = 22;
UPDATE `bonk_card` SET `stat1_value` = 7, `description` = '+7% Haste.' WHERE `id` = 23;
UPDATE `bonk_card` SET `stat1_value` = 5.5, `stat2_value` = 2.7, `description` = '+5.5% Power and +2.7% critical strike chance.' WHERE `id` = 25;
UPDATE `bonk_card` SET `value1` = 67, `description` = 'Enemies that hit you take 67% of the damage they deal.' WHERE `id` = 12;
UPDATE `bonk_card` SET `stat1_value` = 13.5, `stat2_value` = 0.2, `description` = '+13.5% maximum health. Regain 0.2% of your health every second.' WHERE `id` = 3;
UPDATE `bonk_card` SET `value1` = 1.35, `value2` = 1, `description` = 'After standing still for 1 sec, regain 1.35% of your health every second.' WHERE `id` = 6;
UPDATE `bonk_card` SET `rarity` = 1, `cooldown_ms` = 180000, `description` = 'Every 180 sec, every experience orb on the ground flies to you.' WHERE `id` = 28;

UPDATE `bonk_card` SET `value1` = 35, `value2` = 35, `value3` = 0, `cooldown_ms` = 60000,
    `description` = 'When below 35% health, heal for 35% of your maximum health. 60 sec cooldown.' WHERE `id` = 1;
UPDATE `bonk_card` SET `value1` = 6, `description` = 'Your spells have a 6% chance to cast twice.' WHERE `id` = 17;
UPDATE `bonk_card` SET `value1` = 16, `value2` = 5,
    `description` = '+16% damage to elites, mini-bosses and bosses, and they deal 5% less damage to you.' WHERE `id` = 24;
UPDATE `bonk_card` SET `value1` = 20, `value2` = 1, `value3` = 0.8,
    `description` = 'Critical strikes heal you, up to 0.8% of your maximum health a second.' WHERE `id` = 8;
UPDATE `bonk_card` SET `stat1_value` = 11, `value1` = 1, `value2` = 8,
    `description` = 'Gain a Shield of 11% of your maximum health. When it breaks, fire scorches enemies within 8 yards.' WHERE `id` = 11;
UPDATE `bonk_card` SET `value1` = 500, `value2` = 0, `value3` = 0, `cooldown_ms` = 8000,
    `description` = 'After you are hit, take no damage for 0.5 sec. 8 sec cooldown.' WHERE `id` = 13;
UPDATE `bonk_card` SET `value1` = 8, `value2` = 0.7, `value3` = 3,
    `description` = 'Your spells have an 8% chance to strike 3 enemies with lightning for 70% of the spell''s damage.' WHERE `id` = 18;
UPDATE `bonk_card` SET `value1` = 0.025, `value2` = 6.5, `description` = '+1% Power for every 40 kills, up to +6.5%.' WHERE `id` = 20;
UPDATE `bonk_card` SET `rarity` = 2, `value1` = 25, `value2` = 10000, `cooldown_ms` = 30000,
    `description` = 'Every 30 sec, gain 25% Power for 10 sec.' WHERE `id` = 21;

UPDATE `bonk_card` SET `max_copies` = 1, `value1` = 40, `description` = 'When you would die, you come back with 40% health instead. Works once.' WHERE `id` = 15;
UPDATE `bonk_card` SET `max_copies` = 1 WHERE `id` = 31;
UPDATE `bonk_card` SET `stat1` = 5, `stat1_value` = 0.25, `value1` = 20,
    `description` = 'Healing past full health becomes a Shield, up to 20% of your maximum health. Regain 0.25% of your health every second.' WHERE `id` = 9;
UPDATE `bonk_card` SET `value1` = 5, `value2` = 0.8, `value3` = 6,
    `description` = 'Your spells have a 5% chance to deal 80% of the spell''s damage as Fire to enemies within 6 yards.' WHERE `id` = 16;
UPDATE `bonk_card` SET `value1` = 4, `value2` = 5, `description` = 'Your spells have a 4% chance to deal 5 times their damage.' WHERE `id` = 19;

DELETE FROM `bonk_card` WHERE `id` IN (32, 33, 34, 35, 36, 37);
INSERT INTO `bonk_card` (`id`, `name`, `icon`, `description`, `rarity`, `stat1`, `stat1_value`, `stat2`, `stat2_value`, `effect`, `value1`, `value2`, `value3`, `cooldown_ms`, `max_copies`, `in_chests`) VALUES
(32, 'Drake Fang Talisman', 'INV_Misc_MonsterFang_01', '+12% critical strike damage.', 1, 16, 12, 255, 0, 0, 0, 0, 0, 0, 0, 1),
(33, 'Eye of Moam', 'INV_Misc_Eye_01', '+6% Area.', 1, 10, 6, 255, 0, 0, 0, 0, 0, 0, 0, 1),
(34, 'Cloak of Displacement', 'INV_Misc_Cape_18', '+3% Dodge.', 1, 14, 3, 255, 0, 0, 0, 0, 0, 0, 0, 1),
(35, 'Darkmoon Card: Blue Dragon', 'INV_Misc_Ticket_Tarot_BlueDragon_01', 'Your spells have a 10% chance to grant 25% Haste for 6 sec. 20 sec cooldown.', 2, 255, 0, 255, 0, 24, 10, 25, 6000, 20000, 0, 1),
(36, 'Venomous Totem', 'INV_Misc_Idol_02', '+15% damage over time.', 2, 255, 0, 255, 0, 26, 15, 0, 0, 0, 0, 1),
(37, 'Talisman of Ascendance', 'INV_Jewelry_Talisman_09', '+1% Power for each second without being hit, up to +20%.', 3, 255, 0, 255, 0, 25, 1, 20, 0, 0, 0, 1);

UPDATE `bonk_quest` SET `reward_type` = 1, `reward_value` = 15 WHERE `id` IN (300, 315);
UPDATE `bonk_quest` SET `reward_type` = 13, `reward_value` = 1, `icon` = 'INV_Misc_Ticket_Tarot_Stack_01' WHERE `id` = 317;
UPDATE `bonk_quest` SET `reward_type` = 14, `reward_value` = 1, `icon` = 'INV_Misc_Ticket_Tarot_Stack_01' WHERE `id` = 314;
UPDATE `bonk_quest` SET `reward_value` = 37, `icon` = 'INV_Jewelry_Talisman_09' WHERE `id` = 306;
UPDATE `bonk_quest` SET `reward_value` = 35, `icon` = 'INV_Misc_Ticket_Tarot_BlueDragon_01' WHERE `id` = 309;

DELETE FROM `bonk_quest` WHERE `id` IN (318, 319, 330);
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(318, 'Now You See Me', 'Dodge 1,000 attacks.', 'INV_Misc_Cape_18', 29, 0, 0, 1000, 11, 34, 0, 5),
(319, 'Flawless', 'Kill a floor boss without being hit.', 'INV_Jewelry_TrinketPVP_01', 24, 2, 0, 1, 11, 13, 0, 3),
(330, 'Slow Poison', 'Kill 15,000 enemies with damage over time.', 'INV_Misc_Idol_02', 38, 0, 0, 15000, 11, 36, 0, 5);

DELETE FROM `bonk_upgrade` WHERE `id` = 29;

DELETE FROM `bonk_talent` WHERE `id` IN (18, 19);
INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`, `rank_quests`) VALUES
(18, 'Stacked Deck', '+1 Darkmoon Card ban slot.', 17, 1, 0, 5, 25, 0.5, 'INV_Misc_Ticket_Tarot_Stack_01', 0, 0, 0, 0, 0, ''),
(19, 'Sealed Glyphs', '+1 Glyph ban slot.', 18, 1, 0, 3, 30, 0.5, 'INV_Misc_Book_11', 0, 0, 0, 0, 0, '');

DELETE FROM `gameobject_template` WHERE `entry` = 900063;
DROP TEMPORARY TABLE IF EXISTS `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900041;
UPDATE `bonk_go_copy` SET `entry` = 900063, `displayId` = 4712, `name` = 'Darkmoon Deck', `size` = 0.8, `script_name` = 'go_bonk_deck';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;

DELETE FROM `gameobject` WHERE `guid` = 3999100;
INSERT INTO `gameobject` (`guid`, `id`, `map`, `position_x`, `position_y`, `position_z`, `orientation`, `rotation0`, `rotation1`, `rotation2`, `rotation3`, `spawntimesecsmin`, `spawntimesecsmax`, `animprogress`, `state`, `spawn_flags`, `visibility_mod`, `patch_min`, `patch_max`) VALUES
(3999100, 900063, 1, 16251.8, 16311.0, 20.845, 0.46, 0, 0, 0.228, 0.974, 900, 900, 100, 1, 0, 0, 0, 10);

DELETE FROM `creature` WHERE `guid` = 900100;
DELETE FROM `creature_template` WHERE `entry` = 900170;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
