DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023120000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023120000');

UPDATE `bonk_weapon` SET `description` = 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once.' WHERE `id` = 409;
UPDATE `bonk_weapon` SET `description` = 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. If you know Blink, the missiles pile up while you move instead, up to 40, and your next Blink fires them all at once at the nearest enemies, together with its own volley.' WHERE `id` = 429;
UPDATE `bonk_weapon` SET `description` = 'Launches 5 Arcane Missiles at the nearest enemy over 1 sec, each dealing Arcane damage. After each Blink, it fires all 5 at once at the nearest enemies, and all your spells deal 30% more damage for 4 sec.' WHERE `id` = 430;
UPDATE `bonk_weapon` SET `flags` = `flags` & ~0x800000 WHERE `id` IN (409, 429, 430);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
