DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101700000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101700000');

INSERT INTO `bonk_account_quest` (`account`, `quest`, `progress`, `completed`)
SELECT DISTINCT c.`account`, 576, 1, 1 FROM `characters` c JOIN `bonk_character_mode` m ON m.`guid` = c.`guid`
ON DUPLICATE KEY UPDATE `progress` = 1, `completed` = 1;

DROP TABLE IF EXISTS `bonk_character_mode`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
