DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020999950');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020999950');

UPDATE `bonk_tier` SET `description` = 'Two stages in rougher lands, with tougher foes, better loot, more Darkmoon Tickets and 50% more Mastery experience.' WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `description` = 'Three stages against the deadliest foes, then Endless mode for those who dare. Gives 100% more Mastery experience.' WHERE `key` = 'mythic';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
