DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027720000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027720000');

UPDATE `bonk_card` SET `value1` = 40, `value2` = 8, `value3` = 500,
    `description` = 'When an enemy hits you, thorns strike all enemies within 8 yards for 40% of a normal enemy''s health. Once every 0.5 sec.' WHERE `id` = 12;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
