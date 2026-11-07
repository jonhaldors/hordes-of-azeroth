DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261012110000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261012110000');

ALTER TABLE `bonk_weapon`
    ADD COLUMN `tick_ms` INT UNSIGNED NOT NULL DEFAULT 0 COMMENT 'damage over time ticks this often, and damage_fraction is then per second; 0 = the spell''s own rate';

UPDATE `bonk_weapon` SET `target` = 3, `range` = 25, `cooldown_ms` = 10000, `duration_ms` = 10000, `tick_ms` = 500, `damage_fraction` = 0.3,
    `description` = 'Throws a cloud of poison onto the biggest pack of enemies. It lasts 10 seconds and poisons everything inside twice a second.'
    WHERE `id` = 26;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
