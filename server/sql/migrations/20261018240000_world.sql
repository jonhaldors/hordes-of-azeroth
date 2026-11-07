DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261018240000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261018240000');

UPDATE `bonk_weapon` SET `description` = 'Plants a Magma Totem at your feet that pulses fire every 2 seconds, dealing Fire damage and 1 stack of Burning to all enemies within 8 yards of it. The pulse also leaves them Dazed.' WHERE `id` = 731;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
