DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016230000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016230000');

ALTER TABLE `bonk_tier` ADD COLUMN IF NOT EXISTS `stages` INT UNSIGNED NOT NULL DEFAULT 0;
ALTER TABLE `bonk_tier` ADD COLUMN IF NOT EXISTS `endless` TINYINT UNSIGNED NOT NULL DEFAULT 0;

UPDATE `bonk_tier` SET `key` = 'normal', `name` = 'Normal', `stages` = 1, `endless` = 0, `elite_affixes` = 1,
    `description` = 'One stage in wide open lands. Beat its boss to win the run.'
WHERE `id` = 1;
UPDATE `bonk_tier` SET `key` = 'heroic', `name` = 'Heroic', `stages` = 2, `endless` = 0, `elite_affixes` = 2,
    `health_multiplier` = 1.6, `damage_multiplier` = 1.3, `unlock_tier` = 1, `unlock_stage` = 2,
    `description` = 'Two stages in rougher lands. Tougher foes, better loot and more Darkmoon Tickets.'
WHERE `id` = 3;
UPDATE `bonk_tier` SET `key` = 'mythic', `name` = 'Mythic', `stages` = 3, `endless` = 1, `elite_affixes` = 3,
    `health_multiplier` = 2.5, `damage_multiplier` = 1.6, `unlock_tier` = 3, `unlock_stage` = 3,
    `description` = 'Three stages against the deadliest foes, then Endless for those who dare.'
WHERE `id` = 2;

UPDATE `bonk_quest` SET `description` = 'Clear Normal.' WHERE `id` = 7;
UPDATE `bonk_quest` SET `target` = 3, `amount` = 2, `description` = 'Clear stage 1 on Heroic.' WHERE `id` = 8;
UPDATE `bonk_quest` SET `description` = 'Clear stage 1 on Mythic.' WHERE `id` = 10;
UPDATE `bonk_quest` SET `amount` = 3, `description` = 'Clear Heroic.' WHERE `id` = 51;
UPDATE `bonk_quest` SET `target` = 2, `amount` = 4, `description` = 'Clear Mythic.' WHERE `id` = 9;
UPDATE `bonk_quest` SET `description` = REPLACE(`description`, 'Clear stage 1 on Easy', 'Clear Normal')
WHERE `type` = 3 AND `category` = 2 AND `target` = 1 AND `amount` = 2;
UPDATE `bonk_quest` SET `target` = 3, `amount` = 2, `description` = REPLACE(`description`, 'Clear three stages on Easy', 'Clear stage 1 on Heroic')
WHERE `type` = 3 AND `category` = 2 AND `target` = 1 AND `amount` = 4;
UPDATE `bonk_quest` SET `description` = REPLACE(`description`, 'Clear two stages on Medium', 'Clear Heroic')
WHERE `type` = 3 AND `category` = 2 AND `target` = 3 AND `amount` = 3;
UPDATE `bonk_quest` SET `description` = REPLACE(`description`, 'Clear stage 1 on Hard', 'Clear stage 1 on Mythic')
WHERE `type` = 3 AND `category` = 2 AND `target` = 2 AND `amount` = 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
