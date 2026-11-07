DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016600000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016600000');

UPDATE `item_template` SET `required_honor_rank` = 0, `required_city_rank` = 0
WHERE `entry` IN (SELECT `entry` FROM `bonk_gear`) OR `entry` IN (SELECT `keep_entry` FROM `bonk_gear`);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
