DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261031300001');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261031300001');

IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'endless') THEN
    ALTER TABLE `bonk_tier` CHANGE COLUMN `endless` `finale` tinyint(3) unsigned NOT NULL DEFAULT 0;
END IF;
IF NOT EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'levels') THEN
    ALTER TABLE `bonk_tier` ADD COLUMN `levels` int(10) unsigned NOT NULL DEFAULT 0,
        ADD COLUMN `level_health_growth` float NOT NULL DEFAULT 1,
        ADD COLUMN `level_damage_growth` float NOT NULL DEFAULT 1;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'stage_compound') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `stage_compound`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'floor_knee') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `floor_knee`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'late_health_growth') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `late_health_growth`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'late_damage_growth') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `late_damage_growth`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'floor_knee2') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `floor_knee2`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'last_health_growth') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `last_health_growth`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'last_damage_growth') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `last_damage_growth`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'knee_health_step') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `knee_health_step`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'knee2_health_step') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `knee2_health_step`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'boss_health_ramp_floors') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `boss_health_ramp_floors`;
END IF;
IF EXISTS (SELECT 1 FROM `information_schema`.`COLUMNS` WHERE `TABLE_SCHEMA` = DATABASE() AND `TABLE_NAME` = 'bonk_tier' AND `COLUMN_NAME` = 'unlock_stage') THEN
    ALTER TABLE `bonk_tier` DROP COLUMN `unlock_stage`;
END IF;

UPDATE `bonk_tier` SET `stages` = 3, `finale` = 1;
UPDATE `bonk_tier` SET `levels` = 4, `stage_health_growth` = 0.15, `stage_damage_growth` = 0.1, `stage_health_accel` = 0, `stage_damage_accel` = 0 WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `levels` = 5 WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `levels` = 0, `level_health_growth` = 1.08, `level_damage_growth` = 1.05,
    `stage_health_growth` = 0.25, `stage_damage_growth` = 0.25, `stage_health_accel` = 0.05, `stage_damage_accel` = 0.05 WHERE `key` = 'mythic';

UPDATE `bonk_tier` SET `description` = 'Three stages in wide-open lands. Clear Normal 4 to open Heroic.' WHERE `key` = 'normal';
UPDATE `bonk_tier` SET `description` = 'Three stages in rougher lands, with tougher foes, better loot, more Darkmoon Tickets and 50% more Mastery experience. Clear Heroic 5 to open Mythic.' WHERE `key` = 'heroic';
UPDATE `bonk_tier` SET `description` = 'Three stages against the deadliest foes. Every Mythic level is tougher and pays more, and there is always another one. Gives 100% more Mastery experience.',
    `details` = REPLACE(`details`, 'more on every floor.', 'more on every level.') WHERE `key` = 'mythic';

CREATE TABLE IF NOT EXISTS `bonk_level` (
  `tier` int(10) unsigned NOT NULL,
  `level` int(10) unsigned NOT NULL,
  `health` float NOT NULL DEFAULT 1,
  `damage` float NOT NULL DEFAULT 1,
  `extra_affixes` tinyint(3) unsigned NOT NULL DEFAULT 0,
  `veteran_chance` float NOT NULL DEFAULT 0,
  `reward` float NOT NULL DEFAULT 1,
  PRIMARY KEY (`tier`, `level`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COLLATE=utf8mb3_general_ci COMMENT='Hordes of Azeroth enemy scaling and rewards per difficulty level';

DELETE FROM `bonk_level`;
INSERT INTO `bonk_level` (`tier`, `level`, `health`, `damage`, `extra_affixes`, `veteran_chance`, `reward`) VALUES
(1, 1, 1.00, 1.00, 0, 0, 1.0),
(1, 2, 1.15, 1.08, 0, 0, 1.1),
(1, 3, 1.30, 1.16, 0, 0, 1.2),
(1, 4, 1.45, 1.24, 0, 0, 1.3),
(3, 1, 1.00, 1.00, 0, 0, 1.0),
(3, 2, 1.15, 1.06, 0, 0, 1.1),
(3, 3, 1.30, 1.12, 0, 0, 1.2),
(3, 4, 1.45, 1.18, 0, 0, 1.3),
(3, 5, 1.60, 1.24, 0, 0, 1.4),
(2, 1, 1.55, 1.42, 1, 5, 1.9),
(2, 6, 2.28, 1.81, 1, 10, 1.9),
(2, 11, 3.35, 2.31, 2, 10, 1.9);

UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1.' WHERE `id` = 8;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 11, `description` = 'Clear Mythic 2.' WHERE `id` = 9;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3.' WHERE `id` = 14;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3.' WHERE `id` = 51;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a hunter.' WHERE `id` = 141;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a hunter.' WHERE `id` = 148;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a hunter.' WHERE `id` = 149;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a hunter.' WHERE `id` = 150;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a warrior.' WHERE `id` = 151;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a warrior.' WHERE `id` = 157;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a warrior.' WHERE `id` = 158;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a warrior.' WHERE `id` = 159;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a mage.' WHERE `id` = 160;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a mage.' WHERE `id` = 166;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a mage.' WHERE `id` = 167;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a mage.' WHERE `id` = 168;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a shaman.' WHERE `id` = 169;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a shaman.' WHERE `id` = 175;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a shaman.' WHERE `id` = 176;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a shaman.' WHERE `id` = 177;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a priest.' WHERE `id` = 178;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a priest.' WHERE `id` = 184;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a priest.' WHERE `id` = 185;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a priest.' WHERE `id` = 186;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a rogue.' WHERE `id` = 260;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a rogue.' WHERE `id` = 266;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a rogue.' WHERE `id` = 267;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a rogue.' WHERE `id` = 268;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a paladin.' WHERE `id` = 270;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a paladin.' WHERE `id` = 276;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a paladin.' WHERE `id` = 277;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a paladin.' WHERE `id` = 278;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a warlock.' WHERE `id` = 280;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a warlock.' WHERE `id` = 286;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a warlock.' WHERE `id` = 287;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a warlock.' WHERE `id` = 288;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 1, `description` = 'Clear Normal 1 as a druid.' WHERE `id` = 320;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 5, `description` = 'Clear Heroic 1 as a druid.' WHERE `id` = 326;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 7, `description` = 'Clear Heroic 3 as a druid.' WHERE `id` = 327;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1 as a druid.' WHERE `id` = 328;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 11, `description` = 'Clear Mythic 2.' WHERE `id` = 407;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 10, `description` = 'Clear Mythic 1.' WHERE `id` = 412;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3.' WHERE `id` = 413;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 13, `description` = 'Clear Mythic 4.' WHERE `id` = 414;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5.' WHERE `id` = 415;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 15, `description` = 'Clear Mythic 6.' WHERE `id` = 416;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8.' WHERE `id` = 417;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a warrior.' WHERE `id` = 540;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a warrior.' WHERE `id` = 541;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a warrior.' WHERE `id` = 542;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a warrior.' WHERE `id` = 543;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a paladin.' WHERE `id` = 544;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a paladin.' WHERE `id` = 545;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a paladin.' WHERE `id` = 546;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a paladin.' WHERE `id` = 547;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a hunter.' WHERE `id` = 548;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a hunter.' WHERE `id` = 549;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a hunter.' WHERE `id` = 550;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a hunter.' WHERE `id` = 551;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a rogue.' WHERE `id` = 552;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a rogue.' WHERE `id` = 553;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a rogue.' WHERE `id` = 554;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a rogue.' WHERE `id` = 555;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a priest.' WHERE `id` = 556;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a priest.' WHERE `id` = 557;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a priest.' WHERE `id` = 558;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a priest.' WHERE `id` = 559;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a shaman.' WHERE `id` = 560;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a shaman.' WHERE `id` = 561;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a shaman.' WHERE `id` = 562;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a shaman.' WHERE `id` = 563;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a mage.' WHERE `id` = 564;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a mage.' WHERE `id` = 565;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a mage.' WHERE `id` = 566;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a mage.' WHERE `id` = 567;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a warlock.' WHERE `id` = 568;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a warlock.' WHERE `id` = 569;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a warlock.' WHERE `id` = 570;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a warlock.' WHERE `id` = 571;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 12, `description` = 'Clear Mythic 3 as a druid.' WHERE `id` = 572;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 14, `description` = 'Clear Mythic 5 as a druid.' WHERE `id` = 573;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 17, `description` = 'Clear Mythic 8 as a druid.' WHERE `id` = 574;
UPDATE `bonk_quest` SET `target` = 0, `amount` = 19, `description` = 'Clear Mythic 10 as a druid.' WHERE `id` = 575;

UPDATE `bonk_quest` SET `description` = REPLACE(`description`, 'floor boss', 'stage boss') WHERE `description` LIKE '%floor boss%';
UPDATE `bonk_quest` SET `description` = 'Clear a stage with 2 Dark Fortunes active.' WHERE `id` = 253;

UPDATE `bonk_glyph` SET `description` = 'Fatal damage restores you to full health instead. Once per run.', `value2` = 0 WHERE `id` = 11;
UPDATE `bonk_glyph` SET `description` = REPLACE(`description`, 'each floor', 'each stage') WHERE `id` = 19;
UPDATE `bonk_mastery` SET `description` = REPLACE(`description`, 'Once per floor', 'Once per stage') WHERE `description` LIKE 'Once per floor%';
UPDATE `bonk_talent` SET `description` = REPLACE(`description`, 'The floor boss arrives', 'Each stage boss arrives') WHERE `id` = 16;
UPDATE `bonk_map` SET `description` = REPLACE(REPLACE(`description`, 'leads the floor', 'leads the stage'), 'lead the floors', 'lead the stages') WHERE `description` LIKE '%floor%';

DELETE FROM `bonk_string_locale` WHERE `entry` IN (36, 250, 263, 265, 382, 384, 385, 386, 563, 564, 565, 566, 567, 568, 569, 570, 746, 748, 749);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
