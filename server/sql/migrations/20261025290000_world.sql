DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261025290000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261025290000');

UPDATE `bonk_weapon` SET `description` = REPLACE(REPLACE(REPLACE(REPLACE(`description`,
    'Every 3 sec, Starfall strikes a random enemy with Moonfire.', 'Every 3 sec, Starfall strikes 3 different enemies with Moonfire.'),
    'Mauls the nearest enemy, splashing 20% on enemies within 5 yards.', 'Mauls the nearest enemy, splashing 10% on enemies within 5 yards.'),
    'Maul and Swipe deal 8% more per enemy within 8 yards, up to 64%.', 'Swipe deals 8% more per enemy within 8 yards, up to 64%.'),
    'each hit heals you 0.15% of your maximum health', 'each hit heals you 0.3% of your maximum health')
    WHERE `id` = 1013;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
