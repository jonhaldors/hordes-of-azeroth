DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025200000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025200000');

UPDATE `bonk_weapon` SET `description` = 'Moonkin form spell. Every 2 sec, burns the 2 nearest enemies with moonlight: Arcane damage on impact and 1 stack of Moonfire, which deals Arcane damage every sec. Enemies without Moonfire are chosen first.' WHERE `id` = 1002;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
