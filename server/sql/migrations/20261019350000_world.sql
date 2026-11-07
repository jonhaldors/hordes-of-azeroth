DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019350000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019350000');

UPDATE `bonk_weapon` SET `behavior_value` = 8,
    `description` = 'Strikes 8 times over 2 seconds, each strike at a random enemy within 10 yards. Every strike carries your poisons and openers.' WHERE `id` = 603;
UPDATE `bonk_weapon` SET `behavior_value` = 8,
    `description` = 'Strikes 8 times over 2 seconds, each strike at a random enemy within 10 yards. Each kill during the spree adds 2 strikes, up to 20 more.' WHERE `id` = 618;
UPDATE `bonk_weapon` SET `behavior_value` = 8,
    `description` = 'Strikes 8 times over 2 seconds, each strike at a random enemy within 10 yards. The last strike also fires Eviscerate and Envenom, if you hold them, without touching their cooldowns.' WHERE `id` = 619;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
