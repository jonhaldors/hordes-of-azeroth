DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261030010000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261030010000');

CREATE TABLE IF NOT EXISTS `bonk_item_found` (
  `item_guid` INT UNSIGNED NOT NULL,
  `tier` SMALLINT UNSIGNED NOT NULL DEFAULT 1,
  `line1_effect` TINYINT UNSIGNED NOT NULL DEFAULT 255,
  `line1_roll` FLOAT NOT NULL DEFAULT 0,
  `line2_effect` TINYINT UNSIGNED NOT NULL DEFAULT 255,
  `line2_roll` FLOAT NOT NULL DEFAULT 0,
  PRIMARY KEY (`item_guid`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3;

DROP TEMPORARY TABLE IF EXISTS `gear_halving`;
CREATE TEMPORARY TABLE `gear_halving` (
  `old_id` INT UNSIGNED NOT NULL PRIMARY KEY,
  `new_id` INT UNSIGNED NOT NULL,
  `new_tier` INT UNSIGNED NOT NULL
);

INSERT IGNORE INTO `gear_halving` (`old_id`, `new_id`, `new_tier`)
SELECT DISTINCT `item_id`,
  `item_id` - ((`item_id` - 903000) MOD 160 DIV 8) * 8 + (CEIL(((`item_id` - 903000) MOD 160 DIV 8 + 1) / 2) - 1) * 8,
  CEIL(((`item_id` - 903000) MOD 160 DIV 8 + 1) / 2)
FROM `item_instance` WHERE `item_id` BETWEEN 903000 AND 904439;

INSERT IGNORE INTO `gear_halving` (`old_id`, `new_id`, `new_tier`)
SELECT DISTINCT `item_id`,
  `item_id` - (`item_id` - 904500) MOD 20 + CEIL(((`item_id` - 904500) MOD 20 + 1) / 2) - 1,
  CEIL(((`item_id` - 904500) MOD 20 + 1) / 2)
FROM `item_instance` WHERE `item_id` BETWEEN 904500 AND 904899;

INSERT IGNORE INTO `gear_halving` (`old_id`, `new_id`, `new_tier`)
SELECT DISTINCT `item_id`,
  `item_id` - (`item_id` - 905000) MOD 20 + CEIL(((`item_id` - 905000) MOD 20 + 1) / 2) - 1,
  CEIL(((`item_id` - 905000) MOD 20 + 1) / 2)
FROM `item_instance` WHERE `item_id` BETWEEN 905000 AND 905159;

INSERT IGNORE INTO `gear_halving` (`old_id`, `new_id`, `new_tier`)
SELECT DISTINCT `item_id`, 905000 + (`item_id` - 901420) * 20, 1
FROM `item_instance` WHERE `item_id` BETWEEN 901420 AND 901427;

INSERT IGNORE INTO `bonk_item_found` (`item_guid`, `tier`)
SELECT i.`guid`, h.`new_tier` FROM `item_instance` i JOIN `gear_halving` h ON h.`old_id` = i.`item_id`;

DROP TEMPORARY TABLE IF EXISTS `rescaled_owner`;
CREATE TEMPORARY TABLE `rescaled_owner` (
  `guid` INT UNSIGNED NOT NULL PRIMARY KEY,
  `text_id` INT UNSIGNED NOT NULL DEFAULT 0
);
INSERT IGNORE INTO `rescaled_owner` (`guid`)
SELECT DISTINCT i.`owner_guid` FROM `item_instance` i JOIN `gear_halving` h ON h.`old_id` = i.`item_id`
JOIN `characters` c ON c.`guid` = i.`owner_guid` WHERE h.`old_id` <> h.`new_id`;

UPDATE `item_instance` i JOIN `gear_halving` h ON h.`old_id` = i.`item_id` SET i.`item_id` = h.`new_id`;
UPDATE `character_inventory` x JOIN `item_instance` i ON i.`guid` = x.`item_guid` JOIN `bonk_item_found` f ON f.`item_guid` = x.`item_guid`
  SET x.`item_id` = i.`item_id`;
UPDATE `mail_items` x JOIN `item_instance` i ON i.`guid` = x.`item_guid` JOIN `bonk_item_found` f ON f.`item_guid` = x.`item_guid`
  SET x.`item_id` = i.`item_id`;
UPDATE `bonk_account_bank` x JOIN `item_instance` i ON i.`guid` = x.`item_guid` JOIN `bonk_item_found` f ON f.`item_guid` = x.`item_guid`
  SET x.`item_id` = i.`item_id`;

SET @rescale_text = (SELECT COALESCE(MAX(`id`), 0) FROM `item_text`);
UPDATE `rescaled_owner` SET `text_id` = (@rescale_text := @rescale_text + 1) ORDER BY `guid`;
INSERT INTO `item_text` (`id`, `text`)
SELECT `text_id`, 'Mythic gear now drops past Tier 20, so the gear you owned was rescaled to half its tier, rounded up: Tier 20 is now Tier 10, Tier 5 is now Tier 3.\n\nAll of it counts as gear you found. Bring Scrap to the Mythic Quartermaster to upgrade it 1 tier at a time, up to your best Mythic floor. The Quartermaster now sells up to Tier 10; higher tiers drop in Mythic runs.'
FROM `rescaled_owner`;
INSERT INTO `mail` (`message_type`, `stationery`, `mail_template_id`, `sender_guid`, `receiver_guid`, `subject`, `item_text_id`, `has_items`,
  `expire_time`, `deliver_time`, `money`, `cod`, `checked`)
SELECT 3, 41, 0, 900009, `guid`, 'Your Mythic gear was rescaled', `text_id`, 0,
  UNIX_TIMESTAMP() + 30 * 86400, UNIX_TIMESTAMP(), 0, 0, 0
FROM `rescaled_owner`;

DROP TEMPORARY TABLE IF EXISTS `rescaled_owner`;
DROP TEMPORARY TABLE IF EXISTS `gear_halving`;

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
