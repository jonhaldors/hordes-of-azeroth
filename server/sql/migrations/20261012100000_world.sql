DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012100000');

ALTER TABLE `bonk_item_stat`
    ADD COLUMN IF NOT EXISTS `armor` FLOAT NOT NULL DEFAULT 0 COMMENT 'Armor while worn: every enemy hit loses this % of a normal enemy''s hit' AFTER `defense`,
    ADD COLUMN IF NOT EXISTS `dodge` FLOAT NOT NULL DEFAULT 0 COMMENT 'better chance to dodge enemy swings while worn, %' AFTER `armor`;

UPDATE `bonk_item_stat` SET `armor` = 1, `dodge` = 0   WHERE `entry` IN (900101, 900104, 900107, 900110, 900116);
UPDATE `bonk_item_stat` SET `armor` = 2, `dodge` = 0   WHERE `entry` IN (900113, 900114, 900115);
UPDATE `bonk_item_stat` SET `armor` = 2, `dodge` = 0.5 WHERE `entry` IN (900102, 900105, 900108, 900111);
UPDATE `bonk_item_stat` SET `armor` = 3, `dodge` = 0.5 WHERE `entry` IN (900117, 900118, 900119, 900120);
UPDATE `bonk_item_stat` SET `armor` = 3, `dodge` = 1   WHERE `entry` IN (900103, 900106, 900109, 900112);
UPDATE `bonk_item_stat` SET `armor` = 4, `dodge` = 0.5 WHERE `entry` IN (900121, 900122, 900123, 900124);
UPDATE `bonk_item_stat` SET `armor` = 4, `dodge` = 0.5 WHERE `entry` IN (900125, 900126, 900127, 900128);
UPDATE `bonk_item_stat` SET `armor` = 3, `dodge` = 1   WHERE `entry` IN (900129, 900130, 900131, 900132);

ALTER TABLE `bonk_passive`
    MODIFY COLUMN `effect` TINYINT UNSIGNED NOT NULL COMMENT '0 might, 1 cooldown, 2 amount, 3 move speed, 4 max health, 5 recovery, 6 greed, 7 growth, 8 magnet, 9 leech, 10 area, 11 duration, 12 defense, 13 armor, 14 dodge';
DELETE FROM `bonk_passive` WHERE `id` IN (14, 15);
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`) VALUES
(14, 'Armor',   'Spell_Holy_DevotionAura', 'Every enemy hit loses 5% of a normal enemy''s hit.', 13, 5, 5),
(15, 'Evasion', 'Spell_Shadow_ShadowWard', '+3% chance to dodge enemy swings.',                  14, 3, 5);

DELETE FROM `bonk_quest` WHERE `id` = 51;
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `amount`, `reward_type`, `reward_value`) VALUES
(51, 'Light on Your Feet', 'Reach stage 2 on Medium.', 'Spell_Shadow_ShadowWard', 3, 3, 2, 3, 15);

DELETE FROM `gameobject_template` WHERE `entry` = 900008;
DROP TEMPORARY TABLE IF EXISTS `bonk_heal_template`;
CREATE TEMPORARY TABLE `bonk_heal_template` AS SELECT * FROM `gameobject_template` WHERE `entry` = 900007;
UPDATE `bonk_heal_template` SET `entry` = 900008, `displayId` = 114, `name` = 'Turkey Leg', `size` = 2;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_heal_template`;
DROP TEMPORARY TABLE `bonk_heal_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
