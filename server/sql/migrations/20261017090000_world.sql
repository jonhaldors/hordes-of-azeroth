DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261017090000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261017090000');

UPDATE `bonk_mob_ability` SET `size` = 4, `comment` = REPLACE(`comment`, '(3 yd', '(4 yd') WHERE `entry` = 11982 AND `spell_id` = 19449 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 4.5, `comment` = REPLACE(`comment`, '(3.5 yd', '(4.5 yd') WHERE `entry` = 680 AND `spell_id` = 4164 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 4.5, `comment` = REPLACE(`comment`, '(3.5 yd', '(4.5 yd') WHERE `entry` = 1853 AND `spell_id` = 15791 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 4.5, `comment` = REPLACE(`comment`, '(3.5 yd', '(4.5 yd') WHERE `entry` = 12397 AND `spell_id` = 21341 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 639 AND `spell_id` = 7978 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 14834 AND `spell_id` = 24328 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 11486 AND `spell_id` = 19821 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 10813 AND `spell_id` = 14297 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 10430 AND `spell_id` = 11988 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 10429 AND `spell_id` = 8245 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 9019 AND `spell_id` = 19717 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 8443 AND `spell_id` = 12280 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 5, `comment` = REPLACE(`comment`, '(4 yd', '(5 yd') WHERE `entry` = 7273 AND `spell_id` = 10737 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6, `comment` = REPLACE(`comment`, '(4.5 yd', '(6 yd') WHERE `entry` = 11982 AND `spell_id` = 19411 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6, `comment` = REPLACE(`comment`, '(4.5 yd', '(6 yd') WHERE `entry` = 2611 AND `spell_id` = 19798 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6, `comment` = REPLACE(`comment`, '(4.5 yd', '(6 yd') WHERE `entry` = 2748 AND `spell_id` = 21071 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6.5, `comment` = REPLACE(`comment`, '(5 yd', '(6.5 yd') WHERE `entry` = 10363 AND `spell_id` = 16419 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6.5, `comment` = REPLACE(`comment`, '(5 yd', '(6.5 yd') WHERE `entry` = 14467 AND `spell_id` = 19695 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6.5, `comment` = REPLACE(`comment`, '(5 yd', '(6.5 yd') WHERE `entry` = 12397 AND `spell_id` = 21056 AND `shape` = 3;
UPDATE `bonk_mob_ability` SET `size` = 6.5, `comment` = REPLACE(`comment`, '(5 yd', '(6.5 yd') WHERE `entry` = 15339 AND `spell_id` = 25160 AND `shape` = 3;

DELETE FROM `command` WHERE `name` = 'bonk mobinfo';
INSERT INTO `command` (`name`, `security`, `help`, `flags`) VALUES
('bonk mobinfo', 2, 'Syntax: .bonk mobinfo\r\nShows debug facts about the selected creature, or about the nearest enemy within 50 yards when nothing is selected: entry, name and guid, alive or dead, health, despawning and time freeze, its Bonk AI state, faction and unit flags, who summoned or owns it, and its distance and line of sight from you. In a run it also says whether the run tracks it as an enemy and whether a 10-yard strike around you would hit it.', 0);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
