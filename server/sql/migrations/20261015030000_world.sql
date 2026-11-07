DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015030000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015030000');

ALTER TABLE `bonk_quest`
    MODIFY COLUMN `type` TINYINT UNSIGNED NOT NULL COMMENT '0 kills, 1 kills of a kind, 2 kills with a weapon, 3 stage on a tier, 4 level in one run, 5 Darkmoon Tickets found, 6 crits in one run, 7 health healed, 8 kills of a creature type, 9 Ley Lines, 10 Greed stacks at a stage clear, 11 stage cleared with classes, 12 boss killed before a time, 13 hidden encounter, 14 shrine kinds, 15 heirlooms extracted, 16 Mastery level',
    MODIFY COLUMN `target` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'type 1: spawn kind (1 elite, 2 boss, 3 mini-boss); 2: bonk_weapon.id (its evolution counts); 3: bonk_tier.id; 8: creature type (6 undead); 11: class mask; 12: bonk_tier.id or 0; 13: encounter id; 16: class id or 0',
    ADD COLUMN `param` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'type 11: the stage to clear; 12: second of the stage the boss must die before' AFTER `target`,
    MODIFY COLUMN `amount` INT UNSIGNED NOT NULL COMMENT 'kills, stage, level, tickets, crits, health, classes, bosses, stacks, shrine kinds, heirlooms or Mastery level needed',
    MODIFY COLUMN `reward_type` TINYINT UNSIGNED NOT NULL COMMENT '0 gold, 1 Darkmoon Tickets, 2 spell, 3 passive, 4 fortune, 5 upgrade, 6 talent points (class quests), 7 class, 8 Epic spell rank, 9 talent capstone, 10 title',
    MODIFY COLUMN `reward_value` INT UNSIGNED NOT NULL COMMENT 'copper, tickets, points, or the id of what it unlocks (class id, bonk_weapon, bonk_mastery, bonk_title)',
    ADD COLUMN `category` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'quest board tab: 0 Slayer, 1 Victory, 2 Mastery, 3 Challenge, 4 Discovery, 5 Collection' AFTER `class`;

CREATE TABLE IF NOT EXISTS `bonk_title` (
    `id` INT UNSIGNED NOT NULL,
    `name` VARCHAR(64) NOT NULL COMMENT 'as shown after the hero''s name',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk titles, quest rewards';
DELETE FROM `bonk_title` WHERE `id` = 1;
INSERT INTO `bonk_title` (`id`, `name`) VALUES (1, 'the Swift');

UPDATE `bonk_quest` SET `category` = 0 WHERE `type` IN (0, 1, 2);
UPDATE `bonk_quest` SET `category` = 1 WHERE `type` = 3;
UPDATE `bonk_quest` SET `category` = 3 WHERE `type` = 4;
UPDATE `bonk_quest` SET `category` = 5 WHERE `type` = 5;
UPDATE `bonk_quest` SET `category` = 2 WHERE `class` <> 0;

UPDATE `bonk_quest` SET `reward_type` = 1, `reward_value` = 3 WHERE `id` = 6;
UPDATE `bonk_quest` SET `reward_type` = 0, `reward_value` = 10000 WHERE `id` = 13;

DELETE FROM `bonk_quest` WHERE `id` BETWEEN 200 AND 207;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(200, 'Precision', 'Land 500 critical strikes in a single run.', 'Ability_Rogue_Ambush', 6, 0, 0, 500, 7, 4, 0, 1),
(201, 'Mender', 'Heal 10,000 health, across all your runs.', 'Spell_Holy_FlashHeal', 7, 0, 0, 10000, 7, 5, 0, 1),
(202, 'Scourge Bane', 'Kill 2,000 undead.', 'Spell_Holy_TurnUndead', 8, 6, 0, 2000, 7, 2, 0, 1),
(203, 'Many Forms', 'Clear stage 1 with a Warrior, a Hunter and a Mage.', 'Spell_Nature_Regeneration', 11, 133, 1, 3, 7, 11, 0, 1),
(204, 'Seasoned Warrior', 'Reach Mastery level 10 with a Warrior.', 'Ability_Warrior_BattleShout', 16, 1, 0, 10, 1, 5, 0, 2),
(205, 'Seasoned Hunter', 'Reach Mastery level 10 with a Hunter.', 'Ability_Hunter_BeastTaming', 16, 3, 0, 10, 1, 5, 0, 2),
(206, 'Seasoned Mage', 'Reach Mastery level 10 with a Mage.', 'Spell_Holy_MagicalSentry', 16, 8, 0, 10, 1, 5, 0, 2),
(207, 'Swift Justice', 'Kill a stage boss before the stage clock reaches 10:45.', 'Ability_Rogue_Sprint', 12, 0, 645, 1, 10, 1, 0, 3);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
