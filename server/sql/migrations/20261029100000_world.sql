DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261029100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261029100000');

UPDATE `item_template` t
JOIN `item_template` l ON l.`entry` = 901420 + FLOOR((t.`entry` - 905000) / 20)
SET t.`description` = l.`description`
WHERE t.`entry` BETWEEN 905000 AND 905159;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
