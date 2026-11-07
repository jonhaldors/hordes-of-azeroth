DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101700004');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101700004');

CREATE TABLE IF NOT EXISTS `bonk_account_kept_talents` (
  `account` int(10) unsigned NOT NULL,
  `class` tinyint(3) unsigned NOT NULL,
  `points` int(10) unsigned NOT NULL DEFAULT 0,
  PRIMARY KEY (`account`, `class`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci;

INSERT IGNORE INTO `bonk_account_kept_talents` (`account`, `class`, `points`)
SELECT `account`, `class`, LEAST(10, `best_level` DIV 2) FROM `bonk_account_level` WHERE `best_level` >= 2;

DROP TEMPORARY TABLE IF EXISTS `bonk_mastery_curve`;
CREATE TEMPORARY TABLE `bonk_mastery_curve` (`level` int unsigned NOT NULL PRIMARY KEY, `old_xp` int unsigned NOT NULL, `new_xp` int unsigned NOT NULL);
INSERT INTO `bonk_mastery_curve` VALUES
(0, 0, 0),
(1, 50, 50),
(2, 108, 108),
(3, 176, 176),
(4, 254, 254),
(5, 344, 344),
(6, 446, 446),
(7, 562, 562),
(8, 692, 692),
(9, 838, 838),
(10, 1000, 1000),
(11, 1185, 1216),
(12, 1394, 1493),
(13, 1631, 1841),
(14, 1897, 2269),
(15, 2196, 2789),
(16, 2528, 3409),
(17, 2898, 4143),
(18, 3307, 5001),
(19, 3759, 5997),
(20, 4255, 7143),
(21, 4800, 8455),
(22, 5395, 9944),
(23, 6045, 11628),
(24, 6752, 13520),
(25, 7520, 15640),
(26, 8351, 18000),
(27, 9250, 20622),
(28, 10220, 23520),
(29, 11265, 26716),
(30, 12388, 30226);

UPDATE `bonk_account_mastery` m SET m.`xp` = (
  SELECT c.`new_xp` + (m.`xp` - c.`old_xp`) FROM `bonk_mastery_curve` c WHERE c.`old_xp` <= m.`xp` ORDER BY c.`level` DESC LIMIT 1);

DROP TEMPORARY TABLE `bonk_mastery_curve`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
