DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031100001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031100001');

DROP TEMPORARY TABLE IF EXISTS `bonk_white_slot`;
CREATE TEMPORARY TABLE `bonk_white_slot` AS
SELECT i.`inventory_type`, AVG(s.`power`) AS `power`, AVG(s.`max_health`) AS `max_health`, AVG(s.`armor`) AS `armor`,
    AVG(s.`dodge`) AS `dodge`, AVG(s.`crit`) AS `crit`, AVG(s.`crit_damage`) AS `crit_damage`, AVG(s.`shield`) AS `shield`,
    AVG(s.`haste`) AS `haste`, AVG(s.`area`) AS `area`, AVG(s.`pickup_range`) AS `pickup_range`, AVG(s.`luck`) AS `luck`
FROM `bonk_gear` g
JOIN `item_template` i ON i.`entry` = g.`entry`
JOIN `bonk_item_stat` s ON s.`entry` = g.`entry`
WHERE i.`quality` = 1
GROUP BY i.`inventory_type`;

UPDATE `bonk_item_stat` s
JOIN `item_template` i ON i.`entry` = s.`entry`
JOIN `bonk_white_slot` w ON w.`inventory_type` = IF(i.`inventory_type` = 21, 13, i.`inventory_type`)
SET s.`power` = ROUND(w.`power` * 0.75, 1), s.`max_health` = ROUND(w.`max_health` * 0.75, 1), s.`armor` = ROUND(w.`armor` * 0.75, 1),
    s.`dodge` = ROUND(w.`dodge` * 0.75, 1), s.`crit` = ROUND(w.`crit` * 0.75, 1), s.`crit_damage` = ROUND(w.`crit_damage` * 0.75, 1),
    s.`shield` = ROUND(w.`shield` * 0.75, 1), s.`haste` = ROUND(w.`haste` * 0.75, 1), s.`area` = ROUND(w.`area` * 0.75, 1),
    s.`pickup_range` = ROUND(w.`pickup_range` * 0.75, 1), s.`luck` = ROUND(w.`luck` * 0.75, 1)
WHERE s.`entry` BETWEEN 900201 AND 900224;

DROP TEMPORARY TABLE IF EXISTS `bonk_white_slot`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
