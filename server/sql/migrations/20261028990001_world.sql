DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028990001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028990001');

UPDATE `bonk_keyword` SET `description` = 'Increases Fire damage taken by 3% per stack. Stacks up to 5 times.' WHERE `id` = 6;
UPDATE `bonk_keyword` SET `description` = 'Increases Physical damage taken by 4% per stack. Stacks up to 5 times.' WHERE `id` = 7;

UPDATE `bonk_keyword` SET `description` = REPLACE(`description`, 'damage every sec.', 'damage every tick.') WHERE `id` IN (3, 4, 5, 13, 14, 15);
UPDATE `bonk_keyword` SET `description` = REPLACE(`description`, 'every sec it stays on, up to triple after 8 sec.', 'every tick it stays on, up to triple after 8 ticks.') WHERE `id` = 14;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
