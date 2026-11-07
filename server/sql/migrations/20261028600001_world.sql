DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261028600001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261028600001');

DROP TEMPORARY TABLE IF EXISTS `pillar_template`;
CREATE TEMPORARY TABLE `pillar_template` AS SELECT * FROM `gameobject_template` WHERE `entry` = 900041;
UPDATE `pillar_template` SET `entry` = 900070, `displayId` = 2048, `name` = 'Extraction Pillar', `size` = 0.7, `script_name` = 'go_bonk_pillar';
DELETE FROM `gameobject_template` WHERE `entry` = 900070;
INSERT INTO `gameobject_template` SELECT * FROM `pillar_template`;
DROP TEMPORARY TABLE IF EXISTS `pillar_template`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;