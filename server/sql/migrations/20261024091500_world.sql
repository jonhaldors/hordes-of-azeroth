DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261024091500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261024091500');

UPDATE `bonk_weapon` SET
    `description` = 'Fel fire strikes the 2 nearest enemies and applies 2 stacks of Burning. Each enemy struck spreads fire to every enemy within 5 yards of it, dealing half damage and applying 1 stack of Burning.' WHERE `id` = 927;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
