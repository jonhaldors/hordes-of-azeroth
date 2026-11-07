DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261015310000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261015310000');

ALTER TABLE `bonk_card` ADD COLUMN `max_copies` TINYINT UNSIGNED NOT NULL DEFAULT 0 AFTER `cooldown_ms`;

UPDATE `bonk_card` SET `rarity` = 3, `cooldown_ms` = 120000, `value3` = 0, `max_copies` = 1,
    `description` = 'Every 120 sec, every experience orb on the ground flies to you. Only one can be held.'
    WHERE `id` = 28;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
