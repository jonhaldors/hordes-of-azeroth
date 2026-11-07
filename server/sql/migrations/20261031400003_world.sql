DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031400003');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031400003');

UPDATE `bonk_tier` SET `stages` = 1, `description` = 'One stage in wide-open lands. Clear Normal 4 to open Heroic.' WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `stages` = 2, `description` = 'Two stages in rougher lands, with tougher foes, better loot, more Darkmoon Tickets and 50% more Mastery experience. Clear Heroic 5 to open Mythic.' WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `stages` = 3 WHERE `key` = 'mythic';

UPDATE `bonk_upgrade` SET `value_per_rank` = 1, `description` = '+1% Hearthstone find chance.' WHERE `id` = 25;
UPDATE `bonk_upgrade` SET `description` = '+1 Extraction Vault slot.' WHERE `id` = 28;
UPDATE `item_template` SET `description` = 'Mini-bosses on the last stage of a run can drop it. Opens a ring at your feet that fills over 15 sec. Be inside it when it fills to send 1 piece you found this run home. Disappears when the run ends.' WHERE `entry` = 900230;

DELETE FROM `gameobject` WHERE `id` IN (900023, 900070);
DELETE FROM `gameobject_template` WHERE `entry` IN (900023, 900070);
DELETE FROM `bonk_string_locale` WHERE `entry` IN (76, 78, 80, 201, 202, 291, 811, 812);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
