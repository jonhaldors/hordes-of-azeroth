DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012150000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012150000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `elite_affixes` TINYINT UNSIGNED NOT NULL DEFAULT 1 COMMENT 'affixes every elite rolls; mini-bosses roll one more' AFTER `elite_dodge`;
UPDATE `bonk_tier` SET `elite_affixes` = 1 WHERE `key` = 'easy';
UPDATE `bonk_tier` SET `elite_affixes` = 2 WHERE `key` = 'medium';
UPDATE `bonk_tier` SET `elite_affixes` = 3 WHERE `key` = 'hard';

DROP TEMPORARY TABLE IF EXISTS `bonk_pool_template`;
CREATE TEMPORARY TABLE `bonk_pool_template` SELECT * FROM `creature_template` WHERE `entry` = 12758 AND `patch` = 0;
UPDATE `bonk_pool_template` SET `entry` = 900110, `name` = 'Sanguine Pool', `subname` = '', `faction` = 35, `npc_flags` = 0, `gossip_menu_id` = 0,
    `level_min` = 1, `level_max` = 1, `movement_type` = 0, `speed_walk` = 1, `speed_run` = 1, `detection_range` = 0, `call_for_help_range` = 0,
    `loot_id` = 0, `pickpocket_loot_id` = 0, `skinning_loot_id` = 0, `gold_min` = 0, `gold_max` = 0, `spell_list_id` = 0,
    `auras` = NULL, `ai_name` = '', `script_name` = '', `static_flags1` = 0, `static_flags2` = 0, `flags_extra` = 0, `civilian` = 0;
DELETE FROM `creature_template` WHERE `entry` = 900110;
INSERT INTO `creature_template` SELECT * FROM `bonk_pool_template`;
DROP TEMPORARY TABLE `bonk_pool_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
