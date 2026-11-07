DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261019130000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261019130000');

CREATE TABLE IF NOT EXISTS `bonk_bolt_look` (
    `spell_id` INT UNSIGNED NOT NULL,
    `display_id` INT UNSIGNED NOT NULL,
    `scale` FLOAT NOT NULL DEFAULT 1,
    `impact_kit` INT UNSIGNED NOT NULL DEFAULT 0,
    `cast_near` TINYINT UNSIGNED NOT NULL DEFAULT 0,
    PRIMARY KEY (`spell_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8;

DELETE FROM `bonk_bolt_look`;
INSERT IGNORE INTO `bonk_bolt_look` (`spell_id`, `display_id`, `scale`, `impact_kit`, `cast_near`)
SELECT `entry`,
    CASE `spellVisual1`
        WHEN 173 THEN 18600
        WHEN 13 THEN 18002
        WHEN 2147 THEN 18002
        WHEN 64 THEN 18007
        WHEN 1506 THEN 18601
        WHEN 516 THEN 18003
        WHEN 725 THEN 18003
        WHEN 4559 THEN 18004
        WHEN 271 THEN 18006
        WHEN 854 THEN 18602
        WHEN 809 THEN 18602
        WHEN 7391 THEN 18010
    END,
    1,
    CASE `spellVisual1`
        WHEN 173 THEN 283
        WHEN 13 THEN 4991
        WHEN 2147 THEN 68
        WHEN 64 THEN 219
        WHEN 1506 THEN 133
        WHEN 516 THEN 608
        WHEN 725 THEN 608
        WHEN 4559 THEN 608
        WHEN 271 THEN 419
        WHEN 854 THEN 813
        WHEN 809 THEN 813
        WHEN 7391 THEN 549
    END,
    0
FROM `spell_template`
WHERE `entry` IN (9053, 9483, 9532, 9613, 9672, 11021, 11131, 11985, 12466, 12471, 12739, 13748, 14034, 15228, 15230, 15242, 16788, 17393,
    17503, 19391, 19452, 19728, 20297, 20792, 20793, 20816, 20822, 20823, 20825, 20829, 21369, 21832, 24334, 25748, 27806);

INSERT INTO `bonk_bolt_look` (`spell_id`, `display_id`, `scale`, `impact_kit`, `cast_near`) VALUES
(6660, 18009, 1, 0, 1),
(15620, 18009, 1, 0, 1),
(16100, 18009, 1, 0, 1),
(20463, 18009, 1, 0, 1),
(10277, 18011, 1, 0, 1),
(16000, 18011, 1, 0, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
