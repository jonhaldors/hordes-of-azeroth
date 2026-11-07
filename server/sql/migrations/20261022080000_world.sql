DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261022080000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261022080000');

UPDATE `item_template` SET `description` = 'Lets you escape the run early, for emergencies. Opens a ring at your feet: stand in it for 15 sec to return to the Inn with 1 item from the Extraction Vault. Disappears when the run ends.' WHERE `entry` = 900230;
UPDATE `bonk_upgrade` SET `description` = 'Adds a second slot to the Extraction Vault, so you can bring 1 additional piece of run gear home. The Hearthstone''s vault still holds only 1.' WHERE `id` = 28;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
