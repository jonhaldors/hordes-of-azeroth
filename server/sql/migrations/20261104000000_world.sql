DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261104000000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261104000000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.0, `duration_ms` = 4000, `tick_ms` = 1000 WHERE `id` IN (404, 419, 420);
UPDATE `bonk_weapon` SET `description` = 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 4 stacks of Burning. The flames burn the ground for 4 sec, dealing Fire damage to enemies inside.' WHERE `id` = 404;
UPDATE `bonk_weapon` SET `description` = 'Calls down 3 pillars of fire one after another through the largest group of enemies, each dealing Fire damage and applying 4 stacks of Burning. Each pillar burns the ground for 4 sec, dealing Fire damage to enemies inside.' WHERE `id` = 419;
UPDATE `bonk_weapon` SET `description` = 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 4 stacks of Burning. The flames deal Fire damage to enemies inside for 4 sec, and the ground burns for 6 sec, adding 1 stack of Burning every sec to enemies within 8 yards.' WHERE `id` = 420;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
