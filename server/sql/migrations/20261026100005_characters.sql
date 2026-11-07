DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100005');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100005');

ALTER TABLE `bonk_account` ADD COLUMN `talent_reset` TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '1 = tell the player at login that their talents were refunded';

UPDATE `bonk_account` SET `talent_reset` = 1 WHERE `account` IN (SELECT DISTINCT `account` FROM `bonk_account_mastery_node`);
DELETE FROM `bonk_account_mastery_node`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
