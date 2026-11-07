DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022020000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022020000');

UPDATE `bonk_weapon` SET `description` = 'Hammers of light fall from the sky on 3 random enemies within 25 yards, each dealing Holy damage to every enemy within 5 yards of where it lands. Every 3rd time, 1 extra hammer falls on the largest group of enemies and explodes on impact, dealing triple damage to every enemy within 10 yards.' WHERE `id` = 838;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
