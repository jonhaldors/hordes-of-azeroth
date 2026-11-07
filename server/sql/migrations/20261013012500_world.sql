DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261013012500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261013012500');

UPDATE `bonk_weapon` SET `description` = 'Scorches random enemies and leaves them burning. At max level, the burn spreads to nearby enemies when a burning enemy dies.' WHERE `id` = 43;
UPDATE `bonk_weapon` SET `description` = 'Throws poison bolts at every enemy within 30 yards, leaving them poisoned.' WHERE `id` = 107;
UPDATE `bonk_weapon` SET `description` = 'Casts Fireballs; every fourth cast is a huge Pyroblast that leaves the enemy burning.' WHERE `id` = 171;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
