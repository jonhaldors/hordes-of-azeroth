DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261102120008');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261102120008');

UPDATE `bonk_keyword` SET `description` = 'Each stack deals Fire damage every tick. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a burning enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards, and the damage its stacks had left bursts onto up to 4 enemies within 8 yards, half on each.' WHERE `id` = 3;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Physical damage every tick. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a bleeding enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards, and the damage its stacks had left bursts onto up to 4 enemies within 8 yards, half on each.' WHERE `id` = 4;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Nature damage every tick. Each new stack refreshes all stacks to their full duration, up to 30 stacks. When a poisoned enemy dies, half of its stacks spread to the 2 nearest enemies within 8 yards, and the damage its stacks had left bursts onto up to 4 enemies within 8 yards, half on each.' WHERE `id` = 5;
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Every enemy hit counts as a strike toward Seal of Command, up to 4 extra bursts per storm.', 'Each enemy hit counts as a strike for Seal of Command.') WHERE `description` LIKE '%Every enemy hit counts as a strike towar%';
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Your pets mark the enemies they bite with Hunter''s Mark.', 'Your pets'' bites apply Hunter''s Mark.') WHERE `description` LIKE '%Your pets mark the enemies they bite wit%';
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'With an Explosive Arrow loaded, its first hit explodes for full damage within 8 yards.', 'With an Explosive Arrow loaded, the shot explodes on its first hit, dealing its damage to all enemies within 8 yards.') WHERE `description` LIKE '%With an Explosive Arrow loaded, its firs%';
UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'While you have it, your Cleave, Whirlwind and Thunder Clap hits add 1 stack of Bleed.', 'Your Cleave, Whirlwind and Thunder Clap hits also apply 1 stack of Bleed.') WHERE `description` LIKE '%While you have it, your Cleave, Whirlwin%';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
