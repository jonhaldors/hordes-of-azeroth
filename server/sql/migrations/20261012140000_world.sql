DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012140000');

UPDATE `bonk_weapon` SET `chain_every` = 1 WHERE `chain_every` > 0;
ALTER TABLE `bonk_weapon`
    DROP COLUMN `max_level`,
    DROP COLUMN `evolve_passive`,
    DROP COLUMN `target_every`,
    CHANGE COLUMN `chain_every` `chains` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '1: jumps from enemy to enemy; Rare ranks add jumps';

ALTER TABLE `bonk_passive`
    ADD COLUMN `excludes` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'bonk_passive a run can''t have alongside this one, either way round';
UPDATE `bonk_passive` SET `name` = 'Devotion Aura', `icon` = 'Spell_Holy_DevotionAura', `excludes` = 15 WHERE `id` = 13;
UPDATE `bonk_passive` SET `name` = 'Spirit', `icon` = 'Spell_Holy_DivineSpirit', `excludes` = 17 WHERE `id` = 6;

INSERT INTO `bonk_talent` (`id`, `name`, `description`, `effect`, `value_per_rank`, `gold_bonus`, `max_rank`, `cost`, `cost_growth`, `icon`, `tree`, `tree_row`, `tree_column`, `required_id`, `required_rank`) VALUES
(9, 'Moving On', 'Skip an upgrade choice once per run for a few coins.', 8, 1, 0, 3, 2, 0.5, 'Ability_Rogue_Sprint', 4, 1, 1, 0, 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
