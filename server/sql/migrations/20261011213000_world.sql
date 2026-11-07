DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261011213000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261011213000');

CREATE TABLE IF NOT EXISTS `bonk_shop_tree` (
    `id`         INT UNSIGNED     NOT NULL,
    `shop`       TINYINT UNSIGNED NOT NULL COMMENT '1 = upgrades (quartermaster), 2 = talents (talent trainer)',
    `name`       VARCHAR(32)      NOT NULL,
    `background` VARCHAR(64)      NOT NULL COMMENT 'Interface\\TalentFrame art, e.g. WarriorArms',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk talent trees of the camp shops';

DELETE FROM `bonk_shop_tree`;
INSERT INTO `bonk_shop_tree` (`id`, `shop`, `name`, `background`) VALUES
(1, 1, 'Offense',    'WarriorArms'),
(2, 1, 'Defense',    'WarriorProtection'),
(3, 1, 'Fortune',    'PaladinHoly'),
(4, 2, 'Tricks',     'MageArcane'),
(5, 2, 'Challenges', 'WarlockDestruction');

ALTER TABLE `bonk_upgrade`
    ADD COLUMN `icon`          VARCHAR(64)      NOT NULL DEFAULT 'INV_Misc_QuestionMark' COMMENT 'Interface\\Icons file name',
    ADD COLUMN `tree`          INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'bonk_shop_tree.id',
    ADD COLUMN `tree_row`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    ADD COLUMN `tree_column`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    ADD COLUMN `required_id`   INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'bonk_upgrade.id to learn first',
    ADD COLUMN `required_rank` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'ranks of it needed';

ALTER TABLE `bonk_talent`
    ADD COLUMN `icon`          VARCHAR(64)      NOT NULL DEFAULT 'INV_Misc_QuestionMark' COMMENT 'Interface\\Icons file name',
    ADD COLUMN `tree`          INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'bonk_shop_tree.id',
    ADD COLUMN `tree_row`      TINYINT UNSIGNED NOT NULL DEFAULT 1,
    ADD COLUMN `tree_column`   TINYINT UNSIGNED NOT NULL DEFAULT 1,
    ADD COLUMN `required_id`   INT UNSIGNED     NOT NULL DEFAULT 0 COMMENT 'bonk_talent.id to learn first',
    ADD COLUMN `required_rank` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'ranks of it needed';

UPDATE `bonk_upgrade` SET `icon` = 'Spell_Holy_FistOfJustice',  `tree` = 1, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 1;
UPDATE `bonk_upgrade` SET `icon` = 'INV_Misc_PocketWatch_01',   `tree` = 1, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `icon` = 'INV_Misc_Gem_Variety_01',   `tree` = 1, `tree_row` = 3, `tree_column` = 2,
    `required_id` = 1, `required_rank` = 3 WHERE `id` = 8;
UPDATE `bonk_upgrade` SET `icon` = 'Spell_Holy_WordFortitude',  `tree` = 2, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 3;
UPDATE `bonk_upgrade` SET `icon` = 'Ability_Rogue_Sprint',      `tree` = 2, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 5;
UPDATE `bonk_upgrade` SET `icon` = 'Spell_Nature_Rejuvenation', `tree` = 2, `tree_row` = 2, `tree_column` = 2,
    `required_id` = 3, `required_rank` = 2 WHERE `id` = 4;
UPDATE `bonk_upgrade` SET `icon` = 'INV_Misc_Bag_10',           `tree` = 3, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 6;
UPDATE `bonk_upgrade` SET `icon` = 'INV_Misc_Book_09',          `tree` = 3, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 7;

UPDATE `bonk_talent` SET `icon` = 'INV_Misc_Coin_02',            `tree` = 4, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 8;
UPDATE `bonk_talent` SET `icon` = 'Spell_Holy_MindVision',       `tree` = 4, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 5;
UPDATE `bonk_talent` SET `icon` = 'Spell_Shadow_Cripple',        `tree` = 4, `tree_row` = 2, `tree_column` = 3,
    `required_id` = 5, `required_rank` = 1 WHERE `id` = 6;
UPDATE `bonk_talent` SET `icon` = 'Spell_Nature_Reincarnation',  `tree` = 4, `tree_row` = 3, `tree_column` = 2 WHERE `id` = 7;
UPDATE `bonk_talent` SET `icon` = 'Spell_Nature_StoneSkinTotem', `tree` = 5, `tree_row` = 1, `tree_column` = 2 WHERE `id` = 1;
UPDATE `bonk_talent` SET `icon` = 'Spell_Nature_InsectSwarm',    `tree` = 5, `tree_row` = 1, `tree_column` = 3 WHERE `id` = 3;
UPDATE `bonk_talent` SET `icon` = 'Ability_Racial_BloodRage',    `tree` = 5, `tree_row` = 2, `tree_column` = 2,
    `required_id` = 1, `required_rank` = 1 WHERE `id` = 2;
UPDATE `bonk_talent` SET `icon` = 'Ability_Warrior_Challange',   `tree` = 5, `tree_row` = 2, `tree_column` = 3,
    `required_id` = 3, `required_rank` = 1 WHERE `id` = 4;

UPDATE `bonk_upgrade` SET `description` = '+5% weapon damage.'                       WHERE `id` = 1;
UPDATE `bonk_upgrade` SET `description` = 'Weapons fire 4% faster.'                  WHERE `id` = 2;
UPDATE `bonk_upgrade` SET `description` = '+10% maximum health.'                     WHERE `id` = 3;
UPDATE `bonk_upgrade` SET `description` = 'Regain 0.2% health every second.'         WHERE `id` = 4;
UPDATE `bonk_upgrade` SET `description` = '+5% movement speed.'                      WHERE `id` = 5;
UPDATE `bonk_upgrade` SET `description` = '+10% gold.'                               WHERE `id` = 6;
UPDATE `bonk_upgrade` SET `description` = '+5% experience.'                          WHERE `id` = 7;
UPDATE `bonk_upgrade` SET `description` = '+1 projectile for bolt weapons.'          WHERE `id` = 8;
UPDATE `bonk_talent` SET `description` = 'Enemies have 50% more health. +25% gold.'  WHERE `id` = 1;
UPDATE `bonk_talent` SET `description` = 'Enemies deal 50% more damage. +25% gold.'  WHERE `id` = 2;
UPDATE `bonk_talent` SET `description` = '50% more enemies per wave. +20% gold.'     WHERE `id` = 3;
UPDATE `bonk_talent` SET `description` = 'Twice as many elites. +15% gold.'          WHERE `id` = 4;
UPDATE `bonk_talent` SET `description` = 'Reroll an upgrade choice once per run.'    WHERE `id` = 5;
UPDATE `bonk_talent` SET `description` = 'Banish an upgrade once per run.'           WHERE `id` = 6;
UPDATE `bonk_talent` SET `description` = 'Revive once per run at half health.'       WHERE `id` = 7;
UPDATE `bonk_talent` SET `description` = '+25 coins at the start of a run.'          WHERE `id` = 8;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
