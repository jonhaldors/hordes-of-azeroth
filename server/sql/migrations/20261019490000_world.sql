DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019490000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019490000');

DROP TEMPORARY TABLE IF EXISTS `bonk_normal_vendor_epics`;
CREATE TEMPORARY TABLE `bonk_normal_vendor_epics` AS
SELECT DISTINCT v.`item` AS `entry`
FROM `npc_vendor` v
JOIN `bonk_item_stat` s ON s.`entry` = v.`item`
JOIN `item_template` i ON i.`entry` = v.`item`
WHERE v.`entry` = 900004 AND s.`unlock_tier` = 0 AND i.`quality` = 4;

UPDATE `bonk_item_stat` s JOIN `bonk_normal_vendor_epics` e ON e.`entry` = s.`entry` SET
    s.`power` = s.`power` * 0.8, s.`max_health` = s.`max_health` * 0.8, s.`armor` = s.`armor` * 0.8,
    s.`dodge` = s.`dodge` * 0.8, s.`hit` = s.`hit` * 0.8, s.`crit` = s.`crit` * 0.8, s.`crit_damage` = s.`crit_damage` * 0.8,
    s.`shield` = s.`shield` * 0.8, s.`haste` = s.`haste` * 0.8, s.`area` = s.`area` * 0.8,
    s.`pickup_range` = s.`pickup_range` * 0.8, s.`luck` = s.`luck` * 0.8;

UPDATE `item_template` i JOIN `bonk_normal_vendor_epics` e ON e.`entry` = i.`entry` SET
    i.`stat_value1` = ROUND(i.`stat_value1` * 0.8), i.`armor` = ROUND(i.`armor` * 0.8);

DROP TEMPORARY TABLE `bonk_normal_vendor_epics`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
