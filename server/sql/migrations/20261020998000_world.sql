DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020998000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020998000');

UPDATE `bonk_item_stat` s JOIN `bonk_gear` g ON s.`entry` IN (g.`entry`, g.`keep_entry`)
SET s.`haste` = 3, s.`power` = 3.75 WHERE g.`entry` = 900380;

UPDATE `bonk_item_stat` s JOIN `bonk_gear` g ON s.`entry` IN (g.`entry`, g.`keep_entry`)
SET s.`power` = 3.75 WHERE g.`entry` = 900374;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
