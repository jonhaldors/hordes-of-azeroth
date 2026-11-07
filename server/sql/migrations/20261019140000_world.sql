DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019140000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019140000');

UPDATE `item_template` `i`
JOIN `npc_vendor` `v` ON `v`.`item` = `i`.`entry` AND `v`.`entry` = 900004
SET `i`.`sell_price` = CASE `i`.`quality`
        WHEN 2 THEN 1000
        WHEN 3 THEN 2500
        WHEN 4 THEN 10000
        WHEN 5 THEN 50000
        ELSE 0
    END
WHERE `i`.`sell_price` = 0 AND `i`.`quality` BETWEEN 2 AND 5;

UPDATE `item_template` `i`
JOIN `bonk_gear` `g` ON `g`.`keep_entry` = `i`.`entry`
SET `i`.`sell_price` = CASE `i`.`quality`
        WHEN 2 THEN 1000
        WHEN 3 THEN 2500
        WHEN 4 THEN 10000
        WHEN 5 THEN 50000
        ELSE 0
    END
WHERE `i`.`sell_price` = 0 AND `i`.`quality` BETWEEN 2 AND 5;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
