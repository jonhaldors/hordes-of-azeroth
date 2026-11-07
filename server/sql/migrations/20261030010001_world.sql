DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030010001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030010001');

DROP TEMPORARY TABLE IF EXISTS `tier_look_source`;
CREATE TEMPORARY TABLE `tier_look_source` AS
SELECT `entry`, `name`, `display_id`, `set_id` FROM `item_template`
WHERE `entry` BETWEEN 903000 AND 904439 AND (`entry` - 903000) MOD 160 DIV 8 + 1 IN (1, 8, 15);

UPDATE `item_template` t
JOIN `tier_look_source` s ON s.`entry` = t.`entry` - ((t.`entry` - 903000) MOD 160 DIV 8) * 8 +
  (CASE WHEN (t.`entry` - 903000) MOD 160 DIV 8 + 1 <= 10 THEN 0 WHEN (t.`entry` - 903000) MOD 160 DIV 8 + 1 <= 19 THEN 7 ELSE 14 END) * 8
SET t.`name` = s.`name`, t.`display_id` = s.`display_id`, t.`set_id` = s.`set_id`
WHERE t.`entry` BETWEEN 903000 AND 904439;

DROP TEMPORARY TABLE IF EXISTS `tier_look_source`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
