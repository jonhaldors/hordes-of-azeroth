DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101810003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101810003');

UPDATE `bonk_level` SET `health` = 1.100, `damage` = 1.150 WHERE `tier` = 2 AND `level` = 1;
UPDATE `bonk_level` SET `health` = 1.230, `damage` = 1.233 WHERE `tier` = 2 AND `level` = 2;
UPDATE `bonk_level` SET `health` = 1.374, `damage` = 1.322 WHERE `tier` = 2 AND `level` = 3;
UPDATE `bonk_level` SET `health` = 1.536, `damage` = 1.418 WHERE `tier` = 2 AND `level` = 4;
UPDATE `bonk_level` SET `health` = 1.717, `damage` = 1.520 WHERE `tier` = 2 AND `level` = 5;
UPDATE `bonk_level` SET `health` = 1.920, `damage` = 1.630 WHERE `tier` = 2 AND `level` = 6;
UPDATE `bonk_level` SET `health` = 2.146, `damage` = 1.748 WHERE `tier` = 2 AND `level` = 7;
UPDATE `bonk_level` SET `health` = 2.399, `damage` = 1.874 WHERE `tier` = 2 AND `level` = 8;
UPDATE `bonk_level` SET `health` = 2.681, `damage` = 2.009 WHERE `tier` = 2 AND `level` = 9;
UPDATE `bonk_level` SET `health` = 2.997, `damage` = 2.154 WHERE `tier` = 2 AND `level` = 10;
UPDATE `bonk_level` SET `health` = 0.80, `damage` = 0.90 WHERE `tier` = 3 AND `level` = 1;
UPDATE `bonk_level` SET `health` = 0.90, `damage` = 0.96 WHERE `tier` = 3 AND `level` = 2;
UPDATE `bonk_level` SET `health` = 1.00, `damage` = 1.02 WHERE `tier` = 3 AND `level` = 3;
UPDATE `bonk_level` SET `health` = 1.10, `damage` = 1.08 WHERE `tier` = 3 AND `level` = 4;
UPDATE `bonk_level` SET `health` = 1.20, `damage` = 1.14 WHERE `tier` = 3 AND `level` = 5;
UPDATE `bonk_level` SET `health` = 0.85, `damage` = 0.90 WHERE `tier` = 1 AND `level` = 1;
UPDATE `bonk_level` SET `health` = 1.00, `damage` = 1.00 WHERE `tier` = 1 AND `level` = 2;
UPDATE `bonk_level` SET `health` = 1.15, `damage` = 1.08 WHERE `tier` = 1 AND `level` = 3;
UPDATE `bonk_level` SET `health` = 1.30, `damage` = 1.16 WHERE `tier` = 1 AND `level` = 4;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
