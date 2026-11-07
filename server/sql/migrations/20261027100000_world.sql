DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027100000');

UPDATE `bonk_tier` SET `description` = 'One floor in wide-open lands. Beat its boss to win the run.' WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `description` = 'Two floors in rougher lands, with tougher foes, better loot, more Darkmoon Tickets and 50% more Mastery experience.' WHERE `key` = 'heroic';
END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
