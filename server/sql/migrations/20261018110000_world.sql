DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018110000');

ALTER TABLE `bonk_keyword` ADD COLUMN `description` VARCHAR(1024) NOT NULL DEFAULT '';
UPDATE `bonk_keyword` SET `description` = 'Slows the enemy by 3% per stack, up to 30%. At 10 stacks the enemy becomes Frozen. An enemy that can''t be Frozen yet stays at 10 stacks. Each new stack refreshes Chill to 4 sec.' WHERE `id` = 1;
UPDATE `bonk_keyword` SET `description` = 'Normal enemies are frozen in place for 2 sec. Elites and bosses keep moving but count as Frozen for those 2 sec. Shatter: your Frost spells always critically strike Frozen enemies, and every critical strike against a Frozen enemy deals an extra 50% damage. After a Freeze, that enemy can''t be Frozen again for 6 sec.' WHERE `id` = 2;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Fire damage every sec. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a burning enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards.' WHERE `id` = 3;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Physical damage every sec. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a bleeding enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards.' WHERE `id` = 4;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Nature damage every sec. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a poisoned enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards.' WHERE `id` = 5;
UPDATE `bonk_keyword` SET `description` = 'Marked enemies take 15% more damage from every source, more as the spell that marks them ranks up. When a Marked enemy dies, the Mark passes to the 2 nearest unmarked enemies within 10 yards.' WHERE `id` = 9;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
