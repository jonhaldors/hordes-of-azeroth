DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261020994500');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261020994500');

UPDATE `item_template` SET `description` = 'For emergencies. Opens a ring at your feet: stand in it for 15 sec to end the run and return to the outpost with your Extraction Vault item. Disappears when the run ends.' WHERE `entry` = 900230;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
