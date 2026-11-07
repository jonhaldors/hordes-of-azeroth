DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028600003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028600003');

UPDATE `item_template` t JOIN `bonk_gear` g ON g.`keep_entry` = t.`entry` SET t.`buy_price` = 6000 WHERE g.`quality` = 2 AND t.`buy_price` = 0;
INSERT IGNORE INTO `npc_vendor` (`entry`, `slot`, `item`, `maxcount`, `incrtime`, `itemflags`, `condition_id`)
SELECT 900004, 200 + ROW_NUMBER() OVER (ORDER BY g.`keep_entry`), g.`keep_entry`, 0, 0, 0, 0 FROM `bonk_gear` g WHERE g.`quality` = 2 AND g.`keep_entry` <> 0;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
