DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018100000');

UPDATE `bonk_weapon` SET `description` = 'Your dash becomes Blink, teleporting you. Blink gains 1 charge and recharges 30% faster, and each Blink sets off an Arcane Explosion where you leave, dealing Arcane damage to all enemies within 10 yards. Takes one of your spell slots.' WHERE `id` = 407;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
