DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015100000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015100000');

CREATE TABLE IF NOT EXISTS `bonk_weapon_upgrade` (
    `weapon_id` INT UNSIGNED     NOT NULL COMMENT 'bonk_weapon.id',
    `upgrade`   TINYINT UNSIGNED NOT NULL COMMENT 'BonkSpellUpgrade: 1 spell cleave, 2 hit twice, 3 Haste, 5 duration, 6 Mark strength, 7 beast damage, 8 beast size (4, radius, retired)',
    `step`      FLOAT            NOT NULL COMMENT 'what one rank step adds, %',
    PRIMARY KEY (`weapon_id`, `upgrade`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='Vanilla Bonk: what Rare and Epic spell ranks can add';

DELETE FROM `bonk_weapon_upgrade`;
INSERT INTO `bonk_weapon_upgrade` (`weapon_id`, `upgrade`, `step`)
SELECT w.`id`, u.`upgrade`, u.`step`
FROM (
    SELECT `id`, `target`, `behavior`, `duration_ms`,
        CASE
            WHEN `behavior` = 20 THEN 'pet'
            WHEN `behavior` = 14 THEN 'mark'
            WHEN `behavior` IN (4, 5, 9) THEN 'shield'
            WHEN `behavior` IN (15, 16) THEN 'buff'
            WHEN `behavior` IN (7, 19) OR `target` = 3 THEN 'ground'
            WHEN `target` = 2 THEN 'dot'
            WHEN `behavior` = 1 OR `target` IN (1, 6) THEN 'around'
            ELSE 'bolt'
        END AS `grp`
    FROM `bonk_weapon`
) w
JOIN (
              SELECT 'bolt' AS `grp`, 1 AS `upgrade`, 10 AS `step`
    UNION ALL SELECT 'bolt',   2, 10
    UNION ALL SELECT 'bolt',   3, 8
    UNION ALL SELECT 'around', 2, 10
    UNION ALL SELECT 'around', 3, 8
    UNION ALL SELECT 'ground', 5, 15
    UNION ALL SELECT 'ground', 2, 10
    UNION ALL SELECT 'ground', 3, 8
    UNION ALL SELECT 'dot',    5, 15
    UNION ALL SELECT 'dot',    3, 8
    UNION ALL SELECT 'pet',    7, 15
    UNION ALL SELECT 'pet',    8, 10
    UNION ALL SELECT 'mark',   6, 5
    UNION ALL SELECT 'mark',   5, 15
    UNION ALL SELECT 'shield', 3, 8
    UNION ALL SELECT 'buff',   5, 15
    UNION ALL SELECT 'buff',   3, 8
) u ON u.`grp` = w.`grp`
WHERE
    (u.`upgrade` <> 5 OR w.`grp` NOT IN ('ground', 'buff') OR w.`duration_ms` > 0);

DELETE FROM `bonk_passive` WHERE `id` = 19;
INSERT INTO `bonk_passive` (`id`, `name`, `icon`, `description`, `effect`, `value_per_rank`, `max_rank`, `excludes`) VALUES
(19, 'Hand of Justice', 'INV_Jewelry_Talisman_01', '+1 Count: your spells fire 1 more bolt and land 1 more ground spell; spells around you go off 1 more time.', 2, 1, 2, 0);

UPDATE `bonk_passive` SET `value_per_rank` = 5, `description` = '+5 Armor: enemies deal less damage to you.' WHERE `id` = 13;
UPDATE `bonk_upgrade` SET `value_per_rank` = 2.5, `description` = '+2.5 Armor: enemies deal less damage to you.' WHERE `id` = 12;
UPDATE `bonk_mastery` SET `value_per_rank` = `value_per_rank` * 1.25 WHERE `effect` = 0 AND `target` = 12;
UPDATE `bonk_mastery` SET `description` = CONCAT('+', TRIM(TRAILING '.' FROM TRIM(TRAILING '0' FROM FORMAT(`value_per_rank`, 2))), ' Armor.')
    WHERE `effect` = 0 AND `target` = 12;
UPDATE `bonk_item_stat` SET `armor` = `armor` * 1.25 WHERE `armor` <> 0;
UPDATE `bonk_item_set_bonus` SET `armor` = `armor` * 1.25 WHERE `armor` <> 0;
UPDATE `bonk_item_set_bonus` SET `description` = '+12.5 Armor, and regain 1% health every second.' WHERE `set_id` = 1 AND `pieces` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
