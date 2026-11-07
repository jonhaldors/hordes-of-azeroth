DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025170000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025170000');

UPDATE `bonk_weapon` SET `description` = REPLACE(`description`, 'Moonkin hurls Wrath at the nearest enemy, filling Lunar Eclipse.', 'Moonkin hurls Wrath at the nearest enemy.') WHERE `id` = 1013;
UPDATE `bonk_weapon` SET `description` = 'Moonkin form spell. Calls down a bolt of starlight on the strongest enemy within 30 yards.' WHERE `id` = 1001;
UPDATE `bonk_weapon` SET `description` = 'Moonkin form spell. Every sec, burns the 5 nearest enemies with moonlight, applying 1 stack of Moonfire. Enemies without Moonfire are chosen first.' WHERE `id` = 1002;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
