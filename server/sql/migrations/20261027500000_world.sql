DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027500000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027500000');

CREATE TABLE IF NOT EXISTS `bonk_hidden_creature` (
    `guid` INT UNSIGNED NOT NULL,
    PRIMARY KEY (`guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

INSERT IGNORE INTO `bonk_hidden_creature` (`guid`)
SELECT c.`guid`
FROM `creature` c
WHERE c.`id` < 900000
  AND (c.`spawn_flags` & 2) = 0
  AND NOT (c.`map` = 1
       AND c.`position_x` BETWEEN 15800 AND 16800
       AND c.`position_y` BETWEEN 15800 AND 16800);

UPDATE `creature` c
JOIN `bonk_hidden_creature` h ON h.`guid` = c.`guid`
SET c.`spawn_flags` = c.`spawn_flags` | 2;

INSERT IGNORE INTO `bonk_hidden_gameobject` (`guid`)
SELECT g.`guid`
FROM `gameobject` g
JOIN `gameobject_template` t ON t.`entry` = g.`id`
    AND t.`patch` = (SELECT MAX(t2.`patch`) FROM `gameobject_template` t2 WHERE t2.`entry` = g.`id`)
WHERE t.`type` IN (2, 3, 9, 10, 13, 18, 19, 20, 22, 23, 24, 25)
  AND g.`id` < 900000
  AND (g.`spawn_flags` & 2) = 0
  AND NOT (g.`map` = 1
       AND g.`position_x` BETWEEN 15800 AND 16800
       AND g.`position_y` BETWEEN 15800 AND 16800);

UPDATE `gameobject` g
JOIN `bonk_hidden_gameobject` h ON h.`guid` = g.`guid`
SET g.`spawn_flags` = g.`spawn_flags` | 2;

END IF;
END??
DELIMITER ;
CALL add_migration();
