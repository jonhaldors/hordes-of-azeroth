DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030220000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030220000');

UPDATE `item_template` SET `name` = 'Gnomish Battle Goggles', `display_id` = 22420 WHERE `entry` BETWEEN 904740 AND 904759;
UPDATE `item_template` SET `name` = 'Goblin Land Mine', `display_id` = 7626 WHERE `entry` BETWEEN 904760 AND 904779;
UPDATE `item_template` SET `name` = 'Nifty Stopwatch', `display_id` = 6540 WHERE `entry` BETWEEN 904780 AND 904799;
UPDATE `item_template` SET `name` = 'Goblin Rocket Boots', `display_id` = 20622 WHERE `entry` BETWEEN 904800 AND 904819;
UPDATE `item_template` SET `name` = 'Demonic Rune', `display_id` = 22952 WHERE `entry` BETWEEN 904820 AND 904839;
UPDATE `item_template` SET `name` = 'Rumsey Rum', `display_id` = 18119 WHERE `entry` BETWEEN 904840 AND 904859;
UPDATE `item_template` SET `name` = 'Grinning Skull of Wrath', `display_id` = 5215 WHERE `entry` BETWEEN 904860 AND 904879;
UPDATE `item_template` SET `name` = 'Goblin Pocket Gold', `display_id` = 9649 WHERE `entry` BETWEEN 904880 AND 904899;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
