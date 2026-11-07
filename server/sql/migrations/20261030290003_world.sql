DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030290003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030290003');

DELETE FROM `bonk_gear` WHERE `quality` = 0;

UPDATE `item_template` i JOIN `item_template` g ON g.`entry` = i.`entry` - 20000 AND g.`patch` = i.`patch`
SET i.`quality` = 1, i.`name` = CONCAT('Sturdy ', g.`name`), i.`buy_price` = 5000, i.`sell_price` = 1250
WHERE i.`entry` BETWEEN 920000 AND 925999;
UPDATE `bonk_item_stat` s JOIN `bonk_item_stat` g ON g.`entry` = s.`entry` - 20000
SET s.`power` = ROUND(g.`power` * 0.75, 1), s.`max_health` = ROUND(g.`max_health` * 0.75, 1), s.`armor` = ROUND(g.`armor` * 0.75, 1),
    s.`dodge` = ROUND(g.`dodge` * 0.75, 1), s.`crit` = ROUND(g.`crit` * 0.75, 1), s.`crit_damage` = ROUND(g.`crit_damage` * 0.75, 1),
    s.`shield` = ROUND(g.`shield` * 0.75, 1), s.`haste` = ROUND(g.`haste` * 0.75, 1), s.`area` = ROUND(g.`area` * 0.75, 1),
    s.`pickup_range` = ROUND(g.`pickup_range` * 0.75, 1), s.`luck` = ROUND(g.`luck` * 0.75, 1)
WHERE s.`entry` BETWEEN 920000 AND 925999;

UPDATE `item_template` i JOIN `npc_vendor` v ON v.`item` = i.`entry` AND v.`entry` = 900004
SET i.`buy_price` = 45000, i.`sell_price` = 11250
WHERE i.`quality` = 2;

UPDATE `item_template` SET `buy_price` = ROUND(`buy_price` * CASE `item_level` - 60
        WHEN 1 THEN 0.2429
        WHEN 2 THEN 0.4892
        WHEN 3 THEN 0.6801
        WHEN 4 THEN 0.8102
        WHEN 5 THEN 0.8872
        WHEN 6 THEN 0.9225
        WHEN 7 THEN 0.9239
        WHEN 8 THEN 0.9011
        WHEN 9 THEN 0.8606
        WHEN 10 THEN 0.8089
    END)
WHERE (`entry` BETWEEN 903000 AND 904439 OR `entry` BETWEEN 904500 AND 904899) AND `item_level` BETWEEN 61 AND 70;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
