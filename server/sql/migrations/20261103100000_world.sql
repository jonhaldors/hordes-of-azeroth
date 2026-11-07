DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103100000');

UPDATE `bonk_card` SET `value2` = 30, `max_copies` = 1,
    `description` = 'Your spells have a 10% chance to grant 30% Haste for 6 sec. 20 sec cooldown.' WHERE `id` = 35;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
