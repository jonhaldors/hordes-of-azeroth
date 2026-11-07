DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261023180000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261023180000');

UPDATE `bonk_weapon` SET `base_targets` = 2,
    `description` = REPLACE(REPLACE(`description`, 'the 5 nearest enemies', 'the 2 nearest enemies'), 'the 5 enemies with the most health', 'the 2 enemies with the most health')
    WHERE `id` IN (904, 905, 919, 920, 921, 922);
UPDATE `bonk_weapon` SET `damage_fraction` = 0.8 WHERE `id` IN (906, 923, 924);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
