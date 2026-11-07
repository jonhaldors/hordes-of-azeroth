DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261027710000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261027710000');

INSERT INTO `bonk_account_talent` (`account`, `talent`, `rank`, `enabled`)
SELECT `account`, 18, LEAST(`rank`, 5), 0 FROM `bonk_account_upgrade` WHERE `upgrade` = 29
ON DUPLICATE KEY UPDATE `rank` = GREATEST(`bonk_account_talent`.`rank`, VALUES(`rank`));
DELETE FROM `bonk_account_upgrade` WHERE `upgrade` = 29;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
