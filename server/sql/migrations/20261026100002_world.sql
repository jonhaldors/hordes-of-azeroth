DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261026100002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261026100002');

UPDATE `bonk_tier` SET `stages` = 20, `endless` = 1, `stage_health_growth` = 0.2, `stage_health_accel` = 0, `stage_damage_growth` = 0.05, `stage_damage_accel` = 0,
  `description` = 'Climb floor by floor against the deadliest foes. Each floor is tougher and pays more; past floor 20 the climb goes on. Gives 100% more Mastery experience.'
  WHERE `key` = 'mythic';

UPDATE `bonk_quest` SET `description` = 'Clear Mythic floor 3.' WHERE `id` = 9;
UPDATE `bonk_quest` SET `description` = 'Reach Mythic floor 5.' WHERE `id` = 407;
UPDATE `bonk_quest` SET `description` = REPLACE(`description`, 'Clear stage 1 on Mythic as', 'Clear Mythic floor 1 as') WHERE `id` IN (150, 159, 168, 177, 186, 268, 278, 288, 328);


END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
