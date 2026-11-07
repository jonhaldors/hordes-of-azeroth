DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103999000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103999000');

UPDATE `bonk_weapon` SET `damage_fraction` = 1.47, `apply_stacks` = 4,
    `description` = 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 4 stacks of Burning.' WHERE `id` = 404;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.47, `apply_stacks` = 4,
    `description` = 'Calls down 3 pillars of fire one after another through the largest group of enemies, each dealing Fire damage and applying 4 stacks of Burning.' WHERE `id` = 419;
UPDATE `bonk_weapon` SET `damage_fraction` = 1.47, `apply_stacks` = 4,
    `description` = 'Calls down a pillar of fire on the largest group of enemies, dealing Fire damage and applying 4 stacks of Burning. The ground burns for 6 sec, adding 1 stack of Burning every sec to enemies within 8 yards.' WHERE `id` = 420;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
