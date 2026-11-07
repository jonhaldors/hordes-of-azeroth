DROP PROCEDURE IF EXISTS add_migration;
DELIMITER ??
CREATE PROCEDURE `add_migration`()
BEGIN
DECLARE v INT DEFAULT 1;
SET v = (SELECT COUNT(*) FROM `migrations` WHERE `id`='20261016360000');
IF v = 0 THEN
INSERT INTO `migrations` VALUES ('20261016360000');

CREATE TABLE IF NOT EXISTS `bonk_hidden` (
    `id`            INT UNSIGNED NOT NULL,
    `name`          VARCHAR(64) NOT NULL,
    `map_id`        INT UNSIGNED NOT NULL COMMENT 'bonk_map.id',
    `chance`        FLOAT NOT NULL DEFAULT 15 COMMENT '% a stage',
    `trigger`       TINYINT UNSIGNED NOT NULL DEFAULT 0 COMMENT '0 use the object, 1 come near',
    `object_entry`  INT UNSIGNED NOT NULL,
    `boss_entry`    INT UNSIGNED NOT NULL,
    `boss_scale`    FLOAT NOT NULL DEFAULT 1,
    `add_entry`     INT UNSIGNED NOT NULL DEFAULT 0,
    `add_count`     TINYINT UNSIGNED NOT NULL DEFAULT 0,
    `chest_choices` TINYINT UNSIGNED NOT NULL DEFAULT 4,
    `yell`          VARCHAR(255) NOT NULL DEFAULT '',
    `found_text`    VARCHAR(255) NOT NULL DEFAULT '',
    PRIMARY KEY (`id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb3 COMMENT='Vanilla Bonk hidden encounters';

DELETE FROM `gameobject_template` WHERE `entry` IN (900060, 900061);
DROP TEMPORARY TABLE IF EXISTS `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900003;
UPDATE `bonk_go_copy` SET `entry` = 900060, `displayId` = 419, `name` = 'Suspicious Bush', `size` = 1.5, `script_name` = 'go_bonk_hidden';
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;
CREATE TEMPORARY TABLE `bonk_go_copy` SELECT * FROM `gameobject_template` WHERE `entry` = 900004;
UPDATE `bonk_go_copy` SET `entry` = 900061, `displayId` = 192, `name` = 'Campfire', `size` = 1;
INSERT INTO `gameobject_template` SELECT * FROM `bonk_go_copy`;
DROP TEMPORARY TABLE `bonk_go_copy`;

DELETE FROM `bonk_hidden`;
INSERT INTO `bonk_hidden` (`id`, `name`, `map_id`, `chance`, `trigger`, `object_entry`, `boss_entry`, `boss_scale`, `add_entry`, `add_count`, `chest_choices`, `yell`, `found_text`) VALUES
(1, 'Hogger',       1, 15, 0, 900060, 448, 1.3, 117, 4, 4, 'Grrr... fresh meat!',  'Something big was hiding in that bush... it''s Hogger!'),
(2, 'Old Murk-Eye', 1, 15, 1, 900061, 391, 1.5, 126, 6, 4, 'Mrrglllglglgl!',      'A murloc camp! Old Murk-Eye and his band charge out of the surf!');

DELETE FROM `bonk_quest` WHERE `id` IN (500, 501);
INSERT INTO `bonk_quest` (`id`, `name`, `description`, `icon`, `type`, `target`, `param`, `amount`, `reward_type`, `reward_value`, `class`, `category`) VALUES
(500, 'Hogger!',             'Find Hogger hiding in a Westfall run and defeat him.',          'Spell_Nature_NatureTouchGrow', 13, 1, 0, 1, 1, 5, 0, 4),
(501, 'King of the Murlocs', 'Find Old Murk-Eye''s camp in a Westfall run and defeat him.',  'INV_Misc_Head_Murloc_01',      13, 2, 0, 1, 1, 5, 0, 4);

END IF;
END??
DELIMITER ;
CALL add_migration();
DROP PROCEDURE IF EXISTS add_migration;
