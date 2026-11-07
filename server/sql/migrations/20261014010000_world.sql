DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261014010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261014010000');

ALTER TABLE `bonk_tier`
    ADD COLUMN `charge_interval_ms` INT UNSIGNED NOT NULL DEFAULT 8000 COMMENT 'time between a charger''s charges' AFTER `first_elite_sec`;
UPDATE `bonk_tier` SET `charge_interval_ms` = 11000 WHERE `key` = 'easy';

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
