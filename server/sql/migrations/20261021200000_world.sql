DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261021200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261021200000');

UPDATE `bonk_passive` SET `name` = 'Elixir of Agility', `icon` = 'Spell_Holy_BlessingOfAgility' WHERE `id` = 15;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
