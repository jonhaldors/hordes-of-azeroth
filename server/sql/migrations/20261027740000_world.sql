DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027740000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027740000');

DELETE FROM `creature_template` WHERE `entry` = 900151;
CREATE TEMPORARY TABLE `bonk_skeleton_template` SELECT * FROM `creature_template` WHERE `entry` = 900117;
UPDATE `bonk_skeleton_template` SET `entry` = 900151, `name` = 'Risen Skeleton', `display_id1` = 7846, `display_scale1` = 1;
INSERT INTO `creature_template` SELECT * FROM `bonk_skeleton_template`;
DROP TEMPORARY TABLE `bonk_skeleton_template`;

INSERT INTO `bonk_glyph` (`id`, `name`, `icon`, `description`, `drawback`, `rarity`, `effect`, `value1`, `value2`, `value3`, `card_id`, `starter`) VALUES
(39, 'Glyph of Raise Dead', 'Spell_Shadow_RaiseDead', 'Elites you kill rise as skeletons and fight for you for 20 sec. Up to 5 at a time.', '', 3, 36, 20000, 5, 30, 0, 0);

INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(417, 'Bone Collector', 'Reach Mythic floor 17.', 'Spell_Shadow_RaiseDead', 3, 2, 0, 17, 12, 39, 0, 3);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
