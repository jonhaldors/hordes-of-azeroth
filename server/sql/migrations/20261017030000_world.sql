DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017030000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017030000');

DELETE FROM `bonk_quest`
WHERE `class` NOT IN (0, 3)
   OR (`type` IN (2, 21) AND `target` IN (SELECT `id` FROM `bonk_weapon` WHERE `class_mask` <> 4))
   OR (`reward_type` IN (2, 8) AND `reward_value` IN (SELECT `id` FROM `bonk_weapon` WHERE `class_mask` <> 4))
   OR `reward_type` = 7
   OR (`reward_type` = 9 AND `reward_value` IN (SELECT `id` FROM `bonk_mastery` WHERE `class` <> 3));

DELETE FROM `bonk_weapon_upgrade` WHERE `weapon_id` IN (SELECT `id` FROM `bonk_weapon` WHERE `class_mask` <> 4);
DELETE FROM `bonk_weapon` WHERE `class_mask` <> 4;
DELETE FROM `bonk_mastery` WHERE `class` <> 3;
DELETE FROM `bonk_mastery_tree` WHERE `class` <> 3;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
