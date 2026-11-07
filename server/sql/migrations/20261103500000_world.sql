DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261103500000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261103500000');

UPDATE `bonk_tier` SET `damage_multiplier` = 1, `stage_damage_growth` = 0.10, `stage_damage_accel` = 0;
UPDATE `bonk_level` SET `damage` = 0.80 WHERE `tier` = 1 AND `level` = 1;
UPDATE `bonk_level` SET `damage` = 1.08 WHERE `tier` = 1 AND `level` = 2;
UPDATE `bonk_level` SET `damage` = 1.16 WHERE `tier` = 1 AND `level` = 3;
UPDATE `bonk_level` SET `damage` = 1.24 WHERE `tier` = 1 AND `level` = 4;
UPDATE `bonk_level` SET `damage` = 1.32 WHERE `tier` = 3 AND `level` = 1;
UPDATE `bonk_level` SET `damage` = 1.40 WHERE `tier` = 3 AND `level` = 2;
UPDATE `bonk_level` SET `damage` = 1.48 WHERE `tier` = 3 AND `level` = 3;
UPDATE `bonk_level` SET `damage` = 1.56 WHERE `tier` = 3 AND `level` = 4;
UPDATE `bonk_level` SET `damage` = 1.64 WHERE `tier` = 3 AND `level` = 5;
UPDATE `bonk_level` SET `damage` = 1.72 WHERE `tier` = 2 AND `level` = 1;
UPDATE `bonk_level` SET `damage` = 1.80 WHERE `tier` = 2 AND `level` = 2;
UPDATE `bonk_level` SET `damage` = 1.88 WHERE `tier` = 2 AND `level` = 3;
UPDATE `bonk_level` SET `damage` = 1.96 WHERE `tier` = 2 AND `level` = 4;
UPDATE `bonk_level` SET `damage` = 2.04 WHERE `tier` = 2 AND `level` = 5;
UPDATE `bonk_level` SET `damage` = 2.12 WHERE `tier` = 2 AND `level` = 6;
UPDATE `bonk_level` SET `damage` = 2.20 WHERE `tier` = 2 AND `level` = 7;
UPDATE `bonk_level` SET `damage` = 2.28 WHERE `tier` = 2 AND `level` = 8;
UPDATE `bonk_level` SET `damage` = 2.36 WHERE `tier` = 2 AND `level` = 9;
UPDATE `bonk_level` SET `damage` = 2.44 WHERE `tier` = 2 AND `level` = 10;
UPDATE `bonk_level` SET `damage` = 2.52 WHERE `tier` = 2 AND `level` = 11;
UPDATE `bonk_level` SET `damage` = 2.60 WHERE `tier` = 2 AND `level` = 12;
UPDATE `bonk_level` SET `damage` = 2.68 WHERE `tier` = 2 AND `level` = 13;
UPDATE `bonk_level` SET `damage` = 2.76 WHERE `tier` = 2 AND `level` = 14;
UPDATE `bonk_level` SET `damage` = 2.84 WHERE `tier` = 2 AND `level` = 15;
UPDATE `bonk_level` SET `damage` = 2.92 WHERE `tier` = 2 AND `level` = 16;
UPDATE `bonk_level` SET `damage` = 3.00 WHERE `tier` = 2 AND `level` = 17;
UPDATE `bonk_level` SET `damage` = 3.08 WHERE `tier` = 2 AND `level` = 18;
UPDATE `bonk_level` SET `damage` = 3.16 WHERE `tier` = 2 AND `level` = 19;
UPDATE `bonk_level` SET `damage` = 3.24 WHERE `tier` = 2 AND `level` = 20;
UPDATE `bonk_level` SET `damage` = 3.32 WHERE `tier` = 2 AND `level` = 21;
UPDATE `bonk_level` SET `damage` = 3.40 WHERE `tier` = 2 AND `level` = 22;
UPDATE `bonk_level` SET `damage` = 3.48 WHERE `tier` = 2 AND `level` = 23;
UPDATE `bonk_level` SET `damage` = 3.56 WHERE `tier` = 2 AND `level` = 24;
UPDATE `bonk_level` SET `damage` = 3.64 WHERE `tier` = 2 AND `level` = 25;
UPDATE `bonk_level` SET `damage` = 3.72 WHERE `tier` = 2 AND `level` = 26;
UPDATE `bonk_level` SET `damage` = 3.80 WHERE `tier` = 2 AND `level` = 27;
UPDATE `bonk_level` SET `damage` = 3.88 WHERE `tier` = 2 AND `level` = 28;
UPDATE `bonk_level` SET `damage` = 3.96 WHERE `tier` = 2 AND `level` = 29;
UPDATE `bonk_level` SET `damage` = 4.04 WHERE `tier` = 2 AND `level` = 30;
UPDATE `bonk_scaling` SET `hit_share` = 6 WHERE `minute` = 0;
UPDATE `bonk_scaling` SET `hit_share` = 7 WHERE `minute` = 2;
UPDATE `bonk_scaling` SET `hit_share` = 8 WHERE `minute` = 4;
UPDATE `bonk_scaling` SET `hit_share` = 8.75 WHERE `minute` = 6;
UPDATE `bonk_scaling` SET `hit_share` = 9.5 WHERE `minute` = 8;
UPDATE `bonk_scaling` SET `hit_share` = 10 WHERE `minute` = 10;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
