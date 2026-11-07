DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025140000');

UPDATE `bonk_weapon` SET `description` = 'Curses the 2 enemies with the most health with 1 stack of Agony, or 2 on an uncursed enemy.' WHERE `id` = 905;
UPDATE `bonk_weapon` SET `description` = 'Strikes the 2 nearest enemies with fire, dealing damage and applying 2 stacks of Burning.' WHERE `id` = 908;
UPDATE `bonk_weapon` SET `description` = 'Fire burns every enemy within 8 yards of you, dealing damage.' WHERE `id` = 909;
UPDATE `bonk_weapon` SET `description` = 'Rains fire on the largest group of enemies for 4 sec, dealing damage and applying 1 stack of Burning every sec.' WHERE `id` = 910;
UPDATE `bonk_keyword` SET `description` = 'Each stack deals Shadow damage every sec. A stack''s damage grows by a quarter of its starting damage every sec it stays on, up to triple after 8 sec. One curse per enemy.' WHERE `id` = 14;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
