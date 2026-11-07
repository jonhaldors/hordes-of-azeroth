DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023220000');

UPDATE `bonk_weapon` SET `range` = 8 WHERE `id` IN (909, 929, 930);
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards every sec.' WHERE `id` = 909;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards every sec. The ring widens as your health drops, up to 60% wider.' WHERE `id` = 929;
UPDATE `bonk_weapon` SET `description` = 'Fel fire burns every enemy within 8 yards every sec. Your demons burn with it, dealing half its damage to enemies within 6 yards of them.' WHERE `id` = 930;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
