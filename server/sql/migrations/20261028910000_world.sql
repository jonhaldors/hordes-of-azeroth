DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028910000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028910000');

ALTER TABLE `bonk_title` ADD COLUMN `pattern` VARCHAR(64) NOT NULL DEFAULT '' AFTER `name`,
    ADD COLUMN `class` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `pattern`,
    ADD COLUMN `stat` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `class`,
    ADD COLUMN `value` FLOAT NOT NULL DEFAULT 0 AFTER `stat`;
UPDATE `bonk_title` SET `pattern` = '%s the Swift' WHERE `id` = 1;

INSERT INTO `bonk_title` (`id`, `name`, `pattern`, `class`, `stat`, `value`) VALUES
(2, 'the Relentless', '%s the Relentless', 1, 15, 2),
(3, 'Champion of Azeroth', '%s, Champion of Azeroth', 1, 15, 3),
(4, 'the Lightsworn', '%s the Lightsworn', 2, 4, 2),
(5, 'the Ashbringer', '%s the Ashbringer', 2, 4, 3),
(6, 'Stalker of the Wilds', '%s, Stalker of the Wilds', 3, 1, 2),
(7, 'Master of the Hunt', '%s, Master of the Hunt', 3, 1, 3),
(8, 'the Unseen', '%s the Unseen', 4, 16, 2),
(9, 'Kingslayer', '%s the Kingslayer', 4, 16, 3),
(10, 'the Faithful', '%s the Faithful', 5, 11, 2),
(11, 'Light of Azeroth', '%s, Light of Azeroth', 5, 11, 3),
(12, 'Voice of the Elements', '%s, Voice of the Elements', 7, 1, 2),
(13, 'Thunderlord', 'Thunderlord %s', 7, 1, 3),
(14, 'Archmage', 'Archmage %s', 8, 15, 2),
(15, 'Guardian of Tirisfal', '%s, Guardian of Tirisfal', 8, 15, 3),
(16, 'the Netherbound', '%s the Netherbound', 9, 11, 2),
(17, 'Master of Shadows', '%s, Master of Shadows', 9, 11, 3),
(18, 'Keeper of the Grove', '%s, Keeper of the Grove', 11, 0, 2),
(19, 'Archdruid', 'Archdruid %s', 11, 0, 3);

INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(540, 'Into the Deep', 'Clear Mythic floor 5 as a warrior.', 'Ability_Warrior_PunishingBlow', 3, 2, 0, 6, 1, 25, 1, 2),
(541, 'Halfway Down', 'Clear Mythic floor 10 as a warrior.', 'Ability_Warrior_PunishingBlow', 3, 2, 0, 11, 1, 50, 1, 2),
(542, 'Relentless', 'Clear Mythic floor 15 as a warrior.', 'Ability_Warrior_PunishingBlow', 3, 2, 0, 16, 10, 2, 1, 2),
(543, 'Champion of Azeroth', 'Clear Mythic floor 20 as a warrior.', 'Ability_Warrior_PunishingBlow', 3, 2, 0, 21, 10, 3, 1, 2),
(544, 'Into the Deep', 'Clear Mythic floor 5 as a paladin.', 'Spell_Holy_DivineIntervention', 3, 2, 0, 6, 1, 25, 2, 2),
(545, 'Halfway Down', 'Clear Mythic floor 10 as a paladin.', 'Spell_Holy_DivineIntervention', 3, 2, 0, 11, 1, 50, 2, 2),
(546, 'Lightsworn', 'Clear Mythic floor 15 as a paladin.', 'Spell_Holy_DivineIntervention', 3, 2, 0, 16, 10, 4, 2, 2),
(547, 'Ashbringer', 'Clear Mythic floor 20 as a paladin.', 'Spell_Holy_DivineIntervention', 3, 2, 0, 21, 10, 5, 2, 2),
(548, 'Into the Deep', 'Clear Mythic floor 5 as a hunter.', 'Spell_Fire_Volcano', 3, 2, 0, 6, 1, 25, 3, 2),
(549, 'Halfway Down', 'Clear Mythic floor 10 as a hunter.', 'Spell_Fire_Volcano', 3, 2, 0, 11, 1, 50, 3, 2),
(550, 'Stalker of the Wilds', 'Clear Mythic floor 15 as a hunter.', 'Spell_Fire_Volcano', 3, 2, 0, 16, 10, 6, 3, 2),
(551, 'Master of the Hunt', 'Clear Mythic floor 20 as a hunter.', 'Spell_Fire_Volcano', 3, 2, 0, 21, 10, 7, 3, 2),
(552, 'Into the Deep', 'Clear Mythic floor 5 as a rogue.', 'Spell_Shadow_Possession', 3, 2, 0, 6, 1, 25, 4, 2),
(553, 'Halfway Down', 'Clear Mythic floor 10 as a rogue.', 'Spell_Shadow_Possession', 3, 2, 0, 11, 1, 50, 4, 2),
(554, 'Unseen', 'Clear Mythic floor 15 as a rogue.', 'Spell_Shadow_Possession', 3, 2, 0, 16, 10, 8, 4, 2),
(555, 'Kingslayer', 'Clear Mythic floor 20 as a rogue.', 'Spell_Shadow_Possession', 3, 2, 0, 21, 10, 9, 4, 2),
(556, 'Into the Deep', 'Clear Mythic floor 5 as a priest.', 'Spell_Shadow_Shadowform', 3, 2, 0, 6, 1, 25, 5, 2),
(557, 'Halfway Down', 'Clear Mythic floor 10 as a priest.', 'Spell_Shadow_Shadowform', 3, 2, 0, 11, 1, 50, 5, 2),
(558, 'Faithful', 'Clear Mythic floor 15 as a priest.', 'Spell_Shadow_Shadowform', 3, 2, 0, 16, 10, 10, 5, 2),
(559, 'Light of Azeroth', 'Clear Mythic floor 20 as a priest.', 'Spell_Shadow_Shadowform', 3, 2, 0, 21, 10, 11, 5, 2),
(560, 'Into the Deep', 'Clear Mythic floor 5 as a shaman.', 'Spell_Nature_CallStorm', 3, 2, 0, 6, 1, 25, 7, 2),
(561, 'Halfway Down', 'Clear Mythic floor 10 as a shaman.', 'Spell_Nature_CallStorm', 3, 2, 0, 11, 1, 50, 7, 2),
(562, 'Voice of the Elements', 'Clear Mythic floor 15 as a shaman.', 'Spell_Nature_CallStorm', 3, 2, 0, 16, 10, 12, 7, 2),
(563, 'Thunderlord', 'Clear Mythic floor 20 as a shaman.', 'Spell_Nature_CallStorm', 3, 2, 0, 21, 10, 13, 7, 2),
(564, 'Into the Deep', 'Clear Mythic floor 5 as a mage.', 'Spell_Nature_Lightning', 3, 2, 0, 6, 1, 25, 8, 2),
(565, 'Halfway Down', 'Clear Mythic floor 10 as a mage.', 'Spell_Nature_Lightning', 3, 2, 0, 11, 1, 50, 8, 2),
(566, 'Archmage', 'Clear Mythic floor 15 as a mage.', 'Spell_Nature_Lightning', 3, 2, 0, 16, 10, 14, 8, 2),
(567, 'Guardian of Tirisfal', 'Clear Mythic floor 20 as a mage.', 'Spell_Nature_Lightning', 3, 2, 0, 21, 10, 15, 8, 2),
(568, 'Into the Deep', 'Clear Mythic floor 5 as a warlock.', 'Spell_Shadow_ShadowPact', 3, 2, 0, 6, 1, 25, 9, 2),
(569, 'Halfway Down', 'Clear Mythic floor 10 as a warlock.', 'Spell_Shadow_ShadowPact', 3, 2, 0, 11, 1, 50, 9, 2),
(570, 'Netherbound', 'Clear Mythic floor 15 as a warlock.', 'Spell_Shadow_ShadowPact', 3, 2, 0, 16, 10, 16, 9, 2),
(571, 'Master of Shadows', 'Clear Mythic floor 20 as a warlock.', 'Spell_Shadow_ShadowPact', 3, 2, 0, 21, 10, 17, 9, 2),
(572, 'Into the Deep', 'Clear Mythic floor 5 as a druid.', 'Spell_Nature_Reincarnation', 3, 2, 0, 6, 1, 25, 11, 2),
(573, 'Halfway Down', 'Clear Mythic floor 10 as a druid.', 'Spell_Nature_Reincarnation', 3, 2, 0, 11, 1, 50, 11, 2),
(574, 'Keeper of the Grove', 'Clear Mythic floor 15 as a druid.', 'Spell_Nature_Reincarnation', 3, 2, 0, 16, 10, 18, 11, 2),
(575, 'Archdruid', 'Clear Mythic floor 20 as a druid.', 'Spell_Nature_Reincarnation', 3, 2, 0, 21, 10, 19, 11, 2);
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
