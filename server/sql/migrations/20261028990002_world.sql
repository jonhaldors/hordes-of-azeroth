DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028990002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028990002');

UPDATE `bonk_keyword` SET `description` = 'Marked enemies take 15% more damage from you and your summons, raised by the marking spell''s ranks and Mark upgrades up to 30%. Talents add on top. When a Marked enemy dies, the Mark passes to the 2 nearest unmarked enemies within 10 yards.' WHERE `id` = 9;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
