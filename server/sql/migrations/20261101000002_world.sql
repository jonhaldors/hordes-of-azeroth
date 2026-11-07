DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261101000002');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261101000002');

INSERT INTO `bonk_title` (`id`, `name`, `pattern`, `class`, `stat`, `value`) VALUES (20, 'the Veteran', '%s the Veteran', 0, 0, 0);
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`)
VALUES (576, 'Old Guard', 'Played before Mythic levels replaced floors.', 'INV_Misc_Medal_01', 40, 0, 0, 1, 10, 20, 0, 1);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
