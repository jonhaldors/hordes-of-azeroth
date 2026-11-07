DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018130000');

UPDATE `bonk_keyword` SET `max_stacks` = 10, `value_per_stack` = 3 WHERE `id` = 1;
UPDATE `bonk_keyword` SET `description` = 'Slows the enemy by 3% per stack, up to 30%. At 10 stacks the enemy becomes Frozen. An enemy that can''t be Frozen yet stays at 10 stacks. Each new stack refreshes Chill to 4 sec.' WHERE `id` = 1;

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (401, 413, 414) AND `upgrade` = 9;

UPDATE `bonk_mastery` SET `description` = 'Your Chill freezes enemies at 6 stacks instead of 10. You deal 15% less damage to enemies that aren''t Frozen.' WHERE `id` = 80310;
UPDATE `bonk_mastery` SET `description` = 'Once per stage, when you drop below 20% health, you are encased in ice: you take no damage for 2 sec, and every enemy within 10 yd gains 10 stacks of Chill.' WHERE `id` = 80307;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
