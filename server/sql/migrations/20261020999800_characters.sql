DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020999800');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020999800');

DROP TABLE IF EXISTS `bonk_tmp_mastery_curve`;
CREATE TABLE `bonk_tmp_mastery_curve` (`level` INT UNSIGNED PRIMARY KEY, `old_start` INT UNSIGNED, `old_need` INT UNSIGNED,
    `new_start` INT UNSIGNED, `new_need` INT UNSIGNED);
INSERT INTO `bonk_tmp_mastery_curve` VALUES
(0, 0, 60, 0, 50),
(1, 60, 66, 50, 58),
(2, 126, 72, 108, 68),
(3, 198, 78, 176, 78),
(4, 276, 84, 254, 90),
(5, 360, 90, 344, 102),
(6, 450, 96, 446, 116),
(7, 546, 102, 562, 130),
(8, 648, 108, 692, 146),
(9, 756, 114, 838, 162),
(10, 870, 120, 1000, 180),
(11, 990, 126, 1180, 198),
(12, 1116, 132, 1378, 218),
(13, 1248, 138, 1596, 238),
(14, 1386, 144, 1834, 260),
(15, 1530, 150, 2094, 282),
(16, 1680, 156, 2376, 306),
(17, 1836, 162, 2682, 330),
(18, 1998, 168, 3012, 356),
(19, 2166, 174, 3368, 382),
(20, 2340, 180, 3750, 410),
(21, 2520, 186, 4160, 438),
(22, 2706, 192, 4598, 468),
(23, 2898, 198, 5066, 498),
(24, 3096, 204, 5564, 530),
(25, 3300, 210, 6094, 562),
(26, 3510, 216, 6656, 596),
(27, 3726, 222, 7252, 630),
(28, 3948, 228, 7882, 666),
(29, 4176, 234, 8548, 702),
(30, 4410, 0, 9250, 0);

DROP TABLE IF EXISTS `bonk_tmp_mastery_level`;
CREATE TABLE `bonk_tmp_mastery_level` SELECT `m`.`account`, `m`.`class`, `m`.`xp`,
    (SELECT MAX(`l`.`level`) FROM `bonk_tmp_mastery_curve` `l` WHERE `l`.`old_start` <= `m`.`xp`) AS `level`
    FROM `bonk_account_mastery` `m`;

UPDATE `bonk_account_mastery` `m`
    JOIN `bonk_tmp_mastery_level` `t` ON `t`.`account` = `m`.`account` AND `t`.`class` = `m`.`class`
    JOIN `bonk_tmp_mastery_curve` `c` ON `c`.`level` = `t`.`level`
SET `m`.`xp` = IF(`c`.`old_need` = 0, `c`.`new_start`,
    `c`.`new_start` + LEAST(`c`.`new_need` - 1, FLOOR((`t`.`xp` - `c`.`old_start`) * `c`.`new_need` / `c`.`old_need`)));

DROP TABLE `bonk_tmp_mastery_level`;
DROP TABLE `bonk_tmp_mastery_curve`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
