DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019470000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019470000');

DROP TEMPORARY TABLE IF EXISTS `bonk_gear_vendor_order`;
CREATE TEMPORARY TABLE `bonk_gear_vendor_order` AS
SELECT v.`item`, ROW_NUMBER() OVER (ORDER BY
        IF(FIELD(i.`inventory_type`, 1, 2, 3, 16, 5, 20, 4, 19, 9, 10, 6, 7, 8, 11, 12, 13, 21, 17, 22, 14, 23, 15, 26, 25) = 0, 99,
           FIELD(i.`inventory_type`, 1, 2, 3, 16, 5, 20, 4, 19, 9, 10, 6, 7, 8, 11, 12, 13, 21, 17, 22, 14, 23, 15, 26, 25)),
        i.`quality`, i.`item_level`, i.`name`) AS `position`
FROM `npc_vendor` v
JOIN (SELECT `entry`, MIN(`inventory_type`) AS `inventory_type`, MIN(`quality`) AS `quality`, MIN(`item_level`) AS `item_level`, MIN(`name`) AS `name`
      FROM `item_template` GROUP BY `entry`) i ON i.`entry` = v.`item`
WHERE v.`entry` = 900004;

UPDATE `npc_vendor` v JOIN `bonk_gear_vendor_order` o ON o.`item` = v.`item` SET v.`slot` = o.`position` WHERE v.`entry` = 900004;
DROP TEMPORARY TABLE `bonk_gear_vendor_order`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
