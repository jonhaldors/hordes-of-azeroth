DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020960000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020960000');

UPDATE `bonk_weapon` SET `starter_option_mask` = 0 WHERE `id` = 504;
UPDATE `bonk_weapon` SET `starter_option_mask` = 16 WHERE `id` = 505;

UPDATE `bonk_mastery` m JOIN `bonk_weapon` w ON w.`id` = 505 SET
    m.`target` = 505, m.`name` = 'Atonement', m.`icon` = w.`icon`,
    m.`description` = 'Penance can be your starter spell. Choose it at the Run Master.'
WHERE m.`id` = 50102;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
